-- Server-Side Usage Enforcement RPC
-- CRITICAL: This prevents client-side bypass of usage limits
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif/sql

-- Create atomic usage check + increment function
-- Uses row-level locking to prevent race conditions
CREATE OR REPLACE FUNCTION check_and_increment_usage(
  p_user_id UUID,
  p_is_pro BOOLEAN,
  p_month_key TEXT
) RETURNS JSONB AS $$
DECLARE
  v_total_count INT;
  v_monthly_count INT;
  v_current_month_key TEXT;
  v_allowed BOOLEAN := FALSE;
  v_limit INT;
  v_remaining INT;
BEGIN
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
  
  -- Check limits based on subscription status
  IF p_is_pro THEN
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
    'is_pro', p_is_pro
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_and_increment_usage(UUID, BOOLEAN, TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION check_and_increment_usage IS 
  'Atomically checks usage limits and increments if allowed. Returns JSON with allowed status and counts.';
