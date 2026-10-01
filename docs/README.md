# Energy Tracker — Documentation

This folder is the source of truth for **what** the product is, **why** it exists, and **how** it is built.

## Start here

| Doc | Read it when you want to… |
|---|---|
| [PRD.md](PRD.md) | Review the vision, goals, users, scope, and product decisions |
| [FEATURES.md](FEATURES.md) | See every feature, its status, its flow, and where the code lives |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Understand the layers, state management, auth/routing, notifications |
| [DATA_MODEL.md](DATA_MODEL.md) | Look up Firestore fields, collections, and known schema issues |
| [BILLING.md](BILLING.md) | Understand the TNB tariff math, reading chain, and bill recalculation |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Set up, run, test, build, release, and follow conventions |
| [GLOSSARY.md](GLOSSARY.md) | Decode domain terms (EEI, AFA, KWTBB, SST, tier, band…) |
| [ux-review/](ux-review/README.md) | Track UX / microcopy / accessibility findings and fixes |
| [screenshots/](screenshots/) | Visual reference per screen |

The root [README.md](../README.md) is the short public/portfolio overview; this folder is the working detail.

## Status legend

Used in `FEATURES.md`:

| Status | Meaning |
|---|---|
| **Shipped** | Implemented, reachable in the UI, considered working |
| **Shipped (partial)** | Works, but a known sub-part is incomplete or inconsistent |
| **WIP / Hidden** | Code exists but is commented out, feature-flagged, or not reachable |
| **Planned** | Described but not implemented |

## Documentation conventions

- Every doc starts with a **Status** line: `Current`, `Approved`, or `Out of date`.
- Facts cite `path:line` where useful.
- When a feature changes, update the matching row in `FEATURES.md` and, if data changed, `DATA_MODEL.md`.

## Current direction

Energy Tracker is an Android-only portfolio project. Positioning: "Track, estimate, and understand your TNB bill." The active milestone is the WIP feature set — in-app notification settings, Terms/Privacy screens, and guest mode. Full detail in [PRD.md](PRD.md) §16 **Roadmap**.
