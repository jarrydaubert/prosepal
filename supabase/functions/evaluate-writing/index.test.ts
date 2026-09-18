import { assertEquals } from "jsr:@std/assert@1";
import { handleWritingEvaluation } from "./index.ts";

const ENV: Record<string, string> = {
  SUPABASE_URL: "https://llolwgqphwnhbiqewmcq.supabase.co",
  GATEWAY_DEV_ALLOW_ANONYMOUS: "true",
  PROSEPAL_DEV_GATEWAY_SECRET: "test-evaluation-access",
  PROSEPAL_AI_PROVIDER: "openai-compatible",
  PROSEPAL_AI_PROVIDER_URL: "https://openrouter.ai/api/v1/chat/completions",
  PROSEPAL_AI_PROVIDER_API_KEY: "test-provider-credential",
  PROSEPAL_AI_PROVIDER_MODEL: "runtime-model-must-not-be-used",
  PROSEPAL_AI_PROVIDER_FALLBACK_MODELS: "runtime-fallback-must-not-be-used",
  PROSEPAL_AI_PROVIDER_JSON_MODE: "true",
};
const INPUT = {
  scenario_id: "Q02",
  synthetic: true,
  instructions: "Write one message.\nPreserve facts. ",
  prompt: " Sam has been supportive this year.\n",
  max_output_tokens: 37,
};

function request(
  body: unknown = INPUT,
  method = "POST",
  secret = ENV.PROSEPAL_DEV_GATEWAY_SECRET,
): Request {
  return new Request("https://example.test/evaluate-writing", {
    method,
    headers: {
      "X-ProsePal-Dev-Gateway-Secret": secret,
      "Authorization": "Bearer ordinary-app-token",
    },
    ...(method === "POST" ? { body: JSON.stringify(body) } : {}),
  });
}

function fixture(
  raw: string | Uint8Array,
  status = 200,
  overrides: Record<string, string | undefined> = {},
) {
  const env = { ...ENV, ...overrides };
  const calls: { url: string; init: RequestInit }[] = [];
  let clock = 100;
  const deps = {
    getEnv: (key: string) => env[key],
    now: () => {
      clock += 17;
      return clock;
    },
    fetch: ((url: string | URL | Request, init: RequestInit) => {
      calls.push({ url: String(url), init });
      return Promise.resolve(
        new Response(
          typeof raw === "string" ? raw : new Uint8Array(raw).buffer,
          {
            status,
            headers: { "Content-Type": "application/json" },
          },
        ),
      );
    }) as typeof fetch,
  };
  return { deps, calls };
}

function decode(value: string): Uint8Array {
  return Uint8Array.from(atob(value), (char) => char.charCodeAt(0));
}

const RAW =
  ' {"provider":"Anthropic","model":"anthropic/claude-sonnet-5-20260630","choices":[{"message":{"content":"Dear Sam,\\n  Happy birthday!  \\nLove, me"}}],"usage":{"prompt_tokens":41,"completion_tokens":17,"cost":0.000252}}\n';

Deno.test("one pinned call preserves complete raw bytes, supplied prompt, usage and latency", async () => {
  const { deps, calls } = fixture(RAW);
  const response = await handleWritingEvaluation(request(), deps);
  const output = await response.json();
  assertEquals(response.status, 200);
  assertEquals(
    decode(output.raw_response_base64),
    new TextEncoder().encode(RAW),
  );
  assertEquals(output.actual_provider, "Anthropic");
  assertEquals(output.actual_model, "anthropic/claude-sonnet-5-20260630");
  assertEquals(output.usage, {
    prompt_tokens: 41,
    completion_tokens: 17,
    cost: 0.000252,
  });
  assertEquals(output.latency_ms, 17);
  assertEquals(calls.length, 1);
  const body = JSON.parse(String(calls[0].init.body));
  assertEquals(body.model, "anthropic/claude-sonnet-5");
  assertEquals(body.messages, [
    { role: "system", content: INPUT.instructions },
    { role: "user", content: INPUT.prompt },
  ]);
  assertEquals(body.max_tokens, 37);
  assertEquals(body.provider, {
    only: ["anthropic"],
    order: ["anthropic"],
    allow_fallbacks: false,
    require_parameters: true,
    zdr: true,
    data_collection: "deny",
    max_price: { prompt: 2, completion: 10, request: 0 },
  });
  assertEquals(body.reasoning, { enabled: false });
  assertEquals(body.plugins, []);
  assertEquals(body.models, undefined);
  assertEquals(body.response_format, undefined);
  assertEquals(calls[0].init.redirect, "error");
  assertEquals(
    new Headers(calls[0].init.headers).get("Authorization"),
    "Bearer test-provider-credential",
  );
  assertEquals(
    JSON.stringify(output).includes(ENV.PROSEPAL_AI_PROVIDER_API_KEY),
    false,
  );
});

Deno.test("refusals, HTTP failures and unreadable payloads remain exact with no retry", async () => {
  const refusal =
    ' {"provider":"Anthropic","model":"anthropic/claude-sonnet-5","choices":[{"message":{"content":null,"refusal":"I cannot do that.\\n"},"finish_reason":"content_filter"}]}\n';
  for (
    const [raw, status, expected] of [
      [refusal, 200, 200],
      [' {"error":{"message":"declined"}}\n', 403, 502],
      ["unreadable raw body\n", 200, 502],
      [new Uint8Array([255, 0, 13, 10]), 500, 502],
    ] as const
  ) {
    const { deps, calls } = fixture(raw, status);
    const response = await handleWritingEvaluation(request(), deps);
    const output = await response.json();
    assertEquals(response.status, expected);
    assertEquals(
      decode(output.raw_response_base64),
      typeof raw === "string" ? new TextEncoder().encode(raw) : raw,
    );
    assertEquals(output.provider_http_status, status);
    assertEquals(calls.length, 1);
  }
});

Deno.test("substituted or missing identity fails with raw evidence retained", async () => {
  for (
    const identity of [
      { provider: "Google", model: "anthropic/claude-sonnet-5" },
      { provider: "Anthropic", model: "another-engine" },
      {},
    ]
  ) {
    const raw = JSON.stringify({
      ...identity,
      choices: [],
      usage: { completion_tokens: 2 },
    });
    const { deps, calls } = fixture(raw);
    const response = await handleWritingEvaluation(request(), deps);
    const output = await response.json();
    assertEquals(response.status, 502);
    assertEquals(output.error, "provider_identity_unverified");
    assertEquals(
      decode(output.raw_response_base64),
      new TextEncoder().encode(raw),
    );
    assertEquals(calls.length, 1);
  }
});

Deno.test("production, app auth, absent staging opt-in and alternate endpoints cannot call provider", async () => {
  for (
    const overrides of [
      { SUPABASE_URL: "https://mwoxtqxzunsjmbdqezif.supabase.co" },
      { SUPABASE_URL: "https://another-project.supabase.co" },
      { GATEWAY_DEV_ALLOW_ANONYMOUS: "false" },
      { PROSEPAL_DEV_GATEWAY_SECRET: undefined },
      { PROSEPAL_AI_PROVIDER_URL: "https://other-provider.test" },
      { PROSEPAL_AI_PROVIDER_API_KEY: undefined },
    ]
  ) {
    const { deps, calls } = fixture(RAW, 200, overrides);
    const response = await handleWritingEvaluation(request(), deps);
    assertEquals(response.status >= 400, true);
    assertEquals(calls.length, 0);
  }
  const { deps, calls } = fixture(RAW);
  assertEquals(
    (await handleWritingEvaluation(request(INPUT, "POST", ""), deps)).status,
    401,
  );
  assertEquals(
    (await handleWritingEvaluation(request(INPUT, "POST", "wrong"), deps))
      .status,
    401,
  );
  assertEquals(calls.length, 0);
});

Deno.test("authenticated manifest makes no provider call and no credentials escape", async () => {
  const { deps, calls } = fixture(RAW);
  const response = await handleWritingEvaluation(request(null, "GET"), deps);
  const output = await response.json();
  assertEquals(response.status, 200);
  assertEquals(output.requested_model, "anthropic/claude-sonnet-5");
  assertEquals(output.max_output_tokens, 700);
  assertEquals(output.max_input_utf8_bytes, 2048);
  assertEquals(
    JSON.stringify(output).includes(ENV.PROSEPAL_AI_PROVIDER_API_KEY),
    false,
  );
  assertEquals(calls.length, 0);
});

Deno.test("strict caps, synthetic subset, unknown overrides and invalid JSON fail before generation", async () => {
  for (
    const body of [
      { ...INPUT, max_output_tokens: 701 },
      { ...INPUT, max_output_tokens: 0 },
      { ...INPUT, max_output_tokens: 2.5 },
      { ...INPUT, max_output_tokens: "37" },
      { ...INPUT, synthetic: false },
      { ...INPUT, scenario_id: "Q03" },
      { ...INPUT, instructions: " " },
      { ...INPUT, prompt: "é".repeat(1025) },
      { ...INPUT, model: "other" },
      { ...INPUT, provider: { allow_fallbacks: true } },
    ]
  ) {
    const { deps, calls } = fixture(RAW);
    assertEquals(
      (await handleWritingEvaluation(request(body), deps)).status,
      400,
    );
    assertEquals(calls.length, 0);
  }
  const { deps, calls } = fixture(RAW);
  const invalid = new Request("https://example.test", {
    method: "POST",
    headers: {
      "X-ProsePal-Dev-Gateway-Secret": ENV.PROSEPAL_DEV_GATEWAY_SECRET,
    },
    body: "{",
  });
  assertEquals((await handleWritingEvaluation(invalid, deps)).status, 400);
  assertEquals(calls.length, 0);
});

Deno.test("transport failure is one failed attempt without exception text or retry", async () => {
  let calls = 0;
  const response = await handleWritingEvaluation(request(), {
    getEnv: (key) => ENV[key],
    fetch: (() => {
      calls++;
      throw new Error("request text and credential must not escape");
    }) as typeof fetch,
  });
  assertEquals(response.status, 502);
  assertEquals((await response.json()).error, "evaluation_transport_failed");
  assertEquals(calls, 1);
});
