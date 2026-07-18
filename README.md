# Energy Tracker

A Flutter mobile app for Malaysian TNB (Tenaga Nasional Berhad) customers to track electricity usage, estimate bills, and manage monthly energy budgets. Supports both residential (Tariff A) and commercial LV (Tariff B) accounts.

---

## 📦 Live APK (Download & Test)

Latest build is automatically generated via GitHub Actions:

👉 View latest release: https://github.com/H4DRI165/energy-tracker/releases/latest

Built for portfolio demonstration — install and test without any setup required.

---

## 🚀 Features

- **Dashboard** — Bill estimates, EEI band indicator, budget progress, and usage chart
- **Meter Reading Logs** — Manual entry with auto-calculated kWh and cost tracking
- **Tariff Calculator** — Live bill breakdown for domestic and commercial LV tariffs
- **Usage Analytics** — Monthly/yearly charts and history tracking
- **Onboarding** — Tariff type selection and budget setup
- **Push Notifications** — Budget threshold alerts (80% / 100%) and end-of-month meter reading reminders, with per-user toggle controls
- **Crash Reporting** — Automatic crash and error capture across the app via Firebase Crashlytics

---

## 🧰 Tech Stack

| Layer | Technology |
|------|------------|
| Framework | Flutter |
| State Management | Riverpod |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Backend Logic | Cloud Functions (Node.js) |
| Push Notifications | Firebase Cloud Messaging, flutter_local_notifications |
| Analytics | Firebase Analytics |
| Crash Reporting | Firebase Crashlytics |
| App Integrity | Firebase App Check |
| Storage | Firebase Storage |

---

## 🔔 Push Notifications

Notifications are driven by Cloud Functions reacting to Firestore writes and a scheduled job, rather than sent client-side — so alerts reach a device even if the app isn't open.

### Budget alerts (80% / 100%)
- A Firestore trigger fires whenever a monthly bill document is written (created, edited, or affected by a reading deletion)
- Alert state is reserved **atomically inside a Firestore transaction before sending**, so concurrent or retried function invocations can't deliver duplicate notifications
- Alert tier (0 / 80 / 100) is tracked per bill document, not per user — editing a past month's bill can never reset or duplicate the current month's alert state
- If delivery to FCM fails after the tier is reserved, the reservation is safely rolled back so a later update can retry
- Each user can independently toggle 80%/100% alerts on or off from the dashboard

### End-of-month reading reminder
- A scheduled Cloud Function runs monthly, checking which users haven't yet logged a meter reading for the current month
- Sends are batched to respect FCM's 500-token-per-call limit
- Dead tokens (uninstalled app, cleared data) are detected from the delivery response and automatically cleaned up from Firestore

### On-device handling
- Foreground messages are rendered via `flutter_local_notifications` on a dedicated high-importance Android channel
- Background and terminated-state notification taps are routed to the correct screen (dashboard or add-reading) via `onMessageOpenedApp` and `getInitialMessage()`
- FCM tokens are attached on login and detached on logout/account switch, so a shared device never delivers one account's alerts to another
- A dedicated white silhouette icon is used for the Android status bar/notification tray, separate from the full-color app launcher icon, per Android's notification icon guidelines

---

## 🩺 Reliability & Observability

- **Firebase Crashlytics** captures both fatal Flutter errors (`FlutterError.onError`) and uncaught platform-level errors (`PlatformDispatcher.instance.onError`), with crash collection disabled in debug builds
- **Firebase App Check** (Play Integrity in release, debug provider in development) helps guard backend resources against abuse
- All Cloud Functions are code-reviewed via automated PR review (CodeRabbit) covering correctness, idempotency, and Firestore write-limit edge cases before merge

---

## 🧾 TNB Tariff Implementation

### Domestic — Tariff A (post-1 July 2025)

Validated against multiple real TNB e-bill samples across different usage ranges.

| Component | Rate | Condition |
|----------|------|----------|
| Energy | 27.03 sen/kWh | ≤ 1500 kWh |
| Energy | 37.03 sen/kWh | > 1500 kWh |
| Capacity | 4.55 sen/kWh | Always |
| Network | 12.85 sen/kWh | Always |
| Retail | RM 10/month | > 600 kWh |
| EEI Rebate | 0.25–25.0 sen/kWh | ≤ 1000 kWh |
| KWTBB | 1.6% of Energy + Cap + Net − EEI | > 300 kWh |
| SST | 8% on net charge above 600 kWh | > 600 kWh |

---

### Commercial LV — Non-Domestic General (post-1 July 2025)

Validated against multiple real TNB e-bill samples.

| Component | Rate | Condition |
|----------|------|----------|
| Energy | 27.03 sen/kWh | Flat |
| Capacity | 8.83 sen/kWh | Always |
| Network | 14.82 sen/kWh | Always |
| Retail | RM 20/month | Always |
| EEI Rebate | 11.0 sen/kWh | ≤ 200 kWh |
| KWTBB | 1.6% of Energy + Cap + Net − EEI | Always |
| SST | Not applicable | — |

---

> AFA (Automatic Fuel Adjustment) is excluded from estimates by default as it is updated monthly by TNB.

---

## 📊 Data Integrity

- Meter readings store tariff type at creation time to preserve historical accuracy
- Conflict protection prevents mixed-tariff readings within the same billing cycle
- Chain-recompute logic ensures correct kWh deltas after edits or deletions
- Firestore batch writes ensure atomic updates between readings and bills

---

## 📦 CI/CD Pipeline

- GitHub Actions automatically builds APK on every push to `main`
- Release APK is published under GitHub Releases
- No manual build required

---

## 🛠️ Getting Started (Dev)

```bash
flutter pub get
flutter run
```