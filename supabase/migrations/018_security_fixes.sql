-- Security fixes for identified vulnerabilities
-- 1. Remove client Pro status fallback (CRITICAL)
-- 2. Restrict device_usage SELECT policy (MEDIUM)
--
-- Run this in Supabase SQL Editor after deploying updated edge functions

-- =============================================================================
-- FIX 1: Remove client Pro status fallback (CRITICAL)
-- =============================================================================
-- The webhook is deployed and working. Users without entitlement records
-- should default to FREE, not trust the client's p_is_pro parameter.

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
  v_total_count INT;
  v_monthly_count INT;
  v_current_month_key TEXT;
  v_allowed BOOLEAN := FALSE;
  v_limit INT;
  v_remaining INT;
  v_server_is_pro BOOLEAN;
  v_pro_source TEXT;
BEGIN
  -- SERVER-SIDE PRO CHECK (security fix)
  -- Check user_entitlements table - NEVER trust client
  SELECT is_pro INTO v_server_is_pro
  FROM user_entitlements
  WHERE user_id = p_user_id
    AND (expires_at IS NULL OR expires_at > NOW());
  
  IF FOUND THEN
    v_pro_source := 'server';
  ELSE
    -- NO FALLBACK: Users without entitlement record are FREE
    -- Client p_is_pro parameter is IGNORED for security
    v_server_is_pro := FALSE;
    v_pro_source := 'no_record';
  END IF;

  -- Get current usage with row lock to prevent race conditions
  SELECT total_count, monthly_count, month_key 
  INTO v_total_count, v_monthly_count, v_current_month_key
  FROM user_usage
  WHERE user_id = p_user_id
  FOR UPDATE;
  
  -- Initialize if new user
  IF NOT FOUND THEN
    v_total_count := 0;
    v_monthly_count := 0;
    v_current_month_key := p_month_key;
  END IF;
  
  -- Reset monthly count if new month
  IF v_current_month_key != p_month_key THEN
    v_monthly_count := 0;
  END IF;
  
  -- Check limits based on SERVER-VERIFIED subscription status
  IF v_server_is_pro THEN
    v_limit := 500;
    v_allowed := v_monthly_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_monthly_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  ELSE
    v_limit := 1;
    v_allowed := v_total_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_total_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  END IF;
  
  -- Increment if allowed
  IF v_allowed THEN
    INSERT INTO user_usage (user_id, total_count, monthly_count, month_key, updated_at)
    VALUES (
      p_user_id, 
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

COMMENT ON FUNCTION check_and_increment_usage IS 
  'Atomically checks usage limits and increments if allowed. Pro status verified SERVER-SIDE only via user_entitlements table. Client p_is_pro parameter is ignored.';

-- =============================================================================
-- FIX 2: Restrict device_usage SELECT policy (MEDIUM)
-- =============================================================================
-- Currently any authenticated user can read ANY device record.
-- Restrict to only devices where the user's ID is in associated_user_ids.

-- Drop the overly permissive policy
DROP POLICY IF EXISTS "Authenticated users can check device usage" ON device_usage;

-- Create restricted policy - users can only see devices they've used
CREATE POLICY "Users can only read their own device records"
  ON device_usage
  FOR SELECT
  TO authenticated
  USING (auth.uid() = ANY(associated_user_ids));

-- Also allow service role to read all (for admin/debugging)
CREATE POLICY "Service role can read all devices"
  ON device_usage
  FOR SELECT
  TO service_role
  USING (true);

COMMENT ON POLICY "Users can only read their own device records" ON device_usage IS
  'Security fix: Users can only see devices where their user_id is in associated_user_ids array.';
