# Security

- **Status:** Approved (implementation pending)
- **App version:** `0.5.7+1` (target `0.6.0+`)

Ruleset for Firebase security, mapped to **OWASP Top 10:2025**. Enforced by the
`firebase-security` skill (`.opencode/skills/firebase-security/SKILL.md`).

## 1. Scope & threat model

**Scope:** personal/portfolio app. Per-user data, not shared between users.
Pragmatic defense-in-depth — harden access control and trusted values without
moving the whole app server-side.

### What we guarantee
| Threat | Handled | By |
|---|---|---|
| Read another user's readings/bills/token | ✅ | Firestore rules (owner-scoped) |
| Forge XP / badges / streaks | ✅ | Server-authoritative awards + rules |
| Bots/scripts abusing the backend | ✅ (mostly) | App Check + API key restriction + `maxInstances` |
| Eavesdrop on network traffic | ✅ vs third parties | Firebase TLS (already) |

### What we do NOT (and cannot) guarantee
- A user can always see and tamper with **their own** local data — it is their
  device and their requests.
- The whole app is **not** server-authoritative; only trust-sensitive parts.
- A user modifying their own local estimate harms only themselves.

## 2. Baseline state (audit @ v0.5.7)

| # | Category | Status | Finding |
|---|---|---|---|
| A01 | Broken Access Control | 🔴 | No `firestore.rules` / `storage.rules` in repo; `firebase.json` has no rules config; `users/{uid}` holds `fcmToken` |
| A02 | Security Misconfiguration | 🔴 | App Check activated client-side but enforcement is a console setting |
| A03 | Software Supply Chain | 🟠 | CI uses mutable action tags; no Dependabot/CodeQL |
| A04 | Cryptographic Failures | 🟢 | Firebase TLS + at-rest; secrets correctly gitignored |
| A05 | Injection | 🟡 | Structured queries safe; validate field shapes |
| A06 | Insecure Design | 🔴 | Bill/budget math + planned gamification client-authoritative |
| A07 | Authentication Failures | 🟠 | Email verification disabled; password policy ≥8 chars |
| A08 | Software/Data Integrity | 🟠 | No server-side write validation |
| A09 | Logging & Alerting | 🟠 | Crashlytics only; no security-event alerting |
| A10 | Mishandling Exceptions | 🟢 | Client error mapping good; keep functions safe |

## 3. Workstream

- **S1 — Access control foundation:** author `firestore.rules` +
  `storage.rules` (deny-by-default, owner-scoped, schema-validated),
  server-only fields blocked from client writes, wire into `firebase.json`,
  emulator rule tests, CI deploy.
- **S2 — Config hardening:** enforce App Check (release), restrict Google API
  key to Android app + package/SHA, confirm no open rules.
- **S3 — Server authority for gamification:** callable Function validates and
  writes `xp` / streaks / badges; rules block direct client writes.
- **S4 — Optional:** auth policy centralization, supply-chain pins, security
  logging/alerting.

## 4. Notes

- Firebase API keys are **not secrets** (client identifiers). Protect them with
  rules + App Check + key restriction — do not try to hide them.
- Rules must be versioned in-repo and deployed via CI — never console-only.
