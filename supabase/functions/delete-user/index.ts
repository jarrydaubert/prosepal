/**
 * Authenticated, retry-safe self-deletion.
 *
 * Apple authorization is revoked before the auth user is removed. Failures
 * before the final auth deletion starts leave the auth account available for
 * an idempotent retry. Once final deletion starts, an unconfirmed result is
 * reported as indeterminate because the remote deletion may still commit.
 */
import { createClient } from "npm:@supabase/supabase-js@2.95.3";
import {
  type AppleServerConfig,
  type AuthenticatedUser,
  defaultLogger,
  type EnvGetter,
  generateAppleClientSecret,
  isAppleUser,
  jsonResponse,
  type Logger,
  OperationCancelledError,
  OperationTimedOutError,
  readAppleServerConfig,
  readSupabaseServerConfig,
  redactedUserID,
  runBounded,
} from "../_shared/apple-account.ts";

const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";
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
type LoadRefreshToken = (
  config: SupabaseConfig,
  userID: string,
  signal: AbortSignal,
) => Promise<string | null>;
type RevokeAppleToken = (
  config: AppleServerConfig,
  refreshToken: string,
  signal: AbortSignal,
) => Promise<void>;
type CleanupAppData = (
  config: SupabaseConfig,
  userID: string,
  signal: AbortSignal,
) => Promise<void>;
export type AuthUserDeletionResult = "deleted" | "already_deleted";
type DeleteAuthUser = (
  config: SupabaseConfig,
  userID: string,
  signal: AbortSignal,
) => Promise<AuthUserDeletionResult>;

export interface DeleteUserDeps {
  getEnv?: EnvGetter;
  logger?: Logger;
  timeoutMs?: number;
  runBounded?: typeof runBounded;
  authenticate?: Authenticate;
  loadRefreshToken?: LoadRefreshToken;
  revokeAppleToken?: RevokeAppleToken;
  cleanupAppData?: CleanupAppData;
  deleteAuthUser?: DeleteAuthUser;
}

export async function handleDeleteUser(
  req: Request,
  deps: DeleteUserDeps = {},
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders);
  }

  const getEnv = deps.getEnv ?? Deno.env.get;
  const logger = deps.logger ?? defaultLogger;
  const timeoutMs = deps.timeoutMs ?? DEFAULT_OPERATION_TIMEOUT_MS;
  const bounded = deps.runBounded ?? runBounded;
  const authenticate = deps.authenticate ?? defaultAuthenticate;
  const loadRefreshToken = deps.loadRefreshToken ?? defaultLoadRefreshToken;
  const revokeAppleToken = deps.revokeAppleToken ?? defaultRevokeAppleToken;
  const cleanupAppData = deps.cleanupAppData ?? defaultCleanupAppData;
  const deleteAuthUser = deps.deleteAuthUser ?? defaultDeleteAuthUser;
  let authDeletionStarted = false;

  const supabaseConfig = readSupabaseServerConfig(getEnv);
  if (!supabaseConfig) {
    logger.error("delete-user Supabase configuration invalid");
    return jsonResponse({ error: "Server configuration error" }, 503, corsHeaders);
  }
  const authorization = req.headers.get("Authorization")?.trim() ?? "";
  if (!authorization.toLowerCase().startsWith("bearer ")) {
    return jsonResponse({ error: "Authentication required" }, 401, corsHeaders);
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

    const userLabel = redactedUserID(user.id);
    if (isAppleUser(user)) {
      const refreshToken = await bounded(
        (signal) => loadRefreshToken(supabaseConfig, user.id, signal),
        timeoutMs,
        req.signal,
      );
      if (!refreshToken) {
        logger.warn("delete-user Apple revocation material missing", {
          user: userLabel,
        });
        return jsonResponse(
          {
            error:
              "Sign in with Apple again before deleting your account, then retry.",
          },
          409,
          corsHeaders,
        );
      }
      const appleConfig = readAppleServerConfig(getEnv);
      if (!appleConfig) {
        logger.error("delete-user Apple configuration invalid");
        return jsonResponse(
          { error: "Apple account deletion is unavailable. Please try again later." },
          503,
          corsHeaders,
        );
      }

      await bounded(
        (signal) => revokeAppleToken(appleConfig, refreshToken, signal),
        timeoutMs,
        req.signal,
      );
      logger.log("delete-user Apple authorization revoked", { user: userLabel });
    }

    await bounded(
      (signal) => cleanupAppData(supabaseConfig, user.id, signal),
      timeoutMs,
      req.signal,
    );
    const authDeletionResult = await bounded(
      (signal) => {
        authDeletionStarted = true;
        return deleteAuthUser(supabaseConfig, user.id, signal);
      },
      timeoutMs,
      req.signal,
    );

    logger.log("delete-user account deletion confirmed", {
      user: userLabel,
      outcome: authDeletionResult,
    });
    return jsonResponse(
      {
        success: true,
        status: "deleted",
        message: "Account deletion confirmed.",
      },
      200,
      corsHeaders,
    );
  } catch (error) {
    if (authDeletionStarted) {
      logger.warn("delete-user final auth deletion outcome indeterminate", {
        category: error instanceof OperationTimedOutError
          ? "timed_out"
          : error instanceof OperationCancelledError
          ? "cancelled"
          : "server_operation_failed",
      });
      return jsonResponse(
        {
          success: false,
          status: "indeterminate",
          message:
            "Account deletion started, but its final status could not be confirmed. It may already be deleted; if you can still sign in, retry deletion.",
        },
        202,
        corsHeaders,
      );
    }
    if (error instanceof OperationCancelledError) {
      return jsonResponse(
        {
          error:
            "Request cancelled before final account deletion began. Your authentication account remains; please retry.",
        },
        499,
        corsHeaders,
      );
    }
    if (error instanceof OperationTimedOutError) {
      logger.warn("delete-user operation timed out");
      return jsonResponse(
        {
          error:
            "Account deletion timed out before final deletion began. Your authentication account remains; please retry.",
        },
        504,
        corsHeaders,
      );
    }
    logger.error("delete-user operation failed", {
      category: "server_operation_failed",
    });
    return jsonResponse(
      {
        error:
          "Account deletion stopped before final deletion began. Your authentication account remains; please retry.",
      },
      503,
      corsHeaders,
    );
  }
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

async function defaultLoadRefreshToken(
  config: SupabaseConfig,
  userID: string,
  signal: AbortSignal,
): Promise<string | null> {
  const client = createClient(config.url, config.serviceRoleKey);
  const { data, error } = await client
    .from("apple_credentials")
    .select("refresh_token")
    .eq("user_id", userID)
    .abortSignal(signal)
    .maybeSingle();
  if (error) throw new Error("apple_credentials_read_failed");
  const refreshToken = data?.refresh_token;
  return typeof refreshToken === "string" && refreshToken.trim()
    ? refreshToken.trim()
    : null;
}

async function defaultRevokeAppleToken(
  config: AppleServerConfig,
  refreshToken: string,
  signal: AbortSignal,
): Promise<void> {
  const clientSecret = await generateAppleClientSecret(config);
  const response = await fetch(APPLE_REVOKE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: config.clientId,
      client_secret: clientSecret,
      token: refreshToken,
      token_type_hint: "refresh_token",
    }),
    signal,
  });
  if (!response.ok) {
    throw new Error(`apple_revoke_http_${response.status}`);
  }
}

async function defaultCleanupAppData(
  config: SupabaseConfig,
  userID: string,
  signal: AbortSignal,
): Promise<void> {
  const client = createClient(config.url, config.serviceRoleKey);
  const userUsage = await client
    .from("user_usage")
    .delete()
    .eq("user_id", userID)
    .abortSignal(signal);
  if (userUsage.error) throw new Error("user_usage_delete_failed");

  const entitlements = await client
    .from("user_entitlements")
    .delete()
    .eq("user_id", userID)
    .abortSignal(signal);
  if (entitlements.error) throw new Error("user_entitlements_delete_failed");

  const rateLimits = await client
    .from("rate_limit_log")
    .delete()
    .eq("identifier", userID)
    .eq("identifier_type", "user")
    .abortSignal(signal);
  if (rateLimits.error) throw new Error("rate_limit_log_delete_failed");

  const devices = await client
    .rpc("remove_user_from_devices", { p_user_id: userID })
    .abortSignal(signal);
  if (devices.error) throw new Error("device_association_delete_failed");
}

export async function defaultDeleteAuthUser(
  config: SupabaseConfig,
  userID: string,
  signal: AbortSignal,
): Promise<AuthUserDeletionResult> {
  const abortingFetch: typeof fetch = (input, init) =>
    fetch(input, { ...init, signal });
  const client = createClient(config.url, config.serviceRoleKey, {
    global: { fetch: abortingFetch },
  });
  const { error } = await client.auth.admin.deleteUser(userID);
  if (error) {
    if (isAlreadyDeletedAuthUserError(error)) return "already_deleted";
    throw new Error("auth_user_delete_failed");
  }
  return "deleted";
}

export function isAlreadyDeletedAuthUserError(error: unknown): boolean {
  if (typeof error !== "object" || error === null) return false;
  const candidate = error as { code?: unknown; status?: unknown };
  return candidate.code === "user_not_found" || candidate.status === 404;
}

if (import.meta.main) {
  Deno.serve((req) => handleDeleteUser(req));
}
