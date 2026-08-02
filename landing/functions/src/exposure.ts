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

export const exposureCheck = onRequest(
  { cors: true, maxInstances: 5, timeoutSeconds: 20 },
  async (req, res) => {
    const ip = clientIp(req);
    // A private/loopback source means we truly can't see out (e.g. local dev, or
    // some VPNs) — report "unknown", never a misleading "clean".
    if (!ip || isPrivateV4(ip)) {
      res.json({ status: "unknown", ip: ip ?? null });
      return;
    }
    try {
      const r = await fetch(`https://internetdb.shodan.io/${ip}`, {
        headers: { "User-Agent": "iEye-exposure-check (+https://ieye.in)" },
        signal: AbortSignal.timeout(9000),
      });
      // 404 = Shodan has no record for this IP.
      if (r.status === 404) {
        res.json({ status: "clean", ip, cgnat: isCgnatV4(ip) });
        return;
      }
      if (!r.ok) {
        res.json({ status: "error", ip });
        return;
      }
      const data = (await r.json()) as InternetDbResponse;
      const ports = Array.isArray(data.ports) ? data.ports : [];
      const vulns = Array.isArray(data.vulns) ? data.vulns : [];
      res.json({
        status: ports.length > 0 || vulns.length > 0 ? "exposed" : "clean",
        ip,
        cgnat: isCgnatV4(ip),
        ports,
        vulns,
        tags: Array.isArray(data.tags) ? data.tags : [],
        hostnames: Array.isArray(data.hostnames) ? data.hostnames : [],
      });
    } catch (err) {
      logger.warn("exposureCheck lookup failed", { err: String(err) });
      res.json({ status: "error", ip });
    }
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
