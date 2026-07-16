
// budget alerts
const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const functions = require("firebase-functions/v2/firestore");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

exports.checkBudgetOnBillUpdate = functions.onDocumentWritten(
    "users/{uid}/bills/{billId}",
    async (event) => {
      const uid = event.params.uid;
      const billId = event.params.billId; // e.g. "2026-07"
      const bill = event.data.after?.data();
      if (!bill) return; // doc deleted entirely, nothing to check

      const userRef = admin.firestore().collection("users").doc(uid);
      const userDoc = await userRef.get();
      const user = userDoc.data();
      if (!user?.fcmToken || !user?.monthlyBudget) return;

      const alert80Enabled = user.alert80Enabled !== false; // default true
      const alert100Enabled = user.alert100Enabled !== false; // default true

      const usedAmount = bill.amount;
      const budgetAmount = user.monthlyBudget;
      const percentUsed = (usedAmount / budgetAmount) * 100;

      // Reset flags if this is a new month vs last time we alerted
      const lastAlertedMonth = user.lastAlertedMonth;
      let alert80Sent = user.alert80Sent || false;
      let alert100Sent = user.alert100Sent || false;
      if (lastAlertedMonth !== billId) {
        alert80Sent = false;
        alert100Sent = false;
      }

      // If usage dropped back below a threshold (edit/delete),
      // un-flag it so a future re-crossing fires again
      const updates = {lastAlertedMonth: billId};
      if (percentUsed < 80 && alert80Sent) {
        alert80Sent = false;
        updates.alert80Sent = false;
      }
      if (percentUsed < 100 && alert100Sent) {
        alert100Sent = false;
        updates.alert100Sent = false;
      }

      const shouldAlert100 =
      alert100Enabled && percentUsed >= 100 && !alert100Sent;
      const shouldAlert80 =
      alert80Enabled &&
      percentUsed >= 80 &&
      percentUsed < 100 &&
      !alert80Sent;

      if (shouldAlert100 || shouldAlert80) {
        const title = shouldAlert100 ?
        "🚨 Budget Exceeded!" :
        "⚠️ 80% Budget Reached";
        const usedStr = usedAmount.toFixed(2);
        const budgetStr = budgetAmount.toFixed(2);
        const body =
        `You've used RM ${usedStr} of your RM ${budgetStr} ` +
        "monthly target.";

        await admin.messaging().send({
          token: user.fcmToken,
          notification: {title, body},
          data: {type: "budget_alert"},
          android: {notification: {channelId: "budget_alerts"}},
        });

        if (shouldAlert100) updates.alert100Sent = true;
        if (shouldAlert80) updates.alert80Sent = true;
      }

      await userRef.update(updates);
    },
);


// end of month reminder
exports.sendMonthlyReadingReminder = onSchedule(
    {
      schedule: "0 9 28 * *", // 9:00 AM on the 28th, every month
      timeZone: "Asia/Kuala_Lumpur",
    },
    async () => {
      const now = new Date();
      const currentMonthId =
      `${now.getFullYear()}-` +
      `${String(now.getMonth() + 1).padStart(2, "0")}`;
      // e.g. "2026-07"

      const usersSnap = await admin.firestore().collection("users").get();

      const tokens = [];
      for (const doc of usersSnap.docs) {
        const user = doc.data();
        if (!user.fcmToken) continue;

        // Skip if this user already has a bill/reading for this month
        const billDoc = await admin
            .firestore()
            .collection("users")
            .doc(doc.id)
            .collection("bills")
            .doc(currentMonthId)
            .get();

        if (!billDoc.exists) {
          tokens.push(user.fcmToken);
        }
      }

      if (tokens.length === 0) return;

      // sendEachForMulticast handles up to 500 tokens per call
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "📅 Don't forget your meter reading!",
          body: "The month is almost over — log your reading to " +
          "keep your usage tracking accurate.",
        },
        data: {type: "reading_reminder"},
        android: {notification: {channelId: "budget_alerts"}},
      });
    },
);
