# Billing & Tariff Domain

- **Status:** Current
- **Source of truth in code:** `lib/constants/tariff_rates.dart`
- **Rates version:** post-1 July 2025 TNB restructuring

> Estimates exclude **AFA** by default. The app is an estimator, not the official TNB invoice.

## 1. Core concepts

- **Meter reading** — the raw cumulative number on the meter (never decreases).
- **kWh used** — the delta between a reading and the previous reading. This is what gets billed.
- **Tariff type** — `domestic` (Tariff A) or `commercial` (Non-Domestic LV, Tariff B).
- **EEI** — Energy Efficiency Incentive, a per-kWh rebate (domestic only uses a band table; commercial has a flat ≤200 kWh rebate).
- **Tier / Band** — usage bracket used for badges and color. Domestic now uses EEI bands (`EeiBand`), commercial keeps the old 2-tier int.

## 2. Domestic (Tariff A)

Rates (RM per kWh unless noted):

| Component | Rate | Condition |
|---|---|---|
| Energy | 0.2703 | total ≤ 1500 kWh |
| Energy | 0.3703 | total > 1500 kWh (applies to **all** kWh) |
| Capacity | 0.0455 | always |
| Network | 0.1285 | always |
| Retail | RM 10 | only when total > 600 kWh |
| AFA | published monthly | 0 by default; applies when total > 600 kWh |
| EEI rebate | 0.5–25 sen/kWh | lookup table, applies to **all** kWh; 0 above 1000 kWh |
| KWTBB | 1.6% of (Energy + Capacity + Network − EEI) | only when total > 300 kWh |
| SST | 8% of the net subtotal attributable to kWh above 600 | only when total > 600 kWh |

Formula (`_domesticCharges`, `tariff_rates.dart:288-314`):

```
energy   = kwh * (kwh > 1500 ? 0.3703 : 0.2703)
afa      = kwh > 600 ? kwh * afaRate : 0
capacity = kwh * 0.0455
network  = kwh * 0.1285
retail   = kwh > 600 ? 10 : 0
eei      = kwh * (eeiSen(kwh) / 100)
net      = energy + afa + capacity + network + retail - eei
kwtbb    = kwh > 300 ? (energy + capacity + network - eei) * 0.016 : 0
sst      = kwh > 600 ? net * ((kwh - 600) / kwh) * 0.08 : 0
total    = net + kwtbb + sst
```

EEI band lookup (`_eeiBands`, `tariff_rates.dart:240-258`): 17 bands from `≤200 kWh → 25.0 sen` down to `≤1000 kWh → 0.5 sen`, then no rebate above 1000 kWh. The rebate is applied to the **entire month's kWh**, not incrementally.

## 3. Commercial LV (Tariff B)

Rates:

| Component | Rate | Condition |
|---|---|---|
| Energy | 0.2703 | flat (no 1500 kWh crossover) |
| Capacity | 0.0883 | always |
| Network | 0.1482 | always |
| Retail | RM 20 | always |
| AFA | published monthly | excluded by default |
| EEI rebate | 11 sen/kWh | only when total ≤ 200 kWh |
| KWTBB | 1.6% of (Energy + Capacity + Network − EEI) | always (no threshold) |
| SST | not applicable | — |

Formula (`_commercialCharges`, `tariff_rates.dart:567-589`):

```
energy   = kwh * 0.2703
afa      = kwh * afaRate
capacity = kwh * 0.0883
network  = kwh * 0.1482
eei      = kwh <= 200 ? kwh * 0.11 : 0
net      = energy + afa + capacity + network + 20 - eei
kwtbb    = (energy + capacity + network - eei) * 0.016
total    = net + kwtbb
```

## 4. AFA (Automatic Fuel Adjustment)

- Republished by TNB every month, so it is **not** a hard-coded constant.
- `TariffRates.calculate(kwh, type, afaSenPerKwh: ...)` accepts it; all callers currently use the default `0`.
- The UI shows a disclaimer wherever AFA is excluded (`BillBreakdownCard`, usage summary, tariff calculator).

## 5. Reading chain

Handled by `lib/services/billing/reading_chain_service.dart`.

- Readings form a global, date-ordered chain across **all** months.
- `findPrevious` / `findNext` return true neighbors from Firestore (not just in-memory).
- When a reading is inserted/edited/deleted, the **next** reading's `kwh` must be recomputed as `next.reading - previous.reading`.
- If a deleted/replaced reading was the baseline, the next reading becomes the new baseline (`kwh = 0`).
- Invariant enforced: `next.reading >= previous.reading`, else `StateError`.
- `tier` is recomputed with `TariffRates.getTier(newKwh, tariffType)`.

## 6. Bill recalculation

Handled by `lib/services/billing/bill_recalculation_service.dart`.

- One bill doc per month at `users/{uid}/bills/{YYYY-MM}`.
- `recalculateMonth` sums all readings in the month, resolves the tariff from the **latest** reading (fallback to the caller's tariff), and upserts `kwh`, `amount`, `tier`, `tariffType`, `date`.
- If the month has **no readings**, the bill doc is **deleted**.
- Called after add/update/delete of a reading, and for the neighboring month if a chain fix crosses a month boundary.
- `isPaid` and `alertTierSent` are preserved via `SetOptions(merge: true)`.

## 7. Worked examples

### Domestic, 300 kWh

```
energy   300 * 0.2703 = 81.09
capacity 300 * 0.0455 = 13.65
network  300 * 0.1285 = 38.55
eei      300 * 0.2250 = 67.50   (band ≤300 kWh → 22.5 sen)
net      81.09 + 13.65 + 38.55 - 67.50 = 65.79
kwtbb    0            (needs > 300 kWh)
sst      0            (needs > 600 kWh)
total    RM 65.79
```

### Domestic, 700 kWh (shows Retail + SST)

```
energy   700 * 0.2703 = 189.21
capacity 700 * 0.0455 = 31.85
network  700 * 0.1285 = 89.95
retail   10.00
eei      700 * 0.0550 = 38.50   (band ≤700 kWh → 5.5 sen)
net      189.21 + 31.85 + 89.95 + 10 - 38.50 = 282.51
kwtbb    (189.21 + 31.85 + 89.95 - 38.50) * 0.016 = 4.36
sst      282.51 * (100/700) * 0.08 = 3.23
total    RM 290.10
```

### Commercial, 200 kWh

```
energy   200 * 0.2703 = 54.06
capacity 200 * 0.0883 = 17.66
network  200 * 0.1482 = 29.64
retail   20.00
eei      200 * 0.1100 = 22.00   (≤200 kWh)
net      54.06 + 17.66 + 29.64 + 20 - 22.00 = 99.36
kwtbb    (54.06 + 17.66 + 29.64 - 22.00) * 0.016 = 1.27
total    RM 100.63
```

(Values rounded for display; the code computes in full precision.)

## 8. Edge cases & invariants

- `kwh <= 0` → calculate returns `0`; breakdown returns `[]`.
- EEI rebate for domestic disappears above 1000 kWh; `EeiBand.number == 0` means "no rebate", which is also used for >1000 kWh (not "no usage").
- Mixing tariff types in one month is blocked (`_checkTariffConflict`), so a month's tariff is unambiguous.
- Deleting all readings in a month deletes that month's bill (and its paid state).

## 9. When TNB changes rates

1. Update the constants and `_eeiBands` in `lib/constants/tariff_rates.dart`.
2. Re-run the worked examples mentally or add a test; existing tests include `test/tariff_rates_test.dart`.
3. Update the tables in this doc and in the root README.
4. Note that AFA may need the current published rate passed in (currently defaults to 0).
