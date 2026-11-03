/**
 * App Store Server API reconciliation for native StoreKit entitlement.
 *
 * This operator/admin endpoint asks Apple for the latest subscription status
 * for a transaction id, verifies Apple's signed transaction/renewal payloads,
 * and reconciles `user_entitlements`. It logs and stores metadata only; signed
 * payloads, receipts, raw transaction bodies, auth tokens, and secrets are not
 * persisted or logged.
 */

import { createClient } from "npm:@supabase/supabase-js@2.95.3";
import {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier,
  Status,
} from "npm:@apple/app-store-server-library@3.1.0";
import { Buffer } from "node:buffer";

const corsHeaders = {
  "Access-Control-Allow-Origin": "",
  "Access-Control-Allow-Headers":
    "content-type, x-prosepal-app-store-reconcile-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type EnvGetter = (key: string) => string | undefined;

type Logger = {
  log: (...args: unknown[]) => void;
  warn: (...args: unknown[]) => void;
  error: (...args: unknown[]) => void;
};

type DbError = {
  code?: string;
  message?: string;
  details?: string;
};

type AdminClient = {
  from: (table: string) => {
    insert: (
      values: Record<string, unknown>,
    ) => Promise<{ error: DbError | null }>;
    upsert: (
      values: Record<string, unknown>,
      options: { onConflict: string },
    ) => Promise<{ error: DbError | null }>;
  };
};

type CreateAdminClient = (
  supabaseUrl: string,
  supabaseServiceKey: string,
) => AdminClient;

type AppleApiClient = {
  getAllSubscriptionStatuses: (
    transactionId: string,
    statuses?: Status[],
  ) => Promise<Record<string, unknown>>;
};

type AppleVerifier = {
  verifyAndDecodeTransaction: (
    signedTransactionInfo: string,
  ) => Promise<Record<string, unknown>>;
  verifyAndDecodeRenewalInfo: (
    signedRenewalInfo: string,
  ) => Promise<Record<string, unknown>>;
};

type CreateAppleApiClient = (getEnv: EnvGetter) => AppleApiClient;
type CreateAppleVerifier = (getEnv: EnvGetter) => AppleVerifier;

interface AppStoreReconcileDeps {
  getEnv?: EnvGetter;
  createAdminClient?: CreateAdminClient;
  createAppleApiClient?: CreateAppleApiClient;
  createAppleVerifier?: CreateAppleVerifier;
  logger?: Logger;
  now?: () => Date;
}

type ReconciliationCandidate = {
  status: number | null;
  transaction: Record<string, unknown>;
  renewalInfo?: Record<string, unknown>;
  productId: string;
  appAccountToken?: string;
  originalTransactionId?: string;
  transactionId?: string;
  environment: string;
  expiresAt: Date | null;
  revocationDate: Date | null;
  isPro: boolean;
};

class ConfigError extends Error {}

const entitlementSource = "app_store_server_api";
const reconcileSecretHeader = "x-prosepal-app-store-reconcile-secret";

const defaultCreateAdminClient: CreateAdminClient = (
  supabaseUrl: string,
  supabaseServiceKey: string,
) => createClient(supabaseUrl, supabaseServiceKey) as unknown as AdminClient;

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function readString(
  value: Record<string, unknown> | undefined,
  key: string,
): string | undefined {
  const raw = value?.[key];
  if (typeof raw !== "string") return undefined;
  const trimmed = raw.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function readNumber(
  value: Record<string, unknown> | undefined,
  key: string,
): number | undefined {
  const raw = value?.[key];
  return typeof raw === "number" && Number.isFinite(raw) ? raw : undefined;
}

function millisToDate(value: number | undefined): Date | null {
  if (value === undefined) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(value);
}

function redacted(value: string | undefined): string | undefined {
  if (!value) return undefined;
  return value.length <= 8 ? `${value}...` : `${value.substring(0, 8)}...`;
}

function splitList(value: string | undefined): string[] {
  return [
    ...new Set(
      (value ?? "")
        .split(",")
        .map((item) => item.trim())
        .filter((item) => item.length > 0),
    ),
  ];
}

function requiredEnv(getEnv: EnvGetter, key: string): string {
  const value = getEnv(key)?.trim();
  if (!value) throw new ConfigError(`${key} is not configured`);
  return value;
}

function configuredProductIds(getEnv: EnvGetter): string[] {
  const values = splitList(
    getEnv("APP_STORE_PREMIUM_PRODUCT_IDS") ??
      getEnv("PROSEPAL_PREMIUM_PRODUCT_IDS"),
  );
  if (values.length === 0) {
    throw new ConfigError("APP_STORE_PREMIUM_PRODUCT_IDS is not configured");
  }
  return values;
}

function appStoreEnvironment(getEnv: EnvGetter): Environment {
  const raw = requiredEnv(getEnv, "APP_STORE_ENVIRONMENT").toLowerCase();
  switch (raw) {
    case "sandbox":
      return Environment.SANDBOX;
    case "production":
      return Environment.PRODUCTION;
    default:
      throw new ConfigError(
        "APP_STORE_ENVIRONMENT must be Sandbox or Production",
      );
  }
}

function appStorePrivateKey(getEnv: EnvGetter): string {
  return requiredEnv(getEnv, "APP_STORE_SERVER_API_PRIVATE_KEY")
    .replaceAll("\\n", "\n");
}

function rootCertificates(getEnv: EnvGetter): Buffer[] {
  const pemBundle = requiredEnv(getEnv, "APP_STORE_ROOT_CERTIFICATES_PEM")
    .replaceAll("\\n", "\n");
  const matches = pemBundle.match(
    /-----BEGIN CERTIFICATE-----[\s\S]+?-----END CERTIFICATE-----/g,
  ) ?? [];

  const certs = matches.map((pem) => {
    const base64 = pem
      .replace("-----BEGIN CERTIFICATE-----", "")
      .replace("-----END CERTIFICATE-----", "")
      .replace(/\s/g, "");
    return Buffer.from(base64, "base64");
  });

  if (certs.length === 0) {
    throw new ConfigError(
      "APP_STORE_ROOT_CERTIFICATES_PEM has no certificates",
    );
  }

  return certs;
}

function appAppleId(
  getEnv: EnvGetter,
  environment: Environment,
): number | undefined {
  const raw = getEnv("APP_STORE_APP_APPLE_ID")?.trim();
  if (!raw) {
    if (environment === Environment.PRODUCTION) {
      throw new ConfigError(
        "APP_STORE_APP_APPLE_ID is required for Production",
      );
    }
    return undefined;
  }

  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new ConfigError("APP_STORE_APP_APPLE_ID must be a positive integer");
  }
  return parsed;
}

function onlineChecksEnabled(getEnv: EnvGetter): boolean {
  return getEnv("APP_STORE_ENABLE_ONLINE_CHECKS")?.trim().toLowerCase() ===
    "true";
}

const defaultCreateAppleApiClient: CreateAppleApiClient = (getEnv) =>
  new AppStoreServerAPIClient(
    appStorePrivateKey(getEnv),
    requiredEnv(getEnv, "APP_STORE_SERVER_API_KEY_ID"),
    requiredEnv(getEnv, "APP_STORE_SERVER_API_ISSUER_ID"),
    requiredEnv(getEnv, "APP_STORE_BUNDLE_ID"),
    appStoreEnvironment(getEnv),
  ) as unknown as AppleApiClient;

const defaultCreateAppleVerifier: CreateAppleVerifier = (getEnv) => {
  const environment = appStoreEnvironment(getEnv);
  return new SignedDataVerifier(
    rootCertificates(getEnv),
    onlineChecksEnabled(getEnv),
    environment,
    requiredEnv(getEnv, "APP_STORE_BUNDLE_ID"),
    appAppleId(getEnv, environment),
  ) as unknown as AppleVerifier;
};

function constantTimeEquals(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  const length = Math.max(left.length, right.length);
  let diff = left.length ^ right.length;

  for (let index = 0; index < length; index += 1) {
    diff |= (left[index] ?? 0) ^ (right[index] ?? 0);
  }

  return diff === 0;
}

function verifyReconcileSecret(req: Request, getEnv: EnvGetter): boolean {
  const configured = requiredEnv(getEnv, "APP_STORE_RECONCILE_SECRET");
  const provided = req.headers.get(reconcileSecretHeader)?.trim() ?? "";
  return constantTimeEquals(provided, configured);
}

function isUnknownUserDbError(error: unknown): boolean {
  if (!isRecord(error)) return false;
  const code = readString(error, "code");
  const text = `${readString(error, "message") ?? ""} ${
    readString(error, "details") ?? ""
  }`.toLowerCase();
  return (
    code === "23503" ||
    text.includes("foreign key") ||
    text.includes("user_entitlements_user_id_fkey")
  );
}

function effectiveExpiresAt(
  status: number | null,
  transaction: Record<string, unknown>,
  renewalInfo?: Record<string, unknown>,
): Date | null {
  if (status === Status.BILLING_GRACE_PERIOD) {
    return millisToDate(readNumber(renewalInfo, "gracePeriodExpiresDate")) ??
      millisToDate(readNumber(transaction, "expiresDate"));
  }

  return millisToDate(readNumber(transaction, "expiresDate")) ??
    millisToDate(readNumber(renewalInfo, "renewalDate"));
}

function entitlementActiveFromStatus(
  status: number | null,
  transaction: Record<string, unknown>,
  renewalInfo: Record<string, unknown> | undefined,
  now: Date,
): boolean {
  if (millisToDate(readNumber(transaction, "revocationDate"))) return false;
  if (status !== Status.ACTIVE && status !== Status.BILLING_GRACE_PERIOD) {
    return false;
  }

  const expiresAt = effectiveExpiresAt(status, transaction, renewalInfo);
  return !!expiresAt && expiresAt > now;
}

function candidatePriority(candidate: ReconciliationCandidate): number {
  if (candidate.isPro) return candidate.status === Status.ACTIVE ? 50 : 40;

  switch (candidate.status) {
    case Status.BILLING_RETRY:
      return 30;
    case Status.EXPIRED:
      return 20;
    case Status.REVOKED:
      return 10;
    default:
      return 0;
  }
}

function laterDateScore(date: Date | null): number {
  return date?.getTime() ?? 0;
}

async function decodeSubscriptionStatuses(
  statusResponse: Record<string, unknown>,
  verifier: AppleVerifier,
  productIds: string[],
  now: Date,
): Promise<ReconciliationCandidate[]> {
  const groups = Array.isArray(statusResponse.data) ? statusResponse.data : [];
  const candidates: ReconciliationCandidate[] = [];

  for (const group of groups) {
    if (!isRecord(group) || !Array.isArray(group.lastTransactions)) continue;

    for (const item of group.lastTransactions) {
      if (!isRecord(item)) continue;
      const signedTransactionInfo = readString(item, "signedTransactionInfo");
      if (!signedTransactionInfo) continue;

      const transaction = await verifier.verifyAndDecodeTransaction(
        signedTransactionInfo,
      );
      const signedRenewalInfo = readString(item, "signedRenewalInfo");
      const renewalInfo = signedRenewalInfo
        ? await verifier.verifyAndDecodeRenewalInfo(signedRenewalInfo)
        : undefined;
      const productId = readString(transaction, "productId") ??
        readString(renewalInfo, "productId");

      if (!productId || !productIds.includes(productId)) continue;

      const status = readNumber(item, "status") ?? null;
      const appAccountToken = readString(transaction, "appAccountToken") ??
        readString(renewalInfo, "appAccountToken");
      const expiresAt = effectiveExpiresAt(status, transaction, renewalInfo);

      candidates.push({
        status,
        transaction,
        renewalInfo,
        productId,
        appAccountToken,
        originalTransactionId:
          readString(transaction, "originalTransactionId") ??
            readString(item, "originalTransactionId") ??
            readString(renewalInfo, "originalTransactionId"),
        transactionId: readString(transaction, "transactionId"),
        environment: readString(statusResponse, "environment") ??
          readString(transaction, "environment") ??
          "Unknown",
        expiresAt,
        revocationDate: millisToDate(readNumber(transaction, "revocationDate")),
        isPro: entitlementActiveFromStatus(
          status,
          transaction,
          renewalInfo,
          now,
        ),
      });
    }
  }

  return candidates.sort((left, right) => {
    const priorityDiff = candidatePriority(right) - candidatePriority(left);
    if (priorityDiff !== 0) return priorityDiff;
    return laterDateScore(right.expiresAt) - laterDateScore(left.expiresAt);
  });
}

async function upsert(
  adminClient: AdminClient,
  table: string,
  values: Record<string, unknown>,
  onConflict: string,
): Promise<DbError | null> {
  const { error } = await adminClient
    .from(table)
    .upsert(values, { onConflict });
  return error;
}

async function insertAuditEvent(
  adminClient: AdminClient,
  values: Record<string, unknown>,
): Promise<DbError | null> {
  const { error } = await adminClient
    .from("app_store_reconciliation_events")
    .insert(values);
  return error;
}

function auditValues(options: {
  requestedTransactionId: string;
  requestedUserId?: string;
  resolvedUserId?: string;
  candidate?: ReconciliationCandidate;
  outcome: string;
  errorCode?: string;
  now: Date;
}) {
  return {
    requested_transaction_id: options.requestedTransactionId,
    requested_user_id: options.requestedUserId ?? null,
    resolved_user_id: options.resolvedUserId ?? null,
    environment: options.candidate?.environment ?? null,
    product_id: options.candidate?.productId ?? null,
    original_transaction_id: options.candidate?.originalTransactionId ?? null,
    transaction_id: options.candidate?.transactionId ?? null,
    app_account_token: options.candidate?.appAccountToken &&
        isUuid(options.candidate.appAccountToken)
      ? options.candidate.appAccountToken
      : null,
    app_store_status: options.candidate?.status ?? null,
    is_pro: options.candidate?.isPro ?? null,
    expires_at: options.candidate?.expiresAt?.toISOString() ?? null,
    outcome: options.outcome,
    error_code: options.errorCode ?? null,
    processed_at: options.now.toISOString(),
  };
}

export async function handleAppStoreEntitlementReconciliation(
  req: Request,
  deps: AppStoreReconcileDeps = {},
): Promise<Response> {
  const getEnv = deps.getEnv ?? ((key: string) => Deno.env.get(key));
  const createAdminClient = deps.createAdminClient ?? defaultCreateAdminClient;
  const createAppleApiClient = deps.createAppleApiClient ??
    defaultCreateAppleApiClient;
  const createAppleVerifier = deps.createAppleVerifier ??
    defaultCreateAppleVerifier;
  const logger = deps.logger ?? console;
  const now = deps.now ?? (() => new Date());

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    if (!verifyReconcileSecret(req, getEnv)) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
  } catch (error) {
    logger.error("App Store reconciliation configuration error", {
      message: error instanceof Error ? error.message : "unknown",
    });
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }

  if (!isRecord(body)) {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }

  const requestedTransactionId = readString(body, "transaction_id");
  if (!requestedTransactionId) {
    return jsonResponse({ error: "Missing transaction_id" }, 400);
  }

  const requestedUserId = readString(body, "user_id");
  if (requestedUserId && !isUuid(requestedUserId)) {
    return jsonResponse({ error: "Invalid user_id" }, 400);
  }

  let adminClient: AdminClient;
  let appleApiClient: AppleApiClient;
  let verifier: AppleVerifier;
  let productIds: string[];
  try {
    productIds = configuredProductIds(getEnv);
    adminClient = createAdminClient(
      requiredEnv(getEnv, "SUPABASE_URL"),
      requiredEnv(getEnv, "SUPABASE_SERVICE_ROLE_KEY"),
    );
    appleApiClient = createAppleApiClient(getEnv);
    verifier = createAppleVerifier(getEnv);
  } catch (error) {
    logger.error("App Store reconciliation configuration error", {
      message: error instanceof Error ? error.message : "unknown",
    });
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  let statusResponse: Record<string, unknown>;
  try {
    statusResponse = await appleApiClient.getAllSubscriptionStatuses(
      requestedTransactionId,
    );
  } catch (error) {
    logger.error("App Store Server API reconciliation request failed", {
      transaction_id: redacted(requestedTransactionId),
      message: error instanceof Error ? error.message : "unknown",
    });
    return jsonResponse({ error: "App Store Server API unavailable" }, 502);
  }

  let candidates: ReconciliationCandidate[];
  try {
    candidates = await decodeSubscriptionStatuses(
      statusResponse,
      verifier,
      productIds,
      now(),
    );
  } catch (error) {
    logger.error("App Store Server API signed response verification failed", {
      transaction_id: redacted(requestedTransactionId),
      message: error instanceof Error ? error.message : "unknown",
    });
    return jsonResponse(
      { error: "Invalid App Store Server API response" },
      502,
    );
  }

  const candidate = candidates[0];
  if (!candidate) {
    await insertAuditEvent(
      adminClient,
      auditValues({
        requestedTransactionId,
        requestedUserId,
        outcome: "ignored",
        errorCode: "no_configured_product",
        now: now(),
      }),
    );
    return jsonResponse(
      { success: true, message: "No configured subscription product found" },
      200,
    );
  }

  const tokenUserId =
    candidate.appAccountToken && isUuid(candidate.appAccountToken)
      ? candidate.appAccountToken
      : undefined;
  if (requestedUserId && tokenUserId && requestedUserId !== tokenUserId) {
    await insertAuditEvent(
      adminClient,
      auditValues({
        requestedTransactionId,
        requestedUserId,
        resolvedUserId: tokenUserId,
        candidate,
        outcome: "rejected",
        errorCode: "user_mismatch",
        now: now(),
      }),
    );
    return jsonResponse({ error: "Transaction user mismatch" }, 409);
  }

  const resolvedUserId = requestedUserId ?? tokenUserId;
  if (!resolvedUserId) {
    await insertAuditEvent(
      adminClient,
      auditValues({
        requestedTransactionId,
        requestedUserId,
        candidate,
        outcome: "ignored",
        errorCode: "missing_app_account_token",
        now: now(),
      }),
    );
    return jsonResponse(
      {
        success: true,
        message: "No UUID appAccountToken; entitlement ignored",
      },
      200,
    );
  }

  const entitlementError = await upsert(
    adminClient,
    "user_entitlements",
    {
      user_id: resolvedUserId,
      is_pro: candidate.isPro,
      product_id: candidate.productId,
      expires_at: candidate.expiresAt?.toISOString() ?? null,
      updated_at: now().toISOString(),
      revenuecat_app_user_id: null,
      last_event_type: "SERVER_API_RECONCILIATION",
      entitlement_source: entitlementSource,
      app_store_original_transaction_id: candidate.originalTransactionId ??
        null,
      app_store_transaction_id: candidate.transactionId ?? null,
      app_store_environment: candidate.environment,
      app_store_notification_type: "SERVER_API_RECONCILIATION",
      app_store_notification_subtype: candidate.status === null
        ? null
        : String(candidate.status),
      app_store_signed_date: null,
    },
    "user_id",
  );

  if (entitlementError) {
    logger.error("Failed to upsert App Store reconciled entitlement", {
      code: entitlementError.code,
      message: entitlementError.message,
    });
    await insertAuditEvent(
      adminClient,
      auditValues({
        requestedTransactionId,
        requestedUserId,
        resolvedUserId,
        candidate,
        outcome: "failed",
        errorCode: isUnknownUserDbError(entitlementError)
          ? "unknown_user"
          : "database_error",
        now: now(),
      }),
    );

    if (isUnknownUserDbError(entitlementError)) {
      return jsonResponse(
        { success: true, message: "Unknown user, entitlement ignored" },
        200,
      );
    }

    return jsonResponse({ success: false, error: "Database error" }, 503);
  }

  const auditError = await insertAuditEvent(
    adminClient,
    auditValues({
      requestedTransactionId,
      requestedUserId,
      resolvedUserId,
      candidate,
      outcome: "updated",
      now: now(),
    }),
  );
  if (auditError) {
    logger.warn("Failed to record App Store reconciliation event", {
      code: auditError.code,
      message: auditError.message,
    });
  }

  logger.log("App Store entitlement reconciled", {
    user_id: redacted(resolvedUserId),
    is_pro: candidate.isPro,
    product_id: candidate.productId,
    original_transaction_id: redacted(candidate.originalTransactionId),
    transaction_id: redacted(candidate.transactionId),
    status: candidate.status,
  });

  return jsonResponse(
    {
      success: true,
      is_pro: candidate.isPro,
      product_id: candidate.productId,
      expires_at: candidate.expiresAt?.toISOString() ?? null,
      entitlement_source: entitlementSource,
    },
    200,
  );
}

if (import.meta.main) {
  Deno.serve((req) => handleAppStoreEntitlementReconciliation(req));
}
