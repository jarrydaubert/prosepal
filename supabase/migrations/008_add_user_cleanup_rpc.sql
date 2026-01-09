-- RPC function to remove user_id from device_usage.associated_user_ids
-- Called during account deletion for GDPR compliance
--
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif/sql

-- Function to remove a user from all device associations
-- Uses SECURITY DEFINER to bypass RLS (called from delete-user edge function)
CREATE OR REPLACE FUNCTION remove_user_from_devices(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Remove user_id from associated_user_ids array in all device records
  UPDATE device_usage
  SET associated_user_ids = array_remove(associated_user_ids, p_user_id)
  WHERE p_user_id = ANY(associated_user_ids);
END;
$$;

-- Only callable via service role (edge function)
REVOKE ALL ON FUNCTION remove_user_from_devices(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION remove_user_from_devices(UUID) FROM authenticated;
REVOKE ALL ON FUNCTION remove_user_from_devices(UUID) FROM anon;

-- Add comment
COMMENT ON FUNCTION remove_user_from_devices IS 
  'Removes user_id from device_usage.associated_user_ids for GDPR erasure. Called from delete-user edge function.';
