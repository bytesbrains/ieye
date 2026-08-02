// iEye web backend — Cloud Functions.
//
// Region pinned to asia-south1 (Mumbai) to sit next to the India-first user base.
//
// The payments + contribution subsystem (Stripe, the supporter-wall projection,
// contributor invitations, admin claims) was removed — iEye takes no donations.
// What remains is the single outside-in exposure teaser for /app.

import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

// Outside-in exposure teaser for /app — passive Shodan InternetDB lookup of the
// caller's own public IP (no key, no active scanning). Served at /api/exposure.
export { exposureCheck } from "./exposure";
