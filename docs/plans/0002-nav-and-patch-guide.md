# 0002 — Bottom nav shell + patch guide (ported from geergit)

## Structural decisions copied from `gg/geergit`

- **Routing**: `go_router` ^17.3.0 (same pin as geergit). Router lives in
  `lib/core/router/app_router.dart` behind `buildRouter(...)`.
  Tabs use `StatefulShellRoute.indexedStack`; detail pages are top-level
  `GoRoute`s pushed over the shell. No redirect logic (no auth in this app).
- **Shell scaffold**: `lib/screens/home/home_screen.dart` — `Scaffold` with
  `body: navigationShell` + M3 `NavigationBar`
  (`selectedIndex: currentIndex`, `onDestinationSelected: goBranch`,
  outlined/selected icon pairs). Each tab screen brings its own `AppBar`.
- **Layout**: `core/` (router, theme, data) + `features/<feature>/screens/`.
  Theme in `core/theme/app_theme.dart` (`AppTheme.fromBrightness`, seed
  `0xFF8AADF4`). `device_info.dart` moved to `core/data/`.
- **Deliberately NOT ported**: Riverpod (no cross-screen state need; theme
  mode is a `ValueNotifier<ThemeMode>` owned by the app), Hive/auth/env gates.

## Tabs

Home (`/home`), Patch (`/patch`), Settings (`/settings`, theme mode
segmented button).

## Home tab

- Hero CTA card (`primaryContainer`, InkWell) → `context.push('/patch/guide')`.
  Text: "Patch boot.img with AnyKernel zip".
- Device card (Model / Manufacturer / ABI / Build fingerprint) and Software
  card (Android version / Kernel version) unchanged from 0001.

## Patch guide

`lib/features/patch/screens/patch_guide_screen.dart` — M3 `Stepper`
(tap-to-expand steps, no continue/cancel controls) with four steps:
Prepare → Get the right zip → Flash → Verify, plus a warning card
(wrong-device zips / stock boot.img rollback). The same screen is both the
`/patch` tab and the pushed `/patch/guide` page.

## Flutter 3.47 note

`Stepper` has no `shrinkWrap` (it shrink-wraps internally); when nested in a
scrollable pass `physics: ClampingScrollPhysics()`.
