import { assert, assertEquals } from "jsr:@std/assert@1";

import { handleAppStoreNotification } from "./index.ts";

const TEST_USER_ID = "11111111-1111-1111-1111-111111111111";
const TEST_PRODUCT_ID = "com.prosepal.pro.monthly";
const TEST_NOTIFICATION_UUID = "22222222-2222-2222-2222-222222222222";
const TEST_TRANSACTION_ID = "1000000123456789";

type TestVerifiedPayload = {
  notification: Record<string, unknown>;
  transaction?: Record<string, unknown>;
  renewalInfo?: Record<string, unknown>;
};

function makeRequest(payload: unknown): Request {
  return new Request(
    "https://example.supabase.co/functions/v1/app-store-notifications",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    },
  );
}

function verifiedPayload(options: {
  notificationType?: string;
  subtype?: string;
  notificationUUID?: string;
  productId?: string;
  appAccountToken?: string;
  expiresDate?: number;
  omitExpiresDate?: boolean;
  gracePeriodExpiresDate?: number;
  revocationDate?: number;
} = {}): TestVerifiedPayload {
  const transaction: Record<string, unknown> = {
    appAccountToken: options.appAccountToken ?? TEST_USER_ID,
    productId: options.productId ?? TEST_PRODUCT_ID,
    originalTransactionId: "1000000000000001",
    transactionId: TEST_TRANSACTION_ID,
    revocationDate: options.revocationDate,
    environment: "Sandbox",
  };

  if (!options.omitExpiresDate) {
    transaction.expiresDate = options.expiresDate ?? 1_798_761_600_000;
  }

  return {
    notification: {
      notificationType: options.notificationType ?? "SUBSCRIBED",
      subtype: options.subtype,
      notificationUUID: options.notificationUUID ?? TEST_NOTIFICATION_UUID,
      signedDate: 1_767_225_600_000,
      data: {
        environment: "Sandbox",
      },
    },
    transaction,
    renewalInfo: options.gracePeriodExpiresDate
      ? { gracePeriodExpiresDate: options.gracePeriodExpiresDate }
      : undefined,
  };
}

function makeDeps(options: {
  verified?: TestVerifiedPayload;
  verifyError?: Error;
  envOverrides?: Record<string, string | undefined>;
  upsertErrorByTable?: Record<
    string,
    { code?: string; message?: string; details?: string }
  >;
  captureUpserts?: Array<{
    table: string;
    values: Record<string, unknown>;
    onConflict: string;
  }>;
  logMessages?: string[];
} = {}) {
  const captureUpserts = options.captureUpserts ?? [];
  const logMessages = options.logMessages ?? [];

  return {
    getEnv: (key: string): string | undefined => {
      if (Object.hasOwn(options.envOverrides ?? {}, key)) {
        return options.envOverrides?.[key];
      }

      switch (key) {
        case "SUPABASE_URL":
          return "https://example.supabase.co";
        case "SUPABASE_SERVICE_ROLE_KEY":
          return "service-role-key";
        case "APP_STORE_PREMIUM_PRODUCT_IDS":
          return TEST_PRODUCT_ID;
        default:
          return undefined;
      }
    },
    verifySignedPayload: async () => {
      if (options.verifyError) throw options.verifyError;
      return options.verified ?? verifiedPayload();
    },
    createAdminClient: () => ({
      from: (table: string) => ({
        upsert: async (
          values: Record<string, unknown>,
          config: { onConflict: string },
        ): Promise<
          {
            error: { code?: string; message?: string; details?: string } | null;
          }
        > => {
          captureUpserts.push({ table, values, onConflict: config.onConflict });
          return { error: options.upsertErrorByTable?.[table] ?? null };
        },
      }),
    }),
    logger: {
      log: (...args: unknown[]) => logMessages.push(JSON.stringify(args)),
      warn: (...args: unknown[]) => logMessages.push(JSON.stringify(args)),
      error: (...args: unknown[]) => logMessages.push(JSON.stringify(args)),
    },
    now: () => new Date("2026-01-01T00:00:00.000Z"),
  };
}

Deno.test("returns 400 when signedPayload is missing", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({}),
    makeDeps({ captureUpserts: upserts }),
  );

  assertEquals(res.status, 400);
  assertEquals(upserts.length, 0);
});

Deno.test("returns 400 when Apple signedPayload verification fails", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verifyError: new Error("signature verification failed"),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 400);
  assertEquals(upserts.length, 0);
});

Deno.test("stores notification metadata and activates entitlement for signed-in purchases", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({ captureUpserts: upserts }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts.length, 2);
  assertEquals(upserts[0].table, "app_store_notification_events");
  assertEquals(upserts[0].onConflict, "notification_uuid");
  assertEquals(upserts[0].values.notification_uuid, TEST_NOTIFICATION_UUID);
  assertEquals(upserts[0].values.app_account_token, TEST_USER_ID);

  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].onConflict, "user_id");
  assertEquals(upserts[1].values.user_id, TEST_USER_ID);
  assertEquals(upserts[1].values.is_pro, true);
  assertEquals(upserts[1].values.product_id, TEST_PRODUCT_ID);
  assertEquals(
    upserts[1].values.entitlement_source,
    "app_store_server_notifications",
  );
  assertEquals(upserts[1].values.app_store_transaction_id, TEST_TRANSACTION_ID);
});

Deno.test("expires entitlement when Apple sends an expired event", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({
        notificationType: "EXPIRED",
        expiresDate: 1_704_067_200_000,
      }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].values.is_pro, false);
});

Deno.test("does not activate entitlement when a grant candidate has no expiry", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({
        notificationType: "SUBSCRIBED",
        omitExpiresDate: true,
      }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].values.is_pro, false);
  assertEquals(upserts[1].values.expires_at, null);
});

Deno.test("does not activate entitlement for unknown notifications even with a future expiry", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({
        notificationType: "TEST",
        expiresDate: 1_798_761_600_000,
      }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].values.is_pro, false);
});

Deno.test("does not activate entitlement for failed renewal in billing retry", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({
        notificationType: "DID_FAIL_TO_RENEW",
        subtype: "BILLING_RETRY",
        expiresDate: 1_798_761_600_000,
      }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].values.is_pro, false);
});

Deno.test("keeps entitlement active during billing grace period", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];
  const gracePeriodExpiresDate = 1_798_761_600_000;

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({
        notificationType: "DID_FAIL_TO_RENEW",
        subtype: "GRACE_PERIOD",
        expiresDate: 1_704_067_200_000,
        gracePeriodExpiresDate,
      }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].values.is_pro, true);
  assertEquals(
    upserts[1].values.expires_at,
    new Date(gracePeriodExpiresDate).toISOString(),
  );
});

Deno.test("expires entitlement after billing grace period ends", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({
        notificationType: "DID_FAIL_TO_RENEW",
        subtype: "GRACE_PERIOD",
        expiresDate: 1_704_067_200_000,
        gracePeriodExpiresDate: 1_704_067_200_000,
      }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  assertEquals(upserts[1].table, "user_entitlements");
  assertEquals(upserts[1].values.is_pro, false);
});

Deno.test("records event but skips entitlement when appAccountToken is missing", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({ appAccountToken: "" }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  const body = await res.json() as Record<string, unknown>;
  assertEquals(body.message, "No UUID appAccountToken; entitlement ignored");
  assertEquals(upserts.map((upsert) => upsert.table), [
    "app_store_notification_events",
  ]);
});

Deno.test("records event but skips entitlement when product is not configured", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      verified: verifiedPayload({ productId: "com.prosepal.unconfigured" }),
      captureUpserts: upserts,
    }),
  );

  assertEquals(res.status, 200);
  const body = await res.json() as Record<string, unknown>;
  assertEquals(body.message, "Product ignored");
  assertEquals(upserts.map((upsert) => upsert.table), [
    "app_store_notification_events",
  ]);
});

Deno.test("returns 503 for transient entitlement database errors", async () => {
  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      upsertErrorByTable: {
        user_entitlements: { message: "connection timeout" },
      },
    }),
  );

  assertEquals(res.status, 503);
});

Deno.test("returns 200 for unknown local users after recording the event", async () => {
  const upserts: Array<
    { table: string; values: Record<string, unknown>; onConflict: string }
  > = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({
      captureUpserts: upserts,
      upsertErrorByTable: {
        user_entitlements: {
          code: "23503",
          message: "insert or update on table violates foreign key constraint",
          details: "user_entitlements_user_id_fkey",
        },
      },
    }),
  );

  assertEquals(res.status, 200);
  const body = await res.json() as Record<string, unknown>;
  assertEquals(body.message, "Unknown user, event ignored");
  assertEquals(upserts[0].table, "app_store_notification_events");
});

Deno.test("logs metadata without signed payloads or full identifiers", async () => {
  const logs: string[] = [];

  const res = await handleAppStoreNotification(
    makeRequest({ signedPayload: "signed.payload.value" }),
    makeDeps({ logMessages: logs }),
  );

  assertEquals(res.status, 200);
  const joinedLogs = logs.join("\n");
  assert(!joinedLogs.includes("signed.payload.value"));
  assert(!joinedLogs.includes(TEST_USER_ID));
  assert(!joinedLogs.includes(TEST_TRANSACTION_ID));
  assert(joinedLogs.includes(TEST_PRODUCT_ID));
});
