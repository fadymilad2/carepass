const { requireAdmin } = require('./access');
const { onCall, HttpsError } = require("firebase-functions/v2/https");

const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

// ── Send Push Notification ─────────────────────────────────────────────
exports.sendPushNotification = onCall(
  { enforceAppCheck: false },
  async (request) => {
    await requireAdmin(request);
    const { tokens, topic, title, body, data } = request.data || {};

    if (topic) {
      console.log(`Sending push to topic: ${topic}`);
      try {
        await getMessaging().send({
          topic,
          notification: { title, body },
          data: data || {},
          android: {
            priority: "high",
            notification: {
              channelId: "carepass_notifications",
              sound: "default",
              priority: "high",
              visibility: "public",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        });
        console.log(`Topic "${topic}" send: success`);
        return { sent: -1 };
      } catch (e) {
        console.error("Topic send error:", e);
        return { sent: 0, error: e.message };
      }
    }

    if (!tokens || tokens.length === 0) {
      console.log("No tokens provided");
      return { sent: 0 };
    }

    console.log(`Sending push to ${tokens.length} tokens`);

    const batchSize = 500;
    let sent = 0;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      const message = {
        notification: { title, body },
        data: data || {},
        tokens: batch,
        android: {
          priority: "high",
          notification: {
            channelId: "carepass_notifications",
            sound: "default",
            priority: "high",
            visibility: "public",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };

      try {
        const response = await getMessaging().sendEachForMulticast(message);
        sent += response.successCount;
        console.log(
          `Batch ${Math.floor(i / batchSize) + 1}: ` +
          `${response.successCount} success, ` +
          `${response.failureCount} failed`
        );
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Token ${idx} failed:`, resp.error?.message);
          }
        });
      } catch (e) {
        console.error("FCM batch error:", e);
      }
    }

    return { sent };
  }
);

// ── Trigger Expiry Reminders ───────────────────────────────────────────
exports.triggerExpiryRemindersManually = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const db = getFirestore();

    const adminDoc = await db
      .collection("admin_users")
      .doc(auth.uid)
      .get();

    if (!adminDoc.exists || !adminDoc.data().isActive) {
      throw new HttpsError("permission-denied", "Not an active admin");
    }

    try {
      const now = new Date();
      const dateOnly = (d) => d.toISOString().split("T")[0];

      const in7 = dateOnly(new Date(now.getTime() + 7 * 86400000));
      const in3 = dateOnly(new Date(now.getTime() + 3 * 86400000));
      const in1 = dateOnly(new Date(now.getTime() + 1 * 86400000));

      const messages = {
        [in7]: {
          days: 7,
          msg: "Your CarePass subscription expires in 7 days. Renew now!",
        },
        [in3]: {
          days: 3,
          msg: "Only 3 days left on your CarePass subscription!",
        },
        [in1]: {
          days: 1,
          msg: "⚠️ Your CarePass subscription expires tomorrow! Renew now.",
        },
      };

      const snap = await db
        .collection("users")
        .where("subscriptionStatus", "==", "active")
        .get();

      let totalSent = 0;
      let remindersChecked = 0;
      let expiredMarked = 0;
      let batch = db.batch();
      let batchWrites = 0;

      for (const doc of snap.docs) {
        const user = doc.data();
        const uid = doc.id;
        const expiryStr = user.cardExpiryDate;

        if (!expiryStr) continue;

        let expiry;
        try {
          expiry = new Date(expiryStr);
          if (isNaN(expiry.getTime())) continue;
        } catch (_) {
          continue;
        }

        if (expiry.getTime() < now.getTime()) {
          batch.update(doc.ref, { subscriptionStatus: "expired" });
          expiredMarked++;
          batchWrites++;
          if (batchWrites === 400) {
            await batch.commit();
            batch = db.batch();
            batchWrites = 0;
          }
          continue;
        }

        const reminder = messages[dateOnly(expiry)];
        if (!reminder) continue;

        remindersChecked++;

        await db
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .add({
            title: "Subscription Expiring Soon",
            body: reminder.msg,
            type: "subscription_expiry",
            daysLeft: reminder.days,
            isRead: false,
            createdAt: new Date().toISOString(),
          });

        if (user.fcmToken) {
          try {
            await getMessaging().send({
              token: user.fcmToken,
              notification: { title: "CarePass", body: reminder.msg },
              data: {
                type: "subscription_expiry",
                screen: "/payment",
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "carepass_notifications",
                  sound: "default",
                },
              },
            });
            totalSent++;
          } catch (e) {
            console.error(`FCM error for ${uid}:`, e.message);
          }
        }
      }

      if (batchWrites > 0) await batch.commit();

      return {
        success: true,
        remindersSent: totalSent,
        remindersChecked,
        expiredMarked,
      };
    } catch (error) {
      console.error("triggerExpiryRemindersManually error:", error);
      throw new HttpsError(
        "internal",
        error.message || "Failed to process reminders"
      );
    }
  }
);

