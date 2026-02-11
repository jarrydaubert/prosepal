-- Harden device free-tier RPC against abuse
-- 1) Stronger fingerprint input validation
-- 2) Enforce auth.uid/p_user_id binding
-- 3) Apply server-side rate limiting for this RPC

-- Dedicated rate limits for device-check endpoint.
-- Keep generous limits to avoid blocking normal app usage while reducing abuse.
INSERT INTO rate_limit_config (identifier_type, endpoint, max_requests, window_seconds, enabled)
VALUES
  ('device', 'device_check', 60, 60, true),
  ('user', 'device_check', 30, 60, true)
ON CONFLICT (identifier_type, endpoint) DO NOTHING;

CREATE OR REPLACE FUNCTION check_device_free_tier(
  p_device_fingerprint TEXT,
  p_platform TEXT,
  p_user_id UUID DEFAULT NULL,
  p_mark_used BOOLEAN DEFAULT FALSE
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_record device_usage%ROWTYPE;
  v_allowed BOOLEAN := FALSE;
  v_is_new_device BOOLEAN := FALSE;
  v_auth_user_id UUID;
  v_rate_limit JSONB;
  v_rate_allowed BOOLEAN := TRUE;
  v_retry_after INT := 0;
BEGIN
  -- Validate fingerprint shape to reduce abuse surface from arbitrary payloads.
  IF p_device_fingerprint IS NULL
     OR length(p_device_fingerprint) < 8
     OR length(p_device_fingerprint) > 128
     OR p_device_fingerprint !~ '^[A-Za-z0-9:_-]+$'
  THEN
    RETURN jsonb_build_object(
      'allowed', FALSE,
      'error', 'Invalid device fingerprint'
    );
  END IF;

  -- Normalize platform.
  IF p_platform NOT IN ('ios', 'android') THEN
    p_platform := 'unknown';
  END IF;

  -- Bind p_user_id to the authenticated caller when available.
  -- Anonymous callers are never allowed to associate arbitrary user IDs.
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    p_user_id := NULL;
  ELSE
    p_user_id := v_auth_user_id;
  END IF;

  -- Apply server-side rate limit specific to this endpoint.
  SELECT check_rate_limit(
    p_user_id,
    p_device_fingerprint,
    'device_check'
  ) INTO v_rate_limit;

  v_rate_allowed := COALESCE((v_rate_limit->>'allowed')::BOOLEAN, TRUE);
  v_retry_after := COALESCE((v_rate_limit->>'retry_after')::INT, 0);

  IF NOT v_rate_allowed THEN
    RETURN jsonb_build_object(
      'allowed', FALSE,
      'error', 'Rate limit exceeded',
      'reason', COALESCE(v_rate_limit->>'reason', 'device_limit'),
      'retry_after', v_retry_after
    );
  END IF;

  -- Get current device record with row lock.
  SELECT * INTO v_record
  FROM device_usage
  WHERE device_fingerprint = p_device_fingerprint
  FOR UPDATE;

  IF NOT FOUND THEN
    -- New device - allowed to use free tier.
    v_allowed := TRUE;
    v_is_new_device := TRUE;
  ELSE
    -- Existing device - check if already used free tier.
    v_allowed := NOT v_record.used_free_tier;
  END IF;

  -- If marking as used and allowed, update/insert the record.
  IF p_mark_used AND v_allowed THEN
    IF v_is_new_device THEN
      INSERT INTO device_usage (
        device_fingerprint,
        used_free_tier,
        platform,
        first_seen_at,
        last_seen_at,
        associated_user_ids
      ) VALUES (
        p_device_fingerprint,
        TRUE,
        p_platform,
        NOW(),
        NOW(),
        CASE WHEN p_user_id IS NOT NULL THEN ARRAY[p_user_id] ELSE '{}' END
      );
    ELSE
      UPDATE device_usage SET
        used_free_tier = TRUE,
        last_seen_at = NOW(),
        associated_user_ids = CASE
          WHEN p_user_id IS NOT NULL AND NOT (p_user_id = ANY(associated_user_ids))
          THEN array_append(associated_user_ids, p_user_id)
          ELSE associated_user_ids
        END
      WHERE device_fingerprint = p_device_fingerprint;
    END IF;
  ELSIF NOT v_is_new_device THEN
    -- Just update last_seen and potentially add user_id.
    UPDATE device_usage SET
      last_seen_at = NOW(),
      associated_user_ids = CASE
        WHEN p_user_id IS NOT NULL AND NOT (p_user_id = ANY(associated_user_ids))
        THEN array_append(associated_user_ids, p_user_id)
        ELSE associated_user_ids
      END
    WHERE device_fingerprint = p_device_fingerprint;
  END IF;

  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'is_new_device', v_is_new_device,
    'device_fingerprint', left(p_device_fingerprint, 8) || '...'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) TO anon;

COMMENT ON FUNCTION check_device_free_tier IS
  'Checks/marks device free-tier status with fingerprint validation, caller-bound user_id, and RPC rate limiting.';
