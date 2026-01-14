-- User Entitlements Table
-- Stores RevenueCat-synced subscription status for server-side verification
-- This prevents clients from spoofing Pro status
--
-- Run this in Supabase SQL Editor or via migration

-- Create entitlements table
CREATE TABLE IF NOT EXISTS user_entitlements (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_pro BOOLEAN NOT NULL DEFAULT FALSE,
  product_id TEXT,
  expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revenuecat_app_user_id TEXT,
  last_event_type TEXT
);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_user_entitlements_expires 
  ON user_entitlements(expires_at) 
  WHERE is_pro = TRUE;

-- RLS policies
ALTER TABLE user_entitlements ENABLE ROW LEVEL SECURITY;

-- Users can read their own entitlements
CREATE POLICY "Users can read own entitlements" ON user_entitlements
  FOR SELECT USING (auth.uid() = user_id);

-- Only service role can insert/update (via webhook)
-- No INSERT/UPDATE policy for authenticated users = webhook-only writes

-- Helper function to check if user is Pro (with expiry check)
CREATE OR REPLACE FUNCTION is_user_pro(p_user_id UUID)
RETURNS BOOLEAN AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION is_user_pro(UUID) TO authenticated;

-- Add comment
COMMENT ON TABLE user_entitlements IS 
  'RevenueCat-synced subscription status. Updated via webhook, read by usage RPC.';
COMMENT ON FUNCTION is_user_pro IS 
  'Server-side Pro status check with expiry validation. Returns FALSE if no record or expired.';
