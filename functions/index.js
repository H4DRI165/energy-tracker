
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
      const bill = event.data.after?.data();
      if (!bill) return;

      const beforeBill = event.data.before?.data();
      if (beforeBill && beforeBill.amount === bill.amount) return;

      const userRef = admin.firestore().collection("users").doc(uid);
      const userDoc = await userRef.get();
      const user = userDoc.data();
      if (!user?.fcmToken || !user?.monthlyBudget) return;

      const alert80Enabled = user.alert80Enabled !== false;
      const alert100Enabled = user.alert100Enabled !== false;

      const usedAmount = bill.amount;
      const budgetAmount = user.monthlyBudget;
      const percentUsed = (usedAmount / budgetAmount) * 100;

      const billRef = event.data.after.ref;

      // Reserve the alert tier atomically, before sending anything.
      // This is what makes concurrent/retried invocations safe.
      const reservation = await admin.firestore().runTransaction(async (tx) => {
        const snap = await tx.get(billRef);
        if (snap.data()?.amount !== bill.amount) {
          return {shouldSend: false};
        }
        const previousTier = snap.data()?.alertTierSent || 0;

        let currentTier = 0;
        if (percentUsed >= 100) currentTier = 100;
        else if (percentUsed >= 80) currentTier = 80;

        if (currentTier === 0) {
          if (previousTier !== 0) tx.update(billRef, {alertTierSent: 0});
          return {shouldSend: false};
        }

        if (currentTier <= previousTier) {
        // Dropped back or stayed at/below a tier we've already
        // alerted for — not a new crossing, do nothing.
          return {shouldSend: false};
        }

        const crossed100 = previousTier < 100 && currentTier >= 100;
        const crossed80 = previousTier < 80 && currentTier >= 80;
        const sendTier100 = alert100Enabled && crossed100;
        const sendTier80 = alert80Enabled && crossed80 && !sendTier100;

        // Reserve immediately — before send() is ever called.
        tx.update(billRef, {alertTierSent: currentTier});

        if (!sendTier100 && !sendTier80) return {shouldSend: false};
        return {
          shouldSend: true,
          isExceeded: sendTier100,
          reservedTier: currentTier,
          previousTier,
        };
      });

      if (!reservation.shouldSend) return;

      const title = reservation.isExceeded ?
      "🚨 Budget Exceeded!" :
      "⚠️ 80% Budget Reached";
      const usedStr = usedAmount.toFixed(2);
      const budgetStr = budgetAmount.toFixed(2);
      const body =
      `You've used RM ${usedStr} of your RM ${budgetStr} ` +
      "monthly target.";

      try {
        await admin.messaging().send({
          token: user.fcmToken,
          notification: {title, body},
          data: {type: "budget_alert"},
          android: {notification: {channelId: "budget_alerts"}},
        });
      } catch (err) {
        console.error("Failed to send budget alert, releasing reservation",
            err,
        );
        // Roll back the reservation so a future write can retry — but only
        // if nothing newer has already advanced past our reservation.
        await admin.firestore().runTransaction(async (tx) => {
          const snap = await tx.get(billRef);
          if (snap.data()?.alertTierSent === reservation.reservedTier) {
            tx.update(billRef, {alertTierSent: reservation.previousTier});
          }
        });
      }
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
      `${String(now.getMonth() + 1).padStart(2, "0")}`;// e.g. "2026-07"

      const usersSnap = await admin.firestore().collection("users").get();

      const tokens = [];
      const uidByToken = new Map();

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
          uidByToken.set(user.fcmToken, doc.id);
        }
      }

      if (tokens.length === 0) return;

      const message = {
        notification: {
          title: "📅 Don't forget your meter reading!",
          body: "The month is almost over — log your reading to " +
          "keep your usage tracking accurate.",
        },
        data: {type: "reading_reminder"},
        android: {notification: {channelId: "budget_alerts"}},
      };

      // sendEachForMulticast rejects payloads over 500 tokens —
      // split into chunks and send each batch separately.
      const BATCH_SIZE = 500;
      const batches = [];
      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        batches.push(tokens.slice(i, i + BATCH_SIZE));
      }

      const batchResults = await Promise.all(
          batches.map((batchTokens) =>
            admin.messaging().sendEachForMulticast({
              tokens: batchTokens,
              ...message,
            }).then((result) => ({result, batchTokens})),
          ),
      );

      let totalSuccess = 0;
      let totalFailure = 0;
      const staleUids = [];

      for (const {result, batchTokens} of batchResults) {
        totalSuccess += result.successCount;
        totalFailure += result.failureCount;

        result.responses.forEach((res, i) => {
          if (
            !res.success &&
          (res.error?.code === "messaging/registration-token-not-registered" ||
            res.error?.code === "messaging/invalid-registration-token")
          ) {
            const uid = uidByToken.get(batchTokens[i]);
            if (uid) staleUids.push(uid);
          }
        });
      }

      console.log(
          `Monthly reminder sent: ${totalSuccess} succeeded, ` +
      `${totalFailure} failed, ${staleUids.length} stale tokens found.`,
      );

      const CLEANUP_BATCH_SIZE = 500;
      const cleanupChunks = [];
      for (let i = 0; i < staleUids.length; i += CLEANUP_BATCH_SIZE) {
        cleanupChunks.push(staleUids.slice(i, i + CLEANUP_BATCH_SIZE));
      }

      for (const chunk of cleanupChunks) {
        const cleanupBatch = admin.firestore().batch();
        chunk.forEach((uid) => {
          cleanupBatch.update(
              admin.firestore().collection("users").doc(uid),
              {fcmToken: admin.firestore.FieldValue.delete()},
          );
        });
        await cleanupBatch.commit();
      }
    },
);

// ---------------------------------------------------------------------------
// Tariff data: monthly AFA sync
//
// TNB publishes declared AFA values in the tariff microsite's translation
// bundle (`afaGraph.data`). The schedule itself (base rates, EEI bands and
// protection periods) is seeded from assets/tariff/domestic_general.json via
// `npm run seed:tariff`.
// ---------------------------------------------------------------------------

const AFA_MONTHS = {
  JAN: 1, FEB: 2, MAR: 3, MAC: 3, APR: 4, MAY: 5, MEI: 5, JUN: 6,
  JUL: 7, AUG: 8, OGO: 8, SEP: 9, OCT: 10, OKT: 10, NOV: 11, DEC: 12,
  DIS: 12,
};

exports.syncAfaRates = onSchedule(
    {
      // TNB usually publishes the month's rate around the 1st.
      schedule: "0 9 2 * *",
      timeZone: "Asia/Kuala_Lumpur",
      retryCount: 3,
    },
    async () => {
      const response = await fetch("https://www.mytnb.com.my/tariff/EN.json", {
        headers: {"user-agent": "energy-tracker/1.0"},
      });
      if (!response.ok) {
        throw new Error(`TNB tariff fetch failed: HTTP ${response.status}`);
      }

      const payload = await response.json();
      const rows = payload?.afaGraph?.data;
      if (!Array.isArray(rows) || rows.length === 0) {
        throw new Error("TNB tariff payload has no afaGraph.data rows");
      }

      const updates = {};
      for (const row of rows) {
        const month = AFA_MONTHS[String(row.month).toUpperCase()];
        const value = Number(row.value);
        if (!month || !Number.isFinite(value) || Math.abs(value) > 20) {
          continue;
        }
        const key = `${row.year}-${String(month).padStart(2, "0")}`;
        updates[key] = {
          senPerKwh: value,
          status: "final",
        };
      }

      if (Object.keys(updates).length === 0) {
        throw new Error("No valid AFA rows parsed");
      }

      const ref = admin.firestore().doc("tariffs/domestic_general");
      const snapshot = await ref.get();
      if (!snapshot.exists) {
        throw new Error(
            "tariffs/domestic_general is not seeded; run npm run seed:tariff",
        );
      }
      const existing = snapshot.data()?.afaByMonth || {};

      await ref.set(
          {
            afaByMonth: {...existing, ...updates},
            source: "https://www.mytnb.com.my/tariff/EN.json",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
      );

      console.log(
          `Synced ${Object.keys(updates).length} AFA months`,
      );
    },
);
