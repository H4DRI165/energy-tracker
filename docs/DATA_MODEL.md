# Data Model (Cloud Firestore)

- **Status:** Current
- **Last updated:** 2026-10-02
- **Root collection:** `users`

> Note: Firestore field names are **case-sensitive**. Inconsistencies below are real and can cause features to silently fail. They are listed in [Known issues](#known-issues).

## 1. Tree

```
users/{uid}
├── (profile fields, see §2)
├── readings/{autoId}      # one per meter reading
├── bills/{YYYY-MM}        # one per month, e.g. 2026-07
└── appliances/{autoId}    # one per appliance
```

Storage:

```
users/{uid}/profile_<millis>.jpg   # avatar (Firebase Storage)
```

Published reference data:

```
tariffs/domestic_general   # base rates, EEI bands, protection periods, AFA by month
```

## 2. `users/{uid}`

| Field | Type | Default / notes | Written by |
|---|---|---|---|
| `uid` | string | Same as doc id | register |
| `fullName` | string | — | register, edit profile |
| `email` | string | From FirebaseAuth | register |
| `tnbAccountNo` | string | 12 digits | register, edit profile |
| `monthlyBudget` | number | `150` | register, onboarding, settings |
| `onboardingCompleted` | bool | `false` | register, onboarding |
| `createdAt` | timestamp | server | register |
| `updatedAt` | timestamp | server | register, onboarding, settings, edit profile |
| `fcmToken` | string | — | notification service; deleted on logout/account switch |
| `alert80Enabled` | bool | `true` | dashboard notification sheet |
| `alert100Enabled` | bool | `true` | dashboard notification sheet |
| `photoUrl` | string | — | edit profile |
| `photoUpdatedAt` | timestamp | — | edit profile |
| `budgetAlertsEnabled` | bool | read as `true` | **settings model only — no writer** |
| `billRemindersEnabled` | bool | read as `true` | **settings model only — no writer** |
| `monthlySummaryEnabled` | bool | read as `true` (profile) / `false` (settings) | **no writer** |

Authentication is required; there is no guest profile variant.

## 3. `users/{uid}/readings/{autoId}`

| Field | Type | Notes |
|---|---|---|
| `reading` | number | Raw meter value (not a delta) |
| `kwh` | number | Delta vs previous reading for that date |
| `date` | timestamp | Reading date |
| `notes` | string | Optional user note |
| `tier` | number | EEI band at time of reading (display only) |
| `periodStart` | timestamp | Previous reading date; start of this interval (null for baseline) |
| `createdAt` | timestamp | Set on create only (preserved on edit) |

> `ReadingRecord.estimatedBill` and `ReadingRecord.tierLabel` exist in the model, but the add/update path does not persist `estimatedBill`. Treat it as effectively unused; no writer exists.

## 4. `users/{uid}/bills/{YYYY-MM}`

Doc id is the month key, e.g. `2026-07`.

| Field | Type | Notes |
|---|---|---|
| `kwh` | number | Sum of that month's reading kWh |
| `amount` | number | `TariffRates.calculate(kwh, billingMonth)` |
| `tier` | number | Tier/band for the month total |
| `isEstimated` | bool | True when the month includes a long-interval estimate |
| `date` | timestamp | Start of the month |
| `alertTierSent` | number | `0` \| `80` \| `100`; alert reservation (Cloud Function only) |

Bills are **derived, not authored**: `BillRecalculationService.recalculateRange` allocates reading intervals across the months they cover, upserts each month's doc, and deletes it if the month has no allocated usage.

## 5. `users/{uid}/appliances/{autoId}`

| Field | Type | Notes |
|---|---|---|
| `name` | string | |
| `category` | string | One of Cooling, Lighting, Kitchen, Entertainment, Washing, Heating, Other |
| `wattage` | number | Watts |
| `dailyHours` | number | Hours/day (0.5 steps) |
| `createdAt` | timestamp | Preserved on edit |

## 6. Derived values (not stored)

Computed on read from readings + profile:
- Current-month `kwhUsed`, `estimatedBill`, `dailyAvg`, projected bill.
- Budget status (`normal` / `warning`≥80% / `exceeded`≥100%).
- EEI band for a running kWh total.
- 7-day and 12-month usage series.

## 7. Known issues

| # | Issue | Impact | Suggested fix |
|---|---|---|---|
| 2 | Notification toggles: functions + sheet use `alert80Enabled`/`alert100Enabled`; settings model reads `budgetAlertsEnabled`/`billRemindersEnabled` | Re-enabling the settings notification section would write fields nothing reads, so toggles would do nothing | Use `alert80Enabled`/`alert100Enabled` in settings, or add a migration |
| 3 | `monthlySummaryEnabled` default differs (`true` in `UserProfile`, `false` in settings) and has no writer | Dead/contradictory config | Pick one default or remove |
| 4 | No `schemaVersion` field | Hard to migrate safely later | Add `schemaVersion` on the user doc |
| 5 | Firestore/Storage rules are in the repo but deployment is manual | A stale console ruleset can break tariff reads or avatar loading | Deploy `firestore.rules` and `storage.rules` with every rules change |
| 6 | `estimatedBill` on readings is modeled but never written | Possible source of confusion | Remove from model or start writing it |
| 7 | Bills stored per reading-total; deleting all readings deletes the bill | Historical bill records are lost with the month | If history matters, soft-delete instead |

## 8. Indexing notes

Queries filter on `date` with `orderBy('date')` (range + order on the same field) — served by the default single-field index. The monthly reminder queries bills by document id, so no composite index is required.

## 9. Retention & deletion (planned)

Policy ([PRD.md](PRD.md) §15): **raw readings are retained for 12 months, then deleted**, along with their derived monthly bill docs.

Recommended implementation:
- A monthly scheduled Cloud Function (mirrors `sendMonthlyReadingReminder`) that deletes `readings` with `date < now - 12 months` in batches and clears the matching `bills/{YYYY-MM}`.
- Alternatively, write an `expireAt` field per reading and enable a Firestore TTL policy (eventual deletion; does not cover bills).
- Add a user-facing **Delete account** action that removes all subcollections, the user doc, and the FirebaseAuth user.
- Commit `firestore.rules` restricting `users/{uid}/**` to the authenticated owner.

When this ships, update the field tables above to include any new `expireAt` field.

## 11. Published tariff data

`tariffs/domestic_general` is read-only reference data published by TNB and maintained by the `syncAfaRates` Cloud Function. It is not user data.

| Field | Type | Notes |
|---|---|---|
| `schemaVersion` | number | Must match the app's supported schema |
| `formulaVersion` | number | Tracks calculation-rule compatibility |
| `effectiveFrom` / `effectiveTo` | date string | Schedule validity |
| `energySenPerKwh` / `energyHighSenPerKwh` | number | Energy charge (sen/kWh) |
| `capacitySenPerKwh` / `networkSenPerKwh` | number | Flat charges (sen/kWh) |
| `retailRmPerMonth` | number | RM 10 |
| `kwtbbRate` / `sstRate` | number | Fractions |
| `baseProtectionThresholdKwh` | number | 600 normally |
| `protectionPeriods` | array | Temporary thresholds, e.g. 800 kWh Sep–Dec 2026 |
| `eeiBands` | array | `{maxKwh, senPerKwh}` sorted ascending |
| `afaByMonth` | map | `YYYY-MM → {senPerKwh, status}` |
| `source` / `updatedAt` | string / timestamp | Provenance |

The app prefers this document, then `assets/tariff/domestic_general.json`, then `DomesticTariff.fallback`.
