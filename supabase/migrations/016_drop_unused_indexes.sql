-- Drop unused indexes (can be re-added when needed at scale)
-- 
-- These indexes haven't been used yet due to low data volume.
-- Re-add them if query performance becomes an issue.

DROP INDEX IF EXISTS idx_device_usage_last_seen;
DROP INDEX IF EXISTS idx_user_usage_updated;
DROP INDEX IF EXISTS idx_user_entitlements_expires;

-- To re-add later if needed:
-- CREATE INDEX idx_device_usage_last_seen ON device_usage(last_seen_at);
-- CREATE INDEX idx_user_usage_updated ON user_usage(updated_at);
-- CREATE INDEX idx_user_entitlements_expires ON user_entitlements(expires_at) WHERE is_pro = TRUE;
