# Product Requirements

## 1. Summary

Energy Tracker helps Malaysian domestic TNB customers understand and plan their
electricity bill. Users log meter readings manually; the app turns the deltas
into monthly usage, an itemised domestic-tariff estimate, and budget feedback.

The product is also a portfolio project: the implementation favours clear
architecture, reliable billing logic and maintainable Flutter code.

## 2. Problem

TNB customers often see only the final bill amount. They cannot easily answer:

- How much electricity have I used so far this month?
- What will my bill be if usage continues at this pace?
- Which part of the bill is usage, rebates, levies or tax?
- Which appliances are driving the cost?
- How close am I to my monthly budget?

## 3. Target user

- Malaysian household on the domestic TNB tariff.
- Uses a conventional meter and records readings manually.
- Wants a quick, trustworthy estimate without connecting a smart meter.
- Values clear explanations over financial or payment features.

## 4. Goals

1. Make a reading-to-bill estimate understandable to a non-technical user.
2. Keep usage history correct when readings are edited, deleted or entered late.
3. Make budget status visible during the month, not only after the bill arrives.
4. Show appliance estimates with explicit uncertainty.
5. Remain usable offline for reading and viewing existing data where practical.
6. Provide a clean, testable codebase suitable for portfolio review.

## 5. Non-goals

- Commercial or industrial tariffs.
- TNB bill payment, banking or wallet integration.
- Smart-meter or live telemetry integration.
- Multi-country or multi-utility support.
- Bill scanning; that feature is not shipped.
- Real-time meter values.

## 6. Product principles

- **Estimates must look like estimates.** Never present an appliance or
  month-to-date value as the official TNB invoice.
- **Short UI, details on demand.** Show the important number first; explanations
  and assumptions can open in sheets or detail pages.
- **Reading edits must be safe.** Recalculate every affected month and preserve
  the reading chain.
- **Offline failures should be obvious.** Do not leave a spinner running
  indefinitely when a write cannot complete.

## 7. Core flows

### First use

Splash → landing → sign in or register → onboarding budget → dashboard →
add the first meter reading.

A Google account receives a Firestore profile during onboarding. Email
registration creates the profile immediately.

### Regular use

Dashboard → add reading → dashboard/usage refresh → inspect bill breakdown or
usage trend as needed.

### Understanding a bill

Dashboard → Usage/Bill detail → tap a charge for an explanation → optionally
open the tariff calculator.

## 8. Success signals

- A new user can add two readings and see a non-zero usage/bill.
- Editing or deleting a reading keeps later bills consistent.
- A user can explain the main bill components after using the breakdown.
- Budget alerts arrive once at 80% and once at 100% per bill.
- Release builds pass analysis and the billing test suite.

## 9. Roadmap

### Shipped

- Domestic tariff calculations, AFA, EEI, KWTBB and SST.
- Interval allocation across months and estimated-month markers.
- Auth, onboarding, dashboard, usage, devices, settings and calculator.
- Budget alerts, reading reminders and FCM token handling.
- Light/dark theme, offline write guards and release CI.

### Planned / intentionally not shipped

- Email verification flow.
- Terms of Service and Privacy Policy screens.
- Bill scanning / OCR entry.
- Integration and end-to-end tests.
