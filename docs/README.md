# Energy Tracker Documentation

Current documentation for the Energy Tracker Flutter app. The root
[README](../README.md) is the short public overview; this folder contains the
maintainer-level detail.

## Documents

| Document | Purpose |
|---|---|
| [PRD](PRD.md) | Product problem, users, scope and priorities |
| [Features](FEATURES.md) | What the app does today and where the code lives |
| [Architecture](ARCHITECTURE.md) | App layers, state, routing, Firebase and UI systems |
| [Billing](BILLING.md) | Domestic tariff math, reading intervals and bill recalculation |
| [Data model](DATA_MODEL.md) | Firestore collections, fields and security rules |
| [Development](DEVELOPMENT.md) | Setup, commands, Firebase, release and conventions |
| [Glossary](GLOSSARY.md) | TNB and app terminology |

## Project snapshot

- **App version:** `0.5.7+1`
- **Platform:** Flutter mobile, Android-first
- **Firebase project:** `energy-tracker-848fa`
- **Tariff:** TNB Domestic General only
- **Auth:** Firebase Auth (email/password and Google)
- **Backend:** Cloud Firestore, Cloud Functions, FCM
- **UI:** light/dark themes, Riverpod state, go_router navigation

## Documentation rules

- Keep this folder current with shipped behaviour.
- Prefer short explanations over screenshots of code.
- Link to source files for implementation detail.
- Move planned work to the roadmap or mark it clearly as not implemented.
- Do not duplicate full content in `index.html`; it is a landing page for these
  documents.
