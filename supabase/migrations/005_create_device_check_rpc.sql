-- Device Free Tier Check RPC
-- Atomically checks if device has used free tier and marks it if generation proceeds
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif/sql

-- Create atomic device check + mark function
-- Uses row-level locking to prevent race conditions
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
BEGIN
  -- Validate inputs
  IF p_device_fingerprint IS NULL OR length(p_device_fingerprint) < 8 THEN
    RETURN jsonb_build_object(
      'allowed', FALSE,
      'error', 'Invalid device fingerprint'
    );
  END IF;
  
  -- Normalize platform
  IF p_platform NOT IN ('ios', 'android') THEN
    p_platform := 'unknown';
  END IF;
  
  -- Get current device record with row lock
  SELECT * INTO v_record
  FROM device_usage
  WHERE device_fingerprint = p_device_fingerprint
  FOR UPDATE;
  
  IF NOT FOUND THEN
    -- New device - allowed to use free tier
    v_allowed := TRUE;
    v_is_new_device := TRUE;
  ELSE
    -- Existing device - check if already used free tier
    v_allowed := NOT v_record.used_free_tier;
  END IF;
  
  -- If marking as used and allowed, update/insert the record
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
    -- Just update last_seen and potentially add user_id
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) TO authenticated;

-- Also allow anonymous users to check (for free tier before sign-in)
GRANT EXECUTE ON FUNCTION check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) TO anon;

-- Add comment for documentation
COMMENT ON FUNCTION check_device_free_tier IS 
  'Checks if device has used free tier. If p_mark_used=true and allowed, marks device as used. Returns JSON with allowed status.';
