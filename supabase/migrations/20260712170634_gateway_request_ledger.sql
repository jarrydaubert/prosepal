-- Atomic gateway reservation, burst limiting, quota enforcement, and replay.
--
-- The Edge Function is the only caller. Direct client access is revoked and
-- every SECURITY DEFINER function uses an empty search path with qualified
-- relation names.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

CREATE TABLE public.gateway_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  idempotency_key TEXT NOT NULL,
  request_fingerprint TEXT NOT NULL,
  reservation_token UUID NOT NULL DEFAULT gen_random_uuid(),
  status TEXT NOT NULL DEFAULT 'reserved'
    CHECK (status IN ('reserved', 'completed', 'failed')),
  attempt_count INTEGER NOT NULL DEFAULT 1 CHECK (attempt_count > 0),
  failure_bucket TEXT,
  lane TEXT NOT NULL,
  contract_version TEXT NOT NULL,
  is_pro BOOLEAN NOT NULL DEFAULT FALSE,
  month_key TEXT NOT NULL,
  response_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reservation_expires_at TIMESTAMPTZ NOT NULL,
  payload_expires_at TIMESTAMPTZ,
  CONSTRAINT gateway_requests_subject_key_unique
    UNIQUE (subject, idempotency_key),
  CONSTRAINT gateway_requests_identity_shape CHECK (
    (user_id IS NOT NULL AND subject = user_id::TEXT)
    OR (user_id IS NULL AND subject = 'dev-anonymous')
  ),
  CONSTRAINT gateway_requests_idempotency_key_shape CHECK (
    idempotency_key ~ '^[A-Za-z0-9._:-]{1,120}$'
  ),
  CONSTRAINT gateway_requests_fingerprint_shape CHECK (
    request_fingerprint ~ '^[a-f0-9]{64}$'
  ),
  CONSTRAINT gateway_requests_month_key_shape CHECK (
    month_key ~ '^[0-9]{4}-[0-9]{2}$'
  )
);

CREATE INDEX gateway_requests_active_subject_idx
  ON public.gateway_requests(subject, reservation_expires_at)
  WHERE status = 'reserved';

CREATE INDEX gateway_requests_payload_expiry_idx
  ON public.gateway_requests(payload_expires_at)
  WHERE response_payload IS NOT NULL;

CREATE INDEX gateway_requests_cleanup_idx
  ON public.gateway_requests(updated_at)
  WHERE status <> 'reserved';

ALTER TABLE public.gateway_requests ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.gateway_requests FROM PUBLIC, anon, authenticated;

COMMENT ON TABLE public.gateway_requests IS
  'Service-role-only native gateway request ledger. Successful response payloads contain sensitive generated message text and are purged after 24 hours.';
COMMENT ON COLUMN public.gateway_requests.request_fingerprint IS
  'SHA-256 of sanitized provider-affecting request fields. Never logged.';
COMMENT ON COLUMN public.gateway_requests.reservation_token IS
  'Per-attempt token preventing a stale finalize from completing a reclaimed reservation.';
COMMENT ON COLUMN public.gateway_requests.response_payload IS
  'Sensitive generated CardResponse retained for at most 24 hours to replay a response lost in transit.';

CREATE OR REPLACE FUNCTION public.reserve_card_request(
  p_user_id UUID,
  p_dev_anonymous BOOLEAN,
  p_idempotency_key TEXT,
  p_request_fingerprint TEXT,
  p_lane TEXT,
  p_contract_version TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_subject TEXT;
  v_month_key TEXT := to_char(timezone('UTC', NOW()), 'YYYY-MM');
  v_existing public.gateway_requests%ROWTYPE;
  v_request_id UUID;
  v_reservation_token UUID;
  v_server_is_pro BOOLEAN := FALSE;
  v_total_count INTEGER := 0;
  v_monthly_count INTEGER := 0;
  v_usage_month_key TEXT;
  v_active_reservations INTEGER := 0;
  v_effective_count INTEGER := 0;
  v_limit INTEGER;
  v_remaining INTEGER;
  v_rate_count INTEGER := 0;
  v_retry_after INTEGER := 1;
BEGIN
  IF p_user_id IS NULL AND NOT COALESCE(p_dev_anonymous, FALSE) THEN
    RAISE EXCEPTION 'A gateway subject is required' USING ERRCODE = '22023';
  END IF;

  IF p_user_id IS NOT NULL AND COALESCE(p_dev_anonymous, FALSE) THEN
    RAISE EXCEPTION 'Gateway subject modes are mutually exclusive' USING ERRCODE = '22023';
  END IF;

  IF p_idempotency_key IS NULL
     OR p_idempotency_key !~ '^[A-Za-z0-9._:-]{1,120}$' THEN
    RAISE EXCEPTION 'Invalid idempotency key' USING ERRCODE = '22023';
  END IF;

  IF p_request_fingerprint IS NULL
     OR p_request_fingerprint !~ '^[a-f0-9]{64}$' THEN
    RAISE EXCEPTION 'Invalid request fingerprint' USING ERRCODE = '22023';
  END IF;

  IF p_lane IS NULL OR length(p_lane) > 40
     OR p_contract_version IS NULL OR length(p_contract_version) > 40 THEN
    RAISE EXCEPTION 'Invalid gateway request metadata' USING ERRCODE = '22023';
  END IF;

  v_subject := COALESCE(p_user_id::TEXT, 'dev-anonymous');
  PERFORM pg_advisory_xact_lock(hashtextextended(v_subject, 0));

  SELECT *
  INTO v_existing
  FROM public.gateway_requests
  WHERE subject = v_subject
    AND idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing.request_fingerprint <> p_request_fingerprint THEN
      RETURN jsonb_build_object('outcome', 'idempotency_conflict');
    END IF;

    IF v_existing.status = 'completed' THEN
      IF v_existing.response_payload IS NOT NULL
         AND v_existing.payload_expires_at > NOW() THEN
        RETURN jsonb_build_object(
          'outcome', 'replay',
          'request_id', v_existing.id,
          'response_payload', v_existing.response_payload
        );
      END IF;
      RETURN jsonb_build_object('outcome', 'replay_expired');
    END IF;

    IF v_existing.status = 'reserved'
       AND v_existing.reservation_expires_at > NOW() THEN
      RETURN jsonb_build_object(
        'outcome', 'in_flight',
        'retry_after', GREATEST(
          1,
          CEIL(EXTRACT(EPOCH FROM (v_existing.reservation_expires_at - NOW())))::INTEGER
        )
      );
    END IF;
  END IF;

  IF p_user_id IS NOT NULL THEN
    SELECT COALESCE(is_pro, FALSE)
    INTO v_server_is_pro
    FROM public.user_entitlements
    WHERE user_id = p_user_id
      AND is_pro = TRUE
      AND (expires_at IS NULL OR expires_at > NOW());

    IF NOT FOUND THEN
      v_server_is_pro := FALSE;
    END IF;

    SELECT total_count, monthly_count, month_key
    INTO v_total_count, v_monthly_count, v_usage_month_key
    FROM public.user_usage
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
      v_total_count := 0;
      v_monthly_count := 0;
      v_usage_month_key := v_month_key;
    ELSIF v_usage_month_key <> v_month_key THEN
      v_monthly_count := 0;
    END IF;

    SELECT COUNT(*)::INTEGER
    INTO v_active_reservations
    FROM public.gateway_requests
    WHERE subject = v_subject
      AND status = 'reserved'
      AND reservation_expires_at > NOW();

    IF v_server_is_pro THEN
      v_limit := 500;
      v_effective_count := v_monthly_count + v_active_reservations;
    ELSE
      v_limit := 1;
      v_effective_count := v_total_count + v_active_reservations;
    END IF;

    IF v_effective_count >= v_limit THEN
      RETURN jsonb_build_object(
        'outcome', 'quota_exhausted',
        'remaining', 0,
        'limit', v_limit,
        'is_pro', v_server_is_pro
      );
    END IF;
  END IF;

  SELECT COUNT(*)::INTEGER
  INTO v_rate_count
  FROM public.rate_limit_log
  WHERE identifier = v_subject
    AND identifier_type = 'user'
    AND endpoint = 'generation'
    AND created_at > NOW() - INTERVAL '60 seconds';

  IF v_rate_count >= 10 THEN
    SELECT GREATEST(
      1,
      CEIL(EXTRACT(EPOCH FROM (MIN(created_at) + INTERVAL '60 seconds' - NOW())))::INTEGER
    )
    INTO v_retry_after
    FROM public.rate_limit_log
    WHERE identifier = v_subject
      AND identifier_type = 'user'
      AND endpoint = 'generation'
      AND created_at > NOW() - INTERVAL '60 seconds';

    RETURN jsonb_build_object(
      'outcome', 'rate_limited',
      'retry_after', COALESCE(v_retry_after, 1)
    );
  END IF;

  INSERT INTO public.rate_limit_log(identifier, identifier_type, endpoint)
  VALUES (v_subject, 'user', 'generation');

  v_reservation_token := gen_random_uuid();
  IF v_existing.id IS NOT NULL THEN
    UPDATE public.gateway_requests
    SET status = 'reserved',
        reservation_token = v_reservation_token,
        attempt_count = attempt_count + 1,
        failure_bucket = NULL,
        user_id = p_user_id,
        is_pro = v_server_is_pro,
        month_key = v_month_key,
        lane = p_lane,
        contract_version = p_contract_version,
        updated_at = NOW(),
        reservation_expires_at = NOW() + INTERVAL '120 seconds',
        response_payload = NULL,
        payload_expires_at = NULL
    WHERE id = v_existing.id
    RETURNING id INTO v_request_id;
  ELSE
    INSERT INTO public.gateway_requests(
      subject,
      user_id,
      idempotency_key,
      request_fingerprint,
      reservation_token,
      status,
      lane,
      contract_version,
      is_pro,
      month_key,
      reservation_expires_at
    ) VALUES (
      v_subject,
      p_user_id,
      p_idempotency_key,
      p_request_fingerprint,
      v_reservation_token,
      'reserved',
      p_lane,
      p_contract_version,
      v_server_is_pro,
      v_month_key,
      NOW() + INTERVAL '120 seconds'
    )
    RETURNING id INTO v_request_id;
  END IF;

  v_remaining := CASE
    WHEN p_user_id IS NULL THEN NULL
    ELSE GREATEST(0, v_limit - v_effective_count - 1)
  END;

  RETURN jsonb_build_object(
    'outcome', 'reserved',
    'request_id', v_request_id,
    'reservation_token', v_reservation_token,
    'remaining', v_remaining,
    'limit', v_limit,
    'is_pro', v_server_is_pro
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.finalize_card_request(
  p_request_id UUID,
  p_reservation_token UUID,
  p_outcome TEXT,
  p_failure_bucket TEXT,
  p_response_payload JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_subject TEXT;
  v_request public.gateway_requests%ROWTYPE;
  v_total_count INTEGER := 0;
  v_monthly_count INTEGER := 0;
  v_current_month_key TEXT;
BEGIN
  IF p_request_id IS NULL OR p_reservation_token IS NULL THEN
    RAISE EXCEPTION 'Request id and reservation token are required' USING ERRCODE = '22023';
  END IF;

  IF p_outcome NOT IN ('completed', 'failed') THEN
    RAISE EXCEPTION 'Invalid finalization outcome' USING ERRCODE = '22023';
  END IF;

  SELECT subject
  INTO v_subject
  FROM public.gateway_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('outcome', 'not_found');
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(v_subject, 0));

  SELECT *
  INTO v_request
  FROM public.gateway_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('outcome', 'not_found');
  END IF;

  IF v_request.reservation_token <> p_reservation_token THEN
    RETURN jsonb_build_object('outcome', 'stale_reservation');
  END IF;

  IF v_request.status = 'completed' AND p_outcome = 'completed' THEN
    RETURN jsonb_build_object(
      'outcome', 'already_completed',
      'response_payload', v_request.response_payload
    );
  END IF;

  IF v_request.status = 'failed' AND p_outcome = 'failed' THEN
    RETURN jsonb_build_object('outcome', 'already_failed');
  END IF;

  IF v_request.status <> 'reserved' THEN
    RETURN jsonb_build_object(
      'outcome', 'illegal_transition',
      'current_status', v_request.status
    );
  END IF;

  IF p_outcome = 'failed' THEN
    UPDATE public.gateway_requests
    SET status = 'failed',
        failure_bucket = LEFT(COALESCE(p_failure_bucket, 'unknown'), 80),
        response_payload = NULL,
        payload_expires_at = NULL,
        updated_at = NOW()
    WHERE id = p_request_id;

    RETURN jsonb_build_object('outcome', 'failed');
  END IF;

  IF p_response_payload IS NULL OR jsonb_typeof(p_response_payload) <> 'object' THEN
    RAISE EXCEPTION 'Completed response payload must be a JSON object' USING ERRCODE = '22023';
  END IF;

  IF v_request.user_id IS NOT NULL THEN
    SELECT total_count, monthly_count, month_key
    INTO v_total_count, v_monthly_count, v_current_month_key
    FROM public.user_usage
    WHERE user_id = v_request.user_id;

    IF NOT FOUND THEN
      v_total_count := 0;
      v_monthly_count := 0;
      v_current_month_key := v_request.month_key;
    ELSIF v_current_month_key <> v_request.month_key THEN
      v_monthly_count := 0;
    END IF;

    INSERT INTO public.user_usage(
      user_id,
      total_count,
      monthly_count,
      month_key,
      updated_at
    ) VALUES (
      v_request.user_id,
      v_total_count + 1,
      v_monthly_count + 1,
      v_request.month_key,
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
      total_count = public.user_usage.total_count + 1,
      monthly_count = CASE
        WHEN public.user_usage.month_key = v_request.month_key
          THEN public.user_usage.monthly_count + 1
        ELSE 1
      END,
      month_key = v_request.month_key,
      updated_at = NOW();
  END IF;

  UPDATE public.gateway_requests
  SET status = 'completed',
      failure_bucket = NULL,
      response_payload = p_response_payload,
      payload_expires_at = NOW() + INTERVAL '24 hours',
      updated_at = NOW()
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'outcome', 'completed',
    'response_payload', p_response_payload
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_gateway_requests()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payloads_cleared INTEGER;
  v_rows_deleted INTEGER;
BEGIN
  UPDATE public.gateway_requests
  SET response_payload = NULL,
      payload_expires_at = NULL,
      updated_at = NOW()
  WHERE response_payload IS NOT NULL
    AND payload_expires_at <= NOW();
  GET DIAGNOSTICS v_payloads_cleared = ROW_COUNT;

  DELETE FROM public.gateway_requests
  WHERE updated_at < NOW() - INTERVAL '7 days'
    AND (
      status <> 'reserved'
      OR reservation_expires_at <= NOW()
    );
  GET DIAGNOSTICS v_rows_deleted = ROW_COUNT;

  RETURN jsonb_build_object(
    'payloads_cleared', v_payloads_cleared,
    'rows_deleted', v_rows_deleted
  );
END;
$$;

-- Keep the reused sliding-window attempt log bounded as the gateway begins
-- writing one row for every provider-bound attempt.
CREATE OR REPLACE FUNCTION public.cleanup_rate_limit_logs()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM public.rate_limit_log
  WHERE created_at < NOW() - INTERVAL '1 hour';
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.reserve_card_request(UUID, BOOLEAN, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_card_request(UUID, BOOLEAN, TEXT, TEXT, TEXT, TEXT)
  TO service_role;

REVOKE ALL ON FUNCTION public.finalize_card_request(UUID, UUID, TEXT, TEXT, JSONB)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_card_request(UUID, UUID, TEXT, TEXT, JSONB)
  TO service_role;

REVOKE ALL ON FUNCTION public.cleanup_gateway_requests()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_gateway_requests()
  TO service_role;

REVOKE ALL ON FUNCTION public.cleanup_rate_limit_logs()
  FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.reserve_card_request(UUID, BOOLEAN, TEXT, TEXT, TEXT, TEXT) IS
  'Atomically reserves native gateway burst/quota capacity and resolves idempotency before provider work. Service-role only.';
COMMENT ON FUNCTION public.finalize_card_request(UUID, UUID, TEXT, TEXT, JSONB) IS
  'Finalizes exactly one reservation attempt. The reservation token rejects stale completions after reclaim. Service-role only.';
COMMENT ON FUNCTION public.cleanup_gateway_requests() IS
  'Purges sensitive replay payloads after 24 hours and terminal or abandoned ledger metadata after 7 days.';

SELECT cron.schedule(
  'prosepal-gateway-ledger-cleanup-hourly',
  '17 * * * *',
  $cron$
    SELECT public.cleanup_gateway_requests();
    SELECT public.cleanup_rate_limit_logs();
  $cron$
);

COMMENT ON FUNCTION public.check_and_increment_usage(UUID, BOOLEAN, TEXT) IS
  'Legacy native usage RPC retained for staged retirement. generate-card now uses reserve_card_request/finalize_card_request.';
