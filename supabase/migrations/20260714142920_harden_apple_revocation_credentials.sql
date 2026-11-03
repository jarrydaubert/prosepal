-- Keep Apple revocation material behind the service-role Edge Function boundary.
-- Authorization codes are exchanged immediately and access tokens are not
-- needed for account deletion, so neither belongs in durable storage.

DROP FUNCTION IF EXISTS public.save_apple_authorization_code(TEXT);

DROP POLICY IF EXISTS "Users can read own Apple credentials" ON public.apple_credentials;
DROP POLICY IF EXISTS "Users can view own Apple credentials" ON public.apple_credentials;
DROP POLICY IF EXISTS "Users can insert own Apple credentials" ON public.apple_credentials;
DROP POLICY IF EXISTS "Users can update own Apple credentials" ON public.apple_credentials;
DROP POLICY IF EXISTS "apple_credentials_select" ON public.apple_credentials;
DROP POLICY IF EXISTS "apple_credentials_insert" ON public.apple_credentials;
DROP POLICY IF EXISTS "apple_credentials_update" ON public.apple_credentials;

REVOKE ALL ON TABLE public.apple_credentials FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.apple_credentials TO service_role;

DELETE FROM public.apple_credentials
WHERE refresh_token IS NULL OR btrim(refresh_token) = '';

ALTER TABLE public.apple_credentials
  ALTER COLUMN refresh_token SET NOT NULL,
  DROP COLUMN IF EXISTS authorization_code,
  DROP COLUMN IF EXISTS access_token;

COMMENT ON TABLE public.apple_credentials IS
  'Service-role-only Apple refresh tokens retained solely for account-deletion revocation.';
COMMENT ON COLUMN public.apple_credentials.refresh_token IS
  'Apple refresh token used only by the authenticated account-deletion Edge Function.';
