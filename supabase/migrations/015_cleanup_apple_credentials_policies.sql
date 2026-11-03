-- Cleanup duplicate RLS policies on apple_credentials
-- 
-- Issue: Multiple permissive policies exist for same action, hurting performance
-- Fix: Drop ALL duplicates, create single optimized policy per action

-- ============================================================
-- DROP ALL existing policies (all variations)
-- ============================================================
DROP POLICY IF EXISTS "Users can read own Apple credentials" ON apple_credentials;
DROP POLICY IF EXISTS "Users can view own Apple credentials" ON apple_credentials;
DROP POLICY IF EXISTS "apple_credentials_select" ON apple_credentials;

DROP POLICY IF EXISTS "Users can insert own Apple credentials" ON apple_credentials;
DROP POLICY IF EXISTS "apple_credentials_insert" ON apple_credentials;

DROP POLICY IF EXISTS "Users can update own Apple credentials" ON apple_credentials;
DROP POLICY IF EXISTS "apple_credentials_update" ON apple_credentials;

-- ============================================================
-- CREATE single optimized policy per action
-- ============================================================
CREATE POLICY "apple_credentials_select" ON apple_credentials
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "apple_credentials_insert" ON apple_credentials
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "apple_credentials_update" ON apple_credentials
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ============================================================
-- Comments
-- ============================================================
COMMENT ON POLICY "apple_credentials_select" ON apple_credentials IS 
  'SELECT: Optimized with (select auth.uid()), authenticated only';
COMMENT ON POLICY "apple_credentials_insert" ON apple_credentials IS 
  'INSERT: Optimized with (select auth.uid()), authenticated only';
COMMENT ON POLICY "apple_credentials_update" ON apple_credentials IS 
  'UPDATE: Optimized with (select auth.uid()), authenticated only';
