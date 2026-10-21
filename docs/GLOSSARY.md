# Glossary

## TNB and billing

- **TNB** — Tenaga Nasional Berhad, Malaysia’s electricity utility.
- **kWh** — kilowatt-hour; the unit of energy used for billing.
- **Meter reading** — the cumulative number displayed on the meter.
- **kWh used** — the increase between consecutive meter readings.
- **Domestic tariff** — residential TNB tariff; the only tariff supported.
- **sen** — one hundredth of a Ringgit. Tariff rates are often sen/kWh.
- **AFA** — Automatic Fuel Adjustment. A monthly surcharge or rebate published
  by TNB.
- **EEI** — Energy Efficiency Incentive. A rebate per kWh that decreases as
  monthly usage rises.
- **EEI band** — one of 17 usage brackets used to select the EEI rate.
- **KWTBB** — renewable energy fund levy, 1.6% of eligible charges.
- **SST** — Service Tax, applied to the taxable usage slice.
- **Protection threshold** — usage below which Retail, AFA and SST are waived:
  600 kWh normally, 800 kWh from September to December 2026.
- **Taxable slice** — usage above the protection threshold.
- **Net charge** — charges after the EEI rebate but before KWTBB and SST.

## App concepts

- **Baseline reading** — the first reading in the chain; it has no usage.
- **Reading chain** — all user readings ordered by date.
- **Interval** — the period between two readings; its kWh is the delta.
- **Interval allocation** — splitting an interval across calendar months by
  day overlap.
- **Estimated month** — a month containing an interval longer than 35 days.
- **Bill recalculation** — rebuilding bill documents for every affected month.
- **Budget status** — normal, warning (80%) or exceeded (100%).
- **Onboarding status** — loading, complete, incomplete or error.
- **Estimate** — the app’s calculated amount, not the official TNB invoice.

## Technical

- **Riverpod** — state management library used across the app.
- **Notifier / AsyncNotifier** — state holders for synchronous and asynchronous
  screens.
- **`_unset` sentinel** — used in `copyWith` so nullable values can be cleared.
- **Feature slice** — page, notifier and state grouped by feature.
- **FCM** — Firebase Cloud Messaging.
- **App Check** — Firebase abuse protection.
- **Crashlytics** — Firebase crash and error reporting.
- **`alertTierSent`** — per-bill field reserving the 0/80/100 alert state.
- **ScreenUtil** — sizing helper using a 390×844 design canvas.
