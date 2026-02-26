import { assertEquals } from "jsr:@std/assert@1"

import { handleRevenueCatWebhook } from "./index.ts"

const TEST_SECRET = 'test-secret'
const TEST_USER_ID = '11111111-1111-1111-1111-111111111111'

const validPayload = {
  api_version: '1.0',
  event: {
    type: 'INITIAL_PURCHASE',
    app_user_id: TEST_USER_ID,
    product_id: 'pro_monthly',
    original_app_user_id: TEST_USER_ID,
    expiration_at_ms: 1735689600000,
  },
}

function makeRequest(payload: unknown): Request {
  return new Request('https://example.supabase.co/functions/v1/revenuecat-webhook', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${TEST_SECRET}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })
}

function makeDeps(options: {
  upsertError?: { code?: string; message?: string; details?: string }
  now?: Date
  captureUpserts?: Array<Record<string, unknown>>
} = {}) {
  const captureUpserts = options.captureUpserts ?? []

  return {
    getEnv: (key: string): string | undefined => {
      switch (key) {
        case 'REVENUECAT_WEBHOOK_SECRET':
          return TEST_SECRET
        case 'SUPABASE_URL':
          return 'https://example.supabase.co'
        case 'SUPABASE_SERVICE_ROLE_KEY':
          return 'service-role-key'
        default:
          return undefined
      }
    },
    createAdminClient: () => ({
      from: (_table: string) => ({
        upsert: async (
          values: Record<string, unknown>,
          _options: { onConflict: string },
        ): Promise<{ error: { code?: string; message?: string; details?: string } | null }> => {
          captureUpserts.push(values)
          return { error: options.upsertError ?? null }
        },
      }),
    }),
    now: () => options.now ?? new Date('2026-01-01T00:00:00.000Z'),
  }
}

Deno.test('returns 503 for transient database failures so webhook can retry', async () => {
  const res = await handleRevenueCatWebhook(
    makeRequest(validPayload),
    makeDeps({ upsertError: { message: 'connection timeout' } }),
  )

  assertEquals(res.status, 503)
  const body = await res.json() as Record<string, unknown>
  assertEquals(body.success, false)
  assertEquals(body.error, 'Database error')
})

Deno.test('returns 200 for permanent invalid payloads', async () => {
  const invalidPayload = {
    api_version: '1.0',
    event: {
      type: 'INITIAL_PURCHASE',
      app_user_id: TEST_USER_ID,
      // product_id intentionally missing
      original_app_user_id: TEST_USER_ID,
    },
  }

  const res = await handleRevenueCatWebhook(
    makeRequest(invalidPayload),
    makeDeps(),
  )

  assertEquals(res.status, 200)
  const body = await res.json() as Record<string, unknown>
  assertEquals(body.success, true)
  assertEquals(body.message, 'Invalid payload ignored')
})

Deno.test('idempotent replay keeps returning 200 and upserts deterministic payloads', async () => {
  const fixedNow = new Date('2026-01-01T00:00:00.000Z')
  const upserts: Array<Record<string, unknown>> = []
  const deps = makeDeps({ now: fixedNow, captureUpserts: upserts })

  const firstRes = await handleRevenueCatWebhook(makeRequest(validPayload), deps)
  const secondRes = await handleRevenueCatWebhook(makeRequest(validPayload), deps)

  assertEquals(firstRes.status, 200)
  assertEquals(secondRes.status, 200)
  assertEquals(upserts.length, 2)
  assertEquals(upserts[0], upserts[1])
  assertEquals(upserts[0].user_id, TEST_USER_ID)
})
