// Emulator seeding helpers. The Firestore emulator treats
// `Authorization: Bearer owner` as an admin that BYPASSES security rules, so we
// can write the exact docs the trusted backend would (the Stripe webhook's
// `contributions` row, the consent projection's `publicSupporters` row) without
// a functions emulator. This is how we exercise "a contribution was recorded ->
// it reflects in the UI" deterministically.

const PROJECT = "demo-ieye";
const DB_DOCS = `projects/${PROJECT}/databases/(default)/documents`;
const FS = `http://127.0.0.1:8080/v1/${DB_DOCS}`;
const OWNER = { Authorization: "Bearer owner", "Content-Type": "application/json" };

type Val = string | number | boolean | { ts: string };

function toField(v: Val): Record<string, unknown> {
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number")
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (v && typeof v === "object" && "ts" in v) return { timestampValue: v.ts };
  throw new Error(`unsupported seed value: ${JSON.stringify(v)}`);
}

function toFields(obj: Record<string, Val>) {
  const fields: Record<string, unknown> = {};
  for (const [k, val] of Object.entries(obj)) fields[k] = toField(val);
  return { fields };
}

/** Create a doc in `collection`; returns its generated id. */
export async function seedDoc(collection: string, data: Record<string, Val>): Promise<string> {
  const res = await fetch(`${FS}/${collection}`, {
    method: "POST",
    headers: OWNER,
    body: JSON.stringify(toFields(data)),
  });
  if (!res.ok) throw new Error(`seed ${collection} failed: ${res.status} ${await res.text()}`);
  const doc = (await res.json()) as { name: string };
  return doc.name.split("/").pop() as string;
}

/** Delete every doc in `collection` (test isolation for the shared emulator). */
export async function clearCollection(collection: string): Promise<void> {
  const res = await fetch(`${FS}/${collection}?pageSize=1000`, { headers: OWNER });
  if (!res.ok) return;
  const data = (await res.json()) as { documents?: { name: string }[] };
  const writes = (data.documents ?? []).map((d) => ({ delete: d.name }));
  await batchWrite(writes);
}

/** REST batchWrite (owner bypass), chunked to stay under the 500-op limit. */
async function batchWrite(writes: unknown[]): Promise<void> {
  for (let i = 0; i < writes.length; i += 400) {
    const res = await fetch(`${FS}:batchWrite`, {
      method: "POST",
      headers: OWNER,
      body: JSON.stringify({ writes: writes.slice(i, i + 400) }),
    });
    if (!res.ok) throw new Error(`batchWrite failed: ${res.status} ${await res.text()}`);
  }
}

/** Resolve a signed-in user's uid by reading their own users/{uid} doc (id == uid). */
export async function findUidByEmail(email: string, timeoutMs = 10_000): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  const body = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: "users" }],
      where: {
        fieldFilter: {
          field: { fieldPath: "email" },
          op: "EQUAL",
          value: { stringValue: email },
        },
      },
    },
  });
  while (Date.now() < deadline) {
    const res = await fetch(`${FS}:runQuery`, { method: "POST", headers: OWNER, body });
    if (res.ok) {
      const rows = (await res.json()) as { document?: { name: string } }[];
      const hit = rows.find((r) => r.document);
      if (hit?.document) return hit.document.name.split("/").pop() as string;
    }
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error(`no users/{uid} doc found for ${email}`);
}

/** Seed a consented supporter exactly as the backend's consent projection would. */
export function seedPublicSupporter(displayName: string): Promise<string> {
  return seedDoc("publicSupporters", {
    displayName,
    publishedAt: { ts: "2026-06-30T12:00:00.000Z" },
  });
}

/**
 * Seed `count` supporters in one batched write. Zero-padded names ("Supporter
 * 0001"…) so alphabetical order (the wall's orderBy) matches numeric order,
 * making pagination assertions deterministic.
 */
export async function seedManyPublicSupporters(count: number, prefix = "Supporter"): Promise<void> {
  const writes = Array.from({ length: count }, (_, i) => {
    const n = String(i + 1).padStart(4, "0");
    return {
      update: {
        name: `${DB_DOCS}/publicSupporters/seeded-${n}`,
        fields: toFields({ displayName: `${prefix} ${n}`, publishedAt: { ts: "2026-06-30T12:00:00.000Z" } })
          .fields,
      },
    };
  });
  await batchWrite(writes);
}

/** Seed a fiat contribution exactly as the Stripe webhook would on completion. */
export function seedContribution(
  uid: string,
  opts: { amountMinor?: string; currency?: string; status?: string } = {}
): Promise<string> {
  return seedDoc("contributions", {
    ownerUid: uid,
    kind: "money",
    method: "card",
    amountMinor: opts.amountMinor ?? "2500",
    currency: opts.currency ?? "SGD",
    provider: "stripe",
    isPublic: false,
    status: opts.status ?? "paid",
    timestamp: { ts: "2026-06-30T12:00:00.000Z" },
  });
}
