-- Fix RLS Performance for apple_credentials (missed in 013)
-- 
-- The original policy name is "Users can view own Apple credentials" not "read"

-- Drop the existing unoptimized policy
DROP POLICY IF EXISTS "Users can view own Apple credentials" ON apple_credentials;

-- Recreate with optimized auth.uid() call
CREATE POLICY "Users can view own Apple credentials" ON apple_credentials
  FOR SELECT USING ((select auth.uid()) = user_id);

-- Also fix UPDATE policy while we're here
DROP POLICY IF EXISTS "Users can update own Apple credentials" ON apple_credentials;

CREATE POLICY "Users can update own Apple credentials" ON apple_credentials
  FOR UPDATE USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Comments
COMMENT ON POLICY "Users can view own Apple credentials" ON apple_credentials IS 
  'Optimized: uses (select auth.uid()) for single evaluation';

COMMENT ON POLICY "Users can update own Apple credentials" ON apple_credentials IS 
  'Optimized: uses (select auth.uid()) for single evaluation';
