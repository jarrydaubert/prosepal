-- Fix RLS Performance for all tables
-- 
-- Issue: auth.uid() is re-evaluated for each row, causing suboptimal query performance
-- Fix: Wrap in subquery (select auth.uid()) for single evaluation per query
--
-- See: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select

-- ============================================================
-- user_entitlements
-- ============================================================
DROP POLICY IF EXISTS "Users can read own entitlements" ON user_entitlements;

CREATE POLICY "Users can read own entitlements" ON user_entitlements
  FOR SELECT USING ((select auth.uid()) = user_id);

-- ============================================================
-- user_usage (SELECT policy only - INSERT/UPDATE blocked in 011)
-- ============================================================
DROP POLICY IF EXISTS "user_usage_select" ON user_usage;
DROP POLICY IF EXISTS "Users can view own usage" ON user_usage;

CREATE POLICY "Users can view own usage" ON user_usage
  FOR SELECT USING ((select auth.uid()) = user_id);

-- ============================================================
-- apple_credentials
-- ============================================================
DROP POLICY IF EXISTS "Users can read own Apple credentials" ON apple_credentials;
DROP POLICY IF EXISTS "Users can insert own Apple credentials" ON apple_credentials;

CREATE POLICY "Users can read own Apple credentials" ON apple_credentials
  FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own Apple credentials" ON apple_credentials
  FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

-- ============================================================
-- Comments
-- ============================================================
COMMENT ON POLICY "Users can read own entitlements" ON user_entitlements IS 
  'Optimized: uses (select auth.uid()) for single evaluation';

COMMENT ON POLICY "Users can view own usage" ON user_usage IS 
  'Optimized: uses (select auth.uid()) for single evaluation';

COMMENT ON POLICY "Users can read own Apple credentials" ON apple_credentials IS 
  'Optimized: uses (select auth.uid()) for single evaluation';

COMMENT ON POLICY "Users can insert own Apple credentials" ON apple_credentials IS 
  'Optimized: uses (select auth.uid()) for single evaluation';
