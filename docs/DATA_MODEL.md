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

## 2. `users/{uid}`

| Field | Type | Default / notes | Written by |
|---|---|---|---|
| `uid` | string | Same as doc id | register |
| `fullName` | string | — | register, edit profile |
| `email` | string | From FirebaseAuth | register |
| `tnbAccountNo` | string | 12 digits | register, edit profile |
| `tariffType` | `"domestic"` \| `"commercial"` | `"domestic"` | register, onboarding, settings |
| `monthlyBudget` | number | `150` | register, onboarding, settings |
| `onboardingCompleted` | bool | `false` | register, onboarding |
| `createdAt` | timestamp | server | register |
| `updatedAt` | timestamp | server | register, onboarding, settings, edit profile |
| `isGuest` | bool | `false` | register (no flow yet) |
| `fcmToken` | string | — | notification service; deleted on logout/account switch |
| `alert80Enabled` | bool | `true` | dashboard notification sheet |
| `alert100Enabled` | bool | `true` | dashboard notification sheet |
| `photoUrl` | string | — | edit profile |
| `photoUpdatedAt` | timestamp | — | edit profile |
| `photoURL` | null | — | register (legacy/inconsistent — see §5) |
| `budgetAlertsEnabled` | bool | read as `true` | **settings model only — no writer** |
| `billRemindersEnabled` | bool | read as `true` | **settings model only — no writer** |
| `monthlySummaryEnabled` | bool | read as `true` (profile) / `false` (settings) | **no writer** |

## 3. `users/{uid}/readings/{autoId}`

| Field | Type | Notes |
|---|---|---|
| `reading` | number | Raw meter value (not a delta) |
| `kwh` | number | Delta vs previous reading for that date |
| `date` | timestamp | Reading date |
| `notes` | string | Optional user note |
| `tier` | number | EEI band number (domestic) or tier (commercial) at time of reading |
| `tariffType` | string | Tariff at creation; preserved for history |
| `createdAt` | timestamp | Set on create only (preserved on edit) |

> `ReadingRecord.estimatedBill` and `ReadingRecord.tierLabel` exist in the model, but the add/update path does not persist `estimatedBill`. Treat it as effectively unused; no writer exists.

## 4. `users/{uid}/bills/{YYYY-MM}`

Doc id is the month key, e.g. `2026-07`.

| Field | Type | Notes |
|---|---|---|
| `kwh` | number | Sum of that month's reading kWh |
| `amount` | number | `TariffRates.calculate(kwh, tariffType)` |
| `tier` | number | Tier/band for the month total |
| `tariffType` | string | Resolved from the latest reading that month |
| `date` | timestamp | Start of the month |
| `isPaid` | bool | Toggled from bill detail (updates all docs for the month) |
| `alertTierSent` | number | `0` \| `80` \| `100`; alert reservation (Cloud Function only) |

Bills are **derived, not authored**: `BillRecalculationService.recalculateMonth` upserts the doc from current readings, and deletes it if the month has no readings.

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
- EEI band / commercial tier for a running kWh total.
- 7-day and 12-month usage series.

## 7. Known issues

| # | Issue | Impact | Suggested fix |
|---|---|---|---|
| 1 | `photoURL` (register) vs `photoUrl` (edit/settings) | Avatar reads/writes use different keys; register's null is harmless today but confusing | Standardize on `photoUrl` everywhere |
| 2 | Notification toggles: functions + sheet use `alert80Enabled`/`alert100Enabled`; settings model reads `budgetAlertsEnabled`/`billRemindersEnabled` | Re-enabling the settings notification section would write fields nothing reads, so toggles would do nothing | Use `alert80Enabled`/`alert100Enabled` in settings, or add a migration |
| 3 | `monthlySummaryEnabled` default differs (`true` in `UserProfile`, `false` in settings) and has no writer | Dead/contradictory config | Pick one default or remove |
| 4 | No `schemaVersion` field | Hard to migrate safely later | Add `schemaVersion` on the user doc |
| 5 | Firestore security rules are not in the repo (`firebase.json` lists only Functions) | Rules live only in the console; unreviewable and unreproducible | Add `firestore.rules` + reference it in `firebase.json` and CI |
| 6 | `estimatedBill` on readings is modeled but never written | Possible source of confusion | Remove from model or start writing it |
| 7 | Bills stored per reading-total; deleting all readings deletes the bill | Historical "paid" state is lost with the month | If history matters, soft-delete instead |

## 8. Indexing notes

Queries filter on `date` with `orderBy('date')` (range + order on the same field) — served by the default single-field index. The monthly reminder queries bills by document id, so no composite index is required. Multi-field filters (e.g. `tariffType` + `date`) require a composite index.

## 9. Retention & deletion (planned)

Policy ([PRD.md](PRD.md) §15): **raw readings are retained for 12 months, then deleted**, along with their derived monthly bill docs.

Recommended implementation:
- A monthly scheduled Cloud Function (mirrors `sendMonthlyReadingReminder`) that deletes `readings` with `date < now - 12 months` in batches and clears the matching `bills/{YYYY-MM}`.
- Alternatively, write an `expireAt` field per reading and enable a Firestore TTL policy (eventual deletion; does not cover bills).
- Add a user-facing **Delete account** action that removes all subcollections, the user doc, and the FirebaseAuth user.
- Commit `firestore.rules` restricting `users/{uid}/**` to the authenticated owner.

When this ships, update the field tables above to include any new `expireAt` field.
