# ⚡  Energy Tracker

A Flutter mobile app for tracking TNB (Tenaga Nasional Berhad) electricity usage, estimating bills, and managing monthly energy budgets.

## Features

- **Dashboard** — Real-time bill estimates, budget progress, and 7-day usage chart
- **Budget Alerts** — Push notifications at 80% and 100% of monthly target
- **Meter Reading Logs** — Manual entry with auto-calculated kWh and estimated cost
- **Bill Scanner** — OCR via ML Kit to scan TNB bills and auto-populate data
- **Appliance Tracker** — Per-device kWh and RM cost breakdown
- **Tariff Calculator** — Live TNB domestic tiered tariff breakdown (Tier 1–3)
- **Usage Analytics** — Monthly/yearly charts and bill history
- **Onboarding** — Tariff type selection and monthly budget setup

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State Management | Riverpod |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| OCR | Google ML Kit |
| Notifications | Firebase Cloud Messaging (FCM) |

## TNB Domestic Tariff (Tariff A)

| Tier | Range | Rate |
|---|---|---|
| Tier 1 | 1 – 200 kWh | 21.8 sen/kWh |
| Tier 2 | 201 – 300 kWh | 33.4 sen/kWh |
| Tier 3 | 301 – 600 kWh | 51.6 sen/kWh |

## Getting Started

```bash
flutter pub get
flutter run
```

> Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase console before running.

## Project Status

MVP UI complete — see `/mockup/energy-tracker-mockup.html` for full screen designs.