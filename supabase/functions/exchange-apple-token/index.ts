/**
 * Authenticated Apple authorization-code exchange.
 *
 * The one-time code stays in memory, Apple returns a refresh token, and only
 * that refresh token is retained for later account-deletion revocation.
 */
import { createClient } from "npm:@supabase/supabase-js@2.95.3";
import {
  appleSubjectForUser,
  type AppleServerConfig,
  type AppleTokenGrant,
  type AuthenticatedUser,
  defaultLogger,
  type EnvGetter,
  generateAppleClientSecret,
  jsonResponse,
  type Logger,
  OperationCancelledError,
  OperationTimedOutError,
  readAppleServerConfig,
  readBoundedString,
  readSupabaseServerConfig,
  redactedUserID,
  runBounded,
  validateAppleTokenResponse,
} from "../_shared/apple-account.ts";

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const DEFAULT_OPERATION_TIMEOUT_MS = 10_000;

const corsHeaders = {
  "Access-Control-Allow-Origin": "",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type SupabaseConfig = NonNullable<ReturnType<typeof readSupabaseServerConfig>>;

type Authenticate = (
  config: SupabaseConfig,
  authorization: string,
  signal: AbortSignal,
) => Promise<AuthenticatedUser | null>;

type ExchangeCode = (
  config: AppleServerConfig,
  authorizationCode: string,
  signal: AbortSignal,
) => Promise<unknown>;

type StoreRefreshToken = (
  config: SupabaseConfig,
  userID: string,
  refreshToken: string,
  signal: AbortSignal,
) => Promise<void>;

type BoundedRunner = typeof runBounded;

export interface ExchangeAppleTokenDeps {
  getEnv?: EnvGetter;
  logger?: Logger;
  now?: () => Date;
  timeoutMs?: number;
  runBounded?: BoundedRunner;
  authenticate?: Authenticate;
  exchangeCode?: ExchangeCode;
  storeRefreshToken?: StoreRefreshToken;
}

export async function handleExchangeAppleToken(
  req: Request,
  deps: ExchangeAppleTokenDeps = {},
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders);
  }

  const getEnv = deps.getEnv ?? Deno.env.get;
  const logger = deps.logger ?? defaultLogger;
  const now = deps.now ?? (() => new Date());
  const timeoutMs = deps.timeoutMs ?? DEFAULT_OPERATION_TIMEOUT_MS;
  const bounded = deps.runBounded ?? runBounded;
  const authenticate = deps.authenticate ?? defaultAuthenticate;
  const exchangeCode = deps.exchangeCode ?? defaultExchangeCode;
  const storeRefreshToken = deps.storeRefreshToken ?? defaultStoreRefreshToken;

  const supabaseConfig = readSupabaseServerConfig(getEnv);
  const appleConfig = readAppleServerConfig(getEnv);
  if (!supabaseConfig || !appleConfig) {
    logger.error("exchange-apple-token configuration invalid");
    return jsonResponse(
      { error: "Apple account setup is unavailable. Please try again later." },
      503,
      corsHeaders,
    );
  }

  const authorization = req.headers.get("Authorization")?.trim() ?? "";
  if (!authorization.toLowerCase().startsWith("bearer ")) {
    return jsonResponse({ error: "Authentication required" }, 401, corsHeaders);
  }

  let body: Record<string, unknown>;
  try {
    const value = await req.json();
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
      throw new Error("invalid body");
    }
    body = value as Record<string, unknown>;
  } catch {
    return jsonResponse({ error: "Missing or invalid request body" }, 400, corsHeaders);
  }

  const authorizationCode = readOpaqueAppleValue(body.authorization_code, 2048);
  const appleUserID = readOpaqueAppleValue(body.apple_user_id, 512);
  if (!authorizationCode || !appleUserID) {
    return jsonResponse(
      { error: "Missing or malformed Apple authorization result" },
      400,
      corsHeaders,
    );
  }

  try {
    const user = await bounded(
      (signal) => authenticate(supabaseConfig, authorization, signal),
      timeoutMs,
      req.signal,
    );
    if (!user) {
      return jsonResponse({ error: "Authentication required" }, 401, corsHeaders);
    }

    const authenticatedAppleSubject = appleSubjectForUser(user);
    if (!authenticatedAppleSubject || authenticatedAppleSubject !== appleUserID) {
      logger.warn("exchange-apple-token caller identity mismatch", {
        user: redactedUserID(user.id),
      });
      return jsonResponse({ error: "Apple identity mismatch" }, 403, corsHeaders);
    }

    const tokenBody = await bounded(
      (signal) => exchangeCode(appleConfig, authorizationCode, signal),
      timeoutMs,
      req.signal,
    );
    const grant = validateAppleTokenResponse(
      tokenBody,
      appleConfig,
      authenticatedAppleSubject,
      now(),
    );
    if (!grant || grant.subject !== appleUserID) {
      logger.warn("exchange-apple-token Apple response rejected", {
        user: redactedUserID(user.id),
      });
      return jsonResponse(
        { error: "Apple authorization could not be validated. Please try again." },
        502,
        corsHeaders,
      );
    }

    await bounded(
      (signal) =>
        storeRefreshToken(
          supabaseConfig,
          user.id,
          grant.refreshToken,
          signal,
        ),
      timeoutMs,
      req.signal,
    );

    logger.log("exchange-apple-token revocation material stored", {
      user: redactedUserID(user.id),
    });
    return jsonResponse({ success: true }, 200, corsHeaders);
  } catch (error) {
    if (error instanceof OperationCancelledError) {
      return jsonResponse({ error: "Request cancelled" }, 499, corsHeaders);
    }
    if (error instanceof OperationTimedOutError) {
      logger.warn("exchange-apple-token operation timed out");
      return jsonResponse(
        { error: "Apple account setup took too long. Please try again." },
        504,
        corsHeaders,
      );
    }
    logger.error("exchange-apple-token operation failed", {
      category: "server_operation_failed",
    });
    return jsonResponse(
      { error: "Apple account setup failed. Please try again." },
      503,
      corsHeaders,
    );
  }
}

function readOpaqueAppleValue(value: unknown, maximumLength: number): string | null {
  const result = readBoundedString(value, maximumLength);
  if (!result || /[\u0000-\u0020\u007f]/.test(result)) return null;
  return result;
}

async function defaultAuthenticate(
  config: SupabaseConfig,
  authorization: string,
  _signal: AbortSignal,
): Promise<AuthenticatedUser | null> {
  const client = createClient(config.url, config.anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user) return null;
  return user as AuthenticatedUser;
}

async function defaultExchangeCode(
  config: AppleServerConfig,
  authorizationCode: string,
  signal: AbortSignal,
): Promise<unknown> {
  const clientSecret = await generateAppleClientSecret(config);
  const response = await fetch(APPLE_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: config.clientId,
      client_secret: clientSecret,
      code: authorizationCode,
      grant_type: "authorization_code",
    }),
    signal,
  });
  if (!response.ok) {
    throw new Error(`apple_token_http_${response.status}`);
  }
  return await response.json();
}

async function defaultStoreRefreshToken(
  config: SupabaseConfig,
  userID: string,
  refreshToken: string,
  signal: AbortSignal,
): Promise<void> {
  const client = createClient(config.url, config.serviceRoleKey);
  const timestamp = new Date().toISOString();
  const { data, error } = await client
    .from("apple_credentials")
    .upsert({
      user_id: userID,
      refresh_token: refreshToken,
      token_exchanged_at: timestamp,
      updated_at: timestamp,
    }, { onConflict: "user_id" })
    .select("user_id")
    .abortSignal(signal)
    .single();
  if (error || data?.user_id !== userID) {
    throw new Error("apple_credentials_upsert_failed");
  }
}

if (import.meta.main) {
  Deno.serve((req) => handleExchangeAppleToken(req));
}
