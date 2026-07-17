-- Dedicated pre-launch inactivity keepalive.
-- Free-plan Supabase projects pause after prolonged inactivity; a scheduled
-- workflow calls this RPC daily so production and staging register genuine
-- database activity. The function is deliberately inert: it reads no user
-- data, writes nothing, and returns only the server timestamp.

CREATE OR REPLACE FUNCTION public.keepalive()
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT now();
$$;

COMMENT ON FUNCTION public.keepalive() IS
  'Read-only inactivity keepalive. Executes a genuine query (SELECT now()), touches no tables, and returns only the server timestamp. Safe for the public anon key.';

REVOKE ALL ON FUNCTION public.keepalive() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.keepalive() TO anon, authenticated, service_role;
