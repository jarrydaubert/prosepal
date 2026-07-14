import { assert, assertEquals } from "jsr:@std/assert@1";
import { OperationTimedOutError, runBounded } from "../_shared/apple-account.ts";
import { type DeleteUserDeps, handleDeleteUser } from "./index.ts";

const userID = "00000000-0000-4000-8000-000000000001";
const refreshToken = "secret-refresh-token";

function request(): Request {
  return new Request("https://example.supabase.co/functions/v1/delete-user", {
    method: "POST",
    headers: { Authorization: "Bearer secret-supabase-access-token" },
  });
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

function deps(options: {
  appleUser?: boolean;
  refreshToken?: string | null;
  revoke?: (token: string) => Promise<void>;
  cleanup?: () => Promise<void>;
  deleteAuth?: () => Promise<void>;
  calls?: string[];
  logs?: string[];
  runBounded?: typeof runBounded;
} = {}): DeleteUserDeps {
  const calls = options.calls ?? [];
  return {
    getEnv: env,
    runBounded: options.runBounded,
    logger: {
      log: (...values) => options.logs?.push(JSON.stringify(values)),
      warn: (...values) => options.logs?.push(JSON.stringify(values)),
      error: (...values) => options.logs?.push(JSON.stringify(values)),
    },
    authenticate: async () => ({
      id: userID,
      app_metadata: options.appleUser === false
        ? { provider: "email", providers: ["email"] }
        : { provider: "apple", providers: ["apple"] },
      identities: options.appleUser === false
        ? []
        : [{ provider: "apple", identity_id: "apple-user-123" }],
    }),
    loadRefreshToken: async () => {
      calls.push("load");
      return options.refreshToken === undefined
        ? refreshToken
        : options.refreshToken;
    },
    revokeAppleToken: async (_config, token) => {
      calls.push("revoke");
      await options.revoke?.(token);
    },
    cleanupAppData: async () => {
      calls.push("cleanup");
      await options.cleanup?.();
    },
    deleteAuthUser: async () => {
      calls.push("delete-auth");
      await options.deleteAuth?.();
    },
  };
}

Deno.test("deletion revokes Apple then cleans data and deletes auth user", async () => {
  const calls: string[] = [];
  const response = await handleDeleteUser(request(), deps({ calls }));

  assertEquals(response.status, 200);
  assertEquals(calls, ["load", "revoke", "cleanup", "delete-auth"]);
});

Deno.test("missing caller auth and invalid server configuration fail before cleanup", async () => {
  const calls: string[] = [];
  const missingAuth = new Request(
    "https://example.supabase.co/functions/v1/delete-user",
    { method: "POST" },
  );
  const unauthorized = await handleDeleteUser(missingAuth, deps({ calls }));
  const unconfigured = await handleDeleteUser(
    request(),
    { ...deps({ calls }), getEnv: () => undefined },
  );

  assertEquals(unauthorized.status, 401);
  assertEquals(unconfigured.status, 503);
  assertEquals(calls, []);
});

Deno.test("Apple revocation failure preserves account and a retry succeeds", async () => {
  let attempts = 0;
  let authDeletes = 0;
  const configured = deps({
    revoke: async () => {
      attempts += 1;
      if (attempts === 1) throw new Error("Apple unavailable");
    },
    deleteAuth: async () => {
      authDeletes += 1;
    },
  });

  const first = await handleDeleteUser(request(), configured);
  const second = await handleDeleteUser(request(), configured);

  assertEquals(first.status, 503);
  assertEquals(second.status, 200);
  assertEquals(attempts, 2);
  assertEquals(authDeletes, 1);
});

Deno.test("missing Apple revocation material blocks deletion before cleanup", async () => {
  const calls: string[] = [];
  const response = await handleDeleteUser(
    request(),
    deps({ refreshToken: null, calls }),
  );

  assertEquals(response.status, 409);
  assertEquals(calls, ["load"]);
});

Deno.test("partial cleanup failure preserves auth user and can be retried", async () => {
  let cleanupAttempts = 0;
  let authDeletes = 0;
  const configured = deps({
    cleanup: async () => {
      cleanupAttempts += 1;
      if (cleanupAttempts === 1) throw new Error("partial cleanup");
    },
    deleteAuth: async () => {
      authDeletes += 1;
    },
  });

  const first = await handleDeleteUser(request(), configured);
  const second = await handleDeleteUser(request(), configured);

  assertEquals(first.status, 503);
  assertEquals(second.status, 200);
  assertEquals(cleanupAttempts, 2);
  assertEquals(authDeletes, 1);
});

Deno.test("non-Apple account deletion does not require or invoke revocation", async () => {
  const calls: string[] = [];
  const response = await handleDeleteUser(
    request(),
    deps({ appleUser: false, refreshToken: null, calls }),
  );

  assertEquals(response.status, 200);
  assertEquals(calls, ["cleanup", "delete-auth"]);
});

Deno.test("deletion timeout leaves account retryable", async () => {
  let boundedCalls = 0;
  const timeoutRunner: typeof runBounded = async (operation, _timeout, signal) => {
    boundedCalls += 1;
    if (boundedCalls === 4) throw new OperationTimedOutError();
    return await operation(signal ?? new AbortController().signal);
  };
  const calls: string[] = [];
  const response = await handleDeleteUser(
    request(),
    deps({ calls, runBounded: timeoutRunner }),
  );

  assertEquals(response.status, 504);
  assertEquals(calls, ["load", "revoke"]);
});

Deno.test("deletion logs and evidence exclude credentials and tokens", async () => {
  const logs: string[] = [];
  const response = await handleDeleteUser(request(), deps({ logs }));
  const evidence = `${logs.join("\n")}\n${await response.text()}`;

  assertEquals(response.status, 200);
  for (const secret of [
    refreshToken,
    "secret-supabase-access-token",
    "service-role-key",
    "example",
  ]) {
    assert(!evidence.includes(secret));
  }
});
