import { Link } from "react-router-dom";
import {
  LegalPageLayout,
  LegalH2,
  LegalP,
  LegalUL,
} from "../components/legal/LegalPageLayout";
import { CONSENT_VERSION } from "../lib/consentVersion";

// Published privacy notice for the iEye contribution website + account.
//
// Scoped to what we ACTUALLY collect today (Phase 1.5: waitlist + Google account
// + the name-only supporter-wall opt-in). Contributions/crypto are described as
// future because no payment surface is live yet. The fuller, internal draft
// (incl. Phase-2 contribution/on-chain detail) lives in landing/legal/privacy-notice.md.
//
// IMPORTANT: this is the notice users consent to. `Version` is pinned to
// CONSENT_VERSION (the value recorded with each consent) so logged consent always
// maps to a readable notice. Keep this page, CONSENT_VERSION, and the legal/ draft
// in sync; CODEOWNERS routes changes past Legal.
export function Privacy() {
  return (
    <LegalPageLayout
      title="Privacy Notice"
      effectiveDate="21 June 2026"
      version={CONSENT_VERSION}
      intro={
        <>
          iEye is a welfare project run as a public good. It is built to know as little
          about you as possible. This notice explains what the iEye website and contribution
          account collect, why, and the choices you have.
        </>
      }
    >
      <LegalH2>1. Who we are</LegalH2>
      <LegalP>
        The iEye website and contribution account are operated by{" "}
        <strong>BytesBrains Pte Ltd</strong>, a private limited company registered in
        Singapore (&ldquo;BytesBrains,&rdquo; &ldquo;we,&rdquo; &ldquo;us&rdquo;). For the
        personal data described here, BytesBrains Pte Ltd is the data controller.
      </LegalP>
      <LegalP>
        Questions or requests about your data: <strong>privacy@ieye.in</strong>.
      </LegalP>

      <LegalH2>2. What this notice covers (and what it doesn&rsquo;t)</LegalH2>
      <LegalP>
        This notice covers the <strong>contribution website and your account</strong> only.
        It does <strong>not</strong> cover the iEye mobile safety app: that app reads only a
        signal of life at the edge of your own device and does not send your location,
        sleep, or activity to any server. When that app ships it will have its own notice.
      </LegalP>

      <LegalH2>3. What we collect, and why</LegalH2>
      <LegalP>Right now we collect only what we need to do two things you asked for:</LegalP>
      <LegalUL>
        <li>
          <strong>Your Google profile</strong> (name, email, profile photo) when you join
          the launch waitlist or sign in to an account — used to tell you when iEye opens and
          to manage your account. We do not read your Google contacts, files, or anything
          else.
        </li>
        <li>
          <strong>Your supporter-wall choice</strong> — if you opt in to be named, we store
          that choice plus the notice version and time, so we can publish your{" "}
          <strong>name only</strong> (never an amount) and prove your consent.
        </li>
      </LegalUL>
      <LegalP>
        Contributing money isn&rsquo;t open yet. When it is, we will record contribution
        details (amount, method, date) for accounting, tax, and anti-money-laundering
        duties, and this notice will be updated before that goes live.
      </LegalP>

      <LegalH2>4. The supporter wall — name only, opt-in</LegalH2>
      <LegalUL>
        <li>
          <strong>Private by default.</strong> Nothing about you is published unless you
          affirmatively opt in. The opt-in is never pre-ticked.
        </li>
        <li>
          <strong>Name only.</strong> The wall shows your display name and nothing else —
          <strong> no amount, ever</strong>. Being named is not being priced.
        </li>
        <li>
          <strong>You can change your mind anytime</strong> from your account; withdrawing
          removes your name from the wall going forward.
        </li>
      </LegalUL>

      <LegalH2>5. Our lawful basis</LegalH2>
      <LegalP>
        We rely on your <strong>consent</strong> for collecting your profile and for
        publishing your name, and on performing the request you made (e.g. notifying you at
        launch). This is consistent with Singapore&rsquo;s PDPA, the EU/UK GDPR, and
        India&rsquo;s DPDP Act. You can withdraw consent at any time (see your rights below).
      </LegalP>

      <LegalH2>6. Who we share data with</LegalH2>
      <LegalP>
        Service providers who process data on our instructions — authentication and hosting
        (Google / Firebase), and, when contributions open, payment processing and email
        delivery. We disclose data only if required by law (for example a valid legal order
        or a suspicious-transaction report under Singapore law). <strong>We never sell your
        data.</strong>
      </LegalP>

      <LegalH2>7. International transfers</LegalH2>
      <LegalP>
        We are based in Singapore and serve people globally, so your data may be processed
        outside your country. Where required, we rely on appropriate safeguards and on your
        consent for the specific publication described above.
      </LegalP>

      <LegalH2>8. How long we keep it</LegalH2>
      <LegalP>
        We keep account and consent records while your account is active and for as long as
        needed for the purposes above. Once contributions exist, accounting records are kept
        for 5 years to meet Singapore requirements. Withdrawing wall consent removes your
        name from the wall but does not erase records we must keep by law.
      </LegalP>

      <LegalH2>9. Your rights</LegalH2>
      <LegalP>
        Depending on where you live (PDPA / GDPR / DPDP), you can ask to access, correct, or
        delete your data, withdraw consent, and complain to your data-protection authority.
        To exercise any of these, email <strong>privacy@ieye.in</strong>. You can also delete
        your account and its data yourself from your account page at any time.
      </LegalP>

      <LegalH2>10. Changes to this notice</LegalH2>
      <LegalP>
        If we change this notice we update the version and effective date above, and ask for
        consent again where the change is material. Your consent is always recorded against
        the version in force when you gave it (currently{" "}
        <code className="text-charcoal-soft">{CONSENT_VERSION}</code>).
      </LegalP>

      <LegalP>
        See also our{" "}
        <Link to="/terms" className="font-medium text-teal-deep underline">
          Terms
        </Link>
        .
      </LegalP>
    </LegalPageLayout>
  );
}
