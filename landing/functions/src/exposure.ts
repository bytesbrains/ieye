// Outside-in exposure teaser for /app. PASSIVE by design: it reads the caller's
// OWN public IP (the source IP of the request) and looks it up in Shodan's FREE
// InternetDB (https://internetdb.shodan.io — no API key, and Shodan already
// scanned the internet, so WE never scan anything). Because it only ever uses the
// request's own source IP, it cannot be turned into a scanner for other people's
// addresses.
//
// HONEST BY DESIGN (Maktub D-031): "nothing found" is NOT "you're safe". The
// scariest home exposures — a camera that quietly phones out to a vendor cloud
// (P2P) — never appear in an internet port scan, and Shodan's data can be stale.
// This function returns raw facts; the UI states the limits plainly.

import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import type { IncomingHttpHeaders } from "http";

interface InternetDbResponse {
  ip?: string;
  ports?: number[];
  cpes?: string[];
  hostnames?: string[];
  tags?: string[];
  vulns?: string[];
}

// The shaped result of a passive exposure lookup.
type ExposureResult =
  | { status: "unknown"; ip: string | null }
  | { status: "clean"; ip: string; cgnat: boolean }
  | { status: "error"; ip: string }
  | {
      status: "exposed";
      ip: string;
      cgnat: boolean;
      ports: number[];
      vulns: string[];
      tags: string[];
      hostnames: string[];
    };

const arr = <T>(v: T[] | undefined): T[] => (Array.isArray(v) ? v : []);

// The passive lookup + result shaping — the one place with real branching, kept
// OUT of the HTTP handler (SRP) and with `fetchImpl` injectable so it's unit-
// testable without a live network or the emulator.
export async function lookupExposure(
  ip: string,
  fetchImpl: typeof fetch = fetch,
): Promise<ExposureResult> {
  try {
    const r = await fetchImpl(`https://internetdb.shodan.io/${ip}`, {
      headers: { "User-Agent": "iEye-exposure-check (+https://ieye.in)" },
      signal: AbortSignal.timeout(9000),
    });
    if (r.status === 404) return { status: "clean", ip, cgnat: isCgnatV4(ip) }; // Shodan has no record
    if (!r.ok) return { status: "error", ip };
    const data = (await r.json()) as InternetDbResponse;
    const ports = arr(data.ports);
    const vulns = arr(data.vulns);
    if (ports.length === 0 && vulns.length === 0) return { status: "clean", ip, cgnat: isCgnatV4(ip) };
    return {
      status: "exposed",
      ip,
      cgnat: isCgnatV4(ip),
      ports,
      vulns,
      tags: arr(data.tags),
      hostnames: arr(data.hostnames),
    };
  } catch (err) {
    logger.warn("exposureCheck lookup failed", { err: String(err) });
    return { status: "error", ip };
  }
}

// Thin HTTP handler: extract the caller's own IP, guard the private/loopback case
// ("unknown", never a false clean), and delegate the branching to lookupExposure.
export const exposureCheck = onRequest(
  { cors: true, maxInstances: 5, timeoutSeconds: 20 },
  async (req, res) => {
    const ip = clientIp(req);
    if (!ip || isPrivateV4(ip)) {
      res.json({ status: "unknown", ip: ip ?? null });
      return;
    }
    res.json(await lookupExposure(ip));
  }
);

// The client's public IP: leftmost of X-Forwarded-For (client first, proxies
// after), falling back to the socket IP. Behind Firebase Hosting → Cloud Run the
// leftmost entry is the real visitor.
export function clientIp(req: { headers: IncomingHttpHeaders; ip?: string }): string | null {
  const xff = req.headers["x-forwarded-for"];
  const raw = Array.isArray(xff) ? xff[0] : typeof xff === "string" ? xff : "";
  const first = raw.split(",")[0]?.trim();
  return normalizeIp(first || req.ip || "");
}

// Strip an IPv6-mapped-IPv4 prefix (::ffff:1.2.3.4) and a trailing :port on IPv4.
export function normalizeIp(ip: string): string | null {
  if (!ip) return null;
  let v = ip.replace(/^::ffff:/i, "");
  if ((v.match(/:/g)?.length ?? 0) === 1) v = v.split(":")[0]; // bare IPv4:port
  return v || null;
}

function octets(ip: string): number[] | null {
  const m = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (!m) return null;
  const o = m.slice(1, 5).map(Number);
  return o.every((n) => n >= 0 && n <= 255) ? o : null;
}

// RFC1918 + loopback + link-local. Non-IPv4 (IPv6) is treated as public/unknown,
// not private — InternetDB will simply 404 if it has nothing.
export function isPrivateV4(ip: string): boolean {
  const o = octets(ip);
  if (!o) return false;
  const [a, b] = o;
  if (a === 10) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a === 127) return true;
  if (a === 169 && b === 254) return true;
  return false;
}

// 100.64.0.0/10 — carrier-grade NAT shared space. When the egress IP is itself in
// this range the connection is definitely CGNAT; more often CGNAT hides behind an
// ordinary shared public IP we can't detect, so the UI carries the "your ISP may
// share this address" caveat regardless.
export function isCgnatV4(ip: string): boolean {
  const o = octets(ip);
  if (!o) return false;
  return o[0] === 100 && o[1] >= 64 && o[1] <= 127;
}
