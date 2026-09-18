/** Staging-only R-2 evidence transport. Never used by the app/generate-card. */
const STAGING_URL = "https://llolwgqphwnhbiqewmcq.supabase.co";
const PROVIDER_URL = "https://openrouter.ai/api/v1/chat/completions";
// Use the catalogue's API request id; the dated value is its canonical slug.
const MODEL = "anthropic/claude-sonnet-5";
const RESPONSE_MODELS = [MODEL, "anthropic/claude-sonnet-5-20260630"];
const SCENARIOS = ["Q02", "Q04", "Q06", "Q16"];
const INPUT_BYTES = 2048;
const OUTPUT_TOKENS = 700;

interface EvaluationDeps {
  getEnv?: (key: string) => string | undefined;
  fetch?: typeof fetch;
  now?: () => number;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function record(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function secretsMatch(
  expected: string,
  supplied: string,
): Promise<boolean> {
  const encoder = new TextEncoder();
  const [a, b] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(expected)),
    crypto.subtle.digest("SHA-256", encoder.encode(supplied)),
  ]);
  const left = new Uint8Array(a);
  const right = new Uint8Array(b);
  let difference = 0;
  for (let i = 0; i < left.length; i++) difference |= left[i] ^ right[i];
  return difference === 0;
}

function base64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

export async function handleWritingEvaluation(
  request: Request,
  deps: EvaluationDeps = {},
): Promise<Response> {
  const env = deps.getEnv ?? ((key: string) => Deno.env.get(key));
  const fetcher = deps.fetch ?? fetch;
  const now = deps.now ?? (() => performance.now());
  // Refuse accidental deployment to production, or use of ordinary app auth.
  if (
    env("SUPABASE_URL") !== STAGING_URL ||
    env("GATEWAY_DEV_ALLOW_ANONYMOUS") !== "true"
  ) return json({ error: "evaluation_staging_only" }, 403);

  const secret = env("PROSEPAL_DEV_GATEWAY_SECRET")?.trim();
  const supplied = request.headers.get("X-ProsePal-Dev-Gateway-Secret")?.trim();
  if (!secret || !supplied || !(await secretsMatch(secret, supplied))) {
    return json({ error: "evaluation_auth_required" }, 401);
  }
  if (!["GET", "POST"].includes(request.method)) {
    return json({ error: "method_not_allowed" }, 405);
  }
  const key = env("PROSEPAL_AI_PROVIDER_API_KEY")?.trim();
  if (
    env("PROSEPAL_AI_PROVIDER") !== "openai-compatible" ||
    env("PROSEPAL_AI_PROVIDER_URL") !== PROVIDER_URL || !key
  ) return json({ error: "evaluation_provider_unconfigured" }, 503);

  if (request.method === "GET") {
    return json({
      scenario_ids: SCENARIOS,
      requested_model: MODEL,
      accepted_response_models: RESPONSE_MODELS,
      provider_route: "anthropic",
      provider_name: "Anthropic",
      transport: PROVIDER_URL,
      max_input_utf8_bytes: INPUT_BYTES,
      max_output_tokens: OUTPUT_TOKENS,
      max_price_usd_per_million_tokens: { prompt: 2, completion: 10 },
      fallback: false,
      zdr_required: true,
      reasoning_enabled: false,
      raw_response_boundary: "Complete OpenRouter HTTP response body bytes",
    });
  }

  let input: unknown;
  try {
    const bytes = await request.arrayBuffer();
    if (bytes.byteLength > 8192) {
      return json({ error: "request_too_large" }, 400);
    }
    input = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } catch {
    return json({ error: "invalid_request" }, 400);
  }
  const fields = [
    "scenario_id",
    "synthetic",
    "instructions",
    "prompt",
    "max_output_tokens",
  ];
  if (
    !record(input) || Object.keys(input).some((key) => !fields.includes(key)) ||
    input.synthetic !== true ||
    typeof input.scenario_id !== "string" ||
    !SCENARIOS.includes(input.scenario_id) ||
    typeof input.instructions !== "string" || !input.instructions.trim() ||
    typeof input.prompt !== "string" || !input.prompt.trim() ||
    !Number.isInteger(input.max_output_tokens) ||
    Number(input.max_output_tokens) < 1 ||
    Number(input.max_output_tokens) > OUTPUT_TOKENS
  ) return json({ error: "invalid_evaluation_contract" }, 400);
  if (
    new TextEncoder().encode(input.instructions + input.prompt).byteLength >
      INPUT_BYTES
  ) return json({ error: "prompt_too_large" }, 400);

  const start = now();
  let upstream: Response;
  let bytes: Uint8Array;
  try {
    // Reuse only the existing server credential/endpoint. Runtime prompt,
    // model, JSON mode, filters and fallback configuration are not consulted.
    upstream = await fetcher(PROVIDER_URL, {
      method: "POST",
      redirect: "error",
      headers: {
        "Authorization": `Bearer ${key}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          { role: "system", content: input.instructions },
          { role: "user", content: input.prompt },
        ],
        stream: false,
        max_tokens: input.max_output_tokens,
        reasoning: { enabled: false },
        plugins: [],
        provider: {
          only: ["anthropic"],
          order: ["anthropic"],
          allow_fallbacks: false,
          require_parameters: true,
          zdr: true,
          data_collection: "deny",
          max_price: { prompt: 2, completion: 10, request: 0 },
        },
      }),
      signal: AbortSignal.any([request.signal, AbortSignal.timeout(30000)]),
    });
    bytes = new Uint8Array(await upstream.arrayBuffer());
  } catch {
    // Never include exception/request text or credentials in errors/logs.
    return json({
      error: "evaluation_transport_failed",
      latency_ms: now() - start,
    }, 502);
  }
  const latency = now() - start;
  let metadata: Record<string, unknown> = {};
  try {
    const parsed = JSON.parse(
      new TextDecoder("utf-8", { fatal: true }).decode(bytes),
    );
    if (record(parsed)) metadata = parsed;
  } catch {
    /* Raw evidence remains available even without readable metadata. */
  }

  const identityMatches = metadata.provider === "Anthropic" &&
    typeof metadata.model === "string" &&
    RESPONSE_MODELS.includes(metadata.model);
  const error = !upstream.ok
    ? "provider_http_error"
    : !identityMatches
    ? "provider_identity_unverified"
    : metadata.error
    ? "provider_error"
    : null;
  return json({
    scenario_id: input.scenario_id,
    requested_model: MODEL,
    requested_provider: "anthropic",
    actual_model: typeof metadata.model === "string" ? metadata.model : null,
    actual_provider: typeof metadata.provider === "string"
      ? metadata.provider
      : null,
    provider_http_status: upstream.status,
    provider_content_type: upstream.headers.get("Content-Type"),
    raw_response_base64: base64(bytes),
    latency_ms: latency,
    usage: metadata.usage ?? null,
    max_output_tokens: input.max_output_tokens,
    error,
  }, error ? 502 : 200);
}

if (import.meta.main) Deno.serve((request) => handleWritingEvaluation(request));
