# Billing and Tariff

- **Status:** Current
- **Code:** `lib/constants/tariff_rates.dart`, `lib/services/billing/*`
- **Tariff:** TNB Domestic General, effective 1 July 2025

Energy Tracker is an estimator, not an official TNB invoice.

## 1. Bill components

| Component | Rate / rule |
|---|---|
| Energy | 27.03 sen/kWh up to 1,500 kWh; 37.03 sen/kWh above 1,500 kWh applied to all kWh |
| Capacity | 4.55 sen/kWh |
| Network | 12.85 sen/kWh |
| Retail | RM 10/month, only above the protection threshold |
| AFA | Published monthly; only above the protection threshold |
| EEI | Rebate from the 17-band table; applies to the whole month’s kWh |
| KWTBB | 1.6% of Energy + Capacity + Network − EEI; only above 300 kWh |
| SST | 8% of the taxable slice above the protection threshold |

**Protection threshold:** 600 kWh normally, 800 kWh from September to December
2026.

## 2. Calculation

```text
threshold  = 600 or 800 kWh for the billing month
taxable    = max(0, kwh - threshold)
nonTaxable = kwh - taxable

energy     = round(nonTaxable × energyRate) + round(taxable × energyRate)
capacity   = round(nonTaxable × 0.0455) + round(taxable × 0.0455)
network    = round(nonTaxable × 0.1285) + round(taxable × 0.1285)
retail     = taxable > 0 ? 10 : 0
afa        = taxable > 0 ? kwh × publishedAfaRate : 0
eei        = kwh × currentEeiRate
net        = energy + capacity + network + retail + afa - eei
kwtbb      = kwh > 300 ? (energy + capacity + network - eei) × 0.016 : 0
sst        = taxable > 0 ? taxable-slice value × 0.08 : 0
total      = net + kwtbb + sst
```

Values are rounded to sen using the same half-away-from-zero behaviour as TNB.
The calculation mirrors TNB’s threshold split so the estimate matches its
calculator to the sen.

## 3. EEI bands

The EEI rate is selected from whole-month kWh and applied to every kWh, not just
the marginal portion. Bands run from 25 sen/kWh at ≤200 kWh down to 0.5
sen/kWh at ≤1,000 kWh. Above 1,000 kWh there is no rebate.

## 4. Breakdown display

`TariffRates.domesticBreakdown` is shared by Usage, Bill Detail and the Tariff
Calculator. It deliberately returns every TNB calculator row, including zero
rows:

- Energy
- Forecast AFA for the current month
- Forecast AFA for the next month (reference only, amount RM 0.00)
- Capacity
- Network
- Retail
- Energy Efficiency Incentive
- Service Tax (ST) (8%)
- KWTBB (1.6%)

The next-month AFA row is informational and is never included in the total.
Keeping zero rows visible makes the app’s breakdown match what users see on the
TNB calculator.

## 5. Readings are intervals

A reading is not a monthly total. Its `kwh` is the delta since the previous
reading:

```text
periodStart = previous reading date (or explicit stored period start)
periodEnd   = this reading date
kwh         = current meter value - previous meter value
```

`UsageAllocationService` spreads each interval across the calendar months it
overlaps, proportional to days. This prevents a missed reading from dumping a
six-month gap into one month.

- Intervals longer than 35 days are marked estimated.
- Months containing estimated shares are marked in charts and bill detail.
- First readings are baselines with zero usage.
- Same-day readings attribute their delta to that day.

The Add Reading preview uses `UsageAllocationService.monthShareForInterval` for
the new interval and the same monthly allocation path as Usage for existing
month-to-date usage. This keeps the preview and saved bill consistent, including
same-day readings.

## 6. Reading edits and bill recalculation

Readings form a global date-ordered chain. After an insert, edit or delete:

1. Find the previous and next reading globally.
2. Recompute the next reading’s kWh and EEI tier.
3. Update `periodStart` where needed.
4. Recalculate every month touched by the affected intervals.
5. Upsert or delete the corresponding `bills/{YYYY-MM}` documents.

Deleting a baseline promotes the next reading to baseline (`kwh: 0`).

## 7. AFA

AFA is stored by month in the tariff schedule and can be a surcharge or rebate.
Published values are used for historical months; future months may be marked
forecast. If a month has no published value, the app uses 0 and displays the
current schedule’s disclaimer.

## 8. Tests

`test/constants/tariff_rates_test.dart` covers domestic totals, threshold
windows, EEI boundaries, zero-value breakdown rows and TNB calculator samples.
`test/services/billing/*` covers interval allocation and bill recalculation.
