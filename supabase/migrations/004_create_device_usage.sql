-- Device Usage Tracking Table
-- Tracks which devices have used the free tier (survives reinstalls)
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif/sql

-- Create table for device-level free tier tracking
CREATE TABLE IF NOT EXISTS device_usage (
  device_fingerprint TEXT PRIMARY KEY,
  used_free_tier BOOLEAN NOT NULL DEFAULT FALSE,
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'unknown')),
  -- Track which user IDs have been associated with this device
  -- Useful for detecting account-switching abuse
  associated_user_ids UUID[] DEFAULT '{}'
);

-- Enable Row Level Security
ALTER TABLE device_usage ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read device records
-- (needed to check if their device has used free tier)
CREATE POLICY "Authenticated users can check device usage"
  ON device_usage
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow inserts via RPC function only (SECURITY DEFINER)
-- Direct inserts are blocked; must use check_device_free_tier RPC
CREATE POLICY "No direct inserts"
  ON device_usage
  FOR INSERT
  TO authenticated
  WITH CHECK (false);

-- Policy: Allow updates via RPC function only (SECURITY DEFINER)
CREATE POLICY "No direct updates"
  ON device_usage
  FOR UPDATE
  TO authenticated
  USING (false)
  WITH CHECK (false);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_device_usage_last_seen 
  ON device_usage(last_seen_at DESC);

-- Grant select permission to authenticated users
GRANT SELECT ON device_usage TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE device_usage IS 
  'Tracks device-level free tier usage. Device fingerprint is vendor ID (iOS) or Android ID.';
