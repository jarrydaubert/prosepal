// exchange-apple-token: Exchange Apple authorization code for refresh token
// Deploy: supabase functions deploy exchange-apple-token
//
// Called immediately after Apple Sign In to exchange the short-lived
// authorization code for a long-lived refresh token (for revocation on delete).
import { createClient } from "npm:@supabase/supabase-js@2.95.3"

const APPLE_TOKEN_URL = 'https://appleid.apple.com/auth/token'

// CORS restricted - only called from mobile app (native HTTP, not browser)
// Empty origin blocks browser-based attacks while allowing mobile requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '', // Mobile apps don't send Origin header
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Generate Apple client secret JWT
async function generateAppleClientSecret(): Promise<string | null> {
  const teamId = Deno.env.get('APPLE_TEAM_ID')
  const clientId = Deno.env.get('APPLE_CLIENT_ID')
  const keyId = Deno.env.get('APPLE_KEY_ID')
  const privateKey = Deno.env.get('APPLE_PRIVATE_KEY')

  if (!teamId || !clientId || !keyId || !privateKey) {
    console.warn('Apple credentials not configured')
    return null
  }

  const header = { alg: 'ES256', kid: keyId, typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: teamId,
    iat: now,
    exp: now + 300,
    aud: 'https://appleid.apple.com',
    sub: clientId
  }

  const encoder = new TextEncoder()
  const base64url = (data: Uint8Array) => 
    btoa(String.fromCharCode(...data))
      .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const headerB64 = base64url(encoder.encode(JSON.stringify(header)))
  const payloadB64 = base64url(encoder.encode(JSON.stringify(payload)))
  const signingInput = `${headerB64}.${payloadB64}`

  try {
    const pemContents = privateKey
      .replace(/-----BEGIN PRIVATE KEY-----/, '')
      .replace(/-----END PRIVATE KEY-----/, '')
      .replace(/\s/g, '')
    
    const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))
    const key = await crypto.subtle.importKey(
      'pkcs8', binaryKey,
      { name: 'ECDSA', namedCurve: 'P-256' },
      false, ['sign']
    )

    const signature = await crypto.subtle.sign(
      { name: 'ECDSA', hash: 'SHA-256' },
      key, encoder.encode(signingInput)
    )

    return `${signingInput}.${base64url(new Uint8Array(signature))}`
  } catch (e) {
    console.error('Failed to generate Apple client secret:', e)
    return null
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse body - handle empty body gracefully (e.g., health check calls)
    let authorization_code: string | undefined
    try {
      const body = await req.json()
      authorization_code = body?.authorization_code
    } catch {
      // Empty or invalid JSON body
      return new Response(
        JSON.stringify({ error: 'Missing or invalid request body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!authorization_code) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization_code' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const appleClientId = Deno.env.get('APPLE_CLIENT_ID')

    // Verify user
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

    // Generate client secret
    const clientSecret = await generateAppleClientSecret()
    if (!clientSecret || !appleClientId) {
      // Apple credentials not configured - FAIL LOUDLY
      // Do NOT store raw auth codes as fallback (security risk)
      console.error('Apple credentials not configured - cannot exchange token')
      return new Response(
        JSON.stringify({ error: 'Apple Sign In not fully configured. Please contact support.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Exchange authorization code for tokens
    const tokenResponse = await fetch(APPLE_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: appleClientId,
        client_secret: clientSecret,
        code: authorization_code,
        grant_type: 'authorization_code'
      })
    })

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error('Apple token exchange failed:', tokenResponse.status, errorText)
      return new Response(
        JSON.stringify({ error: 'Token exchange failed' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const tokens = await tokenResponse.json()
    
    // Store refresh token
    const adminClient = createClient(supabaseUrl, supabaseServiceKey)
    await adminClient.from('apple_credentials').upsert({
      user_id: user.id,
      refresh_token: tokens.refresh_token,
      access_token: tokens.access_token,
      token_exchanged_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })

    console.log(`Apple tokens stored for user ${user.id.substring(0, 8)}...`)
    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'An error occurred' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
