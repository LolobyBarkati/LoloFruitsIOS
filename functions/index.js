const { onMessagePublished } = require("firebase-functions/v2/pubsub");
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