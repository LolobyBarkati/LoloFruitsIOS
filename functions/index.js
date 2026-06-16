const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.playBillingWebhook = onMessagePublished(
  "play-subscription-events",
  async (event) => {

    try {

      const message = event.data.message;

      const decoded = Buffer.from(message.data, "base64").toString();
      const data = JSON.parse(decoded);

      const subscription = data.subscriptionNotification;

      if (!subscription) {
        return;
      }

      const notificationType = subscription.notificationType;

      // ⭐ Only process renewals
      if (notificationType !== 2) {
        console.log("Skipping non-renewal event");
        return;
      }

      const purchaseToken = subscription.purchaseToken;

      const db = admin.firestore();

      const paymentQuery = await db
        .collection("payments")
        .where("purchaseToken", "==", purchaseToken)
        .orderBy("timestamp","desc")
        .limit(1)
        .get();

      if (paymentQuery.empty) return;

      const paymentData = paymentQuery.docs[0].data();

      const now = new Date();

      let lastExpiry = paymentData.subscription_expiry.toDate();

      if (lastExpiry < now) lastExpiry = now;

      let newExpiry;

      if (paymentData.plan === "yearly") {
        newExpiry = new Date(lastExpiry.getTime() + 365*24*60*60*1000);
      } else {
        newExpiry = new Date(lastExpiry.getTime() + 30*24*60*60*1000);
      }

      await db.collection("payments").add({

        userId: paymentData.userId,
        email: paymentData.email,

        paymentId: "RTDN_RENEWAL",
        productId: paymentData.productId,

        purchaseToken: purchaseToken,

        plan: paymentData.plan,

        status: true,

        subscription_date: now,
        subscription_expiry: newExpiry,

        timestamp: admin.firestore.FieldValue.serverTimestamp(),

        source: "google_rtdn"

      });

      console.log("Renewal saved");

    } catch (error) {

      console.error(error);

    }

  }
);

// ── iOS: Apple App Store Server Notifications (ASSN v2) webhook ──────────────
// Flow: User buys → Apple StoreKit → Apple calls this endpoint → update Firestore → Flutter reads → premium unlocked

const APPLE_BUNDLE_ID = "com.lolo.barkati";

function decodeAppleJWS(token) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWS format");
  return JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
}

exports.appleSubscriptionWebhook = onRequest(async (req, res) => {

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {

    const { signedPayload } = req.body;
    if (!signedPayload) return res.status(400).send("Missing signedPayload");

    // Decode the outer JWS envelope
    const payload = decodeAppleJWS(signedPayload);
    const { notificationType, subtype, data } = payload;

    // Validate this notification belongs to our app
    if (data?.bundleId !== APPLE_BUNDLE_ID) {
      console.warn("Bundle ID mismatch:", data?.bundleId);
      return res.status(400).send("Invalid bundle");
    }

    const env = data?.environment ?? "Unknown";
    console.log(`Apple ASSN [${env}]: ${notificationType}${subtype ? " / " + subtype : ""}`);

    // Decode the inner JWS (transaction info)
    const signedTx = data?.signedTransactionInfo;
    if (!signedTx) return res.status(400).send("Missing signedTransactionInfo");

    const tx = decodeAppleJWS(signedTx);
    const { originalTransactionId, productId, expiresDate } = tx;

    if (!originalTransactionId) {
      return res.status(400).send("Missing originalTransactionId");
    }

    const db = admin.firestore();

    // Find the user's payment record by originalTransactionId (saved at first purchase)
    const paymentQuery = await db
      .collection("payments")
      .where("originalTransactionId", "==", originalTransactionId)
      .orderBy("timestamp", "desc")
      .limit(1)
      .get();

    if (paymentQuery.empty) {
      console.warn("No payment found for originalTransactionId:", originalTransactionId);
      return res.status(200).send("Not found");
    }

    const paymentData = paymentQuery.docs[0].data();
    const now = new Date();

    // ── Events that deactivate the subscription ──────────────────────────────
    // EXPIRED              → billing period ended, no renewal
    // REVOKE               → family sharing revoked or other revocation
    // REFUND               → Apple issued a refund
    // GRACE_PERIOD_EXPIRED → billing retry failed after grace period
    // Note: DID_FAIL_TO_RENEW keeps sub alive during the grace period — do not deactivate
    const deactivateEvents = ["EXPIRED", "REVOKE", "REFUND", "GRACE_PERIOD_EXPIRED"];

    if (deactivateEvents.includes(notificationType)) {
      await db.collection("payments").add({
        userId: paymentData.userId,
        email: paymentData.email,
        paymentId: `ASSN_${notificationType}`,
        productId: productId || paymentData.productId,
        originalTransactionId: originalTransactionId,
        plan: paymentData.plan,
        status: false,
        subscription_date: now,
        subscription_expiry: now,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        source: "apple_assn",
      });
      console.log(`Subscription deactivated [${notificationType}] for user:`, paymentData.userId);
      return res.status(200).send("OK");
    }

    // ── Events that activate or renew the subscription ───────────────────────
    // DID_RENEW   → successful auto-renewal
    // SUBSCRIBED  → new subscription or re-subscribe after expiry
    // DID_RECOVER → billing recovered after a grace period failure
    const activateEvents = ["DID_RENEW", "SUBSCRIBED", "DID_RECOVER"];

    if (!activateEvents.includes(notificationType)) {
      console.log("Ignored event type:", notificationType);
      return res.status(200).send("Ignored");
    }

    // Apple sends expiresDate as milliseconds epoch
    const newExpiry = expiresDate
      ? new Date(expiresDate)
      : new Date(now.getTime() + (paymentData.plan === "yearly" ? 365 : 30) * 24 * 60 * 60 * 1000);

    await db.collection("payments").add({
      userId: paymentData.userId,
      email: paymentData.email,
      paymentId: `ASSN_${notificationType}`,
      productId: productId || paymentData.productId,
      originalTransactionId: originalTransactionId,
      plan: paymentData.plan,
      status: true,
      subscription_date: now,
      subscription_expiry: newExpiry,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      source: "apple_assn",
    });

    console.log(`Apple ${notificationType} saved. Expires: ${newExpiry.toISOString()} User: ${paymentData.userId}`);
    return res.status(200).send("OK");

  } catch (error) {
    console.error("Apple webhook error:", error);
    return res.status(500).send("Error");
  }

});