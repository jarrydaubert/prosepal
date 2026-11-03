-- Lock Down User Usage Table - Security Fix
-- Removes direct INSERT/UPDATE access, forcing all writes through RPC
-- This prevents clients from resetting their usage counts
--
-- Run this in Supabase SQL Editor after backing up data

-- Drop the permissive INSERT/UPDATE policies
-- Note: Original policy names from 001 migration
DROP POLICY IF EXISTS "user_usage_insert" ON user_usage;
DROP POLICY IF EXISTS "user_usage_update" ON user_usage;
-- Also drop if using alternative naming convention
DROP POLICY IF EXISTS "Users can insert own usage" ON user_usage;
DROP POLICY IF EXISTS "Users can update own usage" ON user_usage;

-- Revoke direct INSERT/UPDATE (keep SELECT for reading own usage)
REVOKE INSERT, UPDATE ON user_usage FROM authenticated;

-- Create explicit deny policies for INSERT/UPDATE
-- (Users must go through check_and_increment_usage RPC)
CREATE POLICY "No direct inserts to user_usage"
  ON user_usage
  FOR INSERT
  TO authenticated
  WITH CHECK (false);

CREATE POLICY "No direct updates to user_usage"
  ON user_usage
  FOR UPDATE
  TO authenticated
  USING (false)
  WITH CHECK (false);

-- Add RPC for syncing usage (used by _syncToServer in usage_service.dart)
-- This allows legitimate syncing while preventing abuse
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
  v_current_total INT;
  v_current_monthly INT;
  v_current_month_key TEXT;
BEGIN
  -- Verify caller is the user (security check)
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
  END IF;

  -- Get current server values
  SELECT total_count, monthly_count, month_key
  INTO v_current_total, v_current_monthly, v_current_month_key
  FROM user_usage
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Only allow INCREASING counts (prevents reset abuse)
  -- Take the higher of client vs server values
  IF NOT FOUND THEN
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

GRANT EXECUTE ON FUNCTION sync_user_usage(UUID, INT, INT, TEXT) TO authenticated;

COMMENT ON FUNCTION sync_user_usage IS
  'Syncs usage from client to server. Only allows INCREASING counts to prevent abuse.';
