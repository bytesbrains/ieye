// iEye web backend — Cloud Functions.
//
// Region pinned to asia-south1 (Mumbai) to sit next to Firestore and the
// India-first user base.
//
// The fiat money path (./stripe) is included but stays DARK by default: it is
// gated by the FIAT_CONTRIB_ENABLED param (default "false") and unset Stripe
// secrets, so deploying it does not turn money on — flipping it live is a
// deliberate act once Legal (#39) clears. Everything else is non-money.

import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

export { grantAdmin, revokeAdmin } from "./adminClaims";
export { onUserWritten } from "./publicSupporters";
export { onContributorRequestInvited } from "./invitations";
export { createContributionCheckout, stripeWebhook } from "./stripe";
// Outside-in exposure teaser for /app — passive Shodan InternetDB lookup of the
// caller's own public IP (no key, no active scanning). Served at /api/exposure.
export { exposureCheck } from "./exposure";
