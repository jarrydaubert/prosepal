import { assert, assertEquals } from "jsr:@std/assert@1";

import { handleAppStoreEntitlementReconciliation } from "./index.ts";

const TEST_SECRET = "local-reconcile-secret";
const TEST_USER_ID = "11111111-1111-1111-1111-111111111111";
const OTHER_USER_ID = "33333333-3333-3333-3333-333333333333";
const TEST_PRODUCT_ID = "com.prosepal.pro.monthly";
const TEST_TRANSACTION_ID = "1000000123456789";
const TEST_ORIGINAL_TRANSACTION_ID = "1000000000000001";

type CapturedDbOperation = {
  kind: "insert" | "upsert";
  table: string;
  values: Record<string, unknown>;
  onConflict?: string;
};

type TestStatusItem = {
  status?: number;
  originalTransactionId?: string;
  signedTransactionInfo?: string;
  signedRenewalInfo?: string;
};

function makeRequest(
  payload: unknown,
  options: { secret?: string; method?: string } = {},
): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  const secret = options.secret ?? TEST_SECRET;
  if (secret) {
    headers.set("X-ProsePal-App-Store-Reconcile-Secret", secret);
  }

  return new Request(
    "https://example.supabase.co/functions/v1/app-store-reconcile-entitlement",
    {
      method: options.method ?? "POST",
      headers,
      body: JSON.stringify(payload),
    },
  );
}

function transactionPayload(options: {
  appAccountToken?: string;
  productId?: string;
  expiresDate?: number;
  revocationDate?: number;
} = {}): Record<string, unknown> {
  return {
    appAccountToken: options.appAccountToken ?? TEST_USER_ID,
    productId: options.productId ?? TEST_PRODUCT_ID,
    originalTransactionId: TEST_ORIGINAL_TRANSACTION_ID,
    transactionId: TEST_TRANSACTION_ID,
    expiresDate: options.expiresDate ?? 1_798_761_600_000,
    revocationDate: options.revocationDate,
    environment: "Sandbox",
  };
}

function renewalPayload(options: {
  appAccountToken?: string;
  productId?: string;
  gracePeriodExpiresDate?: number;
  renewalDate?: number;
} = {}): Record<string, unknown> {
  return {
    appAccountToken: options.appAccountToken ?? TEST_USER_ID,
    productId: options.productId ?? TEST_PRODUCT_ID,
    originalTransactionId: TEST_ORIGINAL_TRANSACTION_ID,
    gracePeriodExpiresDate: options.gracePeriodExpiresDate,
    renewalDate: options.renewalDate,
    environment: "Sandbox",
  };
}

function statusResponse(items: TestStatusItem[]) {
  return {
    environment: "Sandbox",
    bundleId: "com.prosepal.prosepal.native",
    data: [
      {
        subscriptionGroupIdentifier: "123456",
        lastTransactions: items,
      },
    ],
  };
}

function makeDeps(options: {
  statusItems?: TestStatusItem[];
  transactionsBySignedValue?: Record<string, Record<string, unknown>>;
  renewalInfoBySignedValue?: Record<string, Record<string, unknown>>;
  apiError?: Error;
  envOverrides?: Record<string, string | undefined>;
  dbErrorByTable?: Record<
    string,
    { code?: string; message?: string; details?: string }
  >;
  operations?: CapturedDbOperation[];
  logMessages?: string[];
} = {}) {
  const operations = options.operations ?? [];
  const logMessages = options.logMessages ?? [];

  return {
    getEnv: (key: string): string | undefined => {
      if (Object.hasOwn(options.envOverrides ?? {}, key)) {
        return options.envOverrides?.[key];
      }

      switch (key) {
        case "APP_STORE_RECONCILE_SECRET":
          return TEST_SECRET;
        case "SUPABASE_URL":
          return "https://example.supabase.co";
        case "SUPABASE_SERVICE_ROLE_KEY":
          return "service-role-key";
        case "APP_STORE_PREMIUM_PRODUCT_IDS":
          return TEST_PRODUCT_ID;
        case "APP_STORE_BUNDLE_ID":
          return "com.prosepal.prosepal.native";
        case "APP_STORE_ENVIRONMENT":
          return "Sandbox";
        default:
          return undefined;
      }
    },
    createAdminClient: () => ({
      from: (table: string) => ({
        insert: async (
          values: Record<string, unknown>,
        ): Promise<
          {
            error: { code?: string; message?: string; details?: string } | null;
          }
        > => {
          operations.push({ kind: "insert", table, values });
          return { error: options.dbErrorByTable?.[table] ?? null };
        },
        upsert: async (
          values: Record<string, unknown>,
          config: { onConflict: string },
        ): Promise<
          {
            error: { code?: string; message?: string; details?: string } | null;
          }
        > => {
          operations.push({
            kind: "upsert",
            table,
            values,
            onConflict: config.onConflict,
          });
          return { error: options.dbErrorByTable?.[table] ?? null };
        },
      }),
    }),
    createAppleApiClient: () => ({
      getAllSubscriptionStatuses: async () => {
        if (options.apiError) throw options.apiError;
        return statusResponse(
          options.statusItems ?? [
            {
              status: 1,
              originalTransactionId: TEST_ORIGINAL_TRANSACTION_ID,
              signedTransactionInfo: "signed.transaction.active",
              signedRenewalInfo: "signed.renewal.active",
            },
          ],
        );
      },
    }),
    createAppleVerifier: () => ({
      verifyAndDecodeTransaction: async (signedTransactionInfo: string) =>
        options.transactionsBySignedValue?.[signedTransactionInfo] ??
          transactionPayload(),
      verifyAndDecodeRenewalInfo: async (signedRenewalInfo: string) =>
        options.renewalInfoBySignedValue?.[signedRenewalInfo] ??
          renewalPayload(),
    }),
    logger: {
      log: (...args: unknown[]) => logMessages.push(JSON.stringify(args)),
      warn: (...args: unknown[]) => logMessages.push(JSON.stringify(args)),
      error: (...args: unknown[]) => logMessages.push(JSON.stringify(args)),
    },
    now: () => new Date("2026-01-01T00:00:00.000Z"),
  };
}

function entitlementUpsert(operations: CapturedDbOperation[]) {
  return operations.find((operation) =>
    operation.kind === "upsert" && operation.table === "user_entitlements"
  );
}

Deno.test("rejects requests without the reconcile secret", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }, { secret: "" }),
    makeDeps({ operations }),
  );

  assertEquals(res.status, 401);
  assertEquals(operations.length, 0);
});

Deno.test("returns 400 when transaction_id is missing", async () => {
  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({}),
    makeDeps(),
  );

  assertEquals(res.status, 400);
});

Deno.test("activates entitlement from an active App Store Server API status", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({ operations }),
  );

  assertEquals(res.status, 200);
  const upsert = entitlementUpsert(operations);
  assert(upsert);
  assertEquals(upsert.values.user_id, TEST_USER_ID);
  assertEquals(upsert.values.is_pro, true);
  assertEquals(upsert.values.product_id, TEST_PRODUCT_ID);
  assertEquals(upsert.values.entitlement_source, "app_store_server_api");
  assertEquals(upsert.values.app_store_transaction_id, TEST_TRANSACTION_ID);
  assertEquals(
    upsert.values.app_store_original_transaction_id,
    TEST_ORIGINAL_TRANSACTION_ID,
  );
});

Deno.test("keeps entitlement active during billing grace period", async () => {
  const operations: CapturedDbOperation[] = [];
  const gracePeriodExpiresDate = 1_798_761_600_000;

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      statusItems: [
        {
          status: 4,
          originalTransactionId: TEST_ORIGINAL_TRANSACTION_ID,
          signedTransactionInfo: "signed.transaction.grace",
          signedRenewalInfo: "signed.renewal.grace",
        },
      ],
      transactionsBySignedValue: {
        "signed.transaction.grace": transactionPayload({
          expiresDate: 1_704_067_200_000,
        }),
      },
      renewalInfoBySignedValue: {
        "signed.renewal.grace": renewalPayload({ gracePeriodExpiresDate }),
      },
      operations,
    }),
  );

  assertEquals(res.status, 200);
  const upsert = entitlementUpsert(operations);
  assert(upsert);
  assertEquals(upsert.values.is_pro, true);
  assertEquals(
    upsert.values.expires_at,
    new Date(gracePeriodExpiresDate).toISOString(),
  );
});

Deno.test("deactivates entitlement for expired subscriptions", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      statusItems: [
        {
          status: 2,
          originalTransactionId: TEST_ORIGINAL_TRANSACTION_ID,
          signedTransactionInfo: "signed.transaction.expired",
        },
      ],
      transactionsBySignedValue: {
        "signed.transaction.expired": transactionPayload({
          expiresDate: 1_704_067_200_000,
        }),
      },
      operations,
    }),
  );

  assertEquals(res.status, 200);
  const upsert = entitlementUpsert(operations);
  assert(upsert);
  assertEquals(upsert.values.is_pro, false);
});

Deno.test("deactivates entitlement for revoked subscriptions", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      statusItems: [
        {
          status: 5,
          originalTransactionId: TEST_ORIGINAL_TRANSACTION_ID,
          signedTransactionInfo: "signed.transaction.revoked",
        },
      ],
      transactionsBySignedValue: {
        "signed.transaction.revoked": transactionPayload({
          revocationDate: 1_704_067_200_000,
        }),
      },
      operations,
    }),
  );

  assertEquals(res.status, 200);
  const upsert = entitlementUpsert(operations);
  assert(upsert);
  assertEquals(upsert.values.is_pro, false);
});

Deno.test("ignores subscriptions outside configured product ids", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      transactionsBySignedValue: {
        "signed.transaction.active": transactionPayload({
          productId: "com.prosepal.unconfigured",
        }),
      },
      operations,
    }),
  );

  assertEquals(res.status, 200);
  const body = await res.json() as Record<string, unknown>;
  assertEquals(body.message, "No configured subscription product found");
  assertEquals(entitlementUpsert(operations), undefined);
});

Deno.test("skips entitlement when no UUID appAccountToken or user_id is available", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      transactionsBySignedValue: {
        "signed.transaction.active": transactionPayload({
          appAccountToken: "not-a-uuid",
        }),
      },
      renewalInfoBySignedValue: {
        "signed.renewal.active": renewalPayload({ appAccountToken: "" }),
      },
      operations,
    }),
  );

  assertEquals(res.status, 200);
  const body = await res.json() as Record<string, unknown>;
  assertEquals(body.message, "No UUID appAccountToken; entitlement ignored");
  assertEquals(entitlementUpsert(operations), undefined);
});

Deno.test("rejects reconciliation when requested user differs from appAccountToken", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({
      transaction_id: TEST_TRANSACTION_ID,
      user_id: OTHER_USER_ID,
    }),
    makeDeps({ operations }),
  );

  assertEquals(res.status, 409);
  assertEquals(entitlementUpsert(operations), undefined);
});

Deno.test("allows explicit user_id when Apple transaction has no appAccountToken", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({
      transaction_id: TEST_TRANSACTION_ID,
      user_id: TEST_USER_ID,
    }),
    makeDeps({
      transactionsBySignedValue: {
        "signed.transaction.active": transactionPayload({
          appAccountToken: "",
        }),
      },
      renewalInfoBySignedValue: {
        "signed.renewal.active": renewalPayload({ appAccountToken: "" }),
      },
      operations,
    }),
  );

  assertEquals(res.status, 200);
  const upsert = entitlementUpsert(operations);
  assert(upsert);
  assertEquals(upsert.values.user_id, TEST_USER_ID);
});

Deno.test("returns 200 for unknown local users after audit metadata is recorded", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      operations,
      dbErrorByTable: {
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
  assertEquals(body.message, "Unknown user, entitlement ignored");
  assert(operations.some((operation) =>
    operation.kind === "insert" &&
    operation.table === "app_store_reconciliation_events"
  ));
});

Deno.test("returns 502 when the App Store Server API request fails", async () => {
  const operations: CapturedDbOperation[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({
      apiError: new Error("Apple unavailable"),
      operations,
    }),
  );

  assertEquals(res.status, 502);
  assertEquals(operations.length, 0);
});

Deno.test("logs metadata without secrets, signed payloads, or full ids", async () => {
  const logs: string[] = [];

  const res = await handleAppStoreEntitlementReconciliation(
    makeRequest({ transaction_id: TEST_TRANSACTION_ID }),
    makeDeps({ logMessages: logs }),
  );

  assertEquals(res.status, 200);
  const joinedLogs = logs.join("\n");
  assert(!joinedLogs.includes(TEST_SECRET));
  assert(!joinedLogs.includes("signed.transaction.active"));
  assert(!joinedLogs.includes(TEST_USER_ID));
  assert(!joinedLogs.includes(TEST_TRANSACTION_ID));
  assert(joinedLogs.includes(TEST_PRODUCT_ID));
});
