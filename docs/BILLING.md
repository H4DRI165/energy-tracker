# Billing & Tariff Domain

- **Status:** Current
- **Source of truth in code:** `lib/constants/tariff_rates.dart`
- **Rates version:** post-1 July 2025 TNB restructuring

> AFA is included automatically from the published monthly schedule when available. The app is an estimator, not the official TNB invoice.

## 1. Core concepts

- **Meter reading** — the raw cumulative number on the meter (never decreases).
- **kWh used** — the delta between a reading and the previous reading. This is what gets billed.
- **Tariff** — domestic only (TNB Tariff A). The app no longer models commercial tariffs.
- **EEI** — Energy Efficiency Incentive, a per-kWh rebate from a 17-band table.
- **Band** — the EEI bracket used for badges and color (`EeiBand`), 1–17; `0` means “no rebate”.

## 2. Domestic (Tariff A)

Rates come from `TariffRates.tariff`, which is loaded from Firestore/bundled JSON and falls back to `DomesticTariff.fallback`.

| Component | Rate | Condition |
|---|---|---|
| Energy | 27.03 sen/kWh | total ≤ 1500 kWh |
| Energy | 37.03 sen/kWh | total > 1500 kWh (applies to **all** kWh) |
| Capacity | 4.55 sen/kWh | always |
| Network | 12.85 sen/kWh | always |
| Retail | RM 10 | only when total > protection threshold |
| AFA | published monthly | included from the schedule; applies when total > protection threshold |
| EEI rebate | 0.5–25 sen/kWh | lookup table, applies to **all** kWh; 0 above 1000 kWh |
| KWTBB | 1.6% of (Energy + Capacity + Network − EEI) | only when total > 300 kWh |
| SST | 8% of the taxable slice | only when total > protection threshold |

**Protection threshold:** 600 kWh normally, **800 kWh for Sep–Dec 2026**. The schedule models this as `protectionPeriods`, so it returns to 600 automatically on 1 Jan 2027.

Formula (`_domesticCharges`; each line is rounded to sen and the bill is split at the threshold, mirroring TNB):

```
threshold = protectionThresholdKwh(billingMonth)
taxable   = max(0, kwh - threshold)
energy    = round(kwh * (kwh > 1500 ? 0.3703 : 0.2703))
afa       = kwh > threshold ? round(kwh * afaRate) : 0
capacity  = round(kwh * 0.0455)
network   = round(kwh * 0.1285)
retail    = kwh > threshold ? 10 : 0
eei       = round(kwh * eeiSen(kwh) / 100)
net       = energy + afa + capacity + network + retail - eei
kwtbb     = kwh > 300 ? round((energy + capacity + network - eei) * 0.016) : 0
sst       = kwh > threshold
              ? round((taxableValueOfEnergy + capacity + network
                       + afa + retail - taxableEEI) * 0.08)
              : 0
total     = round(net + kwtbb + sst)
```

The full taxable-slice calculation lives in `tariff_rates.dart` and is covered by tests against TNB's calculator.

EEI band lookup (`eeiBands`): 17 bands from `≤200 kWh → 25.0 sen` down to `≤1000 kWh → 0.5 sen`, then no rebate above 1000 kWh. The rebate is applied to the **entire month's kWh**, not incrementally.

## 3. Tariff data

- Bundled fallback: `assets/tariff/domestic_general.json`.
- Published source: Firestore `tariffs/domestic_general`.
- `TariffRepository` prefers Firestore, then the bundled asset, then the compiled fallback.
- `main()` loads and applies the schedule before the first calculation.
- AFA is keyed by billing month (`afaByMonth`), so historical bills use the rate that applied then.
- `functions/syncAfaRates` refreshes declared AFA values monthly from TNB's public tariff page; `npm run seed:tariff` seeds the base schedule.

## 4. AFA (Automatic Fuel Adjustment)

- Published monthly by TNB; it can be a rebate (negative) or a surcharge.
- The schedule carries the published rate per month. `TariffRates.calculate` uses it automatically; pass `afaSenPerKwh: 0` to exclude it explicitly.
- Domestic usage at or below the protection threshold is exempt.
- The AFA line appears in the bill breakdown only when it is chargeable and non-zero.
- Forecast values (future months) are marked `status: forecast` in the schedule.

## 5. Reading chain

Handled by `lib/services/billing/reading_chain_service.dart`.

- Readings form a global, date-ordered chain across **all** months.
- `findPrevious` / `findNext` return true neighbors from Firestore (not just in-memory).
- When a reading is inserted/edited/deleted, the **next** reading's `kwh` must be recomputed as `next.reading - previous.reading`.
- If a deleted/replaced reading was the baseline, the next reading becomes the new baseline (`kwh = 0`).
- Invariant enforced: `next.reading >= previous.reading`, else `StateError`.
- `tier` is recomputed with `TariffRates.getTier(newKwh)` (the EEI band).

## 6. Bill recalculation

Handled by `lib/services/billing/bill_recalculation_service.dart`.

- One bill doc per month at `users/{uid}/bills/{YYYY-MM}`.
- `recalculateMonth` sums all readings in the month and upserts `kwh`, `amount`, `tier`, `date`.
- If the month has **no readings**, the bill doc is **deleted**.
- Called after add/update/delete of a reading, and for the neighboring month if a chain fix crosses a month boundary.
- `alertTierSent` is preserved via `SetOptions(merge: true)`.

## 7. Worked examples

### Domestic, 300 kWh

```
energy   300 * 0.2703 = 81.09
capacity 300 * 0.0455 = 13.65
network  300 * 0.1285 = 38.55
eei      300 * 0.2250 = 67.50   (band ≤300 kWh → 22.5 sen)
net      81.09 + 13.65 + 38.55 - 67.50 = 65.79
kwtbb    0            (needs > 300 kWh)
sst      0            (below the protection threshold)
total    RM 65.79
```

### Domestic, 700 kWh (Jan 2027, after the 800 kWh relief)

```
energy   700 * 0.2703 = 189.21
capacity 700 * 0.0455 = 31.85
network  700 * 0.1285 = 89.95
retail   10.00
afa      700 * 0.0759 = 53.13   (Jan 2027 published rate)
eei      700 * 0.0550 = 38.50   (band ≤700 kWh → 5.5 sen)
net      189.21 + 31.85 + 89.95 + 10 + 53.13 - 38.50 = 335.64
kwtbb    (189.21 + 31.85 + 89.95 - 38.50) * 0.016 = 4.36
sst      (27.03 + 4.55 + 12.85 + 7.59 + 10 - 5.50) * 0.08 = 4.52
total    RM 344.52
```

For Oct 2026 (800 kWh relief), 700 kWh has no retail, AFA or SST: **RM 276.87**.

## 8. Edge cases & invariants

- `kwh <= 0` → calculate returns `0`; breakdown returns `[]`.
- EEI rebate disappears above 1000 kWh; `EeiBand.number == 0` means "no rebate", which is also used for >1000 kWh (not "no usage").
- Deleting all readings in a month deletes that month's bill.
- Each charge line is rounded to sen before totalling, matching TNB's calculator.

## 9. When TNB changes rates

1. Update `assets/tariff/domestic_general.json` and the matching `DomesticTariff.fallback` values.
2. Publish to Firestore with `npm run seed:tariff` (in `functions/`), or edit `tariffs/domestic_general` directly.
3. Add or update the golden tests in `test/constants/tariff_rates_test.dart`.
4. AFA is refreshed monthly by the `syncAfaRates` Cloud Function; no app release is needed.
