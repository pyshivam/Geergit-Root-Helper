# DESIGN

Visual decisions for Geergit Root Helper. Read before changing icons,
colors, splash, or any UI styling.

## Brand palette

The theme seed is the logo's navy, read straight from `GRH.svg`
(`#003966`). Light colors are the exact Material 3 surfaces from
`ColorScheme.fromSeed(#003966)`. Dark surfaces are a designed
navy-tinted slate ladder (fixed in `AppTheme`): lighter than Flutter's
near-black fromSeed output, with clear card/background separation in
the style of the KernelSU manager's Material dark theme.

| Token | Light | Dark | Use |
|---|---|---|---|
| `grh_ring` | `#003966` | `#F4F6FD` | Splash mark (logo navy; inverts for contrast on dark) |
| `grh_splash_bg` | `#F8F9FF` | `#161C28` | Splash background (exact fromSeed light / designed dark) |
| `grh_accent` | `#003966` | — | Theme seed (logo navy) |
| `grh_paper` | `#F4F6FD` | — | Reserved light tone |

Dark surface ladder (designed navy-tinted slate, fixed in `AppTheme`):
surface `#161C28` → containerLow `#202936` (Card) → containerHigh
`#2B3547`. Chosen for clear card/background separation over Flutter's
near-black fromSeed output; primary on dark stays the computed light
navy `#A2C9FD` for contrast.
Computed from seed: light primary `#38608F`, dark primary `#A2C9FD`.
The launcher icon itself is fixed: white field + navy `#003966` mark,
independent of the device theme.

## Logo

User-authored mark (`GRH.svg`, final form 2026-09-15): a navy **ring**
(`#003966`, stroked circle r=222 / stroke 150 on a 1152-unit canvas)
with a **play-notch triangle cut** at the upper-right and a solid navy
**bar** at the bottom-right, on a white field. The notch is negative
space that only reads on white/light backgrounds. Canonical source:

- `assets/launcher_icon/grh_logo.svg` — the original, untouched
- `assets/launcher_icon/legacy_icon.svg` — copy of the original used for
  the legacy mipmaps; the adaptive background composes this at **60%
  scale** (user direction 2026-09-15) centered on white, with a
  transparent foreground placeholder — sidesteps SVG-clip
  rasterization quirks

Regenerate launcher PNGs after edits:

```sh
./tools/generate_launcher_icons.sh
```

## Splash screen

Follows the app theme via `values`/`values-night` color aliases:

- `@color/grh_splash_bg` — light `#F8F9FF` / dark `#111418` (the exact
  `ColorScheme.fromSeed(#003966)` surfaces)
- `@color/grh_ring` — inverts with the theme (`#003966` light /
  `#F4F6FD` dark) so the ring always contrasts

Two code paths:

- **Pre-Android-12** (`drawable[-v21]/launch_background.xml`): fully
  ours — bg color + centered `@drawable/ic_logo_splash` (the G at
  0.34 scale, 180dp). Renders exactly as authored.
- **Android 12+** (`values-v31/styles.xml`): only
  `windowSplashScreenBackground` is honored. The animated-icon and
  icon-background overrides are ignored on this platform build
  (verified on Pixel 7 / Android 17 with process-freeze captures: a red
  ring at extreme scale rendered nothing), so the platform falls back
  to the adaptive launcher icon (white field + navy ring) — which is
  our branding anyway. The vector overrides were removed rather than
  left as dead configuration.
