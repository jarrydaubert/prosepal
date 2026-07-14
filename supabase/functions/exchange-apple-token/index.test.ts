import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  OperationTimedOutError,
  runBounded,
} from "../_shared/apple-account.ts";
import {
  type ExchangeAppleTokenDeps,
  handleExchangeAppleToken,
} from "./index.ts";

const appleUserID = "apple-user-123";
const supabaseUserID = "00000000-0000-4000-8000-000000000001";
const authorizationCode = "secret-authorization-code";
const refreshToken = "secret-refresh-token";

function request(body: unknown = {
  authorization_code: authorizationCode,
  apple_user_id: appleUserID,
}): Request {
  return new Request(
    "https://example.supabase.co/functions/v1/exchange-apple-token",
    {
      method: "POST",
      headers: {
        Authorization: "Bearer secret-supabase-access-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
}

function env(key: string): string | undefined {
  switch (key) {
    case "SUPABASE_URL":
      return "https://example.supabase.co";
    case "SUPABASE_ANON_KEY":
      return "anon-key";
    case "SUPABASE_SERVICE_ROLE_KEY":
      return "service-role-key";
    case "APPLE_TEAM_ID":
      return "TEAMID1234";
    case "APPLE_CLIENT_ID":
      return "com.prosepal.prosepal.staging";
    case "APPLE_KEY_ID":
      return "KEYID12345";
    case "APPLE_PRIVATE_KEY":
      return "-----BEGIN PRIVATE KEY-----\nexample\n-----END PRIVATE KEY-----";
    default:
      return undefined;
  }
}

function idToken(overrides: Record<string, unknown> = {}): string {
  const encode = (value: unknown) =>
    btoa(JSON.stringify(value))
      .replaceAll("+", "-")
      .replaceAll("/", "_")
      .replace(/=+$/, "");
  return `${encode({ alg: "ES256", kid: "apple" })}.${encode({
    iss: "https://appleid.apple.com",
    aud: "com.prosepal.prosepal.staging",
    sub: appleUserID,
    exp: 2_000_000_000,
    ...overrides,
  })}.signature`;
}

function deps(options: {
  authenticatedAppleUserID?: string | null;
  internalIdentityID?: string;
  appleResponse?: unknown;
  exchangeError?: Error;
  storeError?: Error;
  captureCodes?: string[];
  captureStoredTokens?: string[];
  logs?: string[];
  runBounded?: typeof runBounded;
} = {}): ExchangeAppleTokenDeps {
  return {
    getEnv: env,
    now: () => new Date("2026-07-14T12:00:00.000Z"),
    runBounded: options.runBounded,
    logger: {
      log: (...values) => options.logs?.push(JSON.stringify(values)),
      warn: (...values) => options.logs?.push(JSON.stringify(values)),
      error: (...values) => options.logs?.push(JSON.stringify(values)),
    },
    authenticate: async () => {
      const subject = options.authenticatedAppleUserID === undefined
        ? appleUserID
        : options.authenticatedAppleUserID;
      return {
        id: supabaseUserID,
        app_metadata: { provider: "apple", providers: ["apple"] },
      identities: subject
          ? [{
            provider: "apple",
            identity_id: options.internalIdentityID ?? subject,
            identity_data: { sub: subject },
          }]
          : [],
      };
    },
    exchangeCode: async (_config, code) => {
      options.captureCodes?.push(code);
      if (options.exchangeError) throw options.exchangeError;
      return options.appleResponse ?? {
        access_token: "unused-secret-access-token",
        refresh_token: refreshToken,
        id_token: idToken(),
        token_type: "Bearer",
        expires_in: 3600,
      };
    },
    storeRefreshToken: async (_config, _userID, token) => {
      if (options.storeError) throw options.storeError;
      options.captureStoredTokens?.push(token);
    },
  };
}

Deno.test("first Apple sign-in forwards the code and stores only validated revocation material", async () => {
  const codes: string[] = [];
  const stored: string[] = [];
  const response = await handleExchangeAppleToken(
    request(),
    deps({ captureCodes: codes, captureStoredTokens: stored }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { success: true });
  assertEquals(codes, [authorizationCode]);
  assertEquals(stored, [refreshToken]);
});

Deno.test("repeat Apple sign-in exchanges and replaces revocation material", async () => {
  const stored: string[] = [];
  const first = await handleExchangeAppleToken(
    request(),
    deps({ captureStoredTokens: stored }),
  );
  const second = await handleExchangeAppleToken(
    request({
      authorization_code: "new-one-time-code",
      apple_user_id: appleUserID,
    }),
    deps({
      appleResponse: {
        refresh_token: "rotated-refresh-token",
        id_token: idToken(),
        token_type: "bearer",
      },
      captureStoredTokens: stored,
    }),
  );

  assertEquals(first.status, 200);
  assertEquals(second.status, 200);
  assertEquals(stored, [refreshToken, "rotated-refresh-token"]);
});

Deno.test("missing and malformed authorization results are rejected before Apple or database work", async () => {
  const cases = [
    {},
    { authorization_code: " ", apple_user_id: appleUserID },
    { authorization_code: "code with space", apple_user_id: appleUserID },
    { authorization_code: "x".repeat(2049), apple_user_id: appleUserID },
    { authorization_code: authorizationCode, apple_user_id: " " },
  ];

  for (const body of cases) {
    const codes: string[] = [];
    const stored: string[] = [];
    const response = await handleExchangeAppleToken(
      request(body),
      deps({ captureCodes: codes, captureStoredTokens: stored }),
    );
    assertEquals(response.status, 400);
    assertEquals(codes, []);
    assertEquals(stored, []);
  }
});

Deno.test("missing caller auth and invalid server configuration fail before Apple work", async () => {
  const codes: string[] = [];
  const missingAuth = new Request(
    "https://example.supabase.co/functions/v1/exchange-apple-token",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        authorization_code: authorizationCode,
        apple_user_id: appleUserID,
      }),
    },
  );
  const unauthorized = await handleExchangeAppleToken(
    missingAuth,
    deps({ captureCodes: codes }),
  );
  const unconfigured = await handleExchangeAppleToken(
    request(),
    { ...deps({ captureCodes: codes }), getEnv: () => undefined },
  );

  assertEquals(unauthorized.status, 401);
  assertEquals(unconfigured.status, 503);
  assertEquals(codes, []);
});

Deno.test("authenticated caller must own the Apple subject", async () => {
  const codes: string[] = [];
  const response = await handleExchangeAppleToken(
    request(),
    deps({ authenticatedAppleUserID: "different-user", captureCodes: codes }),
  );

  assertEquals(response.status, 403);
  assertEquals(codes, []);
});

Deno.test("trusted Apple subject wins over an SDK-internal identity identifier", async () => {
  const codes: string[] = [];
  const response = await handleExchangeAppleToken(
    request(),
    deps({
      internalIdentityID: "supabase-internal-identity-id",
      captureCodes: codes,
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(codes, [authorizationCode]);
});

Deno.test("malformed or mismatched Apple token responses are not stored", async () => {
  const cases = [
    { refresh_token: refreshToken, id_token: "bad", token_type: "Bearer" },
    {
      refresh_token: refreshToken,
      id_token: idToken({ sub: "different-user" }),
      token_type: "Bearer",
    },
    {
      refresh_token: refreshToken,
      id_token: idToken({ aud: "wrong-client" }),
      token_type: "Bearer",
    },
    { id_token: idToken(), token_type: "Bearer" },
  ];

  for (const appleResponse of cases) {
    const stored: string[] = [];
    const response = await handleExchangeAppleToken(
      request(),
      deps({ appleResponse, captureStoredTokens: stored }),
    );
    assertEquals(response.status, 502);
    assertEquals(stored, []);
  }
});

Deno.test("server timeout and storage failure are retryable and fail closed", async () => {
  let boundedCalls = 0;
  const timeoutRunner: typeof runBounded = async (operation, _timeout, signal) => {
    boundedCalls += 1;
    if (boundedCalls === 2) throw new OperationTimedOutError();
    return await operation(signal ?? new AbortController().signal);
  };
  const timedOut = await handleExchangeAppleToken(
    request(),
    deps({ runBounded: timeoutRunner }),
  );
  const failed = await handleExchangeAppleToken(
    request(),
    deps({ storeError: new Error("database failed") }),
  );

  assertEquals(timedOut.status, 504);
  assertEquals(failed.status, 503);
});

Deno.test("authorization codes tokens and private key material never enter logs or responses", async () => {
  const logs: string[] = [];
  const response = await handleExchangeAppleToken(request(), deps({ logs }));
  const evidence = `${logs.join("\n")}\n${await response.text()}`;

  assertEquals(response.status, 200);
  for (const secret of [
    authorizationCode,
    refreshToken,
    "unused-secret-access-token",
    "secret-supabase-access-token",
    "example",
  ]) {
    assert(!evidence.includes(secret));
  }
});
