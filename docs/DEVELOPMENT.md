# Development Guide

## 1. Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter | `>=3.44.0` (CI pins `3.44.1`) | `flutter --version` |
| Dart | `>=3.10.0` | bundled with Flutter |
| Java | 17 | for Android builds |
| Firebase CLI | latest | only for Cloud Functions |
| Node.js | 24 | only for `functions/` |

## 2. First-time setup

```bash
git clone <repo>
cd energy-tracker
flutter pub get
```

### Required local config (gitignored)

The app will not build/run without these:

| File | Purpose | How to get it |
|---|---|---|
| `android/app/google-services.json` | Android Firebase config | Firebase console → project settings, or `flutterfire configure` |
| `lib/firebase_options.dart` | Dart Firebase options | `flutterfire configure` (CI restores it from a secret) |
| `android/release.keystore` | Release signing | Your keystore, only needed for release builds |
| `android/key.properties` | Keystore credentials | See below, only needed for release builds |

`android/key.properties` (do not commit):

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../release.keystore
```

> Firebase project id is `energy-tracker-848fa` (`firebase.json`).

## 3. Run, analyze, test

```bash
flutter run                 # debug on a connected device/emulator
flutter analyze             # static analysis
flutter test                # unit tests
flutter test test/tariff_rates_test.dart   # single file
```

**Analyzer baseline:** `very_good_analysis` (`analysis_options.yaml`). Expect **0 errors** and a handful of pre-existing `lines_longer_than_80_chars` infos. Fix new issues; don't add warnings.

**Existing tests** (`test/`):
- `add_meter_reading_state_test.dart`
- `tariff_rates_test.dart`
- `appliance_test.dart`
- `user_profile_test.dart`
- `bill_recalculation_service_test.dart`
- `reading_chain_service_test.dart`

There are no widget/integration tests yet.

## 4. Build & release

Local release build:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

Version comes from `pubspec.yaml` (`version: 0.5.7+1`).

CI (`.github/workflows/release-apk.yml`) builds on every push to `main` and publishes a GitHub Release. Required repository secrets:

- `GOOGLE_SERVICES_JSON_BASE64`
- `FIREBASE_OPTIONS_DART_BASE64`
- `RELEASE_KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`

## 5. Cloud Functions

```bash
cd functions
npm install
npm run lint
npm run serve          # emulators (functions only)
npm run deploy         # firebase deploy --only functions
npm run logs
```

Lint runs on deploy (`firebase.json` `predeploy`). Node 24, `firebase-functions` v7.

## 6. Code conventions

- Lints: `very_good_analysis` + `prefer_single_quotes`, `require_trailing_commas`, `avoid_print`, `use_key_in_widget_constructors`.
- Imports are package-absolute (`package:energy_tracker/...`); barrel files (`app.dart`, `models/models.dart`, feature `widgets/widgets.dart`) re-export.
- Feature slice pattern:
  ```
  ft_<feature>/
    page.dart
    widgets/*.dart          (optional)
    notifier/
      notifier.dart         (exports)
      <name>_notifier.dart
      <name>_state.dart
  ```
- State classes: immutable, `copyWith` with an `_unset` sentinel for nullable fields.
- User-facing strings currently live inline near the widget; prefer extracting reused ones (see `docs/ux-review/README.md`).
- No comments unless they add non-obvious context (the codebase already uses explains-why comments sparingly).
- `AppLogger.error` for failures; never `print` (lint blocks it).

## 7. Where to add things

### New screen + route
1. Add the path to `AppRoutes` (`lib/ui/routes/routes.dart`).
2. Add a `GoRoute` in `lib/ui/routes/router.dart` (tab branch or top-level).
3. Create the feature slice under `lib/ui/features/ft_<name>/`.

### New Riverpod provider
1. Prefer `NotifierProvider` (form/sync) or `AsyncNotifierProvider` (async data).
2. Mix in `LoggableNotifier` and set `screenName` for error context.
3. Expose via the slice's `notifier.dart` barrel.

### New Firestore field
1. Write it from the relevant notifier (use `SetOptions(merge: true)`).
2. Read it with a safe fallback (`as T? ?? default`).
3. Update [DATA_MODEL.md](DATA_MODEL.md).
4. Keep field names consistent — check the [Known issues](DATA_MODEL.md#known-issues) first.

### New tariff/rate
See [BILLING.md §9](BILLING.md#9-when-tnb-changes-rates).

## 8. Common tasks

**Add a budget alert field / change notification behavior**
- Client prefs: `lib/services/notification/prefs/notification_prefs_notifier.dart`
- Sheet UI: `lib/ui/features/ft_dashboard/widgets/notification_prefs_sheet.dart`
- Server: `functions/index.js`

**Change validation or error copy**
- Notifiers hold validation; `lib/ui/components/logging/app_logger.dart` maps Firebase codes.
- Follow the UX copy rules in `docs/ux-review/README.md`.

**Add an appliance category**
- `lib/ui/features/ft_devices/pg_add_appliance/notifier/add_appliance_state.dart` (`_categories`)
- `lib/models/appliance.dart` (`categoryEmoji`)
- The add-appliance grid `_items` and `_CategoryGrid._hint`.

## 9. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Build fails with missing `firebase_options.dart` | Not generated locally; run `flutterfire configure` |
| Android build fails signing | Missing `key.properties` / keystore (release only) |
| Avatar never appears | `photoUrl` vs `photoURL` field mismatch (see `DATA_MODEL.md` #1) |
| Notification toggles do nothing | Settings model writes fields the functions don't read (`DATA_MODEL.md` #2) |
| Estimates don't match a real bill | AFA excluded by default; also check EEI band edge values |
