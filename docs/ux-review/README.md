# UX Review — Findings

- **Status:** Current

Findings from the pre-overhaul UX audit. Most are scheduled to be fixed during
the theme / screen migration (see [MIGRATION.md](../migration/MIGRATION.md)).
Severity: **C**ritical · **H**igh · **M**edium · **L**ow.

| ID | Severity | Finding | Fix status |
|----|----------|---------|------------|
| C1 | Critical | Dashboard error state dumped raw exceptions | Fixed |
| C2 | Critical | Save button disabled with no explanation | Fixed |
| H2 | High | No autofill / keyboard actions in auth forms | Open |
| H4 | High | Bill-detail delete-failure copy was misleading | Open |
| H5 | High | Password policy inconsistent between hint/checklist and validator | Open |
| H7 | High | Edit-profile TNB hint shows 10 digits but validation requires 12 | Open |
| M1 | Medium | Loading hides header and uses a bare spinner (dashboard, usage) | Open |
| M2 | Medium | "Tap to mark as paid" caption but only the small toggle is tappable | Open |
| M4 | Medium | Tariff-conflict error is verbose and offers no action | Open |
| M6 | Medium | Onboarding summary claims "Alerts enabled" regardless of permission | Open |
| M7 | Medium | Appliance category silently defaults to "Cooling" | Open |
| M8 | Medium | Hours stepper enabled at limits, not typable, missing semantics | Open |
| M9 | Medium | Tariff calculator input has no accessible label | Open |
| L2 | Low | Placeholder "Loading..." fallback for name | Open |
| L5 | Low | Usage error uses a generic `ErrorView` | Open |
| L7 | Low | Tariff calculator input is integer-only | Open |

## Convention

- Per-doc references use the finding IDs above.
- When a finding is fixed, update the **Fix status** here and the matching row
  in [FEATURES.md](../FEATURES.md).
