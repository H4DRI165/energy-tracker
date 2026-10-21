# Features

Current shipped behaviour, grouped by product area.

## Landing and splash

- Splash uses a short branded animation and hands off to Landing.
- Landing presents four real features: usage trends, budget alerts, bill
  estimate and appliance costs.
- Landing has an explicit **Get started** action into Login.
- No automatic redirect and no bill-scanning claim.

**Files:** `lib/ui/ft_main/pg_splash/page.dart`,
`lib/ui/ft_main/pg_landing/page.dart`

## Authentication

- Email/password and Google sign-in.
- Register, sign in and forgot-password pages share one animated auth shell.
- Email and password autofill hints, keyboard actions, password visibility
  toggles and accessible tap targets.
- Password rules are enforced consistently: 8+ characters, uppercase letter,
  number and symbol.
- Full-name input accepts Unicode.
- Forgot-password success supports resending the email or changing the email.
- Google accounts without a Firestore profile are bootstrapped during
  onboarding.
- Confirmation dialogs and auth errors use shared components.

**Files:** `lib/ui/ft_auth/`, `lib/services/auth/`,
`lib/ui/components/display/text.dart`

## Onboarding

- Two steps: monthly budget and completion summary.
- Budget range RM 50–500, matching Settings.
- Estimated kWh uses the same tariff estimator as the rest of the app.
- Summary explains the next real action: add a meter reading.
- Google profile creation and FCM token sync happen after budget confirmation.

**Files:** `lib/ui/features/ft_onboarding/`

## Dashboard

- Month-to-date bill and projected full-month bill.
- Budget progress with 80% and 100% states.
- Same-period comparison against the previous month.
- Daily average compared with a budget-derived daily target.
- 7-day usage chart based on reading intervals.
- First-run empty state and baseline-reading prompt.
- Budget alert banner reserved for exceeded budgets.

**Files:** `lib/ui/features/ft_dashboard/`,
`lib/ui/components/display/chart.dart`

## Meter readings

- Add, edit and delete readings.
- Automatic kWh delta, interval start and EEI tier.
- Reading cannot be lower than the previous reading.
- Long gaps are split across months and flagged as estimated.
- Offline saves fail with a clear message instead of waiting forever.
- Edit mode keeps the original date fixed.

**Files:** `lib/ui/features/ft_add_meter_reading/`,
`lib/services/billing/`

## Bill detail

- Month estimate and shared itemised TNB-style breakdown.
- Every calculator row is visible, including zero-value rows.
- Read-only reading sheet with interval, date, EEI and notes.
- Explicit edit/delete actions; swipe-to-delete remains available.
- Bounded monthly reading query.

**Files:** `lib/ui/features/ft_bill_detail/`

## Usage

- Current month usage and estimated bill.
- Latest reading status and day-of-month progress.
- Monthly/yearly usage chart with budget target.
- Recent bills for the last 12 months.
- Charge explanations open from any breakdown row.

**Files:** `lib/ui/features/ft_usage/`

## Appliances

- Add/edit appliances with wattage and typical daily hours.
- Monthly kWh and cost estimates with a 50%–150% range.
- Search, category filters, sorting and compact rows for large lists.
- Biggest-consumer ranking and category cost breakdown.
- Per-appliance detail page with daily/hourly cost, share of tracked usage and
  savings insight.
- Clear “estimate, not your TNB bill” copy.

**Files:** `lib/ui/features/ft_devices/`, `lib/models/appliance.dart`

## Settings

- Profile card with edit profile.
- Preferences: monthly budget, dark mode and notification settings.
- Tools: tariff calculator.
- About: version.
- Sign-out requires an internet connection.

**Files:** `lib/ui/features/ft_settings/`

## Tariff calculator

- Enter monthly kWh and see a read-only estimated total.
- Shared breakdown with explanations for every charge.
- Expandable tariff reference sheet.
- EEI band shown without treating “no rebate” as “no usage”.

**Files:** `lib/ui/features/ft_settings/pg_tariff_calculator/`

## Theme and shared UI

- Light mode default; persisted dark mode.
- Animated palette transition with contrast-safe colors.
- Shared bottom-sheet system with consistent animation, surface, handle,
  safe-area and scrolling.
- Notched centre add-reading FAB in the bottom navigation.
- Bundled Lato and DM Sans fonts; no runtime font downloads.

**Files:** `lib/theme/`, `lib/ui/components/`,
`lib/ui/components/navigation/nav.dart`

## Notifications

- Budget alerts at 80% and 100%.
- Scheduled monthly reading reminder.
- Per-user alert preferences.
- FCM token saved only after a profile exists; detached on logout/account
  switch.
- Foreground notifications shown through `flutter_local_notifications`.
- Notification taps route to Dashboard or Add Reading.

**Files:** `lib/services/notification/`, `functions/index.js`

## Not shipped

- Bill scanning / OCR.
- Email verification.
- Terms of Service / Privacy Policy screens.
- Integration or E2E test suite.
