-- Fix unused variable warnings in RPC functions
-- Addresses lint warnings from `supabase db lint`

-- ============================================================
-- Fix sync_user_usage: Remove unused variables
-- The SELECT INTO vars were for comparison but UPDATE uses column refs directly
-- ============================================================
CREATE OR REPLACE FUNCTION sync_user_usage(
  p_user_id UUID,
  p_total_count INT,
  p_monthly_count INT,
  p_month_key TEXT
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  -- Verify caller is the user (security check)
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
  END IF;

  -- Check if record exists (with row lock)
  SELECT EXISTS(
    SELECT 1 FROM user_usage WHERE user_id = p_user_id FOR UPDATE
  ) INTO v_exists;

  IF NOT v_exists THEN
    -- New record - insert with provided values
    INSERT INTO user_usage (user_id, total_count, monthly_count, month_key, updated_at)
    VALUES (p_user_id, p_total_count, p_monthly_count, p_month_key, NOW());
  ELSE
    -- Existing record - only increase, never decrease
    UPDATE user_usage SET
      total_count = GREATEST(total_count, p_total_count),
      monthly_count = CASE
        WHEN month_key = p_month_key THEN GREATEST(monthly_count, p_monthly_count)
        WHEN p_month_key > month_key THEN p_monthly_count  -- New month, accept client value
        ELSE monthly_count  -- Client has old month, keep server value
      END,
      month_key = GREATEST(month_key, p_month_key),
      updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- ============================================================
-- Fix check_rate_limit: Remove unused v_identifier and v_identifier_type
-- ============================================================
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID DEFAULT NULL,
  p_device_fingerprint TEXT DEFAULT NULL,
  p_endpoint TEXT DEFAULT 'generation'
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_config rate_limit_config%ROWTYPE;
  v_count INT;
  v_window_start TIMESTAMPTZ;
  v_blocked BOOLEAN := FALSE;
  v_retry_after INT := 0;
  v_reason TEXT := NULL;
BEGIN
  -- Check user rate limit first (most specific)
  IF p_user_id IS NOT NULL THEN
    SELECT * INTO v_config 
    FROM rate_limit_config 
    WHERE identifier_type = 'user' 
      AND endpoint = p_endpoint 
      AND enabled = true;
    
    IF FOUND THEN
      v_window_start := NOW() - (v_config.window_seconds || ' seconds')::INTERVAL;
      
      SELECT COUNT(*) INTO v_count
      FROM rate_limit_log
      WHERE identifier = p_user_id::TEXT
        AND identifier_type = 'user'
        AND endpoint = p_endpoint
        AND created_at > v_window_start;
      
      IF v_count >= v_config.max_requests THEN
        v_blocked := TRUE;
        v_reason := 'user_limit';
        -- Calculate retry_after from oldest entry in window
        SELECT EXTRACT(EPOCH FROM (MIN(created_at) + (v_config.window_seconds || ' seconds')::INTERVAL - NOW()))::INT
        INTO v_retry_after
        FROM rate_limit_log
        WHERE identifier = p_user_id::TEXT
          AND identifier_type = 'user'
          AND endpoint = p_endpoint
          AND created_at > v_window_start;
        v_retry_after := GREATEST(v_retry_after, 1);
      END IF;
    END IF;
  END IF;
  
  -- Check device rate limit if not already blocked
  IF NOT v_blocked AND p_device_fingerprint IS NOT NULL AND length(p_device_fingerprint) >= 8 THEN
    SELECT * INTO v_config 
    FROM rate_limit_config 
    WHERE identifier_type = 'device' 
      AND endpoint = p_endpoint 
      AND enabled = true;
    
    IF FOUND THEN
      v_window_start := NOW() - (v_config.window_seconds || ' seconds')::INTERVAL;
      
      SELECT COUNT(*) INTO v_count
      FROM rate_limit_log
      WHERE identifier = p_device_fingerprint
        AND identifier_type = 'device'
        AND endpoint = p_endpoint
        AND created_at > v_window_start;
      
      IF v_count >= v_config.max_requests THEN
        v_blocked := TRUE;
        v_reason := 'device_limit';
        SELECT EXTRACT(EPOCH FROM (MIN(created_at) + (v_config.window_seconds || ' seconds')::INTERVAL - NOW()))::INT
        INTO v_retry_after
        FROM rate_limit_log
        WHERE identifier = p_device_fingerprint
          AND identifier_type = 'device'
          AND endpoint = p_endpoint
          AND created_at > v_window_start;
        v_retry_after := GREATEST(v_retry_after, 1);
      END IF;
    END IF;
  END IF;
  
  -- If allowed, record the request for both user and device
  IF NOT v_blocked THEN
    IF p_user_id IS NOT NULL THEN
      INSERT INTO rate_limit_log (identifier, identifier_type, endpoint)
      VALUES (p_user_id::TEXT, 'user', p_endpoint);
    END IF;
    
    IF p_device_fingerprint IS NOT NULL AND length(p_device_fingerprint) >= 8 THEN
      INSERT INTO rate_limit_log (identifier, identifier_type, endpoint)
      VALUES (p_device_fingerprint, 'device', p_endpoint);
    END IF;
  END IF;
  
  RETURN jsonb_build_object(
    'allowed', NOT v_blocked,
    'retry_after', v_retry_after,
    'reason', v_reason
  );
END;
$$;

-- Re-grant permissions (CREATE OR REPLACE preserves them, but be explicit)
GRANT EXECUTE ON FUNCTION sync_user_usage(UUID, INT, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit(UUID, TEXT, TEXT) TO anon;

-- Comments
COMMENT ON FUNCTION sync_user_usage IS
  'Syncs usage from client to server. Only allows INCREASING counts to prevent abuse.';
COMMENT ON FUNCTION check_rate_limit IS 
  'Checks and records rate limits. Returns JSON with allowed status and retry_after seconds if blocked.';
