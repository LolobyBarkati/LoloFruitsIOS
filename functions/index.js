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

// ── iOS: Apple App Store Server Notifications (ASSN) webhook ──────────────
exports.appleSubscriptionWebhook = onRequest(async (req, res) => {

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {

    const { signedPayload } = req.body;
    if (!signedPayload) return res.status(400).send("Missing signedPayload");

    // Apple sends a 3-part JWS. Decode the payload section (index 1).
    const parts = signedPayload.split(".");
    if (parts.length !== 3) return res.status(400).send("Invalid JWS");

    const payload = JSON.parse(
      Buffer.from(parts[1], "base64url").toString("utf8")
    );

    const { notificationType, subtype, data } = payload;
    console.log("Apple ASSN event:", notificationType, subtype ?? "");

    // Only handle renewal and new subscription events
    if (!["DID_RENEW", "SUBSCRIBED"].includes(notificationType)) {
      console.log("Ignored:", notificationType);
      return res.status(200).send("Ignored");
    }

    // signedTransactionInfo is also a JWS — decode it the same way
    const signedTx = data?.signedTransactionInfo;
    if (!signedTx) return res.status(400).send("Missing signedTransactionInfo");

    const txParts = signedTx.split(".");
    const txPayload = JSON.parse(
      Buffer.from(txParts[1], "base64url").toString("utf8")
    );

    const { originalTransactionId, productId, expiresDate } = txPayload;

    if (!originalTransactionId) {
      return res.status(400).send("Missing originalTransactionId");
    }

    const db = admin.firestore();

    // Find the user by originalTransactionId saved at first purchase from Flutter
    const paymentQuery = await db
      .collection("payments")
      .where("originalTransactionId", "==", originalTransactionId)
      .orderBy("timestamp", "desc")
      .limit(1)
      .get();

    if (paymentQuery.empty) {
      console.log("No payment found for originalTransactionId:", originalTransactionId);
      return res.status(200).send("Not found");
    }

    const paymentData = paymentQuery.docs[0].data();
    const now = new Date();

    // Apple sends expiresDate as milliseconds epoch
    const newExpiry = expiresDate
      ? new Date(expiresDate)
      : new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

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

    console.log("Apple renewal saved for user:", paymentData.userId);
    return res.status(200).send("OK");

  } catch (error) {
    console.error("Apple webhook error:", error);
    return res.status(500).send("Error");
  }

});