# Glossary

Domain and technical terms used across the app, docs, and code.

## Energy / TNB domain

- **TNB** — Tenaga Nasional Berhad, Malaysia's main electricity utility.
- **kWh** — kilowatt-hour; unit of energy. The app's primary usage unit.
- **Meter reading** — the cumulative number shown on an electricity meter; never decreases.
- **kWh used** — the difference between consecutive meter readings; the billable consumption.
- **Tariff A (Domestic)** — residential tariff category.
- **LV** — Low Voltage.
- **RM** — Malaysian Ringgit; app currency.
- **sen** — 1/100 of a Ringgit; rates are often quoted in sen/kWh.
- **AFA (Automatic Fuel Adjustment)** — a fuel-cost adjustment TNB republishes monthly; included automatically from the published schedule.
- **EEI (Energy Efficiency Incentive)** — a per-kWh rebate that shrinks as usage rises, using a 17-band table.
- **Band** — an EEI rebate bracket numbered 1–17; `0` means "no rebate" (usage > 1000 kWh).
- **KWTBB** — Kumpulan Wang Tenaga Boleh Baharu (renewable energy fund levy), 1.6% of certain components.
- **SST** — Sales and Service Tax (8%), applied to domestic usage above the protection threshold (600 kWh, or 800 kWh for Sep–Dec 2026).
- **Net charge** — subtotal after adding all per-kWh charges and subtracting the EEI rebate, before levies.

## App concepts

- **Baseline reading** — the earliest reading in the chain; its `kwh` is 0 (no predecessor).
- **Chain** — the globally date-ordered sequence of a user's readings.
- **Chain fix** — recomputation of the next reading's `kwh`/`tier` after an insert/edit/delete.
- **Recalculate month** — summing a month's readings and upserting (or deleting) its bill document.
- **Budget status** — `normal` (<80%), `warning` (≥80%), `exceeded` (≥100%) of monthly budget.
- **Onboarding status** — `loading` / `complete` / `incomplete` / `error`, used by the router gate.
- **Estimate** — the app's computed bill, explicitly not the official TNB invoice.

## Technical

- **Riverpod provider** — a dependency/state container. Variants used: `NotifierProvider`, `AsyncNotifierProvider`, `Provider`, `ChangeNotifierProvider`, `StreamProvider`.
- **Notifier / AsyncNotifier** — classes holding screen state; `LoggableNotifier` adds `screenName` for logging.
- **`_unset` sentinel** — a private object used in `copyWith` so nullable fields can be set to null explicitly.
- **Feature slice** — the `pg_<name>/page.dart` + `notifier/` convention.
- **FCM** — Firebase Cloud Messaging (push notifications).
- **Foreground message** — a push received while the app is open; rendered locally via `flutter_local_notifications`.
- **App Check** — Firebase abuse protection; Play Integrity in release, debug provider in development.
- **Crashlytics** — Firebase crash/error reporting.
- **`alertTierSent`** — per-bill field (`0`/`80`/`100`) reserving which budget alert has been sent, to prevent duplicates.
- **ScreenUtil** — `flutter_screenutil`; sizes written as `.w`/`.h`/`.r`/`.sp` against a 390×844 design size.
