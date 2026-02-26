// revenuecat-webhook: Sync subscription status from RevenueCat
// Deploy: supabase functions deploy revenuecat-webhook
//
// Setup in RevenueCat Dashboard:
// 1. Go to Project Settings > Integrations > Webhooks
// 2. Add webhook URL: https://<project>.supabase.co/functions/v1/revenuecat-webhook
// 3. Add Authorization header with REVENUECAT_WEBHOOK_SECRET
//
// Environment variables required:
// - REVENUECAT_WEBHOOK_SECRET: Shared secret for webhook auth
// - SUPABASE_URL: Auto-set by Supabase
// - SUPABASE_SERVICE_ROLE_KEY: Auto-set by Supabase

import { createClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// RevenueCat event types that indicate Pro status
const PRO_GRANT_EVENTS = [
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE', // Upgrade
  'UNCANCELLATION',
  'SUBSCRIPTION_EXTENDED',
]

const PRO_REVOKE_EVENTS = [
  'EXPIRATION',
  'CANCELLATION', // Note: User still has access until expiration
  'BILLING_ISSUE',
]

interface RevenueCatEvent {
  event: {
    type: string
    app_user_id: string
    product_id: string
    expiration_at_ms?: number
    original_app_user_id: string
    aliases?: string[]
  }
  api_version: string
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    // Verify webhook secret
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
    const authHeader = req.headers.get('Authorization')
    
    if (!webhookSecret) {
      console.error('REVENUECAT_WEBHOOK_SECRET not configured')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // RevenueCat sends: Authorization: Bearer<secret> (no space)
    const providedSecret = authHeader?.replace(/^Bearer\s?/, '')
    if (providedSecret !== webhookSecret) {
      console.warn('Invalid webhook secret')
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse webhook payload
    const payload: RevenueCatEvent = await req.json()
    const { event } = payload
    
    console.log('RevenueCat webhook received:', {
      type: event.type,
      app_user_id: event.app_user_id?.substring(0, 8) + '...',
      product_id: event.product_id,
    })

    // Get Supabase user ID from app_user_id
    // RevenueCat app_user_id should be set to Supabase user.id during identify()
    const supabaseUserId = event.app_user_id

    // Validate UUID format (Supabase user IDs are UUIDs)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(supabaseUserId)) {
      console.log('Skipping non-UUID app_user_id (anonymous user):', supabaseUserId?.substring(0, 8))
      return new Response(
        JSON.stringify({ success: true, message: 'Skipped anonymous user' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase admin client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const adminClient = createClient(supabaseUrl, supabaseServiceKey)

    // Determine Pro status based on event type
    let isPro = false
    let expiresAt: Date | null = null

    if (PRO_GRANT_EVENTS.includes(event.type)) {
      isPro = true
      if (event.expiration_at_ms) {
        expiresAt = new Date(event.expiration_at_ms)
      }
    } else if (PRO_REVOKE_EVENTS.includes(event.type)) {
      isPro = false
      // For CANCELLATION, user still has access until expiration
      if (event.type === 'CANCELLATION' && event.expiration_at_ms) {
        const expiry = new Date(event.expiration_at_ms)
        if (expiry > new Date()) {
          isPro = true
          expiresAt = expiry
        }
      }
    } else {
      // Unknown event type - log and acknowledge
      console.log('Ignoring event type:', event.type)
      return new Response(
        JSON.stringify({ success: true, message: 'Event type ignored' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Upsert entitlement record
    const { error: upsertError } = await adminClient
      .from('user_entitlements')
      .upsert({
        user_id: supabaseUserId,
        is_pro: isPro,
        product_id: event.product_id,
        expires_at: expiresAt?.toISOString() ?? null,
        updated_at: new Date().toISOString(),
        revenuecat_app_user_id: event.original_app_user_id,
        last_event_type: event.type,
      }, {
        onConflict: 'user_id',
      })

    if (upsertError) {
      console.error('Failed to upsert entitlement:', upsertError)
      // Return 200 anyway to prevent RevenueCat retries for DB errors
      // The event can be replayed manually if needed
      return new Response(
        JSON.stringify({ success: false, error: 'Database error', details: upsertError.message }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('Entitlement updated:', {
      user_id: supabaseUserId.substring(0, 8) + '...',
      is_pro: isPro,
      expires_at: expiresAt?.toISOString(),
      event_type: event.type,
    })

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Webhook error:', error)
    // Return 200 to prevent infinite retries
    return new Response(
      JSON.stringify({ success: false, error: 'Processing error' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
