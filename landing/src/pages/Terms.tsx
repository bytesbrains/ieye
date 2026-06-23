import { Link } from "react-router-dom";
import {
  LegalPageLayout,
  LegalH2,
  LegalP,
  LegalUL,
} from "../components/legal/LegalPageLayout";
import { LEGAL } from "../lib/legalCopy";

// Published Terms of Use for the iEye contribution website + account.
//
// Plain, conservative, scoped to what the site does today. The contribution
// wording is pulled from the canonical single source (lib/legalCopy) so it can't
// drift from the approved "contribution, not donation" text. The binding clauses
// (governing law, liability, jurisdiction-specific solicitation wording) remain
// Legal-gated before the site relies on them.
export function Terms() {
  return (
    <LegalPageLayout
      title="Terms of Use"
      effectiveDate="21 June 2026"
      intro={
        <>
          These terms govern your use of the iEye website and contribution account. iEye is a
          welfare project run as a public good — please read these in the same plain-spoken
          spirit as the rest of the site.
        </>
      }
    >
      <LegalH2>1. Who we are; what these terms cover</LegalH2>
      <LegalP>
        The iEye website and contribution account are operated by{" "}
        <strong>BytesBrains Pte Ltd</strong>, a private limited company registered in
        Singapore. By using this website or creating an account, you agree to these terms.
        They cover the <strong>website and account only</strong> — the iEye mobile safety app
        has its own terms and will be governed separately when it ships.
      </LegalP>

      <LegalH2>2. iEye is a public good — not a product sale, not an investment</LegalH2>
      <LegalP>
        iEye is free and open, built to outlive any single company. <strong>There is no iEye
        token, coin, or investment offer.</strong> Nothing on this site is an offer or
        solicitation to buy a security or financial product, and you should never treat it as
        one. The Maktub Protocol that iEye is built on is infrastructure, not an investment.
      </LegalP>

      <LegalH2>3. Contributions, not donations</LegalH2>
      <LegalP>{LEGAL.contributionDisclaimerShort}</LegalP>
      <LegalP>
        Contributing money is not open yet. When it is, additional contribution terms
        (including how contributions are received and recorded) will apply and will be
        presented at the point of contribution.
      </LegalP>

      <LegalH2>4. No emergency service; no guarantee</LegalH2>
      <LegalP>
        iEye is designed to detect quickly and bring help quickly, and it <strong>can</strong>{" "}
        save a life when a life can be saved. But it is <strong>not a substitute for emergency
        services</strong>, and we promise the <strong>effort</strong>, never the{" "}
        <strong>outcome</strong>. We do not guarantee that help will arrive in time in any
        given case. In an emergency, always contact your local emergency services. This
        website is provided on an &ldquo;as is&rdquo; and &ldquo;as available&rdquo; basis.
      </LegalP>

      <LegalH2>5. Your account &amp; acceptable use</LegalH2>
      <LegalUL>
        <li>Provide accurate information and keep your account secure.</li>
        <li>
          Don&rsquo;t misuse the site: no attempts to gain unauthorised access, disrupt the
          service, scrape or republish others&rsquo; data, or use it unlawfully.
        </li>
        <li>
          We may suspend or remove access for abuse, or to protect people who rely on iEye.
        </li>
        <li>You can delete your account and data at any time from your account page.</li>
      </LegalUL>

      <LegalH2>6. Building with us (contributors)</LegalH2>
      <LegalP>
        Offering your skills is a request to participate — we review contributors before
        inviting them, because this is a safety codebase. Code contributions are governed by a
        separate contributor agreement. The repository is private during beta and is intended
        to open under an MIT licence at the first public release.
      </LegalP>

      <LegalH2>7. Intellectual property &amp; open source</LegalH2>
      <LegalP>
        iEye&rsquo;s protocol and SDK are open source (MIT). The iEye name, logo, and brand
        belong to BytesBrains Pte Ltd and may not be used in a way that implies endorsement.
        Site content is provided for information about the project.
      </LegalP>

      <LegalH2>8. Privacy</LegalH2>
      <LegalP>
        How we handle your data is described in our{" "}
        <Link to="/privacy" className="font-medium text-teal-deep underline">
          Privacy Notice
        </Link>
        . By using the site you acknowledge that notice.
      </LegalP>

      <LegalH2>9. Liability</LegalH2>
      <LegalP>
        To the maximum extent permitted by law, BytesBrains is not liable for indirect or
        consequential loss arising from your use of this website, and nothing in these terms
        limits any liability that cannot be limited by law. This clause is about the{" "}
        <strong>website</strong>; it does not change the honest promise about the iEye service
        in section 4.
      </LegalP>

      <LegalH2>10. Changes</LegalH2>
      <LegalP>
        We may update these terms; we will update the effective date above, and material
        changes will be highlighted. Continued use after a change means you accept the updated
        terms.
      </LegalP>

      <LegalH2>11. Governing law &amp; contact</LegalH2>
      <LegalP>
        These terms are governed by the laws of Singapore. Questions about these terms:{" "}
        <strong>legal@ieye.in</strong>.
      </LegalP>
    </LegalPageLayout>
  );
}
