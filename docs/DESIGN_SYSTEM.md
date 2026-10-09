# Design System

- **Status:** Approved (build pending)
- **App version:** `0.5.7+1` (target `0.6.0+`)

The ruleset every screen follows. Enforced by the `ui-refactor` skill
(`.opencode/skills/ui-refactor/SKILL.md`).

## 1. Tokens

| Concern | Source | Rule |
|---|---|---|
| Spacing | `AppDimensions.s2…s48` | 8pt rhythm; never raw numbers |
| Radius | `AppDimensions.radiusSm/Md/Lg/Xl/Pill` | no ad-hoc radii |
| Type | `AppTextStyles.*` | no ad-hoc `TextStyle` in screens |
| Color | `AppPalette` via `context.palette` (post-M1) | never hardcode hex in widgets |
| Elevation/shadow | palette shadows | soft, low-contrast |

> Until M1 lands, `AppColors` is the color source. After M1, `AppColors` is
> replaced by the `AppPalette` ThemeExtension with `.light` / `.dark` instances.

## 2. Theming

- **Auto day/night** from device local time; user override (Auto / Light / Dark)
  in Settings → Appearance, persisted via `shared_preferences`.
- **Continuous sky interpolation** — the background gradient is a function of
  time-of-day (no visible steps). Phases (dawn/day/dusk/night) are used for
  logic only.
- Gradients across all time/weather states **must share a fixed color-stop
  count** so `Gradient.lerp` can interpolate them.

## 3. Motion

- Calm and subtle. Prefer implicit animations (`AnimatedContainer`,
  `AnimatedSwitcher`, `TweenAnimationBuilder`).
- ≤1–2 slow ambient loops per screen.
- The Energy Home uses ONE `SceneController` easing `current → target`
  (2–4s day/night, 1–1.5s weather). Retarget mid-flight; never queue.
- `RepaintBoundary` around animated scenes; pause tickers off-screen/backgrounded.
- Honor `MediaQuery.disableAnimations` (reduce-motion) → quick fade or instant.

## 4. Interaction budget

- ~1 hero interactive area + ≤5–8 tappable sprites per screen.
- Deep interactivity only on the **3 pillars**: Energy Home, Rooms, Bill
  Journey. All other screens stay conventional.

## 5. States

Every interactive element: default · pressed · focused · disabled (with reason)
· loading.
Every screen: loading (skeleton, not bare spinner) · empty (with CTA) · error
(with retry) · offline.

## 6. Accessibility

- `Semantics` labels on icon-only buttons and sprites; standard fallbacks kept.
- Contrast ≥ 4.5:1 in both light and dark; tap targets ≥ 44×44.
- Never hide essential actions behind only a decorative sprite.

## 7. Verification

- `flutter analyze` clean.
- 60fps in DevTools on a low-end Android device.
- Contrast + tap-target checks.
