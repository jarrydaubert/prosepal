-- Harden native usage enforcement behind the generate-card Edge Function.
--
-- The native app does not call usage/rate-limit RPCs or read usage tables
-- directly. The gateway authenticates the user with the anon key, then calls
-- check_and_increment_usage with the service-role key. This removes the legacy
-- Flutter-era public RPC/table surface flagged by Supabase database lints.

CREATE OR REPLACE FUNCTION public.check_and_increment_usage(
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
  v_authenticated_user_id UUID;
  v_effective_user_id UUID;
  v_total_count INT;
  v_monthly_count INT;
  v_current_month_key TEXT;
  v_allowed BOOLEAN := FALSE;
  v_limit INT;
  v_remaining INT;
  v_server_is_pro BOOLEAN;
  v_pro_source TEXT;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User id is required'
      USING ERRCODE = '42501';
  END IF;

  IF p_month_key IS NULL OR p_month_key !~ '^[0-9]{4}-[0-9]{2}$' THEN
    RAISE EXCEPTION 'Invalid month key'
      USING ERRCODE = '22023';
  END IF;

  v_authenticated_user_id := auth.uid();

  IF auth.role() = 'service_role' THEN
    v_effective_user_id := p_user_id;
  ELSE
    IF v_authenticated_user_id IS NULL THEN
      RAISE EXCEPTION 'Authentication required'
        USING ERRCODE = '42501';
    END IF;

    IF p_user_id IS DISTINCT FROM v_authenticated_user_id THEN
      RAISE EXCEPTION 'Unauthorized user id'
        USING ERRCODE = '42501';
    END IF;

    v_effective_user_id := v_authenticated_user_id;
  END IF;

  -- Client p_is_pro remains ignored for security.
  SELECT is_pro INTO v_server_is_pro
  FROM public.user_entitlements
  WHERE user_id = v_effective_user_id
    AND (expires_at IS NULL OR expires_at > NOW());

  IF FOUND THEN
    v_pro_source := 'server';
  ELSE
    v_server_is_pro := FALSE;
    v_pro_source := 'no_record';
  END IF;

  SELECT total_count, monthly_count, month_key
  INTO v_total_count, v_monthly_count, v_current_month_key
  FROM public.user_usage
  WHERE user_id = v_effective_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    v_total_count := 0;
    v_monthly_count := 0;
    v_current_month_key := p_month_key;
  END IF;

  IF v_current_month_key != p_month_key THEN
    v_monthly_count := 0;
  END IF;

  IF v_server_is_pro THEN
    v_limit := 500;
    v_allowed := v_monthly_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_monthly_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  ELSE
    v_limit := 1;
    v_allowed := v_total_count < v_limit;
    v_remaining := GREATEST(0, v_limit - v_total_count - (CASE WHEN v_allowed THEN 1 ELSE 0 END));
  END IF;

  IF v_allowed THEN
    INSERT INTO public.user_usage (user_id, total_count, monthly_count, month_key, updated_at)
    VALUES (
      v_effective_user_id,
      v_total_count + 1,
      v_monthly_count + 1,
      p_month_key,
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
      total_count = public.user_usage.total_count + 1,
      monthly_count = CASE
        WHEN public.user_usage.month_key = p_month_key THEN public.user_usage.monthly_count + 1
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

COMMENT ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) IS
  'Atomically checks/increments usage for the native generate-card gateway. Direct client grants are revoked; service_role may call after Edge Function authentication.';

-- Tables used by gateway/service-role paths should not be visible to client
-- roles through GraphQL/PostgREST.
REVOKE SELECT ON public.user_usage FROM anon, authenticated;

-- Remove legacy client-facing SECURITY DEFINER RPC grants. The native app
-- reaches usage and rate limits through Edge Functions only.
REVOKE ALL ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) TO service_role;

REVOKE ALL ON FUNCTION public.check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_device_free_tier(TEXT, TEXT, UUID, BOOLEAN) FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.check_rate_limit(UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_rate_limit(UUID, TEXT, TEXT) FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.sync_user_usage(UUID, INT, INT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_user_usage(UUID, INT, INT, TEXT) FROM anon, authenticated;
