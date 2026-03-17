/**
 * Authenticated feedback-delivery edge function.
 *
 * Accepts an in-app feedback payload from an authenticated user, then relays
 * it through Resend so support receives the message without exposing secrets
 * to the client.
 */
import { createClient } from "npm:@supabase/supabase-js@2.95.3"

const RESEND_API_URL = 'https://api.resend.com/emails'
const MAX_MESSAGE_LENGTH = 4000
const MAX_DIAGNOSTIC_LENGTH = 24000
const RESEND_TIMEOUT_MS = 12000

const corsHeaders = {
  'Access-Control-Allow-Origin': '',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function safeErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    const message = error.message.toLowerCase()
    if (
      message.includes('timeout') ||
      message.includes('network') ||
      message.includes('abort')
    ) {
      return 'Unable to submit feedback right now. Please try again.'
    }
  }
  return 'Unable to submit feedback right now. Please try again.'
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return jsonResponse({ error: 'Authentication required' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    const feedbackToEmail =
      Deno.env.get('FEEDBACK_TO_EMAIL') ?? 'jarryd@prosepal.app'
    const feedbackFromEmail =
      Deno.env.get('FEEDBACK_FROM_EMAIL') ?? 'jarryd@prosepal.app'

    if (!supabaseUrl || !supabaseAnonKey || !resendApiKey) {
      console.error('Missing send-feedback configuration')
      return jsonResponse({ error: 'Feedback service is not configured' }, 500)
    }

    let payload: Record<string, unknown>
    try {
      payload = await req.json()
    } catch {
      return jsonResponse({ error: 'Invalid request body' }, 400)
    }

    const message = typeof payload.message === 'string' ? payload.message.trim() : ''
    const diagnosticReport =
      typeof payload.diagnostic_report === 'string'
        ? payload.diagnostic_report.trim()
        : ''
    const includeSensitiveLogs = payload.include_sensitive_logs === true

    if (!message) {
      return jsonResponse({ error: 'Feedback message is required' }, 400)
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      return jsonResponse(
        { error: `Feedback must be ${MAX_MESSAGE_LENGTH} characters or less` },
        400,
      )
    }
    if (diagnosticReport.length > MAX_DIAGNOSTIC_LENGTH) {
      return jsonResponse(
        {
          error:
            'Diagnostics are too large to send directly. Please use the manual share fallback.',
        },
        400,
      )
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return jsonResponse({ error: 'Authentication required' }, 401)
    }
    console.log(
      'Feedback request authenticated',
      JSON.stringify({
        userId: `${user.id.substring(0, 8)}...`,
        hasDiagnostics: diagnosticReport.length > 0,
        includeSensitiveLogs,
      }),
    )

    const subject = `Prosepal Feedback (${user.id.substring(0, 8)})`
    const text = [
      'New Prosepal in-app feedback',
      '',
      `User ID: ${user.id}`,
      `User Email: ${user.email ?? '(none)'}`,
      `Sensitive Diagnostics Included: ${includeSensitiveLogs ? 'yes' : 'no'}`,
      '',
      '--- Message ---',
      message,
      diagnosticReport
        ? ['', '--- Diagnostic Report ---', diagnosticReport].join('\n')
        : '',
    ]
      .filter(Boolean)
      .join('\n')

    let resendResponse: Response
    try {
      resendResponse = await fetch(RESEND_API_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: `Prosepal Support <${feedbackFromEmail}>`,
          to: [feedbackToEmail],
          reply_to: user.email ? [user.email] : undefined,
          subject,
          text,
        }),
        signal: AbortSignal.timeout(RESEND_TIMEOUT_MS),
      })
    } catch (error) {
      console.error('Resend feedback delivery request failed:', error)
      return jsonResponse(
        { error: 'Feedback delivery timed out. Please try again.' },
        504,
      )
    }

    if (!resendResponse.ok) {
      const errorText = await resendResponse.text()
      console.error('Resend feedback delivery failed:', resendResponse.status, errorText)
      return jsonResponse({ error: 'Feedback delivery failed' }, 502)
    }

    const resendPayload = await resendResponse.json()
    console.log(
      'Feedback delivered',
      JSON.stringify({
        resendId:
          typeof resendPayload?.id === 'string' ? resendPayload.id : '(unknown)',
        userId: `${user.id.substring(0, 8)}...`,
        hasDiagnostics: diagnosticReport.length > 0,
      }),
    )

    return jsonResponse({ success: true })
  } catch (error) {
    console.error('send-feedback unexpected error:', error)
    return jsonResponse({ error: safeErrorMessage(error) }, 500)
  }
})
