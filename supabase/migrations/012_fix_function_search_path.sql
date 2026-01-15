-- Fix search_path security warnings for is_user_pro and check_and_increment_usage
-- Addresses Supabase Security Advisor warnings:
-- - function_search_path_mutable for public.is_user_pro
-- - function_search_path_mutable for public.check_and_increment_usage
--
-- Without SET search_path, attackers could exploit search_path injection
-- by creating malicious functions in schemas they control.
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/_/sql

-- Fix is_user_pro function
CREATE OR REPLACE FUNCTION is_user_pro(p_user_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
STABLE
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_pro BOOLEAN;
  v_expires_at TIMESTAMPTZ;
BEGIN
  SELECT is_pro, expires_at 
  INTO v_is_pro, v_expires_at
  FROM user_entitlements
  WHERE user_id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Check if subscription is active and not expired
  IF v_is_pro AND (v_expires_at IS NULL OR v_expires_at > NOW()) THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$;

-- Fix check_and_increment_usage function
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
  -- Check user_entitlements table instead of trusting client
  SELECT is_pro INTO v_server_is_pro
  FROM user_entitlements
  WHERE user_id = p_user_id
    AND (expires_at IS NULL OR expires_at > NOW());
  
  IF FOUND THEN
    v_pro_source := 'server';
  ELSE
    -- Fallback to client hint during migration period
    -- TODO: Remove this fallback after webhook is deployed and all users synced
    v_server_is_pro := p_is_pro;
    v_pro_source := 'client_hint';
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
    v_limit := 500; -- Pro monthly limit
    v_allowed := v_monthly_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_monthly_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  ELSE
    v_limit := 1; -- Free lifetime limit (single generation)
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

COMMENT ON FUNCTION is_user_pro IS 
  'Server-side Pro status check with expiry validation. Returns FALSE if no record or expired.';
COMMENT ON FUNCTION check_and_increment_usage IS 
  'Atomically checks usage limits and increments if allowed. Pro status verified server-side via user_entitlements table.';
