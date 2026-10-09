---
name: ui-refactor
description: Use when auditing, redesigning, refactoring, or building any UI screen in the Energy Tracker Flutter app — enforces design tokens (spacing, type, color), consistent component states, purposeful/calm animation, and accessibility. Trigger on UI, UX, redesign, refactor, screen, spacing, typography, animation, widget, or theme work under lib/ui/** or lib/theme/**.
---

# Energy Tracker — UI/UX Redesign

Purposeful, consistent, calm. Every visual change must support a task or
clarify content.

## Scope

Any work under `lib/ui/**` or `lib/theme/**`. Complements the master plan
(day/night theme, gamification, Energy Home) — this skill is the ruleset those
follow.

## Non-negotiables (design tokens only)

- Spacing: only `AppDimensions.s*` (never raw numbers). Keep to the 8pt rhythm.
- Typography: only `AppTextStyles.*`. No ad-hoc `TextStyle(...)` in screens.
- Color: use `context.palette.*` (`AppPalette` ThemeExtension) once M1 lands;
  until then use `AppColors`, but NEVER hardcode raw hex in widgets.
- Radius/elevation: only `AppDimensions.radius*` + palette shadows.
- Reuse shared components from `lib/ui/components/**` before building new ones.

## Workflow (6 steps)

1. **Audit** — list inconsistent spacing, color clashes, unclear CTAs, redundant
   elements, and missing states. Write down what confuses the user.
2. **Hierarchy** — make the primary action obvious; demote secondary actions;
   use size/color/placement to guide the eye.
3. **Refresh visuals** — cohesive palette + type + spacing. Replace heavy
   borders and noisy backgrounds with clean surfaces.
4. **States** — design default, pressed, focused, disabled, loading, empty,
   error, offline. Disabled controls must explain *why* (see docs/FEATURES.md).
5. **Motion** — subtle only: micro-interactions, state transitions, staggered
   list entrances. Calm mood (see Motion).
6. **Test** — `flutter analyze`; check 60fps on a low-end Android device; verify
   contrast and tap targets.

## Interaction states checklist

Every interactive element defines: default · pressed · focused · disabled (with
reason) · loading. Every screen defines: loading (skeleton, not bare spinner) ·
empty (with CTA) · error (with retry) · offline.

## Motion rules

- Calm/subtle. Prefer implicit animations (`AnimatedContainer`,
  `AnimatedSwitcher`, `TweenAnimationBuilder`) over perpetual loops.
- ≤1–2 slow ambient loops per screen; ~1 hero interactive area + ≤5–8 sprites.
- The Energy Home scene uses ONE `SceneController`/`AnimationController` that
  eases current→target; gradients must share a fixed stop count so
  `Gradient.lerp` works.
- Wrap animated scenes in `RepaintBoundary`; pause tickers when off-screen or
  backgrounded.
- Honor `MediaQuery.disableAnimations` (reduce-motion) → shorten to a quick fade.

## Accessibility

- `Semantics` labels on icon-only buttons and sprites; keep standard fallbacks.
- Contrast ≥ 4.5:1 in BOTH light and dark themes; tap targets ≥ 44×44.
- Never hide essential actions behind only a decorative sprite.

## Screen refactor checklist

1. Replace hardcoded colors with palette
2. Normalize spacing to tokens
3. Unify cards/inputs/buttons to shared components
4. Add empty/loading/error/offline states + disabled reasons
5. Apply calm motion + staggered entrance
6. Verify: `flutter analyze` clean, 60fps, contrast, tap targets

## References

- Tokens: `lib/theme/app_dimensions.dart`, `app_text_styles.dart`, `app_colors.dart`
- Components: `lib/ui/components/**`
- Features/screens: `lib/ui/features/**`
- Known UX issues to fix while refactoring: `docs/FEATURES.md`
- Design system: `docs/DESIGN_SYSTEM.md`
