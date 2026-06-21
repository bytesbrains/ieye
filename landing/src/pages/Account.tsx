// /account — the signed-in user's space.
//   - profile (from users/{uid}, seeded from Google on first visit)
//   - opt-in-to-be-named toggles (default OFF; framed as request-to-publish)
//   - contribution history (read own; empty until backend writes — #42/Phase 2)
//   - contributor-request status / button to request to participate (#36)
//
// CISO constraints honored: never writes contributions; admin is the custom
// claim (not read here); opt-in toggles live on the user's own doc.

import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { AppLayout } from "../components/app/AppLayout";
import { OptInToggle } from "../components/app/OptInToggle";
import { Spinner } from "../components/app/Spinner";
import { useAuth } from "../auth/AuthProvider";
import { CONSENT_VERSION, upsertUserProfile, useUserDoc } from "../lib/useUserDoc";
import { useMyContributions } from "../lib/useContributions";
import {
  createContributorRequest,
  useMyContributorRequests,
} from "../lib/useContributorRequest";
import { formatAmount } from "../lib/format";

function Card({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-8 rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-6 sm:p-8">
      <h2 className="text-xl font-semibold text-charcoal">{title}</h2>
      <div className="mt-4">{children}</div>
    </section>
  );
}

const REQUEST_STATUS_COPY: Record<string, string> = {
  requested: "Received — we'll review it. Nothing more to do for now.",
  vetted: "Reviewed and approved. We'll be in touch about next steps.",
  invited: "You've been invited to contribute. Welcome aboard.",
};

export function Account() {
  const { user } = useAuth();
  const { data: profile, loading: profileLoading } = useUserDoc();
  const { rows: contributions, loading: contribLoading } = useMyContributions();
  const { rows: requests, loading: reqLoading } = useMyContributorRequests();

  // First-visit: seed the user doc from the Google profile + record consent.
  useEffect(() => {
    if (!user || profileLoading) return;
    if (profile === null) {
      void upsertUserProfile(
        user.uid,
        {
          displayName: user.displayName ?? "",
          email: user.email ?? "",
          photoURL: user.photoURL ?? "",
          optInDisplayName: false,
        },
        { recordConsent: true }
      );
    }
  }, [user, profile, profileLoading]);

  if (!user) return null;

  return (
    <AppLayout>
      <h1 className="text-3xl font-semibold sm:text-4xl">Your account</h1>
      <p className="mt-3 max-w-prose text-base text-charcoal-soft">
        This is your iEye <strong>contribution</strong> account — separate from the safety app on
        your phone. Manage how you appear, see anything you&rsquo;ve contributed, and ask to help
        build iEye.
      </p>

      {/* ---- Profile ---- */}
      <Card title="Profile">
        {profileLoading ? (
          <Spinner />
        ) : (
          <dl className="grid gap-4 sm:grid-cols-[auto,1fr] sm:items-center">
            {user.photoURL && (
              <img
                src={user.photoURL}
                alt=""
                referrerPolicy="no-referrer"
                className="h-16 w-16 rounded-full border border-charcoal/15 sm:row-span-2"
              />
            )}
            <div>
              <dt className="text-sm font-semibold text-charcoal-muted">Name</dt>
              <dd className="text-lg text-charcoal">
                {profile?.displayName || user.displayName || "—"}
              </dd>
            </div>
            <div className="sm:col-start-2">
              <dt className="text-sm font-semibold text-charcoal-muted">Email</dt>
              <dd className="text-lg text-charcoal">{profile?.email || user.email || "—"}</dd>
            </div>
          </dl>
        )}
        <p className="mt-4 text-sm text-charcoal-muted">
          Your name and email come from Google. We never publish them anywhere unless you ask us
          to, below.
        </p>
      </Card>

      {/* ---- Opt-in-to-be-named ---- */}
      <Card title="Appearing on the public supporter wall">
        <p className="max-w-prose text-base text-charcoal-soft">
          iEye shows contributions on a public wall so the money is as open as the code. Being
          named is entirely <strong>opt-in</strong>, and off by default. Turning a switch on is a{" "}
          <strong>request to publish</strong> — our team handles the actual publishing, and you can
          turn it back off anytime to be withdrawn from the wall going forward.
        </p>
        {/* The most important honest-promise caveat sits next to the act itself,
            not buried below it: being named is reversible; the chain is not. */}
        <div className="mt-4 rounded-lg border border-amber-deep/30 bg-amber-deep/5 px-4 py-3 text-sm text-charcoal-soft">
          <strong className="text-charcoal">One thing that isn&rsquo;t reversible:</strong> turning
          these switches on or off is always reversible — but a contribution made on a public
          blockchain is permanent and can&rsquo;t be un-published from the chain itself. We&rsquo;ll
          warn you clearly before any on-chain contribution.
        </div>
        {/* Name only — the wall never shows amounts (#36, "named ≠ priced"),
            so there is deliberately no amount toggle to offer. */}
        <div className="mt-4">
          <OptInToggle
            id="optInDisplayName"
            label="Request to show my name"
            description="Ask us to display your name on the public supporter wall. Everyone named is thanked equally — amounts are never shown."
            checked={profile?.optInDisplayName === true}
            disabled={profileLoading}
            onChange={async (next) => {
              await upsertUserProfile(
                user.uid,
                { optInDisplayName: next },
                { recordConsent: true }
              );
            }}
          />
        </div>
        <p className="mt-4 text-sm text-charcoal-muted">
          Consent recorded against{" "}
          <Link to="/privacy" className="underline hover:text-charcoal">
            privacy notice
          </Link>{" "}
          version <code className="text-charcoal-soft">{CONSENT_VERSION}</code>.
        </p>
      </Card>

      {/* ---- Contribution history ---- */}
      <Card title="Your contributions">
        {contribLoading ? (
          <Spinner />
        ) : contributions.length === 0 ? (
          <div className="rounded-xl border-2 border-dashed border-charcoal/20 bg-paper p-6 text-center">
            <p className="text-base font-semibold text-charcoal">No contributions yet.</p>
            <p className="mx-auto mt-2 max-w-prose text-sm text-charcoal-soft">
              When contributing opens and you give — by card, bank, crypto, in-kind, or your time —
              your record will appear here. Contributions are recorded by us, not by this page, so
              the ledger stays trustworthy.
            </p>
          </div>
        ) : (
          <ul className="divide-y divide-charcoal/10">
            {contributions.map((c) => (
              <li key={c.id} className="flex items-center justify-between gap-4 py-3">
                <div>
                  <p className="text-base font-semibold capitalize text-charcoal">{c.kind}</p>
                  <p className="text-sm text-charcoal-soft">{c.method}</p>
                </div>
                <div className="text-right">
                  {c.amountWei && (
                    <p className="text-base text-charcoal">{formatAmount(c.amountWei, c.asset)}</p>
                  )}
                  <p className="text-sm text-charcoal-muted">{c.status ?? ""}</p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </Card>

      {/* ---- Contributor request ---- */}
      <Card title="Help build iEye">
        {reqLoading ? (
          <Spinner />
        ) : requests.length > 0 ? (
          <div>
            <p className="text-base text-charcoal-soft">
              You&rsquo;ve asked to help build iEye. Here&rsquo;s where that stands:
            </p>
            <ul className="mt-3 space-y-3">
              {requests.map((r) => (
                <li key={r.id} className="rounded-xl border border-charcoal/15 bg-paper p-4">
                  <p className="text-base font-semibold capitalize text-charcoal">{r.status}</p>
                  <p className="mt-1 text-sm text-charcoal-soft">
                    {REQUEST_STATUS_COPY[r.status] ?? ""}
                  </p>
                  {r.skills && (
                    <p className="mt-2 text-sm text-charcoal-muted">Skills: {r.skills}</p>
                  )}
                </li>
              ))}
            </ul>
          </div>
        ) : (
          <ContributorRequestForm uid={user.uid} />
        )}
      </Card>
    </AppLayout>
  );
}

function ContributorRequestForm({ uid }: { uid: string }) {
  const [skills, setSkills] = useState("");
  const [links, setLinks] = useState("");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await createContributorRequest(uid, { skills, links, note });
      // The live subscription will swap this form for the status view.
    } catch {
      setError("We couldn't send your request just now. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <p className="max-w-prose text-base text-charcoal-soft">
        Give what you know — specs, testing, code, design, translation. Tell us a little and
        we&rsquo;ll be in touch. This just starts a conversation; nothing is committed.
      </p>
      <div>
        <label htmlFor="skills" className="field-label">
          What can you help with?
        </label>
        <input
          id="skills"
          type="text"
          className="field-input"
          placeholder="e.g. Flutter, Hindi translation, testing"
          value={skills}
          onChange={(e) => setSkills(e.target.value)}
        />
      </div>
      <div>
        <label htmlFor="links" className="field-label">
          A link or two (optional)
        </label>
        <input
          id="links"
          type="text"
          className="field-input"
          placeholder="GitHub, portfolio, LinkedIn…"
          value={links}
          onChange={(e) => setLinks(e.target.value)}
        />
      </div>
      <div>
        <label htmlFor="note" className="field-label">
          Anything else? (optional)
        </label>
        <textarea
          id="note"
          className="field-input min-h-[96px]"
          placeholder="Why iEye matters to you, when you're free…"
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </div>
      {error && (
        <p role="alert" className="field-error">
          {error}
        </p>
      )}
      <button type="submit" disabled={busy} className="btn btn-primary disabled:opacity-60">
        {busy ? "Sending…" : "Ask to help build iEye"}
      </button>
    </form>
  );
}
