export type EnvGetter = (key: string) => string | undefined;

export type Logger = {
  log: (...args: unknown[]) => void;
  warn: (...args: unknown[]) => void;
  error: (...args: unknown[]) => void;
};

export type AppleServerConfig = {
  teamId: string;
  clientId: string;
  keyId: string;
  privateKey: string;
};

export type AuthenticatedUser = {
  id: string;
  app_metadata?: Record<string, unknown>;
  identities?: Array<{
    provider?: string;
    provider_id?: string;
    identity_id?: string;
    identity_data?: Record<string, unknown>;
  }>;
};

export type AppleTokenGrant = {
  refreshToken: string;
  subject: string;
};

export class OperationTimedOutError extends Error {
  constructor() {
    super("Operation timed out");
    this.name = "OperationTimedOutError";
  }
}

export class OperationCancelledError extends Error {
  constructor() {
    super("Operation cancelled");
    this.name = "OperationCancelledError";
  }
}

export const defaultLogger: Logger = console;

export function jsonResponse(
  body: Record<string, unknown>,
  status: number,
  headers: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, "Content-Type": "application/json" },
  });
}

export function readAppleServerConfig(
  getEnv: EnvGetter,
): AppleServerConfig | null {
  const teamId = getEnv("APPLE_TEAM_ID")?.trim() ?? "";
  const clientId = getEnv("APPLE_CLIENT_ID")?.trim() ?? "";
  const keyId = getEnv("APPLE_KEY_ID")?.trim() ?? "";
  const privateKey = (getEnv("APPLE_PRIVATE_KEY") ?? "")
    .replaceAll("\\n", "\n")
    .trim();

  guardValid: {
    if (!/^[A-Z0-9]{10}$/.test(teamId)) break guardValid;
    if (!/^[A-Za-z0-9.-]{3,255}$/.test(clientId)) break guardValid;
    if (!/^[A-Z0-9]{10}$/.test(keyId)) break guardValid;
    if (!privateKey.startsWith("-----BEGIN PRIVATE KEY-----")) break guardValid;
    if (!privateKey.endsWith("-----END PRIVATE KEY-----")) break guardValid;
    return { teamId, clientId, keyId, privateKey };
  }

  return null;
}

export function readSupabaseServerConfig(getEnv: EnvGetter): {
  url: string;
  anonKey: string;
  serviceRoleKey: string;
} | null {
  const url = getEnv("SUPABASE_URL")?.trim() ?? "";
  const anonKey = getEnv("SUPABASE_ANON_KEY")?.trim() ?? "";
  const serviceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY")?.trim() ?? "";
  let parsedURL: URL;
  try {
    parsedURL = new URL(url);
  } catch {
    return null;
  }

  if (parsedURL.protocol !== "https:" || !anonKey || !serviceRoleKey) {
    return null;
  }
  return { url: parsedURL.toString(), anonKey, serviceRoleKey };
}

export function appleSubjectForUser(user: AuthenticatedUser): string | null {
  const identity = user.identities?.find((candidate) =>
    candidate.provider === "apple"
  );
  const identitySubject = identity?.identity_data?.sub;
  if (typeof identitySubject === "string" && identitySubject.trim()) {
    return identitySubject.trim();
  }
  const providerID = identity?.provider_id?.trim();
  if (providerID) return providerID;
  const identityID = identity?.identity_id?.trim();
  if (identityID) return identityID;
  return null;
}

export function isAppleUser(user: AuthenticatedUser): boolean {
  if (appleSubjectForUser(user)) return true;
  const provider = user.app_metadata?.provider;
  if (provider === "apple") return true;
  const providers = user.app_metadata?.providers;
  return Array.isArray(providers) && providers.includes("apple");
}

export async function runBounded<T>(
  operation: (signal: AbortSignal) => Promise<T>,
  timeoutMs: number,
  parentSignal?: AbortSignal,
): Promise<T> {
  const controller = new AbortController();
  let timeoutID: ReturnType<typeof setTimeout> | undefined;
  let parentAbort: (() => void) | undefined;

  const timeout = new Promise<never>((_, reject) => {
    timeoutID = setTimeout(() => {
      reject(new OperationTimedOutError());
      controller.abort();
    }, timeoutMs);
  });
  const cancellation = new Promise<never>((_, reject) => {
    if (!parentSignal) return;
    parentAbort = () => {
      reject(new OperationCancelledError());
      controller.abort();
    };
    if (parentSignal.aborted) {
      parentAbort();
    } else {
      parentSignal.addEventListener("abort", parentAbort, { once: true });
    }
  });

  try {
    return await Promise.race([
      operation(controller.signal),
      timeout,
      cancellation,
    ]);
  } finally {
    if (timeoutID !== undefined) clearTimeout(timeoutID);
    if (parentSignal && parentAbort) {
      parentSignal.removeEventListener("abort", parentAbort);
    }
  }
}

export async function generateAppleClientSecret(
  config: AppleServerConfig,
  now: Date = new Date(),
): Promise<string> {
  const header = { alg: "ES256", kid: config.keyId, typ: "JWT" };
  const issuedAt = Math.floor(now.getTime() / 1000);
  const payload = {
    iss: config.teamId,
    iat: issuedAt,
    exp: issuedAt + 300,
    aud: "https://appleid.apple.com",
    sub: config.clientId,
  };
  const encoder = new TextEncoder();
  const headerPart = base64URL(encoder.encode(JSON.stringify(header)));
  const payloadPart = base64URL(encoder.encode(JSON.stringify(payload)));
  const signingInput = `${headerPart}.${payloadPart}`;

  const pemContents = config.privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(pemContents), (character) =>
    character.charCodeAt(0)
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    encoder.encode(signingInput),
  );
  return `${signingInput}.${base64URL(new Uint8Array(signature))}`;
}

export function validateAppleTokenResponse(
  body: unknown,
  config: AppleServerConfig,
  expectedSubject: string,
  now: Date = new Date(),
): AppleTokenGrant | null {
  if (!isRecord(body)) return null;
  const refreshToken = readBoundedString(body.refresh_token, 8192);
  const idToken = readBoundedString(body.id_token, 16_384);
  const tokenType = readBoundedString(body.token_type, 32);
  if (!refreshToken || !idToken || tokenType?.toLowerCase() !== "bearer") {
    return null;
  }

  const claims = decodeJWTClaims(idToken);
  if (!claims) return null;
  const subject = readBoundedString(claims.sub, 512);
  const issuer = readBoundedString(claims.iss, 128);
  const expiry = claims.exp;
  const audience = claims.aud;
  const audienceMatches = typeof audience === "string"
    ? audience === config.clientId
    : Array.isArray(audience) && audience.includes(config.clientId);

  if (
    subject !== expectedSubject ||
    issuer !== "https://appleid.apple.com" ||
    !audienceMatches ||
    typeof expiry !== "number" ||
    expiry <= Math.floor(now.getTime() / 1000)
  ) {
    return null;
  }

  return { refreshToken, subject };
}

export function readBoundedString(
  value: unknown,
  maximumLength: number,
): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maximumLength) return null;
  return trimmed;
}

export function redactedUserID(userID: string): string {
  return `${userID.slice(0, 8)}...`;
}

function decodeJWTClaims(token: string): Record<string, unknown> | null {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const base64 = parts[1].replaceAll("-", "+").replaceAll("_", "/");
    const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
    const decoded = Uint8Array.from(atob(padded), (character) =>
      character.charCodeAt(0)
    );
    const value = JSON.parse(new TextDecoder().decode(decoded));
    return isRecord(value) ? value : null;
  } catch {
    return null;
  }
}

function base64URL(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replace(/=+$/, "");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
