-- Apple Credentials Storage for Token Revocation
-- Stores Apple authorization codes/refresh tokens for account deletion compliance
--
-- Apple requires apps to revoke tokens when users delete their accounts.
-- See: https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif/sql

-- Table to store Apple credentials for token revocation
CREATE TABLE IF NOT EXISTS apple_credentials (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  authorization_code TEXT,              -- One-time code from Apple (expires in 5 min)
  refresh_token TEXT,                   -- Long-lived token for revocation
  access_token TEXT,                    -- Short-lived access token
  token_exchanged_at TIMESTAMPTZ,       -- When tokens were exchanged
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE apple_credentials ENABLE ROW LEVEL SECURITY;

-- Users can only read/update their own credentials
CREATE POLICY "Users can view own Apple credentials"
  ON apple_credentials
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own Apple credentials"
  ON apple_credentials
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own Apple credentials"
  ON apple_credentials
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_apple_credentials_user 
  ON apple_credentials(user_id);

-- Trigger to update updated_at
CREATE OR REPLACE TRIGGER update_apple_credentials_updated_at
  BEFORE UPDATE ON apple_credentials
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON apple_credentials TO authenticated;

-- Function to save Apple authorization code (called after sign-in)
CREATE OR REPLACE FUNCTION save_apple_authorization_code(
  p_authorization_code TEXT
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Upsert the authorization code
  INSERT INTO apple_credentials (user_id, authorization_code, created_at, updated_at)
  VALUES (v_user_id, p_authorization_code, NOW(), NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    authorization_code = p_authorization_code,
    updated_at = NOW();
  
  RETURN jsonb_build_object('success', true);
END;
$$;

-- Grant execute
GRANT EXECUTE ON FUNCTION save_apple_authorization_code(TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE apple_credentials IS 
  'Stores Apple Sign In credentials for token revocation on account deletion. Required for Apple compliance.';
COMMENT ON FUNCTION save_apple_authorization_code IS 
  'Saves Apple authorization code after sign-in. Call this immediately after Apple Sign In succeeds.';
