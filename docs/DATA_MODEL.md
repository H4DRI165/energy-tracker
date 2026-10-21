# Data Model

- **Status:** Current
- **Database:** Cloud Firestore
- **Root collection:** `users`

## 1. Tree

```text
users/{uid}
  readings/{autoId}
  bills/{YYYY-MM}
  appliances/{autoId}

tariffs/domestic_general
```

Avatars are stored in Firebase Storage under `users/{uid}/`.

## 2. `users/{uid}`

| Field | Type | Notes |
|---|---|---|
| `uid` | string | Same as the document ID |
| `fullName` | string | Google display name or registration name |
| `email` | string | Firebase Auth email |
| `tnbAccountNo` | string | 12 digits for email registration; may be empty for Google users until edited |
| `monthlyBudget` | number | Defaults to 150; editable in onboarding/settings |
| `onboardingCompleted` | bool | Router gate |
| `createdAt` | timestamp | Server timestamp |
| `updatedAt` | timestamp | Server timestamp |
| `fcmToken` | string | Present after the profile exists |
| `alert80Enabled` | bool | Budget alert preference, default true |
| `alert100Enabled` | bool | Budget alert preference, default true |
| `photoUrl` | string | Optional profile image |
| `photoUpdatedAt` | timestamp | Optional profile image version |

### Profile creation paths

- **Email registration:** creates the full profile immediately, then onboarding
  updates the budget and completion flag.
- **Google sign-in:** Firebase Auth creates the account first. Onboarding
  creates the required profile fields and then syncs the FCM token.

The create rule requires `uid`, `fullName`, `email`, `tnbAccountNo`,
`monthlyBudget` and `onboardingCompleted`.

## 3. Readings

`users/{uid}/readings/{autoId}`

| Field | Type | Notes |
|---|---|---|
| `reading` | number | Raw cumulative meter value |
| `kwh` | number | Delta since the previous reading |
| `date` | timestamp | Reading date |
| `periodStart` | timestamp | Previous reading date; absent/null for a baseline |
| `tier` | number | EEI band snapshot for display |
| `notes` | string | Optional |
| `createdAt` | timestamp | Creation only |

`ReadingRecord.estimatedBill` exists in the model but is not written by the
current add/edit flow.

## 4. Bills

`users/{uid}/bills/{YYYY-MM}`

| Field | Type | Notes |
|---|---|---|
| `kwh` | number | Monthly allocated usage |
| `amount` | number | Tariff estimate for that month |
| `tier` | number | Monthly EEI band |
| `isEstimated` | bool | True when a long interval contributed |
| `date` | timestamp | First day of the month |
| `alertTierSent` | number | `0`, `80` or `100`; Cloud Function reservation |

Bills are denormalized and can be rebuilt from readings.

## 5. Appliances

`users/{uid}/appliances/{autoId}`

| Field | Type | Notes |
|---|---|---|
| `name` | string | Display name |
| `category` | string | Appliance category |
| `wattage` | number | Rated watts |
| `dailyHours` | number | Typical use per day, 0–24 |
| `createdAt` / `updatedAt` | timestamp | Server timestamps |

Appliance costs are estimates only and never the TNB bill.

## 6. Tariff schedule

`tariffs/domestic_general` is read-only to clients. It contains base rates,
protection periods, EEI bands, monthly AFA values and an updated timestamp.
Writes are restricted to Admin SDK/seed tooling.

## 7. Security rules

Rules live in `firestore.rules` and are deployed with:

```bash
firebase deploy --only firestore:rules
```

Summary:

- All user data requires `request.auth.uid == uid`.
- User profile create requires the full identity fields listed above.
- User profile update requires `uid` equal to the path UID and a numeric
  non-negative budget.
- Readings require numeric reading, kWh and timestamp.
- Bills require numeric kWh/amount; clients cannot write `alertTierSent`.
- Appliances require valid name/category/wattage/daily-hours values.
- Tariff reads are public; writes are denied.

## 8. App Check

Firebase App Check is initialized in `main.dart` with the debug provider in
debug builds and Play Integrity in release. Firestore enforcement is currently
**unenforced**.

Before enabling enforcement:

1. Register the debug token / verify Play Integrity.
2. Test release and debug builds.
3. Enable Firestore enforcement in Firebase Console.
