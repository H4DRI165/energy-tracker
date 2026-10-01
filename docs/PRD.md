# Product Requirements Document (PRD) — Energy Tracker

- **Status:** Approved
- **Platform:** Android (mobile, portrait)
- **Version documented:** app `0.5.7+1`
- **Last updated:** 2026-10-02

---

## 1. One-liner

A Flutter mobile app that helps Malaysian TNB electricity customers log meter readings, estimate their bill from real TNB tariff rates, track usage over time, and stay within a monthly budget.

## 2. Problem

TNB customers, especially in Malaysia, struggle to:

- Predict what their next bill will cost before it arrives.
- Understand why a bill changed (tariff components, EEI rebate, usage tier).
- Track usage over time without manually reading the meter and doing math.
- Stay within a monthly electricity budget.

The TNB e-bill shows a final number but does not help users *plan* or *change behavior during the month*.

## 3. Vision / north star

> "Never get surprised by your electricity bill again."

Give a household or small business a trustworthy, low-effort estimate of the running bill from a single meter reading, and turn that estimate into actionable budget feedback.

### Positioning

Positioning is **combined** — the three framings reinforce each other and all are real features:

> **Headline:** "Track, estimate, and understand your TNB bill."
>
> - **Bill estimator** — the core value (kWh → RM using real TNB rates).
> - **Budget tracker** — turns the estimate into behaviour (80%/100% alerts).
> - **Tariff education tool** — the calculator and breakdown explain *why* the bill is what it is.

For the **portfolio audience**, the headline is different and should lead with craft:

> "A production-quality Flutter app that implements real TNB tariff logic end-to-end — billing engine, data integrity, push notifications, and CI/CD."

## 4. Goals

1. **Accurate estimation** — convert a meter reading delta into an itemized RM estimate using current TNB tariff components.
2. **Low-friction tracking** — adding a reading takes seconds; the app does the kWh and cost math.
3. **Budget awareness** — show progress toward a monthly budget and alert before/after exceeding it.
4. **Historical insight** — monthly/yearly usage charts and per-month bill history.
5. **Appliance-level awareness** — estimate what individual appliances cost per month.
6. **Trust** — correct handling of edits/deletes (recompute dependent bills) and honest disclaimers (AFA excluded).

## 5. Non-goals

- Not a payment app — no TNB bill payment, no bank/wallet integration.
- Not a real-time smart-meter integration — readings are manual.
- Not multi-utility — electricity only (no water/gas/internet).
- Not multi-country — TNB tariffs (Malaysia) only.
- **Android only** for the foreseeable future; iOS is not a target. Web/desktop are not targets. (Portrait-only mobile.)
- No social features.
- **Not a monetized product** — it is a portfolio piece, not a business.

## 6. Target users

Energy Tracker is portfolio-first. The primary audience is the portfolio reviewer; the target end user is a Malaysian domestic TNB customer. Commercial accounts are supported but are not the focus.

| Priority | Persona | Description | What they need |
|---|---|---|---|
| **1** | **The portfolio reviewer** | Recruiter / senior engineer / collaborator evaluating the project | Clean architecture, working APK, readable docs, evidence of product thinking |
| **2** | **The budget-conscious homeowner** | Malaysian household (Tariff A), wants no bill shock | Quick reading log, clear RM estimate, budget alerts |
| **3** | **The small-business operator** | Shop/office on Non-Domestic LV (Tariff B) | Commercial tariff estimate, usage history |

Design priorities:
- Optimise the **reviewer experience** (README, docs, APK, code quality, tests) without neglecting real usability.
- The **homeowner** is the design target for flows and copy.
- **Commercial** must remain correct but does not need dedicated UX investment.

## 7. Success metrics

Success is measured in two layers: portfolio outcomes first, product health second.

### Layer A — Portfolio success (primary)

- A signed, installable **release APK** is always downloadable.
- The GitHub repo shows **clean architecture, meaningful tests, and readable docs**.
- `flutter analyze` reports **no new issues**; billing logic has unit-test coverage.
- A reviewer can go from install → log reading → see estimate in **under 2 minutes**.

### Layer B — Product health (secondary, instrumented)

| Metric | Definition | Target (initial) |
|---|---|---|
| Activation | % of registrations that complete onboarding | ≥ 70% |
| Habit | Median readings logged per active user / month | ≥ 2 |
| Retention | 4-week retention | "improving", no hard target |
| Reliability | Crash-free sessions | ≥ 99% |
| Estimate trust | % of months where estimate is within accuracy bar (§11) | ≥ 95% |

### Recommended Analytics events

Firebase Analytics is already integrated, but only auto events exist. Add a small, deliberate set (privacy-safe, no PII):

```
onboarding_completed         { tariff_type }
reading_logged               { tariff_type, is_edit }
budget_alert_received        { tier: 80|100 }
budget_alert_opened          { tier }
bill_marked_paid
tariff_calculator_used       { tariff_type }
appliance_added              { category }
profile_updated
```

Guidance:
- Do **not** log meter values, TNB account numbers, email, or names.
- Prefer a handful of high-signal events over exhaustive screen tracking.
- Use these to validate Layer B only; do not let instrumentation delay portfolio work.

## 8. Scope

### In scope (v0.5.x)

- Email/password + Google authentication, password reset.
- First-run onboarding: tariff type + monthly budget.
- Dashboard: estimated bill, budget progress, 7-day chart, saving tips.
- Meter readings: add / edit / delete, with chain re-computation.
- Bill detail: itemized breakdown, paid toggle, readings list.
- Usage: monthly/yearly chart, bill history, delete month.
- Appliances: CRUD + monthly cost estimate.
- Settings: profile, tariff, budget, sign out, app version.
- Tariff calculator (standalone).
- Push notifications: budget threshold (80/100%) + end-of-month reminder.
- Observability: Crashlytics, Analytics, App Check.

### Out of scope / WIP

**Next milestone — build these:**

- In-app notification settings section (currently commented out; prefs live in a dashboard sheet).
- Terms of Service / Privacy Policy screens (referenced in register, not built).
- Guest mode (`isGuest` field exists, no flow yet).

**Deliberately out of scope:**

- Bill scanning via camera/AI (route exists as "Coming Soon"; not a priority).

> Dependency note: notification settings must first resolve the field-name mismatch in [DATA_MODEL.md](DATA_MODEL.md#known-issues) (#2), otherwise the toggles will not affect real alerts.

## 9. Key user journeys

1. **First run:** splash → landing → sign in/register → onboarding (tariff + budget) → dashboard.
2. **Log a reading:** dashboard/tab → Add Reading → enter reading + date → auto-calc kWh/cost → save → dashboard + usage refresh.
3. **Understand a bill:** usage → bill history → bill detail → itemized breakdown + readings → mark paid.
4. **Fix a mistake:** bill detail → swipe a reading → delete/edit → dependent kWh + bills recompute.
5. **Set budget:** onboarding or settings/dashboard → budget sheet → confirm → alert thresholds active.
6. **Convert a number:** settings → tariff calculator → enter kWh → see breakdown for either tariff.

## 10. Functional requirements (summary)

Detailed inventory is in [FEATURES.md](FEATURES.md).

- **FR-1 Auth:** users can register (name, email, 12-digit TNB account, password), sign in, sign in with Google, and reset password.
- **FR-2 Onboarding:** users choose domestic/commercial and set a monthly budget (RM 50–300 in onboarding; RM 50–500 in settings).
- **FR-3 Readings:** users log a monotonic meter reading per date; app computes kWh delta vs previous reading and estimated cost.
- **FR-4 Integrity:** editing/deleting a reading fixes the next reading's kWh and recalculates affected monthly bills.
- **FR-5 Bills:** the app maintains one bill document per user per month (sum of kWh, amount, tier, tariff).
- **FR-6 Budget:** app tracks budget % used and can alert at 80% and 100%.
- **FR-7 Usage:** app shows monthly/yearly kWh charts and bill history; deleting a month removes its readings and bill.
- **FR-8 Appliances:** users manage appliances and see estimated monthly kWh/cost.
- **FR-9 Tariff calc:** users can compute a bill breakdown for any kWh amount.
- **FR-10 Notifications:** budget alerts and monthly reminders; per-user toggles for 80/100%.

## 11. Constraints & domain rules

- Tariff figures reflect **post-1 July 2025** TNB rates and are hard-coded in `lib/constants/tariff_rates.dart`.
- **AFA** (Automatic Fuel Adjustment) is intentionally **excluded** from estimates because TNB republishes it monthly.
- Meter readings must be **monotonically increasing** within the chain (a reading cannot be lower than the previous one).
- A billing month must not mix tariff types.
- Estimates are labelled as estimates, not official TNB invoices.
- **Accuracy bar:** the estimate should match a real TNB bill within **±5%**, measured **excluding AFA**, across the validated sample set (300 / 600 / 900 / 1100 / 1600 kWh). See [Accuracy](#accuracy-note) for why AFA matters.
- **Data retention:** raw readings are retained for **12 months**, then deleted. See [§15 Data & Privacy](#15-data--privacy).

### Accuracy note

The billing formula is deterministic, so excluding AFA the estimate should be **~exactly** right. The real risk to a 95% target is AFA:

- AFA is 0 ≤ 600 kWh, but around **2.59 sen/kWh** above 600 kWh (June 2026 example).
- On a 700 kWh month that is ~RM 18 (~6% of the bill) — enough to blow the ±5% band on its own.

Recommendation:
1. Define the accuracy bar as **±5% excluding AFA**, and state that prominently in the UI (already partly done via disclaimers).
2. For high-usage customers, add an optional **"current AFA rate" setting** (the user enters the monthly figure from their TNB bill). This is the most impactful single accuracy improvement.
3. Add a `tariff_rates_test.dart` case per sample kWh so the bar is enforced by tests, not hopes.

## 12. Release & versioning

- `pubspec.yaml` version drives the build (currently `0.5.7+1`).
- CI builds a release APK on every push to `main` and publishes a GitHub Release tagged `v<run_number>`.
- See [DEVELOPMENT.md](DEVELOPMENT.md#build--release) for the release mechanics.

---

## 13. Operating Assumptions

1. The project is primarily a **portfolio piece** that is also **genuinely usable**.
2. English is the only language; currency is RM (Malaysian Ringgit).
3. Dark theme only is intentional.
4. Manual meter entry is acceptable; smart-meter integration is future scope.
5. Android is the only target platform.
6. There is no monetization; the app is free and not a business.

## 14. Product Decisions

Captured 2026-10-02.

| # | Question | Decision |
|---|---|---|
| 1 | Primary audience | **Portfolio reviewers first**; target end user is the Malaysian domestic TNB customer. Commercial supported, not a focus. |
| 2 | Monetization | **None.** Portfolio piece, free. |
| 3 | Positioning | **Combined:** "Track, estimate, and understand your TNB bill" (estimator + budget tracker + tariff education). |
| 4 | Platform priority | **Android only.** iOS/web/desktop are non-goals. |
| 5 | Accuracy bar | **±5% excluding AFA** on validated samples. Optional "current AFA rate" setting recommended. See §11. |
| 6 | Next WIP features | **In-app notification settings, ToS/Privacy, guest mode.** Bill scanning is out of scope. |
| 7 | Analytics | Optional; define a small privacy-safe event set (see §7). |
| 8 | Data & privacy | Retain raw readings **12 months**, then delete. See §15. |

New decisions are appended to this table as they are made.

---

## 15. Data & Privacy

### What "data & privacy" means here

It answers four things about the data the app stores:

1. **What** personal/sensitive data is stored.
2. **Who** can access it.
3. **How long** it is kept (retention).
4. **How** a user can get it deleted.

In short: it is mainly about **when data is deleted**, plus a clear statement of the four points above.

### What the app stores (today)

| Data | Where | Sensitivity |
|---|---|---|
| Email, display name | `users/{uid}`, Firebase Auth | PII |
| TNB account number (12 digits) | `users/{uid}` | Sensitive identifier |
| Meter readings (usage) | `users/{uid}/readings` | Usage data (can reveal occupancy habits) |
| Monthly bills (derived) | `users/{uid}/bills` | Usage data |
| Appliances / budget | `users/{uid}/appliances`, profile | Low |
| Profile photo | Firebase Storage `users/{uid}/…` | PII |
| FCM token | `users/{uid}` | Device identifier |

### Policy

- **Retention:** raw readings are kept for **12 months**, then deleted.
- **Bills:** because bills are derived from readings and only 12 months are shown, delete the matching month bill when its readings age out (keeps history consistent with the 12-month chart).
- **Account deletion:** a user can delete their account, which removes all their data (see below).
- **No selling / no third-party sharing** beyond the Firebase services used to run the app.
- **Never log** readings, TNB account numbers, email, or names to Analytics/Crashlytics.

### How to implement retention

Two viable options:

1. **Firestore TTL policy** — write an `expireAt` timestamp on each reading (`date + 12 months`) and enable a TTL policy on the `readings` collection group. Pros: no code to maintain. Cons: TTL deletion is eventual (not exact) and does not delete the derived bill docs.
2. **Scheduled Cloud Function** (recommended, consistent with the existing monthly reminder) — once a month, query `readings` with `date < now - 12 months` and batch-delete them, then delete/refresh the corresponding `bills/{YYYY-MM}` docs. Pros: precise, handles bills, easy to reason about for reviewers.

Also recommended for a public release:

- **Account deletion flow** ("Delete account" in Settings) that removes subcollections + user doc + FirebaseAuth user. Google Play requires this for published apps.
- **`firestore.rules` committed to the repo** restricting `users/{uid}/**` to the authenticated owner. Rules are currently not version-controlled (see `DATA_MODEL.md` #5).
- A short **privacy policy** (screen planned for the next milestone) stating: what is stored, 12-month retention, account deletion, and the Firebase services used.

---

## 16. Roadmap

Ordered so each milestone de-risks the next. (UX details live in [ux-review/](../ux-review/README.md).)

| Milestone | Theme | Contents | Status |
|---|---|---|---|
| **M0** | Core app | v0.5.7 feature set + Critical UX fixes (C1 raw error, C2 disabled CTAs) | Done |
| **M1** | Trust & accessibility | ux-review Milestones 1–2 (copy honesty H4–H7, contrast H1, semantics/touch targets H3) | Next |
| **M2** | WIP features | Notification settings (fix field mismatch first), ToS/Privacy screens, guest mode | Planned |
| **M3** | Accuracy | Optional current-AFA-rate setting; per-sample accuracy tests; prominent "excl. AFA" labelling | Planned |
| **M4** | Privacy & compliance | 12-month retention job, account deletion flow, `firestore.rules`, privacy policy | Planned |
| **M5** | Polish | Remaining UX consistency/loading/error items; copy centralization | Planned |

Rationale:
- **M1 before M2:** the WIP screens will reuse the accessibility and copy patterns fixed in M1.
- **M2 before M3/M4:** ship the promised features; then harden correctness and privacy.
- **M4 demonstrates privacy engineering:** retention, deletion, and access rules are handled the way production apps handle them.
