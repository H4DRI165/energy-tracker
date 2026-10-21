# Energy Tracker

A Flutter app for Malaysian domestic TNB customers. Log meter readings, see where your usage is heading, estimate the bill using the current domestic tariff, and keep spending inside a monthly budget.

> Detailed product, architecture, billing, data, and development documentation lives in [`docs/`](docs/README.md).

## Features

- **Meter readings** — manual readings with automatic kWh deltas and chain-safe edit/delete.
- **Dashboard** — month-to-date usage, projected bill, budget progress and a 7-day chart.
- **Bill detail** — itemised TNB-style charges with plain-language explanations and reading details.
- **Usage** — monthly usage trend, budget pace and recent bill history.
- **Appliances** — estimated running costs, biggest consumers and category breakdowns.
- **Tariff calculator** — itemised estimate for any monthly kWh value.
- **Budget alerts** — optional 80% / 100% push notifications.
- **Google and email sign-in** — account creation, password reset and Google onboarding.
- **Light / dark mode** — persisted preference with a smooth theme transition.
- **Offline-aware writes** — clear connection errors instead of endless loading.

## Tariff scope

Domestic TNB tariff only. The calculation includes Energy, Capacity, Network, Retail, EEI, KWTBB, SST and monthly AFA where applicable. It does not model commercial tariffs, net metering, or bill payment.

## Tech stack

| Layer | Technology |
|---|---|
| App | Flutter / Dart, Riverpod, go_router |
| Backend | Firebase Auth, Cloud Firestore, Cloud Functions, FCM |
| Reporting | Firebase Crashlytics |
| Integrity | Firebase App Check |
| UI | flutter_screenutil, Google Fonts (bundled locally) |

## Run locally

```bash
flutter pub get
flutter run
```

Local Firebase configuration is required; see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Build

```bash
flutter build apk --release
```

GitHub Actions builds a release APK on pushes to `main`:

https://github.com/H4DRI165/energy-tracker/releases/latest

## Documentation

- [Documentation index](docs/README.md)
- [Product requirements](docs/PRD.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Features](docs/FEATURES.md)
- [Billing and tariff logic](docs/BILLING.md)
- [Firestore data model](docs/DATA_MODEL.md)
- [Development guide](docs/DEVELOPMENT.md)
- [Glossary](docs/GLOSSARY.md)
