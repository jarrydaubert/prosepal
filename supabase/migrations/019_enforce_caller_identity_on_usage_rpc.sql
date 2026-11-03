-- Enforce caller identity for check_and_increment_usage
-- Prevents authenticated users from targeting another user's usage row.

CREATE OR REPLACE FUNCTION check_and_increment_usage(
  p_user_id UUID,
  p_is_pro BOOLEAN,
  p_month_key TEXT
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_authenticated_user_id UUID;
  v_total_count INT;
  v_monthly_count INT;
  v_current_month_key TEXT;
  v_allowed BOOLEAN := FALSE;
  v_limit INT;
  v_remaining INT;
  v_server_is_pro BOOLEAN;
  v_pro_source TEXT;
BEGIN
  -- Enforce that callers can only operate on their own user_id.
  v_authenticated_user_id := auth.uid();

  IF v_authenticated_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING ERRCODE = '42501';
  END IF;

  IF p_user_id IS DISTINCT FROM v_authenticated_user_id THEN
    RAISE EXCEPTION 'Unauthorized user id'
      USING ERRCODE = '42501';
  END IF;

  -- SERVER-SIDE PRO CHECK
  -- Client p_is_pro remains ignored for security.
  SELECT is_pro INTO v_server_is_pro
  FROM user_entitlements
  WHERE user_id = v_authenticated_user_id
    AND (expires_at IS NULL OR expires_at > NOW());

  IF FOUND THEN
    v_pro_source := 'server';
  ELSE
    v_server_is_pro := FALSE;
    v_pro_source := 'no_record';
  END IF;

  -- Get current usage with row lock to prevent race conditions.
  SELECT total_count, monthly_count, month_key
  INTO v_total_count, v_monthly_count, v_current_month_key
  FROM user_usage
  WHERE user_id = v_authenticated_user_id
  FOR UPDATE;

  -- Initialize if new user.
  IF NOT FOUND THEN
    v_total_count := 0;
    v_monthly_count := 0;
    v_current_month_key := p_month_key;
  END IF;

  -- Reset monthly count if new month.
  IF v_current_month_key != p_month_key THEN
    v_monthly_count := 0;
  END IF;

  -- Check limits based on server-verified subscription status.
  IF v_server_is_pro THEN
    v_limit := 500;
    v_allowed := v_monthly_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_monthly_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  ELSE
    v_limit := 1;
    v_allowed := v_total_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_total_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  END IF;

  -- Increment if allowed.
  IF v_allowed THEN
    INSERT INTO user_usage (user_id, total_count, monthly_count, month_key, updated_at)
    VALUES (
      v_authenticated_user_id,
      v_total_count + 1,
      v_monthly_count + 1,
      p_month_key,
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
      total_count = user_usage.total_count + 1,
      monthly_count = CASE
        WHEN user_usage.month_key = p_month_key THEN user_usage.monthly_count + 1
        ELSE 1
      END,
      month_key = p_month_key,
      updated_at = NOW();
  END IF;

  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'total_count', v_total_count + (CASE WHEN v_allowed THEN 1 ELSE 0 END),
    'monthly_count', v_monthly_count + (CASE WHEN v_allowed THEN 1 ELSE 0 END),
    'remaining', v_remaining,
    'limit', v_limit,
    'is_pro', v_server_is_pro,
    'pro_source', v_pro_source
  );
END;
$$;

-- Keep explicit grant for clarity across environments.
GRANT EXECUTE ON FUNCTION check_and_increment_usage(UUID, BOOLEAN, TEXT) TO authenticated;

COMMENT ON FUNCTION check_and_increment_usage IS
  'Atomically checks/increments usage for authenticated caller only. Pro status is verified server-side via user_entitlements and client p_is_pro is ignored.';
