# Development

## 1. Requirements

| Tool | Version |
|---|---|
| Flutter | 3.44+ (CI: 3.44.1) |
| Dart | 3.10+ |
| Java | 17 |
| Node.js | 24 for Cloud Functions |
| Firebase CLI | Current |

Firebase project: `energy-tracker-848fa`.

## 2. Local setup

```bash
git clone <repo>
cd energy-tracker
flutter pub get
flutter run
```

Required local Firebase files:

| File | Purpose |
|---|---|
| `android/app/google-services.json` | Android Firebase config |
| `lib/firebase_options.dart` | FlutterFire configuration |
| `android/key.properties` | Release signing |
| `android/release.keystore` | Release signing |

Do not commit signing credentials or generated plugin registrants.

`android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../release.keystore
```

## 3. Commands

```bash
dart format lib test
flutter analyze
flutter test
flutter test test/constants/tariff_rates_test.dart
flutter build apk --release
```

The analyzer baseline is `very_good_analysis` and should stay at zero
diagnostics. Do not suppress lints to bypass cleanup.

## 4. Firebase

```bash
firebase login
firebase use energy-tracker-848fa
firebase deploy --only firestore:rules
firebase deploy --only functions
```

Rules are in `firestore.rules`. Storage rules are in `storage.rules`.

### App Check

Debug builds use the Android debug provider; release builds use Play
Integrity. Firestore App Check enforcement is currently off.

Before enabling enforcement:

1. Register the debug token in Firebase Console.
2. Verify Play Integrity in a release build.
3. Test reads and writes for both auth providers.
4. Enable Firestore enforcement.

### Google sign-in

`ApiException: 10` means the Android OAuth client is misconfigured, usually a
missing SHA fingerprint. The Firebase Android app must include the debug,
release, and Play App Signing SHA-1 values, followed by a fresh
`google-services.json` and clean rebuild.

## 5. Tests

Tests live in `test/` and cover:

- tariff calculation and breakdown rows
- usage interval allocation
- reading chain and bill recalculation
- add-reading state
- appliance estimates
- profile parsing
- theme contrast

Run all tests before merging:

```bash
flutter test
```

## 6. Build and release

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

CI: `.github/workflows/release-apk.yml` builds on pushes to `main` and publishes
a GitHub Release. It restores Firebase and signing files from repository
secrets.

## 7. Conventions

- Feature slice: `pg_<name>/page.dart`, `notifier/<name>_notifier.dart`,
  `notifier/<name>_state.dart`, optional `widgets/`.
- Prefer small widgets over very large build methods.
- Use shared components (`AppBottomSheet`, `AuthPageScaffold`,
  `ConfirmDialog`, `GradientButton`) rather than duplicating UI.
- Add comments only where logic is non-obvious: tariff math, interval
  allocation, auth/onboarding lifecycle and other domain edge cases.
- Do not leave commented-out implementation or stale TODOs.
- Run `dart format`, `flutter analyze`, and `flutter test` before committing.

## 8. Troubleshooting

| Problem | Check |
|---|---|
| Google sign-in fails | SHA fingerprints, Google provider enabled, updated `google-services.json` |
| Firestore permission denied | Deployed rules, signed-in UID, required profile fields |
| FCM token write fails | Profile exists before token write; see `NotificationService` |
| Tariff is stale | Bundled asset and Firestore `tariffs/domestic_general` |
| Release build signing fails | `key.properties`, keystore path and CI secrets |
