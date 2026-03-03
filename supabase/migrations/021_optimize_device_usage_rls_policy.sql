-- =============================================================================
-- Optimize device_usage RLS policy evaluation
-- =============================================================================
-- Supabase linter warns when auth.uid() is evaluated per row in policy checks.
-- Wrap auth.uid() in a scalar subquery so it is evaluated once per statement.

DROP POLICY IF EXISTS "Users can only read their own device records" ON device_usage;

CREATE POLICY "Users can only read their own device records"
  ON device_usage
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = ANY(associated_user_ids));

COMMENT ON POLICY "Users can only read their own device records" ON device_usage IS
  'Security fix + performance optimization: users can only see devices where their user_id is in associated_user_ids; optimized with (select auth.uid()).';
