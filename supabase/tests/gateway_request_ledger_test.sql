BEGIN;
SELECT plan(27);

INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at
) VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'ledger-a@example.invalid', '',
    NOW(), NOW(), NOW()
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'ledger-b@example.invalid', '',
    NOW(), NOW(), NOW()
  );

SELECT ok(
  NOT has_function_privilege(
    'anon',
    'public.reserve_card_request(uuid,boolean,text,text,text,text)',
    'EXECUTE'
  ),
  'anon cannot reserve gateway requests'
);

SELECT ok(
  NOT has_function_privilege(
    'authenticated',
    'public.finalize_card_request(uuid,uuid,text,text,jsonb)',
    'EXECUTE'
  ),
  'authenticated cannot finalize gateway requests'
);

SELECT ok(
  has_function_privilege(
    'service_role',
    'public.reserve_card_request(uuid,boolean,text,text,text,text)',
    'EXECUTE'
  ),
  'service role can reserve gateway requests'
);

SELECT ok(
  NOT has_table_privilege('anon', 'public.gateway_requests', 'SELECT'),
  'anon cannot read the request ledger'
);

CREATE TEMP TABLE ledger_test_values (
  name TEXT PRIMARY KEY,
  value JSONB NOT NULL
);

INSERT INTO ledger_test_values(name, value)
SELECT 'first_reservation', public.reserve_card_request(
  '11111111-1111-1111-1111-111111111111',
  FALSE,
  'ledger-key-a',
  repeat('a', 64),
  'standard',
  'prompt-1:output-1'
);

SELECT is(
  (SELECT value->>'outcome' FROM ledger_test_values WHERE name = 'first_reservation'),
  'reserved',
  'first authenticated request reserves capacity'
);

SELECT is(
  public.reserve_card_request(
    '11111111-1111-1111-1111-111111111111',
    FALSE,
    'ledger-key-b',
    repeat('b', 64),
    'standard',
    'prompt-1:output-1'
  )->>'outcome',
  'quota_exhausted',
  'a live free reservation prevents concurrent quota oversubscription'
);

INSERT INTO ledger_test_values(name, value)
SELECT 'failed_finalize', public.finalize_card_request(
  (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'first_reservation'),
  (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'first_reservation'),
  'failed',
  'provider_failed',
  NULL
);

SELECT is(
  (SELECT value->>'outcome' FROM ledger_test_values WHERE name = 'failed_finalize'),
  'failed',
  'failed generation releases its reservation'
);

SELECT is(
  COALESCE((SELECT total_count FROM public.user_usage
            WHERE user_id = '11111111-1111-1111-1111-111111111111'), 0),
  0,
  'failed generation does not consume usage'
);

INSERT INTO ledger_test_values(name, value)
SELECT 'reclaimed_reservation', public.reserve_card_request(
  '11111111-1111-1111-1111-111111111111',
  FALSE,
  'ledger-key-a',
  repeat('a', 64),
  'standard',
  'prompt-1:output-1'
);

SELECT isnt(
  (SELECT value->>'reservation_token' FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
  (SELECT value->>'reservation_token' FROM ledger_test_values WHERE name = 'first_reservation'),
  'reclaim mints a fresh reservation token'
);

SELECT is(
  public.finalize_card_request(
    (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'first_reservation'),
    (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'first_reservation'),
    'completed',
    NULL,
    '{"messages":[]}'::JSONB
  )->>'outcome',
  'stale_reservation',
  'late finalization cannot complete a reclaimed attempt'
);

SELECT is(
  (SELECT COUNT(*)::INTEGER FROM public.rate_limit_log
   WHERE identifier = '11111111-1111-1111-1111-111111111111'
     AND endpoint = 'generation'),
  2,
  'reclaimed provider attempt receives its own burst-log row'
);

INSERT INTO ledger_test_values(name, value)
SELECT 'completed_finalize', public.finalize_card_request(
  (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
  (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
  'completed',
  NULL,
  '{"messages":[{"id":"one","text":"Hello"}],"usage":{"remaining":0,"limit":1}}'::JSONB
);

SELECT is(
  (SELECT value->>'outcome' FROM ledger_test_values WHERE name = 'completed_finalize'),
  'completed',
  'successful generation completes its reservation'
);

SELECT is(
  (SELECT total_count FROM public.user_usage
   WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'successful generation consumes usage exactly once'
);

SELECT is(
  public.finalize_card_request(
    (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
    (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
    'completed',
    NULL,
    '{"messages":[]}'::JSONB
  )->>'outcome',
  'already_completed',
  'duplicate completion is an idempotent no-op'
);

SELECT is(
  (SELECT total_count FROM public.user_usage
   WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'duplicate completion cannot double-charge usage'
);

SELECT is(
  public.finalize_card_request(
    (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
    (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'reclaimed_reservation'),
    'failed',
    'late_failure',
    NULL
  )->>'outcome',
  'illegal_transition',
  'completed reservation cannot transition to failed'
);

SELECT is(
  public.reserve_card_request(
    '11111111-1111-1111-1111-111111111111',
    FALSE,
    'ledger-key-a',
    repeat('a', 64),
    'standard',
    'prompt-1:output-1'
  )->>'outcome',
  'replay',
  'completed duplicate replays the retained response'
);

SELECT is(
  public.reserve_card_request(
    '11111111-1111-1111-1111-111111111111',
    FALSE,
    'ledger-key-a',
    repeat('c', 64),
    'standard',
    'prompt-1:output-1'
  )->>'outcome',
  'idempotency_conflict',
  'same key with different request fingerprint is rejected'
);

SELECT is(
  public.reserve_card_request(
    '22222222-2222-2222-2222-222222222222',
    FALSE,
    'ledger-key-a',
    repeat('a', 64),
    'standard',
    'prompt-1:output-1'
  )->>'outcome',
  'reserved',
  'same idempotency key is isolated across authenticated subjects'
);

INSERT INTO ledger_test_values(name, value)
SELECT 'dev_reservation', public.reserve_card_request(
  NULL,
  TRUE,
  'ledger-dev-key',
  repeat('d', 64),
  'standard',
  'prompt-1:output-1'
);

SELECT is(
  (SELECT value->>'outcome' FROM ledger_test_values WHERE name = 'dev_reservation'),
  'reserved',
  'authorized development request reserves burst capacity'
);

SELECT is(
  public.finalize_card_request(
    (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'dev_reservation'),
    (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'dev_reservation'),
    'failed',
    'provider_failed',
    NULL
  )->>'outcome',
  'failed',
  'development reservation can fail without usage accounting'
);

SELECT is(
  public.finalize_card_request(
    (SELECT (value->>'request_id')::UUID FROM ledger_test_values WHERE name = 'dev_reservation'),
    (SELECT (value->>'reservation_token')::UUID FROM ledger_test_values WHERE name = 'dev_reservation'),
    'failed',
    'provider_failed',
    NULL
  )->>'outcome',
  'already_failed',
  'duplicate failure finalization is idempotent'
);

UPDATE public.gateway_requests
SET response_payload = '{"messages":[]}'::JSONB,
    payload_expires_at = NOW() - INTERVAL '1 minute'
WHERE id = (
  SELECT (value->>'request_id')::UUID
  FROM ledger_test_values
  WHERE name = 'reclaimed_reservation'
);

SELECT is(
  public.cleanup_gateway_requests()->>'payloads_cleared',
  '1',
  'cleanup clears expired sensitive response payloads'
);

UPDATE public.gateway_requests
SET updated_at = NOW() - INTERVAL '8 days'
WHERE id = (
  SELECT (value->>'request_id')::UUID
  FROM ledger_test_values
  WHERE name = 'dev_reservation'
);

SELECT is(
  public.cleanup_gateway_requests()->>'rows_deleted',
  '1',
  'cleanup deletes old completed or failed ledger metadata'
);

UPDATE public.gateway_requests
SET updated_at = NOW() - INTERVAL '8 days',
    reservation_expires_at = NOW() + INTERVAL '1 minute'
WHERE subject = '22222222-2222-2222-2222-222222222222'
  AND idempotency_key = 'ledger-key-a';

SELECT ok(
  EXISTS (
    SELECT 1
    FROM public.gateway_requests
    WHERE subject = '22222222-2222-2222-2222-222222222222'
      AND idempotency_key = 'ledger-key-a'
  ),
  'cleanup retains an active reservation even when its row is old'
);

UPDATE public.gateway_requests
SET reservation_expires_at = NOW() - INTERVAL '1 minute'
WHERE subject = '22222222-2222-2222-2222-222222222222'
  AND idempotency_key = 'ledger-key-a';

SELECT is(
  public.cleanup_gateway_requests()->>'rows_deleted',
  '1',
  'cleanup deletes abandoned reservation metadata after seven days'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM cron.job
    WHERE jobname = 'prosepal-gateway-ledger-cleanup-hourly'
  ),
  'hourly gateway cleanup job is installed'
);

SELECT * FROM finish();
ROLLBACK;
