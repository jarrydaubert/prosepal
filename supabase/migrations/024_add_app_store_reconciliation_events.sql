-- Add a privacy-safe App Store Server API reconciliation ledger.
--
-- This table records operator/server reconciliation attempts for native
-- StoreKit 2 entitlements. It stores metadata only: no signed Apple payloads,
-- receipts, private keys, provider payloads, or raw transaction bodies.

CREATE TABLE IF NOT EXISTS app_store_reconciliation_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requested_transaction_id TEXT NOT NULL,
  requested_user_id UUID,
  resolved_user_id UUID,
  environment TEXT,
  product_id TEXT,
  original_transaction_id TEXT,
  transaction_id TEXT,
  app_account_token UUID,
  app_store_status INTEGER,
  is_pro BOOLEAN,
  expires_at TIMESTAMPTZ,
  outcome TEXT NOT NULL,
  error_code TEXT,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_store_reconciliation_events_resolved_user
  ON app_store_reconciliation_events(resolved_user_id)
  WHERE resolved_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_store_reconciliation_events_original_transaction
  ON app_store_reconciliation_events(original_transaction_id)
  WHERE original_transaction_id IS NOT NULL;

ALTER TABLE app_store_reconciliation_events ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE app_store_reconciliation_events IS
  'Privacy-safe App Store Server API reconciliation metadata. Does not store signed payloads, receipts, private keys, or raw transaction bodies.';
