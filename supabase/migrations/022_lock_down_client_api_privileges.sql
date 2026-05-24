-- Lock down client role API privileges flagged by Supabase database lints.
--
-- The app should reach sensitive tables through RLS-scoped direct reads only
-- where still required, or through narrowly validated RPCs. SECURITY DEFINER
-- functions should not keep PostgreSQL's default PUBLIC execute grant.

-- Tables should not be visible to anonymous clients in GraphQL/PostgREST.
REVOKE SELECT ON public.apple_credentials FROM anon;
REVOKE SELECT ON public.device_usage FROM anon;
REVOKE SELECT ON public.rate_limit_config FROM anon;
REVOKE SELECT ON public.rate_limit_log FROM anon;
REVOKE SELECT ON public.user_entitlements FROM anon;
REVOKE SELECT ON public.user_usage FROM anon;

-- These tables are only used by SECURITY DEFINER RPCs or service-role edge
-- functions, so signed-in clients do not need direct table SELECT grants.
REVOKE SELECT ON public.apple_credentials FROM authenticated;
REVOKE SELECT ON public.device_usage FROM authenticated;
REVOKE SELECT ON public.rate_limit_config FROM authenticated;
REVOKE SELECT ON public.rate_limit_log FROM authenticated;
REVOKE SELECT ON public.user_entitlements FROM authenticated;

-- user_usage remains directly readable by authenticated users for
-- UsageService.syncFromServer(); RLS restricts rows to auth.uid().
GRANT SELECT ON public.user_usage TO authenticated;

-- Remove default PUBLIC execute grants from SECURITY DEFINER functions.
REVOKE ALL ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_rate_limit(UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cleanup_rate_limit_logs() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_user_pro(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.save_apple_authorization_code(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_user_usage(UUID, INT, INT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_updated_at_column() FROM PUBLIC;

-- Defense in depth: revoke direct role grants, then grant back only RPCs the
-- Flutter app intentionally calls.
REVOKE ALL ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.check_rate_limit(UUID, TEXT, TEXT) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.cleanup_rate_limit_logs() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.is_user_pro(UUID) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.save_apple_authorization_code(TEXT) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_user_usage(UUID, INT, INT, TEXT) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.update_updated_at_column() FROM anon, authenticated;

GRANT EXECUTE ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sync_user_usage(UUID, INT, INT, TEXT) TO authenticated;

-- Some deployed databases contain this helper from older/manual hardening.
-- Revoke it when present without making fresh environments fail.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'rls_auto_enable'
      AND pg_get_function_identity_arguments(p.oid) = ''
  ) THEN
    REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC;
    REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM anon, authenticated;
  END IF;
END $$;
