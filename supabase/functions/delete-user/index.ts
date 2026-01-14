// delete-user: Secure self-deletion edge function
// Deploy: supabase functions deploy delete-user
//
// Security model:
// 1. User's JWT verifies identity (anon key + bearer token)
// 2. Service role key used only for privileged deletion
// 3. Apple tokens revoked before auth record removal (compliance)
// 4. All user data deleted before auth record removal
import { createClient } from "npm:@supabase/supabase-js@2"

// Apple token revocation endpoint
const APPLE_REVOKE_URL = 'https://appleid.apple.com/auth/revoke'

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

// Generate Apple client secret JWT
// Required for Apple token revocation API
async function generateAppleClientSecret(): Promise<string | null> {
  const teamId = Deno.env.get('APPLE_TEAM_ID')
  const clientId = Deno.env.get('APPLE_CLIENT_ID') // Service ID (com.prosepal.prosepal)
  const keyId = Deno.env.get('APPLE_KEY_ID')
  const privateKey = Deno.env.get('APPLE_PRIVATE_KEY')

  if (!teamId || !clientId || !keyId || !privateKey) {
    console.warn('Apple credentials not configured - token revocation skipped')
    return null
  }

  // Create JWT header and payload
  const header = {
    alg: 'ES256',
    kid: keyId,
    typ: 'JWT'
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: teamId,
    iat: now,
    exp: now + 300, // 5 minutes
    aud: 'https://appleid.apple.com',
    sub: clientId
  }

  // Base64URL encode
  const encoder = new TextEncoder()
  const base64url = (data: Uint8Array) => 
    btoa(String.fromCharCode(...data))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')

  const headerB64 = base64url(encoder.encode(JSON.stringify(header)))
  const payloadB64 = base64url(encoder.encode(JSON.stringify(payload)))
  const signingInput = `${headerB64}.${payloadB64}`

  try {
    // Import the private key
    const pemContents = privateKey
      .replace(/-----BEGIN PRIVATE KEY-----/, '')
      .replace(/-----END PRIVATE KEY-----/, '')
      .replace(/\s/g, '')
    
    const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))
    
    const key = await crypto.subtle.importKey(
      'pkcs8',
      binaryKey,
      { name: 'ECDSA', namedCurve: 'P-256' },
      false,
      ['sign']
    )

    // Sign the JWT
    const signature = await crypto.subtle.sign(
      { name: 'ECDSA', hash: 'SHA-256' },
      key,
      encoder.encode(signingInput)
    )

    const signatureB64 = base64url(new Uint8Array(signature))
    return `${signingInput}.${signatureB64}`
  } catch (e) {
    console.error('Failed to generate Apple client secret:', e)
    return null
  }
}

// Revoke Apple refresh token
async function revokeAppleToken(refreshToken: string, clientSecret: string): Promise<boolean> {
  const clientId = Deno.env.get('APPLE_CLIENT_ID')
  if (!clientId) return false

  try {
    const response = await fetch(APPLE_REVOKE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: refreshToken,
        token_type_hint: 'refresh_token'
      })
    })

    if (response.ok) {
      console.log('Apple token revoked successfully')
      return true
    } else {
      const errorText = await response.text()
      console.warn('Apple token revocation failed:', response.status, errorText)
      return false
    }
  } catch (e) {
    console.error('Apple token revocation error:', e)
    return false
  }
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

    // Step 1: Revoke Apple tokens if user signed in with Apple (compliance requirement)
    try {
      // Check if user has stored Apple credentials
      const { data: appleCredentials } = await adminClient
        .from('apple_credentials')
        .select('refresh_token')
        .eq('user_id', user.id)
        .single()

      if (appleCredentials?.refresh_token) {
        console.log(`Revoking Apple token for ${userIdPrefix}...`)
        const clientSecret = await generateAppleClientSecret()
        if (clientSecret) {
          await revokeAppleToken(appleCredentials.refresh_token, clientSecret)
        }
        
        // Delete Apple credentials
        await adminClient
          .from('apple_credentials')
          .delete()
          .eq('user_id', user.id)
      }
    } catch (e) {
      // Log but continue - Apple revocation is best-effort
      console.warn(`Apple token revocation skipped for ${userIdPrefix}:`, e)
    }

    // Step 2: Delete user's data from custom tables BEFORE deleting auth record
    // This ensures data cleanup even if auth deletion fails
    
    // 2a. Delete user_usage
    try {
      const { error: usageError } = await adminClient
        .from('user_usage')
        .delete()
        .eq('user_id', user.id)

      if (usageError) {
        console.warn(`Failed to delete user_usage for ${userIdPrefix}:`, usageError.message)
      } else {
        console.log(`Deleted user_usage for ${userIdPrefix}`)
      }
    } catch (e) {
      console.warn(`Error deleting user_usage for ${userIdPrefix}:`, e)
    }

    // 2b. Delete user_entitlements (subscription status)
    try {
      const { error: entitlementError } = await adminClient
        .from('user_entitlements')
        .delete()
        .eq('user_id', user.id)

      if (entitlementError) {
        console.warn(`Failed to delete user_entitlements for ${userIdPrefix}:`, entitlementError.message)
      } else {
        console.log(`Deleted user_entitlements for ${userIdPrefix}`)
      }
    } catch (e) {
      console.warn(`Error deleting user_entitlements for ${userIdPrefix}:`, e)
    }

    // 2c. Delete rate limit logs for this user
    try {
      const { error: rateLimitError } = await adminClient
        .from('rate_limit_log')
        .delete()
        .eq('identifier', user.id)
        .eq('identifier_type', 'user')

      if (rateLimitError) {
        console.warn(`Failed to delete rate_limit_log for ${userIdPrefix}:`, rateLimitError.message)
      } else {
        console.log(`Deleted rate_limit_log for ${userIdPrefix}`)
      }
    } catch (e) {
      console.warn(`Error deleting rate_limit_log for ${userIdPrefix}:`, e)
    }

    // 2d. Remove user_id from device_usage.associated_user_ids (GDPR erasure)
    // This uses array_remove to clean up the user reference from any devices
    try {
      const { error: deviceError } = await adminClient.rpc('remove_user_from_devices', {
        p_user_id: user.id
      })

      if (deviceError) {
        console.warn(`Failed to remove user from device_usage for ${userIdPrefix}:`, deviceError.message)
      } else {
        console.log(`Removed user from device associations for ${userIdPrefix}`)
      }
    } catch (e) {
      console.warn(`Error removing user from device_usage for ${userIdPrefix}:`, e)
    }

    // Step 3: Delete the user from auth.users
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
