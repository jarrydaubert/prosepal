-- Add App Store Server Notification entitlement metadata.
--
-- Native iOS uses StoreKit 2 locally, but server/gateway entitlement must be
-- driven by Apple's signed server notifications. This migration keeps the
-- existing user_entitlements table while adding App Store source metadata and a
-- minimal processed-notification ledger for idempotency/audit.

ALTER TABLE user_entitlements
  ADD COLUMN IF NOT EXISTS entitlement_source TEXT NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS app_store_original_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS app_store_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS app_store_environment TEXT,
  ADD COLUMN IF NOT EXISTS app_store_notification_type TEXT,
  ADD COLUMN IF NOT EXISTS app_store_notification_subtype TEXT,
  ADD COLUMN IF NOT EXISTS app_store_signed_date TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_user_entitlements_app_store_original_transaction_id
  ON user_entitlements(app_store_original_transaction_id)
  WHERE app_store_original_transaction_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS app_store_notification_events (
  notification_uuid TEXT PRIMARY KEY,
  notification_type TEXT NOT NULL,
  subtype TEXT,
  environment TEXT,
  product_id TEXT,
  original_transaction_id TEXT,
  transaction_id TEXT,
  app_account_token UUID,
  signed_date TIMESTAMPTZ,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

ALTER TABLE app_store_notification_events ENABLE ROW LEVEL SECURITY;

COMMENT ON COLUMN user_entitlements.entitlement_source IS
  'Authoritative entitlement source, for example app_store_server_notifications or app_store_server_api.';

COMMENT ON TABLE app_store_notification_events IS
  'Privacy-safe App Store Server Notification metadata. Does not store signed payloads, receipts, or tokens.';
