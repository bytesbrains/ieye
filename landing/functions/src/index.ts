// iEye web backend — non-money Cloud Functions.
//
// Region pinned to asia-south1 (Mumbai) to sit next to Firestore and the
// India-first user base. None of these functions touch money: the contributions
// ledger and payment webhooks are a later, Legal-gated phase (#39).

import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

export { grantAdmin, revokeAdmin } from "./adminClaims";
export { onUserWritten } from "./publicSupporters";
export { onContributorRequestInvited } from "./invitations";
