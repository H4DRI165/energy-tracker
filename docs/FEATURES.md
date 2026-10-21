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
- Authentication is required; guest mode is not supported.
- Register captures name, email, 12-digit TNB account, password; writes `users/{uid}` with defaults (`monthlyBudget: 150`, `onboardingCompleted: false`).
- Registration rolls back the Firestore doc and auth user if the profile write fails.
- Error codes mapped in `lib/ui/components/logging/app_logger.dart:90` (`mapFirebaseAuthError`).

**Gaps / issues**
- Email verification is disabled (`register_notifier.dart:204-205` TODO).
- Password policy is inconsistent between hint/checklist and validator (see `ux-review/FINDINGS.md` H5).
- No autofill/keyboard actions (H2).

---

## Onboarding
**Status:** Shipped

**What it does:** Two steps — set the monthly budget and review the summary — then writes `monthlyBudget` and `onboardingCompleted: true`.

**User flow:** Register → Step 1 Budget → Step 2 Complete → "Start Tracking".

**Key files**
- Screen: `lib/ui/features/ft_onboarding/page.dart`
- State: `ft_onboarding/notifier/onboarding_notifier.dart`, `onboarding_state.dart`

**Details**
- Domestic tariff only (TNB Tariff A).
- Budget slider RM 50–300 plus quick presets.
- Progress header ("1 of 3") and back handling via `PopScope`.

**Gaps / issues**
- Completion is gated only on Firestore write success; no retry guidance beyond an error banner.
- Summary claims "Alerts enabled" regardless of notification permission (see `ux-review/FINDINGS.md` M6).

---

## Dashboard
**Status:** Shipped

**What it does:** The home screen. Shows the current-month month-to-date bill, projected bill, budget progress, 7-day usage chart, EEI band, saving tips, and quick actions.

**Key files**
- Screen: `lib/ui/features/ft_dashboard/page.dart`
- State: `ft_dashboard/notifier/dashboard_notifier.dart`, `dashboard_state.dart`
- Widgets: `ft_dashboard/widgets/*`

**Data read:** current-month readings, previous-month readings, user profile (name, budget).
**Derived values:** `kwhUsed`, `estimatedBill`, `dailyAvg`, projected bill, `percentageVsLastMonth`, budget status (normal/warning/exceeded at 80/100%), 7-day usage series.

**Details**
- The comparison uses the same number of days from the previous month, not a partial month against a full month.
- The hero card labels the current amount as month-to-date and always shows the projected full-month bill.
- Daily average is compared with a budget-derived daily kWh target instead of a fixed threshold.
- A first-run empty state prompts for the first reading; one saved baseline gets a next-reading hint.
- The weekly chart says its daily values come from reading intervals.
- At 80% budget the hero card and saving tips warn; the separate alert banner is reserved for exceeded budgets.

**Gaps / issues**
- Error state previously dumped raw exceptions (fixed in `ux-review` C1).
- Loading hides the header and uses a bare spinner (M1).

---

## Meter readings
**Status:** Shipped

**What it does:** Add/edit/delete a meter reading for a date. Computes kWh delta vs the previous reading, itemized cost, and the current EEI band.

**User flow:** Dashboard/tab → Add Reading → pick date → enter reading (kWh) → see auto-calc → save → dashboard + usage refresh.

**Key files**
- Screen: `lib/ui/features/ft_add_meter_reading/page.dart`
- State: `ft_add_meter_reading/notifier/add_meter_reading_notifier.dart`, `add_meter_reading_state.dart`
- Chain/bill services: `lib/services/billing/reading_chain_service.dart`, `bill_recalculation_service.dart`

**Rules**
- Reading must be > 0 and cannot be lower than the previous reading or higher than the next.
- Edit mode fixes the date (read-only).
- Saving recalculates every month touched by the reading intervals and the next reading if the chain shifted.
- Long gaps are split across the covered months and flagged as estimated; the add screen warns before saving.
- The first reading is a baseline: the add screen explains this, and the success snackbar prompts for a second reading.

**Gaps / issues**
- Save button disabled with no explanation (fixed C2).

---

## Bill detail
**Status:** Shipped

**What it does:** Per-month bill page: estimated amount, itemized breakdown, and the month's readings. Tapping a reading opens a read-only detail sheet with explicit Edit/Delete actions; swiping also deletes.

**Key files**
- Screen: `lib/ui/features/ft_bill_detail/page.dart`
- State: `ft_bill_detail/notifier/bill_detail_notifier.dart`, `bill_detail_state.dart`

**Details**
- Readings show meter value, interval usage, date, EEI band, and notes in a read-only detail sheet.
- Editing from the sheet opens the reading editor; deleting from the sheet asks for confirmation.
- Deleting a reading recomputes neighbors and recalculates the month.
- The section uses a "Tap for details" hint; swipe-to-delete remains available.

**Gaps / issues**
- Delete failure copy was misleading (see `ux-review` H4).

---

## Usage
**Status:** Shipped

**What it does:** Monthly/yearly kWh chart (last 6 or 12 months), current month summary with latest-reading status, an expandable charge breakdown shared with the tariff calculator, and recent bills (last 12 months) with delete-month.

**Key files**
- Screen: `lib/ui/features/ft_usage/page.dart`
- State: `ft_usage/notifier/usage_notifier.dart`, `usage_state.dart`
- Widgets: `ft_usage/widgets/*`

**Details**
- Empty state with "Add First Reading" CTA.
- After only a baseline reading exists, the empty state changes to "Baseline reading saved / 1 of 2 readings" and prompts for the next reading, so a zero-usage screen is not mistaken for a broken refresh.
- The summary shows the latest reading date, its interval usage and month-to-date progress.
- Deleting a bill month removes all its readings + bill docs in a batch.
- AFA disclaimer shown for applicable tariffs.
- Each charge line opens a plain-language explanation sheet.

**Gaps / issues**
- Bare spinner loading (M1); error uses generic `ErrorView` (L5).

---

## Appliances
**Status:** Shipped

**What it does:** Manage household appliances (name, category, wattage, typical daily hours), review estimated monthly cost and range, see biggest consumers and category breakdowns, and open a per-appliance detail page with hourly cost and savings insight.

**Key files**
- Screen: `lib/ui/features/ft_devices/pg_devices/page.dart`, `pg_add_appliance/page.dart`, `pg_appliance_detail/page.dart`
- State: `pg_devices/notifier/devices_notifier.dart`, `pg_add_appliance/notifier/add_appliance_notifier.dart`
- Model: `lib/models/appliance.dart`

**Formula:** `monthlyKwh = (wattage / 1000) * typicalDailyHours * 30`; cost via `TariffRates.marginalCost`. The UI labels costs as estimates (~RM), shows a 50%–150% usage range, states that the total is not the TNB bill, and compares the estimate with the monthly budget.

**Details**
- The appliance list uses compact rows with search, category filters and sorting available for non-empty lists.
- Biggest-consumers ranking and category cost breakdown live inside one collapsible Insights card, not as separate cards.
- Add/edit supports quick hour presets (`1h`, `4h`, `8h`, `12h`, `24h ? Always on`) in addition to the stepper.
- Appliance cards open a detail page with cost/day, cost/hour, monthly kWh, share of tracked usage, a 1-hour reduction saving, and the estimation assumptions.
- Tapping Edit from the detail page returns to the edit form; the detail view refreshes from the provider.

**Gaps / issues**
- Category silently defaults to "Cooling" (M7).
- Hours stepper enabled at limits, not typable, no semantics (M8).
- Save disabled with no explanation (fixed C2).

---

## Settings
**Status:** Shipped

**What it does:** Profile card, Preferences (Monthly Budget, Dark Mode, Notifications), Tools (Tariff Calculator), About (version), and Sign Out.

**Key files:** `lib/ui/features/ft_settings/pg_settings/page.dart`, `widgets/settings_layout.dart`, `widgets/budget_sheet.dart`, `widgets/notification_prefs_sheet.dart`, `notifier/settings_notifier.dart`

**Details**
- The profile card opens Edit Profile; there is no duplicate Edit Profile list tile.
- Preferences combines Monthly Budget, Dark Mode and Notifications in one group.
- Dark mode is a persisted local preference, defaulting to **light**. Toggling it plays a day-to-night transition.
- The Notifications tile opens the budget-alert preferences sheet.
- Budget changes are confirmed via a dialog.
- Sign out is confirmed and redirects to login.

**Gaps / issues**
- Legacy `budgetAlertsEnabled` / `billRemindersEnabled` fields remain in the settings model but are not used by the notification system (see `DATA_MODEL.md`).

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

**What it does:** Standalone calculator: enter kWh in a clearly editable field, see a read-only estimated total, then the shared itemized breakdown and an expandable tariff reference sheet. Each charge line opens a plain-language explanation sheet.

**Key files:** `lib/ui/features/ft_settings/pg_tariff_calculator/page.dart`, `notifier/tariff_calculator_notifier.dart`

**Gaps / issues**
- Input is integer-only (L7).

---

## Notifications
**Status:** Shipped

**What it does:** Budget threshold alerts (80% / 100%) and an end-of-month reading reminder, delivered via FCM; per-user toggles for the budget alerts.

**Architecture:** Server-driven. Cloud Functions react to bill writes and a monthly schedule; the client handles foreground display and tap routing.

**Key files**
- Client: `lib/services/notification/service/notification_service.dart`, `prefs/notification_prefs_notifier.dart`, `ft_settings/pg_settings/widgets/notification_prefs_sheet.dart`
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

Priorities ([PRD.md](PRD.md) §14): **next milestone = notification settings, ToS/Privacy**. Bill scanning is explicitly out of scope.

| Feature | Priority | Status | Evidence / note |
|---|---|---|---|
| In-app notification settings section | **Next** | WIP / Hidden | Commented block in `pg_settings/page.dart:155-181`. Fix the field mismatch (`DATA_MODEL.md` #2) before enabling |
| Terms of Service / Privacy Policy | **Next** | Planned | Referenced in register (`ft_register/page.dart:353-363`) and commented in settings; no routes. Pair with the privacy policy in `PRD.md` §15 |
| Scan TNB bill (camera/AI) | Out of scope | WIP / Hidden | `AppRoutes.scanBill` → `ComingSoonPage`; QuickActions Scan tile commented out (`ft_dashboard/widgets/quick_actions.dart:27-35`) |
| Email verification | Backlog | WIP / Hidden | Commented in `register_notifier.dart:204-205` |
