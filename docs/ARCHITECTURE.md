# Architecture

- **Status:** Current
- **App version:** `0.5.7+1`

## 1. Overview

```text
Flutter app
  ui/
    features/     dashboard, usage, devices, settings, readings, bill detail
    ft_auth/      login, register, forgot password
    ft_main/      splash, landing
    components/   shared input, display, feedback and navigation widgets
    routes/       go_router configuration
  services/       auth, billing, notifications, tariff, network, logging
  models/         Firestore-backed data models
  theme/          colors, dimensions, typography and ThemeData
  constants/      tariff calculations and domain constants
```

Firebase provides Auth, Firestore, Storage, Messaging, Crashlytics and App
Check. Cloud Functions send budget alerts and reading reminders.

The client owns the billing data and recomputes affected bills after reading
changes. Cloud Functions react to bill writes and scheduled reminders; they do
not perform the core bill calculation.

## 2. Stack

| Area | Choice |
|---|---|
| Framework | Flutter 3.44+, Dart 3.10+ |
| State | Riverpod 3 |
| Routing | go_router with a stateful bottom-navigation shell |
| Auth | Firebase Authentication (email/password and Google) |
| Data | Cloud Firestore |
| Server logic | Firebase Cloud Functions v2, Node.js 24 |
| Notifications | FCM + flutter_local_notifications |
| Integrity | Firebase App Check |
| Sizing | flutter_screenutil, design size 390×844 |
| Fonts | Lato + DM Sans, bundled locally |

## 3. App shell

`lib/main.dart` initializes Firebase, Crashlytics, App Check, notifications and
fonts, loads the bundled tariff immediately, then refreshes the published
tariff in the background.

The main tabs use `StatefulShellRoute.indexedStack`:

- Dashboard
- Usage
- Devices
- Settings

A notched centre FAB opens Add Reading. Non-tab routes include onboarding,
bill detail, edit profile, add/edit appliance, tariff calculator and error.

## 4. State management

Most screen state uses Riverpod:

- `AsyncNotifierProvider` for Firestore-backed screens.
- `NotifierProvider` for synchronous form and detail state.
- `StreamProvider` for the current UID.
- `ChangeNotifierProvider` bridges the auth/onboarding notifier.

State classes use an unset sentinel where `copyWith` must distinguish
"unchanged" from "clear to null".

## 5. Authentication and onboarding gate

`AuthService` is a singleton. It listens to Firebase Auth, subscribes to the
user profile document and drives `AppUserNotifier`:

```text
loading | complete | incomplete | error
```

The router redirects based on that state:

- loading → stay on the current route
- error → `/error`
- incomplete → `/onboarding`
- complete on a public/onboarding route → `/dashboard`
- signed out on a protected route → `/login`

Email registration creates the full Firestore profile. Google sign-in may have
no profile yet, so onboarding bootstraps the required profile fields and then
syncs the FCM token. This keeps Firestore rules strict without blocking OAuth
users.

## 6. Billing data flow

```text
reading save/edit/delete
  → ReadingChainService fixes neighbouring deltas
  → BillRecalculationService finds affected months
  → usage intervals are allocated by calendar day
  → one bill document per affected month is upserted or deleted
```

The first reading is a baseline. Long intervals are marked estimated and split
across the months they overlap.

See [BILLING.md](BILLING.md) and [DATA_MODEL.md](DATA_MODEL.md).

## 7. Tariff loading

`TariffRepository` resolves data in this order:

1. Bundled `assets/tariff/domestic_general.json` (fast startup fallback).
2. Firestore `tariffs/domestic_general` (background refresh).
3. Compiled-in `DomesticTariff.fallback`.

Remote refresh invalidates usage, dashboard and devices providers so visible
calculations update without delaying launch.

## 8. Notifications

- `NotificationService` requests permission, creates the Android channel,
  displays foreground messages, routes notification taps and stores the FCM
  token.
- Token writes are skipped until the profile exists. Onboarding calls
  `syncToken()` after creating a Google profile.
- `functions/index.js` handles 80%/100% budget alerts and monthly reading
  reminders.

## 9. Security

- Firestore rules are version-controlled in `firestore.rules`.
- User data is owner-scoped under `users/{uid}`.
- Tariff reads are public; tariff writes are denied to clients.
- App Check is configured for the app. Firestore enforcement is currently
  **unenforced**; enable it only after confirming debug tokens and Play
  Integrity work in the target builds.

## 10. UI systems

- `AppColors` supplies the semantic light/dark palette.
- `AppDimensions` centralizes spacing, radii and component sizes.
- `AppTextStyles` supplies Lato headings and DM Sans body text.
- `AppBottomSheet` + `showAppBottomSheet` provide one animation, surface,
  handle, safe-area and scrolling policy for all bottom sheets.
- `AuthPageScaffold` provides the shared auth-page animation and layout.

## 11. Release pipeline

`.github/workflows/release-apk.yml` builds a signed release APK on pushes to
`main`. It restores Firebase configuration and signing secrets, then publishes
the APK to GitHub Releases.

## 12. Trade-offs

- Billing runs client-side; Cloud Functions only handle notifications.
- Google profiles are bootstrapped at onboarding rather than by a server-side
  auth trigger.
- TNB account number is blank for Google users until they edit their profile.
- Rules and App Check must be configured per Firebase project.
- Integration and widget coverage is still limited; billing and state services
  have unit tests.
