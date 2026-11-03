BEGIN;
SELECT plan(9);

SELECT has_column(
  'public',
  'apple_credentials',
  'refresh_token',
  'Apple credentials retain the refresh token required for revocation'
);

SELECT hasnt_column(
  'public',
  'apple_credentials',
  'authorization_code',
  'one-time Apple authorization codes are not stored durably'
);

SELECT hasnt_column(
  'public',
  'apple_credentials',
  'access_token',
  'short-lived Apple access tokens are not stored durably'
);

SELECT is(
  (
    SELECT is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'apple_credentials'
      AND column_name = 'refresh_token'
  ),
  'NO',
  'stored Apple credential rows always contain revocation material'
);

SELECT ok(
  NOT has_table_privilege('anon', 'public.apple_credentials', 'SELECT'),
  'anonymous clients cannot read Apple revocation material'
);

SELECT ok(
  NOT has_table_privilege('authenticated', 'public.apple_credentials', 'SELECT'),
  'authenticated clients cannot read Apple revocation material'
);

SELECT ok(
  NOT has_table_privilege('authenticated', 'public.apple_credentials', 'INSERT,UPDATE,DELETE'),
  'authenticated clients cannot mutate Apple revocation material'
);

SELECT ok(
  has_table_privilege('service_role', 'public.apple_credentials', 'SELECT,INSERT,UPDATE,DELETE'),
  'service-role Edge Functions can manage Apple revocation material'
);

SELECT is(
  to_regprocedure('public.save_apple_authorization_code(text)'),
  NULL::regprocedure,
  'the client-callable authorization-code storage function is removed'
);

SELECT * FROM finish();
ROLLBACK;
