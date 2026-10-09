---
name: firebase-security
description: Use when writing or reviewing Firebase security rules, Cloud Functions, auth, secrets, App Check, or CI for the Energy Tracker app, or when applying OWASP Top 10 checks. Trigger on security, OWASP, firestore rules, storage rules, app check, auth, secrets, callable functions, vulnerability, or hardening.
---

# Energy Tracker — Firebase Security

Defense-in-depth for a personal/portfolio Flutter + Firebase app. Deny by
default.

## Golden rules

- **Deny by default.** Every rule path must explicitly allow; no wildcard-open
  rules.
- **Owner-scoped.** All user data readable/writable only when
  `request.auth.uid == uid`.
- **Validate schema in rules** (types, ranges, enums) — never trust client
  shapes.
- **Server-authoritative fields** (`alertTierSent`, `xp`, `unlockedBadges`,
  streaks): clients cannot write these; only Cloud Functions (admin SDK) may.
- **App Check enforced** for Firestore/Storage/Functions in release.
- **Client values are estimates.** Anything trusted/shared must be derived
  server-side.

## Firestore / Storage rules checklist

- `match /users/{uid}` and subcollections: `request.auth.uid == uid`.
- Create/update: validate required fields + types + ranges; reject unknown or
  server-managed fields.
- Storage: owner path, image content-type, max size.
- Add emulator tests for allow AND deny cases; run in CI.
- Rules live in-repo (`firestore.rules`, `storage.rules`) and deploy via CI —
  never console-only.

## Cloud Functions checklist

- Verify `context.auth` where the call is user-scoped.
- Idempotency for side-effecting/award flows (keys/transactions).
- Never leak internal errors to clients (safe, generic messages).
- Bound resource usage (`maxInstances`, timeouts).

## Secrets & supply chain

- Secrets only via gitignored files / CI secrets; never in client bundles.
- Firebase API keys are NOT secrets — protect via rules + App Check + API key
  restriction.
- Pin GitHub Actions to commit SHAs; enable Dependabot + CodeQL; audit pub/npm
  deps.

## OWASP Top 10:2025 quick-map

- A01 access control → rules
- A02 misconfig → App Check / key restriction
- A03 supply chain → pinned actions + scanners
- A04 crypto → TLS + secure storage
- A05 injection → structured queries + validation
- A06 insecure design → server authority
- A07 auth → policy + verification
- A08 integrity → server-only fields + signed releases
- A09 logging → security events / alerts
- A10 exceptions → safe error handling

## Before merging security work

- Emulator rule tests pass (allow + deny).
- `flutter analyze` clean; no secret in diff.
- App Check enforced; rules deployed from repo, not console.

## References

- Security plan + threat model: `docs/SECURITY.md`
- Migration plan: `docs/migration/MIGRATION.md`
- Functions: `functions/index.js`
