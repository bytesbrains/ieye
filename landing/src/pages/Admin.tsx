// /admin — admin shell, gated by the `admin` custom claim (RequireAdmin).
//
// A functional shell, NOT a full ops console:
//   - contributorRequests queue with "advance status" (allowed by rules)
//   - read-only contributions ledger (writes are backend-only — noted in UI)
//   - read-only users list (support)
//
// Every place the backend/Functions are required is called out explicitly so
// no one mistakes the shell for a complete admin surface.

import { useCallback, useEffect, useState } from "react";
import { AppLayout } from "../components/app/AppLayout";
import { Spinner } from "../components/app/Spinner";
import {
  advanceRequest,
  fetchContributions,
  fetchContributorRequests,
  fetchUsers,
  nextStatus,
} from "../lib/admin";
import type {
  ContributionDoc,
  ContributorRequestDoc,
  UserDoc,
  WithId,
} from "../lib/types";
import { formatAmount } from "../lib/format";
import { adminActionError, callGrantAdmin, callRevokeAdmin } from "../lib/adminActions";
import { useAuth } from "../auth/AuthProvider";

function BackendNote({ children }: { children: React.ReactNode }) {
  return (
    <p className="mt-3 rounded-lg border border-teal-deep/30 bg-teal-deep/5 px-4 py-3 text-sm text-teal-deep">
      <strong>Backend required:</strong> {children}
    </p>
  );
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mt-8 rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-6 sm:p-8">
      <h2 className="text-xl font-semibold text-charcoal">{title}</h2>
      <div className="mt-4">{children}</div>
    </section>
  );
}

export function Admin() {
  return (
    <AppLayout>
      <h1 className="text-3xl font-semibold sm:text-4xl">Admin</h1>
      <p className="mt-3 max-w-prose text-base text-charcoal-soft">
        You&rsquo;re here because your account holds the <code>admin</code> claim. This is a
        functional shell — the parts that touch money or publish to the public wall run in the
        backend, never from this browser.
      </p>

      <ManageAdmins />
      <RequestsQueue />
      <ContributionsLedger />
      <UsersList />
    </AppLayout>
  );
}

function ManageAdmins() {
  const { user } = useAuth();
  const [email, setEmail] = useState("");
  const [busy, setBusy] = useState<"grant" | "revoke" | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function run(action: "grant" | "revoke") {
    const target = email.trim();
    if (!target) {
      setError("Enter the person’s email address.");
      return;
    }
    setBusy(action);
    setMessage(null);
    setError(null);
    try {
      const fn = action === "grant" ? callGrantAdmin : callRevokeAdmin;
      const res = await fn({ email: target });
      const verb = action === "grant" ? "Granted" : "Revoked";
      setMessage(`${verb} admin for ${res.email ?? target}. ${res.note ?? ""}`.trim());
      setEmail("");
    } catch (err) {
      setError(adminActionError(err));
    } finally {
      setBusy(null);
    }
  }

  const revokingSelf = email.trim() !== "" && email.trim().toLowerCase() === user?.email?.toLowerCase();

  return (
    <Card title="Manage admins">
      <p className="max-w-prose text-base text-charcoal-soft">
        Grant or revoke the <code>admin</code> claim by email. The person must have signed in at
        least once. Changes take effect after their token refreshes — they should sign out and back
        in to see the change.
      </p>
      <div className="mt-4 flex flex-col gap-3 sm:flex-row">
        <input
          type="email"
          inputMode="email"
          autoComplete="off"
          placeholder="person@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="field-input sm:max-w-sm"
          aria-label="Email of the user to grant or revoke admin"
        />
        <div className="flex gap-3">
          <button
            type="button"
            disabled={busy !== null}
            onClick={() => run("grant")}
            className="btn btn-primary px-5 py-2 text-sm disabled:opacity-60"
          >
            {busy === "grant" ? "Granting…" : "Grant admin"}
          </button>
          <button
            type="button"
            disabled={busy !== null}
            onClick={() => run("revoke")}
            className="btn btn-secondary px-5 py-2 text-sm disabled:opacity-60"
          >
            {busy === "revoke" ? "Revoking…" : "Revoke admin"}
          </button>
        </div>
      </div>

      {revokingSelf && (
        <p className="mt-3 text-sm text-amber-deep">
          Heads up: that’s your own account — revoking it will remove your access on your next token
          refresh.
        </p>
      )}
      {message && (
        <p role="status" className="mt-3 text-sm text-teal-deep">
          {message}
        </p>
      )}
      {error && (
        <p role="alert" className="field-error mt-3">
          {error}
        </p>
      )}

      <BackendNote>
        Minting and revoking the claim runs in a secured, admin-only Cloud Function
        (<code>grantAdmin</code> / <code>revokeAdmin</code>) — never from a client write — and every
        change is recorded to an append-only audit trail.
      </BackendNote>
    </Card>
  );
}

function RequestsQueue() {
  const [rows, setRows] = useState<WithId<ContributorRequestDoc>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setRows(await fetchContributorRequests());
    } catch {
      setError("Couldn't load requests. (Are you signed in with an admin account?)");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function handleAdvance(r: WithId<ContributorRequestDoc>) {
    setBusyId(r.id);
    try {
      await advanceRequest(r.id, r.status);
      await load();
    } catch {
      setError("Couldn't advance that request.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <Card title="Contributor requests">
      {loading ? (
        <Spinner />
      ) : error ? (
        <p role="alert" className="field-error">
          {error}
        </p>
      ) : rows.length === 0 ? (
        <p className="text-base text-charcoal-soft">No requests yet.</p>
      ) : (
        <ul className="divide-y divide-charcoal/10">
          {rows.map((r) => {
            const next = nextStatus(r.status);
            return (
              <li key={r.id} className="flex flex-wrap items-center justify-between gap-3 py-4">
                <div className="max-w-prose">
                  <p className="text-base font-semibold capitalize text-charcoal">{r.status}</p>
                  {r.skills && <p className="text-sm text-charcoal-soft">Skills: {r.skills}</p>}
                  {r.links && <p className="text-sm text-charcoal-muted">Links: {r.links}</p>}
                  {r.note && <p className="text-sm text-charcoal-muted">{r.note}</p>}
                  <p className="mt-1 text-xs text-charcoal-faint">Requested by: {r.ownerUid}</p>
                </div>
                {next ? (
                  <button
                    type="button"
                    disabled={busyId === r.id}
                    onClick={() => handleAdvance(r)}
                    className="btn btn-primary px-5 py-2 text-sm disabled:opacity-60"
                  >
                    {busyId === r.id ? "Working…" : `Advance to ${next}`}
                  </button>
                ) : (
                  <span className="text-sm font-semibold text-teal-deep">Invited</span>
                )}
              </li>
            );
          })}
        </ul>
      )}
      <BackendNote>
        Sending the actual invitation email and any onboarding happens in a Cloud Function — this
        button only moves the request&rsquo;s status, which is all the rules allow a client to do.
      </BackendNote>
    </Card>
  );
}

function ContributionsLedger() {
  const [rows, setRows] = useState<WithId<ContributionDoc>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        setRows(await fetchContributions());
      } catch {
        setError("Couldn't load the ledger.");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <Card title="Contributions ledger (read-only)">
      {loading ? (
        <Spinner />
      ) : error ? (
        <p role="alert" className="field-error">
          {error}
        </p>
      ) : rows.length === 0 ? (
        <p className="text-base text-charcoal-soft">
          No contributions recorded yet. The ledger fills in once the payment backend starts
          writing entries.
        </p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-charcoal-muted">
              <tr className="border-b border-charcoal/10">
                <th className="py-2 pr-4 font-semibold">Kind</th>
                <th className="py-2 pr-4 font-semibold">Method</th>
                <th className="py-2 pr-4 font-semibold">Amount</th>
                <th className="py-2 pr-4 font-semibold">Status</th>
                <th className="py-2 font-semibold">Owner</th>
              </tr>
            </thead>
            <tbody className="text-charcoal">
              {rows.map((c) => (
                <tr key={c.id} className="border-b border-charcoal/5">
                  <td className="py-2 pr-4 capitalize">{c.kind}</td>
                  <td className="py-2 pr-4">{c.method}</td>
                  <td className="py-2 pr-4">{formatAmount(c.amountWei, c.asset)}</td>
                  <td className="py-2 pr-4">{c.status ?? "—"}</td>
                  <td className="py-2 text-charcoal-faint">{c.ownerUid}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <BackendNote>
        This view is read-only by design. No client — not even an admin — can write the
        contributions ledger. Recording, correcting, and reconciling money happens in trusted
        backend functions (payment webhooks, admin reconciliation, on-chain indexer).
      </BackendNote>
    </Card>
  );
}

function UsersList() {
  const [rows, setRows] = useState<WithId<UserDoc>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        setRows(await fetchUsers());
      } catch {
        setError("Couldn't load users.");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <Card title="Users (read-only)">
      {loading ? (
        <Spinner />
      ) : error ? (
        <p role="alert" className="field-error">
          {error}
        </p>
      ) : rows.length === 0 ? (
        <p className="text-base text-charcoal-soft">No users yet.</p>
      ) : (
        <ul className="divide-y divide-charcoal/10">
          {rows.map((u) => (
            <li key={u.id} className="flex items-center justify-between gap-4 py-3">
              <div className="min-w-0">
                <p className="truncate text-base text-charcoal">{u.displayName || "—"}</p>
                <p className="truncate text-sm text-charcoal-soft">{u.email || "—"}</p>
              </div>
              <div className="text-right text-xs text-charcoal-muted">
                <p>name: {u.optInDisplayName ? "opted-in" : "private"}</p>
              </div>
            </li>
          ))}
        </ul>
      )}
      <BackendNote>
        Opt-in here reflects each user&rsquo;s <em>request</em> to be shown. The actual public wall
        (<code>publicSupporters</code>) is built by the backend strictly from consent, and honors
        withdrawals — admins don&rsquo;t publish from this screen. Minting the admin claim is also
        backend-only.
      </BackendNote>
    </Card>
  );
}
