/**
 * App Store Server Notifications V2 handler for native StoreKit entitlement.
 *
 * This function verifies Apple's signedPayload with Apple's App Store Server
 * Library, maps appAccountToken to a Supabase user UUID, and updates
 * user_entitlements as the server-side source of truth for future Premium
 * limits/extras. It stores metadata only; signed payloads, receipts, and
 * transaction bodies are not persisted or logged.
 */

import { createClient } from "npm:@supabase/supabase-js@2.95.3";
import {
  Environment,
  SignedDataVerifier,
} from "npm:@apple/app-store-server-library@3.1.0";
import { Buffer } from "node:buffer";

const corsHeaders = {
  "Access-Control-Allow-Origin": "",
  "Access-Control-Allow-Headers": "content-type",
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

type VerifiedApplePayload = {
  notification: Record<string, unknown>;
  transaction?: Record<string, unknown>;
  renewalInfo?: Record<string, unknown>;
};

type VerifySignedPayload = (
  signedPayload: string,
  getEnv: EnvGetter,
) => Promise<VerifiedApplePayload>;

interface AppStoreNotificationDeps {
  getEnv?: EnvGetter;
  createAdminClient?: CreateAdminClient;
  verifySignedPayload?: VerifySignedPayload;
  logger?: Logger;
  now?: () => Date;
}

class ConfigError extends Error {}

const entitlementSource = "app_store_server_notifications";

const inactiveNotificationTypes = new Set([
  "EXPIRED",
  "REFUND",
  "REVOKE",
  "GRACE_PERIOD_EXPIRED",
]);

const grantNotificationTypes = new Set([
  "SUBSCRIBED",
  "DID_RENEW",
  "DID_RECOVER",
  "DID_CHANGE_RENEWAL_PREF",
  "DID_CHANGE_RENEWAL_STATUS",
  "OFFER_REDEEMED",
  "PRICE_INCREASE",
  "REFUND_DECLINED",
  "RENEWAL_EXTENDED",
  "RENEWAL_EXTENSION",
]);

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

async function defaultVerifySignedPayload(
  signedPayload: string,
  getEnv: EnvGetter,
): Promise<VerifiedApplePayload> {
  const environment = appStoreEnvironment(getEnv);
  const verifier = new SignedDataVerifier(
    rootCertificates(getEnv),
    onlineChecksEnabled(getEnv),
    environment,
    requiredEnv(getEnv, "APP_STORE_BUNDLE_ID"),
    appAppleId(getEnv, environment),
  );

  const notification = await verifier.verifyAndDecodeNotification(
    signedPayload,
  ) as unknown as Record<string, unknown>;
  const data = isRecord(notification.data) ? notification.data : undefined;
  const signedTransactionInfo = readString(data, "signedTransactionInfo");
  const signedRenewalInfo = readString(data, "signedRenewalInfo");

  return {
    notification,
    transaction: signedTransactionInfo
      ? await verifier.verifyAndDecodeTransaction(
        signedTransactionInfo,
      ) as unknown as Record<string, unknown>
      : undefined,
    renewalInfo: signedRenewalInfo
      ? await verifier.verifyAndDecodeRenewalInfo(
        signedRenewalInfo,
      ) as unknown as Record<string, unknown>
      : undefined,
  };
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

function safeNotificationFacts(payload: VerifiedApplePayload) {
  const notification = payload.notification;
  const data = isRecord(notification.data) ? notification.data : undefined;
  const transaction = payload.transaction;

  return {
    notificationType: readString(notification, "notificationType") ?? "UNKNOWN",
    subtype: readString(notification, "subtype") ?? null,
    notificationUUID: readString(notification, "notificationUUID"),
    environment: readString(data, "environment") ??
      readString(transaction, "environment") ??
      "Unknown",
    signedDate: millisToDate(readNumber(notification, "signedDate")),
    appAccountToken: readString(transaction, "appAccountToken"),
    productId: readString(transaction, "productId"),
    originalTransactionId: readString(transaction, "originalTransactionId"),
    transactionId: readString(transaction, "transactionId"),
    expiresAt: millisToDate(readNumber(transaction, "expiresDate")),
    revocationDate: millisToDate(readNumber(transaction, "revocationDate")),
  };
}

function entitlementIsActive(
  notificationType: string,
  facts: ReturnType<typeof safeNotificationFacts>,
  now: Date,
): boolean {
  if (facts.revocationDate) return false;
  if (inactiveNotificationTypes.has(notificationType)) return false;
  if (facts.expiresAt) return facts.expiresAt > now;
  return grantNotificationTypes.has(notificationType);
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

export async function handleAppStoreNotification(
  req: Request,
  deps: AppStoreNotificationDeps = {},
): Promise<Response> {
  const getEnv = deps.getEnv ?? ((key: string) => Deno.env.get(key));
  const createAdminClient = deps.createAdminClient ?? defaultCreateAdminClient;
  const verifySignedPayload = deps.verifySignedPayload ??
    defaultVerifySignedPayload;
  const logger = deps.logger ?? console;
  const now = deps.now ?? (() => new Date());

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }

  if (!isRecord(body) || typeof body.signedPayload !== "string") {
    return jsonResponse({ error: "Missing signedPayload" }, 400);
  }

  let productIds: string[];
  let adminClient: AdminClient;
  try {
    productIds = configuredProductIds(getEnv);
    adminClient = createAdminClient(
      requiredEnv(getEnv, "SUPABASE_URL"),
      requiredEnv(getEnv, "SUPABASE_SERVICE_ROLE_KEY"),
    );
  } catch (error) {
    logger.error("App Store notification configuration error", {
      message: error instanceof Error ? error.message : "unknown",
    });
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  let verified: VerifiedApplePayload;
  try {
    verified = await verifySignedPayload(body.signedPayload, getEnv);
  } catch (error) {
    logger.warn("App Store signedPayload verification failed", {
      message: error instanceof Error ? error.message : "unknown",
    });
    return jsonResponse({ error: "Invalid signedPayload" }, 400);
  }

  const facts = safeNotificationFacts(verified);
  if (!facts.notificationUUID) {
    logger.warn("App Store notification missing UUID", {
      type: facts.notificationType,
      environment: facts.environment,
    });
    return jsonResponse(
      { success: true, message: "Notification ignored" },
      200,
    );
  }

  const eventValues = {
    notification_uuid: facts.notificationUUID,
    notification_type: facts.notificationType,
    subtype: facts.subtype,
    environment: facts.environment,
    product_id: facts.productId ?? null,
    original_transaction_id: facts.originalTransactionId ?? null,
    transaction_id: facts.transactionId ?? null,
    app_account_token: facts.appAccountToken && isUuid(facts.appAccountToken)
      ? facts.appAccountToken
      : null,
    signed_date: facts.signedDate?.toISOString() ?? null,
    processed_at: now().toISOString(),
  };

  const eventError = await upsert(
    adminClient,
    "app_store_notification_events",
    eventValues,
    "notification_uuid",
  );
  if (eventError) {
    logger.error("Failed to record App Store notification event", {
      code: eventError.code,
      message: eventError.message,
    });
    return jsonResponse({ success: false, error: "Database error" }, 503);
  }

  logger.log("App Store notification received", {
    notification_uuid: redacted(facts.notificationUUID),
    type: facts.notificationType,
    subtype: facts.subtype,
    environment: facts.environment,
    product_id: facts.productId,
    transaction_id: redacted(facts.transactionId),
    app_account_token_present: !!facts.appAccountToken,
  });

  if (!facts.productId || !productIds.includes(facts.productId)) {
    return jsonResponse(
      { success: true, message: "Product ignored" },
      200,
    );
  }

  if (!facts.appAccountToken || !isUuid(facts.appAccountToken)) {
    return jsonResponse(
      {
        success: true,
        message: "No UUID appAccountToken; entitlement ignored",
      },
      200,
    );
  }

  const isPro = entitlementIsActive(facts.notificationType, facts, now());
  const entitlementError = await upsert(
    adminClient,
    "user_entitlements",
    {
      user_id: facts.appAccountToken,
      is_pro: isPro,
      product_id: facts.productId,
      expires_at: facts.expiresAt?.toISOString() ?? null,
      updated_at: now().toISOString(),
      revenuecat_app_user_id: null,
      last_event_type: facts.notificationType,
      entitlement_source: entitlementSource,
      app_store_original_transaction_id: facts.originalTransactionId ?? null,
      app_store_transaction_id: facts.transactionId ?? null,
      app_store_environment: facts.environment,
      app_store_notification_type: facts.notificationType,
      app_store_notification_subtype: facts.subtype,
      app_store_signed_date: facts.signedDate?.toISOString() ?? null,
    },
    "user_id",
  );

  if (entitlementError) {
    logger.error("Failed to upsert App Store entitlement", {
      code: entitlementError.code,
      message: entitlementError.message,
    });
    if (isUnknownUserDbError(entitlementError)) {
      return jsonResponse(
        { success: true, message: "Unknown user, event ignored" },
        200,
      );
    }

    return jsonResponse({ success: false, error: "Database error" }, 503);
  }

  logger.log("App Store entitlement updated", {
    user_id: redacted(facts.appAccountToken),
    is_pro: isPro,
    product_id: facts.productId,
    expires_at: facts.expiresAt?.toISOString(),
    event_type: facts.notificationType,
  });

  return jsonResponse({ success: true }, 200);
}

if (import.meta.main) {
  Deno.serve((req) => handleAppStoreNotification(req));
}
