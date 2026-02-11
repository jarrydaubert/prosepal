BEGIN;
SELECT plan(1);

-- AUDIT-09: Authenticated user A must not be able to increment user B usage.
-- Simulate an authenticated request context by setting JWT claim + role.
SELECT set_config(
  'request.jwt.claim.sub',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  true
);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$
    SELECT check_and_increment_usage(
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
      false,
      '2026-02'
    );
  $$,
  '42501',
  'check_and_increment_usage denies cross-user usage mutation attempts'
);

SELECT * FROM finish();
ROLLBACK;
