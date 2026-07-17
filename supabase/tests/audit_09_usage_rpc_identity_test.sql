BEGIN;
SELECT plan(1);

-- AUDIT-09: migration 025 moved usage mutation fully behind the service-role
-- gateway. Authenticated users cannot invoke the function at all, which is
-- stronger than the older in-function cross-user rejection.
SELECT ok(
  NOT has_function_privilege(
    'authenticated',
    'public.check_and_increment_usage(uuid,boolean,text)',
    'EXECUTE'
  ),
  'authenticated users cannot invoke check_and_increment_usage'
);

SELECT * FROM finish();
ROLLBACK;
