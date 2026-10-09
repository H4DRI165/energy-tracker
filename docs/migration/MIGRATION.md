# Migration Plan — UI/UX + Gamification Overhaul

- **Status:** Approved (execution in progress)
- **Baseline:** `v0.5.7` (tagged on `main`)
- **Target:** `1.0.0`

This is a **major migration** touching `lib/theme/**`, every screen under
`lib/ui/**`, 3 models, services, `functions/`, CI, and docs. It is additive and
phased — each milestone ships standalone, so `main` stays releasable.

## Branch strategy

**Per-milestone PRs → `main`.** Each merge = a testable APK release.
Branches: `feat/m1-theme`, `feat/m2-daily-gamification`, `feat/m3-energy-home`,
`feat/m4-rooms`, `feat/m5-bill-journey`, `feat/m6-weather`,
`chore/m-security-*`. Version bump per milestone; final `1.0.0`.

**Rollback:** revert the merge, or reset to tag `v0.5.7`.

## Milestones

| ID | Milestone | Scope |
|---|---|---|
| M-Security S1 | Access-control foundation | `firestore.rules`, `storage.rules`, `firebase.json`, emulator tests, CI deploy |
| M1 | Day/night theme | `AppPalette`, `AppTheme.light`, continuous sky + `SceneController`, migrate ~20 screens, Settings appearance |
| M2 | Daily-logging gamification | `createdAt`, streak engine, XP/levels/badges, daily reminder, dashboard widgets |
| M3 | Energy Home | scene + sprites, inspect + what-if |
| M3b | Readings Log | sprite → functional log screen (all readings by month) |
| M4 | Rooms | `ApplianceTemplate` catalog, type-first add flow, rooms, reconciliation |
| M5 | Bill Journey | itemized visuals + tariff explainers |
| M6 | Weather | Open-Meteo, city-based, cross-faded overlay |
| M-Security S3/S4 | Server authority + hardening | gamification Function, supply-chain, logging |

## Data / schema changes

- `ReadingRecord` +`createdAt` (for the 2-day backfill rule).
- `Appliance` +`typeId` +`room` (defaulted from template).
- New `users/{uid}/gamification` doc.
- New `ApplianceTemplate` catalog (`lib/constants/appliance_templates.dart`).

## Skill & tooling setup

- Project skills: `.opencode/skills/ui-refactor/SKILL.md`,
  `.opencode/skills/firebase-security/SKILL.md` (restart opencode to load).
- Install Firebase CLI: `npm i -g firebase-tools`.
- No MCP servers used.

## Gates per milestone

- `flutter analyze` clean.
- Existing tests pass.
- New rule/unit tests pass.
- Manual device check + 60fps.
- Docs updated for the milestone.

## Order of execution

1. Tag `v0.5.7`; branch; create skills; add docs skeleton; install Firebase CLI.
2. M-Security S1 (rules) — cheap, high-impact, independent.
3. M1 → M2 → M3 (+M3b) → M4 → M5 → M6 → Security S3/S4.
4. Regenerate screenshots; bump `1.0.0`; PR to `main`.

## Documentation updates

Update per milestone: `README.md`, `docs/PRD.md`, `docs/FEATURES.md`,
`docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/DEVELOPMENT.md`,
`docs/GLOSSARY.md`, `docs/ux-review/`, `docs/screenshots/`.
New: `docs/DESIGN_SYSTEM.md`, `docs/SECURITY.md`, `docs/migration/MIGRATION.md` (this file).

## Progress

| Step | Status | Notes |
|------|--------|-------|
| Step 0 — tag, branch, skills, docs skeleton, Firebase CLI | ✅ Done | `v0.5.7` tagged; branch `chore/m-security-rules`; skills + docs added; `firebase-tools` installed |
| Deps baseline | ✅ Done | `fake_cloud_firestore` bump on `chore/deps-baseline`; 24/24 tests pass |
| S1 — access-control foundation | ⏳ In progress | `firestore.rules` + `storage.rules` + `firebase.json` done; emulator tests + CI deploy **on hold** (needs JDK 21; revisit later) |
| M1 — day/night theme | ⬜ Pending | |
| M2 — daily-logging gamification | ⬜ Pending | |
| M3/M3b — Energy Home + Readings Log | ⬜ Pending | |
| M4 — rooms | ⬜ Pending | |
| M5 — bill journey | ⬜ Pending | |
| M6 — weather | ⬜ Pending | |
| S3/S4 — server authority + hardening | ⬜ Pending | |
