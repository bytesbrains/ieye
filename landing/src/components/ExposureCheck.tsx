import { useState } from "react";

// The outside-in browser teaser. Calls /api/exposure (same-origin Cloud Function),
// which passively looks up the caller's OWN public IP in Shodan's free InternetDB.
// A browser CANNOT scan a home LAN — so this only ever shows what's visible from
// the internet, and every result ends with the honest truth: the real check is
// the app, because "nothing found" is not "you're safe".

type Result =
  | { status: "exposed"; ip: string; cgnat?: boolean; ports?: number[]; vulns?: string[] }
  | { status: "clean"; ip: string; cgnat?: boolean }
  | { status: "unknown"; ip: string | null }
  | { status: "error" };

type UiState = "idle" | "loading" | "done";

const SERVICE: Record<number, string> = {
  21: "FTP", 22: "SSH", 23: "Telnet (insecure)", 80: "web (HTTP)", 443: "web (HTTPS)",
  554: "camera stream (RTSP)", 8000: "web / camera", 8080: "web admin", 8443: "web admin",
  8899: "camera (XM)", 34567: "camera (XM)", 37777: "DVR", 3389: "remote desktop",
};
const svc = (p: number) => (SERVICE[p] ? `Port ${p} — ${SERVICE[p]}` : `Port ${p}`);

const CARD = "rounded-2xl border-2 p-6";

export function ExposureCheck() {
  const [ui, setUi] = useState<UiState>("idle");
  const [result, setResult] = useState<Result | null>(null);

  async function run() {
    setUi("loading");
    try {
      const r = await fetch("/api/exposure", { headers: { Accept: "application/json" } });
      const ct = r.headers.get("content-type") ?? "";
      if (!r.ok || !ct.includes("application/json")) throw new Error("bad response");
      setResult((await r.json()) as Result);
    } catch {
      setResult({ status: "error" });
    } finally {
      setUi("done");
    }
  }

  return (
    <div>
      {ui !== "done" && (
        <>
          <p className="max-w-prose text-base leading-relaxed text-charcoal-soft">
            A browser can&rsquo;t look inside your home network — that&rsquo;s exactly the protection
            the app exists for. But we can show you what&rsquo;s visible on your connection{" "}
            <em>from the internet</em>, using public scan data (we never scan you).
          </p>
          <button
            type="button"
            onClick={run}
            disabled={ui === "loading"}
            className="btn btn-primary mt-5 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {ui === "loading" ? "Checking…" : "Check my exposure"}
          </button>
        </>
      )}

      {ui === "done" && result && (
        <div role="status">
          <ResultView result={result} />
          <button type="button" onClick={run} className="btn-ghost mt-4 text-sm">
            Check again
          </button>
        </div>
      )}
    </div>
  );
}

function ResultView({ result }: { result: Result }) {
  if (result.status === "exposed") {
    const ports = result.ports ?? [];
    const vulns = result.vulns ?? [];
    return (
      <div className={`${CARD} border-amber bg-amber/5`}>
        <p className="text-lg font-semibold text-charcoal">
          Visible from the internet on your connection:
        </p>
        <ul role="list" className="mt-3 space-y-1.5">
          {ports.map((p) => (
            <li key={p} className="text-base text-charcoal-soft">
              • {svc(p)}
            </li>
          ))}
        </ul>
        {vulns.length > 0 && (
          <p className="mt-3 text-base font-medium text-amber-deep">
            …and {vulns.length} known vulnerabilit{vulns.length === 1 ? "y" : "ies"} on this address.
          </p>
        )}
        <SharedIpCaveat cgnat={result.cgnat} />
        <InsideNudge />
      </div>
    );
  }

  if (result.status === "clean") {
    return (
      <div className={`${CARD} border-teal/40 bg-teal/5`}>
        <p className="text-lg font-semibold text-charcoal">
          Nothing showed up for your connection in public scan data.
        </p>
        <p className="mt-2 text-base leading-relaxed text-charcoal-soft">
          That&rsquo;s a good sign — but it isn&rsquo;t a clean bill of health. A browser can&rsquo;t
          see inside your home, and the scariest exposures — a camera quietly streaming to a vendor
          cloud — <strong className="font-semibold text-charcoal">never appear in a scan like
          this.</strong>
        </p>
        <SharedIpCaveat cgnat={result.cgnat} />
        <InsideNudge />
      </div>
    );
  }

  if (result.status === "unknown") {
    return (
      <div className={`${CARD} border-charcoal/15 bg-paper`}>
        <p className="text-lg font-semibold text-charcoal">
          We couldn&rsquo;t read a public address for your connection.
        </p>
        <p className="mt-2 text-base leading-relaxed text-charcoal-soft">
          You may be on a VPN or a private network. Either way, the outside-in view can&rsquo;t tell
          you much here — the app checks your home directly.
        </p>
        <InsideNudge />
      </div>
    );
  }

  return (
    <div className={`${CARD} border-charcoal/15 bg-paper`}>
      <p className="text-lg font-semibold text-charcoal">Couldn&rsquo;t run the check right now.</p>
      <p className="mt-2 text-base text-charcoal-soft">Please try again in a moment.</p>
    </div>
  );
}

function SharedIpCaveat({ cgnat }: { cgnat?: boolean }) {
  return (
    <p className="mt-3 text-sm leading-relaxed text-charcoal-muted">
      {cgnat
        ? "Your connection uses a shared carrier address (CGNAT), so this view is about a network many people share — not your home alone."
        : "This is your connection’s public address, which your internet provider may share with others — so some of this may not be your home."}
    </p>
  );
}

function InsideNudge() {
  return (
    <p className="mt-4 text-base font-medium text-charcoal">
      To see what&rsquo;s exposed <em>inside</em> your home, install the app below and run the full
      scan. <a href="#install" className="underline hover:text-charcoal-soft">Get it →</a>
    </p>
  );
}
