BEGIN;
SELECT plan(7);

SELECT has_function(
  'public',
  'keepalive',
  ARRAY[]::text[],
  'the keepalive RPC exists'
);

SELECT function_returns(
  'public',
  'keepalive',
  ARRAY[]::text[],
  'timestamp with time zone',
  'keepalive returns only a server timestamp'
);

SELECT is(
  (
    SELECT p.prosecdef
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'keepalive'
  ),
  false,
  'keepalive is SECURITY INVOKER, never definer'
);

SELECT is(
  (
    SELECT p.provolatile
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'keepalive'
  ),
  's',
  'keepalive is stable and cannot write rows'
);

SELECT ok(
  (
    SELECT p.proconfig::text LIKE '%search_path=%'
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'keepalive'
  ),
  'keepalive pins a restricted search_path'
);

SELECT ok(
  has_function_privilege('anon', 'public.keepalive()', 'EXECUTE'),
  'the public anon key can execute keepalive without service-role credentials'
);

SELECT ok(
  (SELECT public.keepalive()) IS NOT NULL,
  'keepalive executes a genuine query and returns the server time'
);

SELECT * FROM finish();
ROLLBACK;
