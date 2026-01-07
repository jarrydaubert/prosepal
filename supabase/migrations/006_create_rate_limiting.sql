-- Rate Limiting Tables and Functions
-- Prevents API abuse by tracking request frequency per user/device
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif/sql

-- Table to track rate limit windows
-- Uses sliding window algorithm for accurate rate limiting
CREATE TABLE IF NOT EXISTS rate_limit_log (
  id BIGSERIAL PRIMARY KEY,
  identifier TEXT NOT NULL,           -- user_id, device_fingerprint, or IP
  identifier_type TEXT NOT NULL CHECK (identifier_type IN ('user', 'device', 'ip')),
  endpoint TEXT NOT NULL DEFAULT 'generation',  -- which endpoint/action
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookups within time window
CREATE INDEX IF NOT EXISTS idx_rate_limit_lookup 
  ON rate_limit_log(identifier, identifier_type, endpoint, created_at DESC);

-- Automatically clean up old entries (older than 1 hour)
-- This prevents table bloat
CREATE INDEX IF NOT EXISTS idx_rate_limit_cleanup 
  ON rate_limit_log(created_at);

-- Enable Row Level Security
ALTER TABLE rate_limit_log ENABLE ROW LEVEL SECURITY;

-- No direct access - only via RPC functions
CREATE POLICY "No direct access to rate limit log"
  ON rate_limit_log
  FOR ALL
  TO authenticated, anon
  USING (false)
  WITH CHECK (false);

-- Rate limit configuration table
-- Allows dynamic adjustment without code changes
CREATE TABLE IF NOT EXISTS rate_limit_config (
  id SERIAL PRIMARY KEY,
  identifier_type TEXT NOT NULL CHECK (identifier_type IN ('user', 'device', 'ip', 'global')),
  endpoint TEXT NOT NULL DEFAULT 'generation',
  max_requests INT NOT NULL DEFAULT 10,
  window_seconds INT NOT NULL DEFAULT 60,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(identifier_type, endpoint)
);

-- Insert default rate limits
INSERT INTO rate_limit_config (identifier_type, endpoint, max_requests, window_seconds, enabled)
VALUES 
  ('user', 'generation', 20, 60, true),      -- 20 requests per minute per user
  ('device', 'generation', 30, 60, true),    -- 30 requests per minute per device
  ('ip', 'generation', 50, 60, true),        -- 50 requests per minute per IP (shared networks)
  ('global', 'generation', 1000, 60, true)   -- 1000 requests per minute global (emergency brake)
ON CONFLICT (identifier_type, endpoint) DO NOTHING;

-- Enable RLS on config table (read-only for authenticated)
ALTER TABLE rate_limit_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read rate limit config"
  ON rate_limit_config
  FOR SELECT
  TO authenticated, anon
  USING (true);

-- Function to check rate limit
-- Returns JSON with allowed status and retry_after if blocked
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
  v_identifier TEXT;
  v_identifier_type TEXT;
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

-- Grant execute to authenticated and anonymous users
GRANT EXECUTE ON FUNCTION check_rate_limit(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit(UUID, TEXT, TEXT) TO anon;

-- Function to clean up old rate limit logs (call via cron or manually)
CREATE OR REPLACE FUNCTION cleanup_rate_limit_logs()
RETURNS INT
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_deleted INT;
BEGIN
  DELETE FROM rate_limit_log
  WHERE created_at < NOW() - INTERVAL '1 hour';
  
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

-- Add comment for documentation
COMMENT ON FUNCTION check_rate_limit IS 
  'Checks and records rate limits. Returns JSON with allowed status and retry_after seconds if blocked.';
COMMENT ON FUNCTION cleanup_rate_limit_logs IS 
  'Removes rate limit log entries older than 1 hour. Call periodically to prevent table bloat.';
COMMENT ON TABLE rate_limit_log IS 
  'Tracks API requests for rate limiting. Entries older than 1 hour should be cleaned up.';
COMMENT ON TABLE rate_limit_config IS 
  'Configurable rate limits per identifier type and endpoint.';
