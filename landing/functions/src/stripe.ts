// Fiat contributions — Stripe Checkout + webhook → ledger (#36/#54).
//
// THIS IS THE FIRST MONEY PATH. It stays DARK by default and behind a hard gate
// (#39): the FIAT_CONTRIB_ENABLED param defaults to "false", and the Stripe
// secrets are unset until Legal clears and a BytesBrains-SG Stripe account
// exists. Nothing here can move money until all three are deliberately turned on.
//
// Design (mirrors the rest of this backend — Admin SDK bypasses rules, so the
// ledger integrity lives here, not in the client):
//   - createContributionCheckout (callable): signed-in user picks an amount; we
//     create a Stripe-hosted Checkout Session server-side (the client never sees
//     a secret key, never sets the price arbitrarily) and return its URL.
//   - stripeWebhook (HTTP): Stripe calls us when a payment completes. We VERIFY
//     the signature, then write ONE idempotent `contributions` doc keyed by the
//     Stripe event id, so a redelivered webhook can never double-count.
//
// Honest-money guardrails (#38): currency is SGD (BytesBrains is a SG entity);
// the product description says "contribution… not a tax-deductible donation";
// publicity is NEVER set from the client (consent drives the supporter wall via
// onUserWritten, name-only).

import { onCall, onRequest, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";
import { db } from "./firebaseAdmin";

// Secrets live in Secret Manager, never in code or .env (gitleaks gate + #43).
// Bound only to the functions that need them; until set, the path stays dark.
const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

// The master gate. Default "false" — fiat NEVER goes live implicitly. Flip to
// "true" only once #39 (CA view + FCRA confirmation + MAS n/a for fiat) clears
// and a BytesBrains-SG Stripe account is connected.
const FIAT_CONTRIB_ENABLED = defineString("FIAT_CONTRIB_ENABLED", { default: "false" });

// Deployed site origin, for Checkout success/cancel redirects.
const SITE_ORIGIN = defineString("SITE_ORIGIN", { default: "https://ieye.in" });

const CURRENCY = "sgd"; // BytesBrains Pte Ltd is a Singapore entity (#38).
const MIN_MINOR = 100; //   S$1.00  — floor (Stripe min + keeps fees sane)
const MAX_MINOR = 1_000_000; // S$10,000.00 — ceiling; large inflows want the
//                              source-of-funds / AML attention of #38 §5 first.

interface CheckoutInput {
  amountMinor?: number;
}

/**
 * Create a Stripe Checkout Session for a contribution. Signed-in only (ties the
 * contribution to an account + the opt-in-to-be-named consent model). The amount
 * is validated server-side so a tampered client can't set 0/negative/huge values.
 */
export const createContributionCheckout = onCall(
  { secrets: [STRIPE_SECRET_KEY] },
  async (req: CallableRequest<CheckoutInput>) => {
    if (FIAT_CONTRIB_ENABLED.value() !== "true") {
      // Gate closed — this is the normal state until #39 clears.
      throw new HttpsError("failed-precondition", "Contributions aren't open yet.");
    }
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Please sign in to contribute.");
    }

    const amountMinor = req.data?.amountMinor;
    if (
      typeof amountMinor !== "number" ||
      !Number.isInteger(amountMinor) ||
      amountMinor < MIN_MINOR ||
      amountMinor > MAX_MINOR
    ) {
      throw new HttpsError("invalid-argument", "Choose a valid contribution amount.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const origin = SITE_ORIGIN.value();

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: CURRENCY,
            unit_amount: amountMinor,
            product_data: {
              name: "Contribution to iEye",
              description:
                "Voluntary contribution to support the iEye project (BytesBrains Pte Ltd, " +
                "Singapore). Not a charity / not a tax-deductible donation.",
            },
          },
        },
      ],
      // Tie the eventual webhook back to the account (and the consent model).
      client_reference_id: req.auth.uid,
      metadata: { uid: req.auth.uid, kind: "money" },
      success_url: `${origin}/account?contribution=thanks`,
      cancel_url: `${origin}/?contribution=cancelled#contribute`,
    });

    if (!session.url) {
      // Stripe should always return a hosted URL for mode:"payment"; treat a
      // missing one as a server error rather than handing the client a null.
      logger.error("checkout session has no URL", { uid: req.auth.uid, sessionId: session.id });
      throw new HttpsError("internal", "Couldn’t start checkout. Please try again.");
    }

    logger.info("checkout session created", { uid: req.auth.uid, amountMinor });
    return { url: session.url };
  }
);

/**
 * Idempotent ledger write. Doc id is derived from the Stripe EVENT id, so a
 * webhook redelivery (Stripe retries) creates the same id and the create()
 * fails-as-no-op instead of double-counting. Clients never write this collection
 * (firestore.rules); only this Admin SDK path does.
 */
async function recordContribution(
  eventId: string,
  session: Stripe.Checkout.Session
): Promise<void> {
  const ref = db.collection("contributions").doc(`stripe_${eventId}`);
  const uid = session.client_reference_id ?? session.metadata?.uid ?? null;

  const data = {
    ownerUid: uid,
    kind: "money",
    method: "card",
    // Fiat is stored in MINOR units as a string (no floats in money, ever).
    amountMinor: String(session.amount_total ?? 0),
    currency: (session.currency ?? CURRENCY).toUpperCase(),
    provider: "stripe",
    providerSessionId: session.id,
    // Publicity is decided by the contributor's consent, never by this write.
    isPublic: false,
    status: session.payment_status === "paid" ? "paid" : (session.payment_status ?? "pending"),
    // TODO(#38 §5 / #54): AML/sanctions screening before this inflow is treated
    // as spendable. Record now; gate "spendable" on screening in a follow-up.
    timestamp: FieldValue.serverTimestamp(),
  };

  try {
    await ref.create(data);
    logger.info("contribution recorded", { eventId, uid, amountMinor: data.amountMinor });
  } catch (err) {
    // Firestore ALREADY_EXISTS (gRPC code 6) == redelivery of an event we already
    // recorded. That's the idempotency win — swallow it. Anything else is a real
    // failure: rethrow so the webhook 500s and Stripe retries.
    if ((err as { code?: number }).code === 6) {
      logger.info("contribution already recorded — idempotent skip", { eventId });
      return;
    }
    throw err;
  }
}

/**
 * Stripe webhook. MUST verify the signature against the raw body before trusting
 * anything (an unverified POST is just an internet stranger). Records completed
 * checkouts to the ledger. Does NOT check FIAT_CONTRIB_ENABLED: if a real payment
 * completed, we record it regardless — the flag gates *starting* a payment, not
 * acknowledging one that already happened.
 */
export const stripeWebhook = onRequest(
  { secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET] },
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    if (!sig) {
      res.status(400).send("Missing stripe-signature header");
      return;
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    let event: Stripe.Event;
    try {
      // req.rawBody is the unparsed body Firebase preserves — required because
      // signature verification is over the exact bytes Stripe signed.
      event = stripe.webhooks.constructEvent(req.rawBody, sig, STRIPE_WEBHOOK_SECRET.value());
    } catch (err) {
      logger.warn("stripe webhook signature verification failed", { err: String(err) });
      res.status(400).send("Invalid signature");
      return;
    }

    try {
      if (event.type === "checkout.session.completed") {
        await recordContribution(event.id, event.data.object as Stripe.Checkout.Session);
      }
      // Verified but unhandled types are intentionally ignored (200 so Stripe
      // stops retrying them).
      res.status(200).send("ok");
    } catch (err) {
      logger.error("stripe webhook handler failed", { eventId: event.id, err: String(err) });
      res.status(500).send("handler error"); // Stripe will retry.
    }
  }
);
