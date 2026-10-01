# Architecture

- **Status:** Current
- **App version:** `0.5.7+1`

## 1. Overview

```
┌──────────────────────────────────────────────────────────────┐
│                        Flutter app (lib/)                     │
│                                                               │
│  ui/            Presentation: pages, widgets, components      │
│   ├─ features/  Feature slices (dashboard, usage, devices…)   │
│   ├─ ft_auth/   Auth feature slice                            │
│   ├─ ft_main/   Splash + landing                              │
│   ├─ components Shared widgets (input, display, feedback…)    │
│   └─ routes/    go_router config + auth redirect               │
│                                                               │
│  Riverpod       Notifiers / AsyncNotifiers hold screen state   │
│                 and orchestrate reads/writes                   │
│                                                               │
│  services/      Auth, billing engine, notifications, logging   │
│  models/        Plain data models (from Firestore docs)        │
│  theme/         Colors, dimensions, text styles, ThemeData     │
│  constants/     Tariff rates (domain constants)                │
└──────────────────────────────────────────────────────────────┘
              │                          │
              ▼                          ▼
     Firebase Auth            Cloud Firestore
     Firebase Storage         (users/{uid}/…)
     Firebase Messaging
              ▲
              │ triggers
┌──────────────────────────────────────────────────────────────┐
│         Cloud Functions (functions/index.js, Node 24)          │
│  checkBudgetOnBillUpdate · sendMonthlyReadingReminder          │
└──────────────────────────────────────────────────────────────┘
```

Key idea: **the client owns everything except notifications.** Bill math, reading chains, and bill writes happen on-device; Cloud Functions only react to bill writes and run a scheduled reminder.

## 2. Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart SDK `>=3.10.0`, Flutter `>=3.44.0`; CI pins `3.44.1`) |
| State | `flutter_riverpod` 3.x |
| Routing | `go_router` 17 with `StatefulShellRoute` bottom nav |
| Backend | Firebase: Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, App Check |
| Server logic | Firebase Cloud Functions v2, Node.js 24 |
| UI scale | `flutter_screenutil` (design size 390×844) |
| Charts | `fl_chart` (+ custom `CustomPaint` for the appliance ring) |
| Fonts | `google_fonts` (Lato headings, DM Sans body) |
| Local prefs | `shared_preferences`, `flutter_secure_storage` |

## 3. Folder map

```
lib/
├── main.dart                 # bootstrap: Firebase, Crashlytics, App Check, runApp
├── app.dart                  # barrel export
├── firebase_options.dart     # generated (gitignored in CI, restored from secret)
├── constants/tariff_rates.dart
├── extensions/               # DateTime + TariffType extensions
├── models/                   # Appliance, BillRecord, ReadingRecord, UserProfile
├── services/
│   ├── auth/                 # AuthService singleton + currentUidProvider
│   ├── billing/              # ReadingChainService, BillRecalculationService
│   ├── notification/         # FCM/local notifications + prefs
│   ├── notifier/             # AppUserNotifier, userProfileProvider, tariffTypeProvider
│   └── observers/            # CrashlyticsProviderObserver
├── theme/                    # AppColors, AppDimensions, AppTextStyles, AppTheme
└── ui/
    ├── components/           # shared input/display/feedback/navigation
    ├── features/             # dashboard, usage, devices, settings, meter reading, bill
    ├── ft_auth/              # login, register, forgot password
    ├── ft_main/              # splash, landing
    └── routes/              # router + AppRoutes constants
```

Feature slice convention: `pg_<name>/page.dart` (the screen) + `notifier/<name>_notifier.dart` + `notifier/<name>_state.dart` (+ optional `widgets/`).

## 4. State management

- **Riverpod** providers, mostly:
  - `AsyncNotifierProvider` for async screen data (`dashboardProvider`, `usageProvider`, `settingsProvider`, `editProfileProvider`).
  - `NotifierProvider` for synchronous/form state (`loginProvider`, `registerProvider`, `addReadingProvider`, `addApplianceProvider`, `billDetailProvider`, `onboardingProvider`).
  - `Provider` for derived values (`tariffTypeProvider`, `isProfileLoadingProvider`).
  - `ChangeNotifierProvider` bridging `AppUserNotifier` (`userProfileProvider`).
  - `StreamProvider` for uid (`currentUidProvider`).
- Screen state classes use a `_unset` sentinel so `copyWith` can distinguish "no change" from "set to null".
- `loggable_notifier.dart` mixes in screen-name context for error logging.

## 5. Auth & routing gate

`AuthService` is a **singleton** (`factory AuthService() => _instance`) that:
- listens to `authStateChanges`, subscribes to the user's Firestore doc, and drives `AppUserNotifier`.
- exposes `uidChanges` (immediate current value, then future changes).

`AppUserNotifier` holds `OnboardingStatus`: `loading | complete | incomplete | error`.

`appRouter` (`lib/ui/routes/router.dart`) uses `refreshListenable` on auth + profile and redirects:
- Logged in + loading → stay.
- Logged in + error → `/error` (safe retry screen; never overwrites data).
- Logged in + incomplete → `/onboarding`.
- Logged in + complete hitting a public/onboarding route → `/dashboard`.
- Logged out + protected route → `/login`.

Navigation is a `StatefulShellRoute.indexedStack` with four branches (Dashboard, Usage, Devices, Settings) behind `AppBottomNav`, plus non-tab routes (onboarding, add reading, bill detail, add/edit appliance, edit profile, tariff calculator, scan bill, error).

## 6. Data access patterns

- Reads happen in notifiers via Firestore queries scoped to `users/{uid}/…`.
- Writes that must stay consistent use **`WriteBatch`** (reading delete + chain fix) or **transactions** (budget-alert reservation in the Cloud Function).
- Bills are **denormalized**: one `bills/{YYYY-MM}` doc per month, recomputed by `BillRecalculationService.recalculateMonth` whenever readings change.
- Tariff is resolved from the **most recent reading** of the month, falling back to the live profile tariff.

See [DATA_MODEL.md](DATA_MODEL.md) and [BILLING.md](BILLING.md).

## 7. Billing engine

Two services on top of `TariffRates`:

- `ReadingChainService` — finds previous/next readings globally across months and computes corrected `kwh`/`tier` for a reading whose chain position changed. Invariant: a reading cannot be lower than its predecessor.
- `BillRecalculationService` — sums a month's readings and upserts/deletes the month's bill doc.

Full domain detail: [BILLING.md](BILLING.md).

## 8. Notifications

- Client (`NotificationService`): requests permission, initializes the Android channel `budget_alerts`, renders foreground messages via `flutter_local_notifications`, routes taps by `data.type`, attaches/detaches FCM tokens on login/logout.
- Server (`functions/index.js`): `checkBudgetOnBillUpdate` (Firestore trigger + atomic tier reservation + rollback on failure) and `sendMonthlyReadingReminder` (scheduled, batched, stale-token cleanup).

## 9. Error handling & logging

- `AppLogger.error` sanitizes keys and forwards to Crashlytics.
- `mapFirebaseError` / `mapFirebaseAuthError` centralize user-facing messages.
- Router sends profile-load failures to `/error`, which calls `AuthService.retryLoadUser()`.
- `CrashlyticsProviderObserver` records Riverpod provider errors.

## 10. Theming

- `AppColors` (dark palette, semantic colors, gradients, shadows), `AppDimensions` (spacing/radius/sizes via `.r`/`.w`/`.h`), `AppTextStyles` (Lato + DM Sans), assembled in `AppTheme.dark`.
- `ScreenUtilInit(designSize: 390×844, minTextAdapt: true)` wraps `MaterialApp.router`.

## 11. CI/CD

`.github/workflows/release-apk.yml`: on push to `main` → Java 17, Flutter 3.44.1, restore secrets (`google-services.json`, `firebase_options.dart`, keystore, `key.properties`), `flutter build apk --release`, publish a GitHub Release `v<run_number>`.

## 12. Known architectural risks / tech debt

1. **Field-name drift** between settings and notification systems (`photoURL` vs `photoUrl`; `budgetAlertsEnabled` vs `alert80Enabled`). See `DATA_MODEL.md`.
2. **No Firestore security rules in the repo** — `firebase.json` only declares Functions. Rules are not version-controlled here.
3. **All migration/versioning is implicit** — no schema version field; older docs fall back via `??` defaults.
4. **Hard-coded tariff constants** — a TNB update requires a code change and release.
5. **No integration/E2E tests** — unit tests cover state and billing services only.
6. **Singleton `AuthService`** — convenient, but makes isolated testing harder.
