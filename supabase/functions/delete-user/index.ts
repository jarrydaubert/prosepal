// delete-user: Secure self-deletion edge function
// Deploy: supabase functions deploy delete-user
//
// Security model:
// 1. User's JWT verifies identity (anon key + bearer token)
// 2. Service role key used only for privileged deletion
// 3. All user data deleted before auth record removal
import { createClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Sanitize error messages for client responses (don't leak internal details)
function getSafeErrorMessage(error: Error | unknown): string {
  if (error instanceof Error) {
    const msg = error.message.toLowerCase()
    if (msg.includes('not found') || msg.includes('does not exist')) {
      return 'Account not found or already deleted'
    }
    if (msg.includes('network') || msg.includes('connection')) {
      return 'Connection error. Please try again.'
    }
  }
  return 'An error occurred. Please try again.'
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header (user's JWT)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
      console.error('Missing required environment variables')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify user and get their ID
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })
    
    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid user' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Use service role to delete user (admin privilege required)
    const adminClient = createClient(supabaseUrl, supabaseServiceKey)

    // Log deletion attempt (redacted user ID for privacy)
    const userIdPrefix = user.id.substring(0, 8)
    console.log(`Deleting user data for ${userIdPrefix}...`)

    // Step 1: Delete user's data from custom tables BEFORE deleting auth record
    // This ensures data cleanup even if auth deletion fails
    try {
      const { error: usageError } = await adminClient
        .from('user_usage')
        .delete()
        .eq('user_id', user.id)

      if (usageError) {
        // Log but continue - user may not have usage data
        console.warn(`Failed to delete user_usage for ${userIdPrefix}:`, usageError.message)
      } else {
        console.log(`Deleted user_usage for ${userIdPrefix}`)
      }
    } catch (e) {
      console.warn(`Error deleting user_usage for ${userIdPrefix}:`, e)
    }

    // Step 2: Delete the user from auth.users
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)

    if (deleteError) {
      console.error(`Delete auth error for ${userIdPrefix}:`, deleteError)
      return new Response(
        JSON.stringify({ error: getSafeErrorMessage(deleteError) }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Successfully deleted user ${userIdPrefix}`)
    return new Response(
      JSON.stringify({ success: true, message: 'Account deleted successfully' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: getSafeErrorMessage(error) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
