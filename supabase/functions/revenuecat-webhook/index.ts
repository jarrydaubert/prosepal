/**
 * RevenueCat webhook handler for entitlement synchronization.
 *
 * Deploy with:
 * `supabase functions deploy revenuecat-webhook`
 *
 * Dashboard setup:
 * 1. Project Settings -> Integrations -> Webhooks
 * 2. URL: `https://<project>.supabase.co/functions/v1/revenuecat-webhook`
 * 3. Authorization header value: `Bearer <REVENUECAT_WEBHOOK_SECRET>`
 */

import { createClient } from "npm:@supabase/supabase-js@2.95.3"

/**
 * CORS policy for server-to-server webhook use.
 * Empty origin prevents browser use.
 */
const corsHeaders = {
  'Access-Control-Allow-Origin': '', // No browser access needed
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

/** Event types that grant/maintain Pro access. */
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

/** Minimal validated shape of incoming RevenueCat webhook payload. */
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

/** Environment getter abstraction for testability. */
type EnvGetter = (key: string) => string | undefined

/** Logger abstraction for testable structured logging. */
type Logger = {
  log: (...args: unknown[]) => void
  warn: (...args: unknown[]) => void
  error: (...args: unknown[]) => void
}

/** Subset of database error fields consumed by this handler. */
type DbError = {
  code?: string
  message?: string
  details?: string
}

/** Minimal admin-client contract required by this handler. */
type AdminClient = {
  from: (table: string) => {
    upsert: (
      values: Record<string, unknown>,
      options: { onConflict: string },
    ) => Promise<{ error: DbError | null }>
  }
}

/** Factory signature for creating admin clients. */
type CreateAdminClient = (
  supabaseUrl: string,
  supabaseServiceKey: string,
) => AdminClient

/** Optional dependency overrides for deterministic testing. */
interface WebhookDeps {
  getEnv?: EnvGetter
  createAdminClient?: CreateAdminClient
  logger?: Logger
  now?: () => Date
}

/**
 * Builds a JSON response with shared webhook headers.
 */
function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    },
  )
}

/**
 * Validates UUID format for Supabase user IDs.
 */
function isUuid(value: string): boolean {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(value)
}

/**
 * Returns true when the DB error indicates an unknown/deleted user and should
 * be treated as a permanent no-retry condition.
 */
function isUnknownUserDbError(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false
  const e = error as { code?: string; message?: string; details?: string }
  const text = `${e.message ?? ''} ${e.details ?? ''}`.toLowerCase()
  return (
    e.code === '23503' ||
    text.includes('foreign key') ||
    text.includes('user_entitlements_user_id_fkey')
  )
}

/**
 * Parses and validates a RevenueCat webhook payload.
 * Invalid payloads are considered permanent and should be acknowledged.
 */
function parsePayload(payload: unknown): { ok: true; value: RevenueCatEvent } | { ok: false; reason: string } {
  if (!payload || typeof payload !== 'object') {
    return { ok: false, reason: 'Invalid payload root' }
  }

  const data = payload as { api_version?: unknown; event?: unknown }
  const event = data.event as {
    type?: unknown
    app_user_id?: unknown
    product_id?: unknown
    original_app_user_id?: unknown
    expiration_at_ms?: unknown
    aliases?: unknown
  }

  if (!event || typeof event !== 'object') {
    return { ok: false, reason: 'Missing event object' }
  }

  if (typeof event.type !== 'string' || !event.type) {
    return { ok: false, reason: 'Missing event.type' }
  }
  if (typeof event.app_user_id !== 'string' || !event.app_user_id) {
    return { ok: false, reason: 'Missing event.app_user_id' }
  }
  if (typeof event.product_id !== 'string' || !event.product_id) {
    return { ok: false, reason: 'Missing event.product_id' }
  }
  if (typeof event.original_app_user_id !== 'string' || !event.original_app_user_id) {
    return { ok: false, reason: 'Missing event.original_app_user_id' }
  }
  if (
    event.expiration_at_ms !== undefined &&
    typeof event.expiration_at_ms !== 'number'
  ) {
    return { ok: false, reason: 'Invalid event.expiration_at_ms' }
  }
  if (event.aliases !== undefined && !Array.isArray(event.aliases)) {
    return { ok: false, reason: 'Invalid event.aliases' }
  }

  return {
    ok: true,
    value: {
      api_version: typeof data.api_version === 'string' ? data.api_version : 'unknown',
      event: {
        type: event.type,
        app_user_id: event.app_user_id,
        product_id: event.product_id,
        original_app_user_id: event.original_app_user_id,
        expiration_at_ms: event.expiration_at_ms as number | undefined,
        aliases: event.aliases as string[] | undefined,
      },
    },
  }
}

const defaultCreateAdminClient: CreateAdminClient = (
  supabaseUrl: string,
  supabaseServiceKey: string,
) => createClient(supabaseUrl, supabaseServiceKey) as unknown as AdminClient

export async function handleRevenueCatWebhook(
  req: Request,
  deps: WebhookDeps = {},
): Promise<Response> {
  const getEnv = deps.getEnv ?? ((key: string) => Deno.env.get(key))
  const createAdminClient = deps.createAdminClient ?? defaultCreateAdminClient
  const logger = deps.logger ?? console
  const now = deps.now ?? (() => new Date())

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept POST
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  try {
    // Verify webhook secret
    const webhookSecret = getEnv('REVENUECAT_WEBHOOK_SECRET')
    const authHeader = req.headers.get('Authorization')
    
    if (!webhookSecret) {
      logger.error('REVENUECAT_WEBHOOK_SECRET not configured')
      return jsonResponse({ error: 'Server configuration error' }, 500)
    }

    // RevenueCat sends: Authorization: Bearer<secret> (no space)
    const providedSecret = authHeader?.replace(/^Bearer\s?/, '')
    if (providedSecret !== webhookSecret) {
      logger.warn('Invalid webhook secret')
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    // Parse webhook payload. Invalid payload is a permanent failure for this event.
    let rawPayload: unknown
    try {
      rawPayload = await req.json()
    } catch (error) {
      logger.warn('Invalid JSON payload', error)
      return jsonResponse({ success: true, message: 'Invalid JSON payload ignored' }, 200)
    }

    const parsed = parsePayload(rawPayload)
    if (!parsed.ok) {
      logger.warn('Invalid webhook payload:', parsed.reason)
      return jsonResponse({ success: true, message: 'Invalid payload ignored' }, 200)
    }

    const payload = parsed.value
    const { event } = payload
    
    logger.log('RevenueCat webhook received:', {
      type: event.type,
      app_user_id: event.app_user_id?.substring(0, 8) + '...',
      product_id: event.product_id,
    })

    // Get Supabase user ID from app_user_id
    // RevenueCat app_user_id should be set to Supabase user.id during identify()
    const supabaseUserId = event.app_user_id

    // Validate UUID format (Supabase user IDs are UUIDs)
    if (!isUuid(supabaseUserId)) {
      logger.log(
        'Skipping non-UUID app_user_id (anonymous user):',
        supabaseUserId?.substring(0, 8),
      )
      return jsonResponse({ success: true, message: 'Skipped anonymous user' }, 200)
    }

    // Initialize Supabase admin client
    const supabaseUrl = getEnv('SUPABASE_URL')!
    const supabaseServiceKey = getEnv('SUPABASE_SERVICE_ROLE_KEY')!
    const adminClient = createAdminClient(supabaseUrl, supabaseServiceKey)

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
        if (expiry > now()) {
          isPro = true
          expiresAt = expiry
        }
      }
    } else {
      // Unknown event type - log and acknowledge
      logger.log('Ignoring event type:', event.type)
      return jsonResponse({ success: true, message: 'Event type ignored' }, 200)
    }

    // Upsert entitlement record
    const { error: upsertError } = await adminClient
      .from('user_entitlements')
      .upsert({
        user_id: supabaseUserId,
        is_pro: isPro,
        product_id: event.product_id,
        expires_at: expiresAt?.toISOString() ?? null,
        updated_at: now().toISOString(),
        revenuecat_app_user_id: event.original_app_user_id,
        last_event_type: event.type,
      }, {
        onConflict: 'user_id',
      })

    if (upsertError) {
      logger.error('Failed to upsert entitlement:', upsertError)
      // Unknown user is a permanent failure (do not retry forever).
      if (isUnknownUserDbError(upsertError)) {
        return jsonResponse(
          { success: true, message: 'Unknown user, event ignored' },
          200,
        )
      }

      // Transient DB errors should be retried by RevenueCat.
      return jsonResponse(
        { success: false, error: 'Database error', details: upsertError.message },
        503,
      )
    }

    logger.log('Entitlement updated:', {
      user_id: supabaseUserId.substring(0, 8) + '...',
      is_pro: isPro,
      expires_at: expiresAt?.toISOString(),
      event_type: event.type,
    })

    return jsonResponse({ success: true }, 200)

  } catch (error) {
    logger.error('Webhook error:', error)
    // Unexpected failures are transient and should be retried.
    return jsonResponse({ success: false, error: 'Processing error' }, 500)
  }
}

if (import.meta.main) {
  Deno.serve((req) => handleRevenueCatWebhook(req))
}
