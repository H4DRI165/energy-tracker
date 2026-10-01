# Feature Inventory

Status legend: **Shipped** · **Shipped (partial)** · **WIP / Hidden** · **Planned**

Jump to: [Auth](#auth) · [Onboarding](#onboarding) · [Dashboard](#dashboard) · [Meter readings](#meter-readings) · [Bill detail](#bill-detail) · [Usage](#usage) · [Appliances](#appliances) · [Settings](#settings) · [Edit profile](#edit-profile) · [Tariff calculator](#tariff-calculator) · [Notifications](#notifications) · [Observability](#observability) · [WIP / Planned](#wip--planned)

---

## Auth
**Status:** Shipped (partial)

**What it does:** Register, sign in (email/password or Google), and reset password. Account creation also writes the Firestore user profile that gates onboarding.

**User flow:** Splash → Landing (auto-redirect) → Login ↔ Register → (Forgot Password) → Onboarding if profile incomplete, else Dashboard.

**Key files**
- Screens: `lib/ui/ft_auth/ft_login/page.dart`, `ft_register/page.dart`, `ft_forgot_password/page.dart`
- State: `lib/ui/ft_auth/*/notifier/*.dart`
- Service: `lib/services/auth/auth_service.dart`
- Routing gate: `lib/ui/routes/router.dart:19-57`

**Details**
- Email/password via Firebase Auth; Google via `google_sign_in`.
- Register captures name, email, 12-digit TNB account, password; writes `users/{uid}` with defaults (`tariffType: domestic`, `monthlyBudget: 150`, `onboardingCompleted: false`).
- Registration rolls back the Firestore doc and auth user if the profile write fails.
- Error codes mapped in `lib/ui/components/logging/app_logger.dart:90` (`mapFirebaseAuthError`).

**Gaps / issues**
- Email verification is disabled (`register_notifier.dart:204-205` TODO).
- No guest mode despite an `isGuest` field.
- Password policy is inconsistent between hint/checklist and validator (see `ux-review/FINDINGS.md` H5).
- No autofill/keyboard actions (H2).

---

## Onboarding
**Status:** Shipped

**What it does:** Three steps — choose tariff type, set monthly budget, summary — then writes `tariffType`, `monthlyBudget`, and `onboardingCompleted: true`.

**User flow:** Register → Step 1 Tariff → Step 2 Budget → Step 3 Complete → "Start Tracking".

**Key files**
- Screen: `lib/ui/features/ft_onboarding/page.dart`
- State: `ft_onboarding/notifier/onboarding_notifier.dart`, `onboarding_state.dart`

**Details**
- Tariff options from `TariffType` enum (`domestic` / `commercial`).
- Budget slider RM 50–300 plus quick presets.
- Progress header ("1 of 3") and back handling via `PopScope`.

**Gaps / issues**
- Completion is gated only on Firestore write success; no retry guidance beyond an error banner.
- Summary claims "Alerts enabled" regardless of notification permission (see `ux-review/FINDINGS.md` M6).

---

## Dashboard
**Status:** Shipped

**What it does:** The home screen. Shows current-month estimated bill, budget progress, 7-day usage chart, EEI band / tariff tier, saving tips, and quick actions.

**Key files**
- Screen: `lib/ui/features/ft_dashboard/page.dart`
- State: `ft_dashboard/notifier/dashboard_notifier.dart`, `dashboard_state.dart`
- Widgets: `ft_dashboard/widgets/*`

**Data read:** current-month readings, previous-month readings, user profile (name, budget), derived tariff from the latest reading.
**Derived values:** `kwhUsed`, `estimatedBill`, `dailyAvg`, projected bill, `percentageVsLastMonth`, budget status (normal/warning/exceeded at 80/100%), 7-day usage series.

**Gaps / issues**
- Error state previously dumped raw exceptions (fixed in `ux-review` C1).
- Loading hides the header and uses a bare spinner (M1).

---

## Meter readings
**Status:** Shipped

**What it does:** Add/edit/delete a meter reading for a date. Computes kWh delta vs the previous reading, itemized cost, and the current EEI band / commercial tier.

**User flow:** Dashboard/tab → Add Reading → pick date → enter reading (kWh) → see auto-calc → save → dashboard + usage refresh.

**Key files**
- Screen: `lib/ui/features/ft_add_meter_reading/page.dart`
- State: `ft_add_meter_reading/notifier/add_meter_reading_notifier.dart`, `add_meter_reading_state.dart`
- Chain/bill services: `lib/services/billing/reading_chain_service.dart`, `bill_recalculation_service.dart`

**Rules**
- Reading must be > 0 and cannot be lower than the previous reading or higher than the next.
- Edit mode fixes the date (read-only).
- A month cannot mix tariff types (`_checkTariffConflict`).
- Saving recalculates the affected month's bill and the next reading if the chain shifted.

**Gaps / issues**
- Save button disabled with no explanation (fixed C2).
- Tariff-conflict error is verbose and has no action (M4).

---

## Bill detail
**Status:** Shipped

**What it does:** Per-month bill page: estimated amount, itemized breakdown, payment status toggle, and the month's readings (tap to edit, swipe to delete).

**Key files**
- Screen: `lib/ui/features/ft_bill_detail/page.dart`
- State: `ft_bill_detail/notifier/bill_detail_notifier.dart`, `bill_detail_state.dart`

**Details**
- Paid toggle updates all bill docs for the month and refreshes usage.
- Deleting a reading recomputes neighbors and recalculates the month.
- "Swipe to delete history" hint is shown.

**Gaps / issues**
- Delete failure copy was misleading (see `ux-review` H4).
- "Tap to mark as paid" caption but only the small toggle is tappable (M2).

---

## Usage
**Status:** Shipped

**What it does:** Monthly/yearly kWh chart (last 6 or 12 months), current month summary, charge breakdown, and bill history with delete-month.

**Key files**
- Screen: `lib/ui/features/ft_usage/page.dart`
- State: `ft_usage/notifier/usage_notifier.dart`, `usage_state.dart`
- Widgets: `ft_usage/widgets/*`

**Details**
- Empty state with "Add First Reading" CTA.
- Deleting a bill month removes all its readings + bill docs in a batch.
- AFA disclaimer shown for applicable tariffs.

**Gaps / issues**
- Bare spinner loading (M1); error uses generic `ErrorView` (L5).

---

## Appliances
**Status:** Shipped

**What it does:** Manage household appliances (name, category, wattage, daily hours) and see estimated monthly kWh and RM cost, plus a share-of-total ring.

**Key files**
- Screen: `lib/ui/features/ft_devices/pg_devices/page.dart`, `pg_add_appliance/page.dart`
- State: `pg_devices/notifier/devices_notifier.dart`, `pg_add_appliance/notifier/add_appliance_notifier.dart`
- Model: `lib/models/appliance.dart`

**Formula:** `monthlyKwh = (wattage / 1000) * dailyHours * 30`; cost via `TariffRates.marginalCost`.

**Gaps / issues**
- Category silently defaults to "Cooling" (M7).
- Hours stepper enabled at limits, not typable, no semantics (M8).
- Save disabled with no explanation (fixed C2).

---

## Settings
**Status:** Shipped

**What it does:** Profile card, account section (Edit Profile, Tariff Type, Monthly Budget), Tools (Tariff Calculator), About (version), and Sign Out.

**Key files:** `lib/ui/features/ft_settings/pg_settings/page.dart`, `widgets/settings_layout.dart`, `widgets/budget_sheet.dart`, `widgets/tariff_type_sheet.dart`, `notifier/settings_notifier.dart`

**Details**
- Tariff switch and budget change are confirmed via dialogs.
- Sign out is confirmed and redirects to login.

**Gaps / issues**
- The "NOTIFICATIONS" settings section is **commented out**; notification prefs actually live in the dashboard bell sheet.
- Reads `budgetAlertsEnabled` / `billRemindersEnabled` fields that the notification system does not use (see `DATA_MODEL.md`).

---

## Edit profile
**Status:** Shipped

**What it does:** Edit display name and TNB account number, upload/replace avatar, view account info. Email is read-only.

**Key files:** `lib/ui/features/ft_settings/pg_edit_profile/page.dart`, `notifier/edit_profile_notifier.dart`

**Details**
- Avatar uploaded to Firebase Storage at `users/{uid}/profile_<timestamp>.jpg`; old avatar deleted.
- Syncs `displayName` to FirebaseAuth.
- Save button only enabled when there are changes.

**Gaps / issues**
- TNB hint shows 10 digits but validation requires 12 (H7).
- Placeholder "Loading..." fallback for name (L2).

---

## Tariff calculator
**Status:** Shipped

**What it does:** Standalone calculator: enter kWh, switch between domestic/commercial, see itemized breakdown, total, min-charge and EEI band/tier. Includes tariff reference cards.

**Key files:** `lib/ui/features/ft_settings/pg_tariff_calculator/page.dart`, `notifier/tariff_calculator_notifier.dart`

**Gaps / issues**
- Input has no accessible label (M9) and is integer-only (L7).

---

## Notifications
**Status:** Shipped

**What it does:** Budget threshold alerts (80% / 100%) and an end-of-month reading reminder, delivered via FCM; per-user toggles for the budget alerts.

**Architecture:** Server-driven. Cloud Functions react to bill writes and a monthly schedule; the client handles foreground display and tap routing.

**Key files**
- Client: `lib/services/notification/service/notification_service.dart`, `prefs/notification_prefs_notifier.dart`, `ft_dashboard/widgets/notification_prefs_sheet.dart`
- Backend: `functions/index.js`

**Details**
- `checkBudgetOnBillUpdate`: on `users/{uid}/bills/{billId}` write, computes `amount / monthlyBudget`; atomically reserves tier (`alertTierSent`) before sending; rolls back on FCM failure.
- `sendMonthlyReadingReminder`: 9:00 AM on the 28th (Asia/Kuala_Lumpur); sends to users with a token and no bill for `YYYY-MM`; batches at 500 and cleans stale tokens.
- Tap payload `type`: `budget_alert` → dashboard, `reading_reminder` → add reading.
- Token attached on login, detached on logout/account switch.

**Gaps / issues**
- Field-name mismatch between the notification system (`alert80Enabled`/`alert100Enabled`) and the settings model (`budgetAlertsEnabled`/`billRemindersEnabled`). See `DATA_MODEL.md`.
- Permission denial is not surfaced; onboarding claims alerts are enabled (M6).

---

## Observability
**Status:** Shipped

**What it does:** Crashlytics for fatal + non-fatal errors, Firebase Analytics, App Check, and a safe error screen for Firestore profile-load failures.

**Key files:** `lib/main.dart`, `lib/ui/components/logging/app_logger.dart`, `lib/services/observers/crashlytics_provider_observer.dart`, `lib/ui/routes/router.dart:200-216`

**Details**
- Crash collection disabled in debug.
- `AppLogger` sanitizes custom keys to String/int/double/bool.
- `mapFirebaseError` / `mapFirebaseAuthError` central mapping.

---

## WIP / Planned

Priorities ([PRD.md](PRD.md) §14): **next milestone = notification settings, ToS/Privacy, guest mode**. Bill scanning is explicitly out of scope.

| Feature | Priority | Status | Evidence / note |
|---|---|---|---|
| In-app notification settings section | **Next** | WIP / Hidden | Commented block in `pg_settings/page.dart:155-181`. Fix the field mismatch (`DATA_MODEL.md` #2) before enabling |
| Terms of Service / Privacy Policy | **Next** | Planned | Referenced in register (`ft_register/page.dart:353-363`) and commented in settings; no routes. Pair with the privacy policy in `PRD.md` §15 |
| Guest mode | **Next** | Planned | `isGuest` written in register; no flow. Needs auth + router changes |
| Scan TNB bill (camera/AI) | Out of scope | WIP / Hidden | `AppRoutes.scanBill` → `ComingSoonPage`; QuickActions Scan tile commented out (`ft_dashboard/widgets/quick_actions.dart:27-35`) |
| Email verification | Backlog | WIP / Hidden | Commented in `register_notifier.dart:204-205` |
