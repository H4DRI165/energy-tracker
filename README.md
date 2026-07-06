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

---

## 🧰 Tech Stack

| Layer | Technology |
|------|------------|
| Framework | Flutter |
| State Management | Riverpod |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Analytics | Firebase Analytics |
| Crash Reporting | Firebase Crashlytics |
| Storage | Firebase Storage |

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