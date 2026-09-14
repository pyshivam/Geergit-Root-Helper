# 0001 — KSU-style home page

Counter placeholder → modern Material 3 home modeled on KernelSU-Next
manager `Home.kt`: hero status card, device card, kernel card.

## Layout (single screen, `lib/main.dart`)

- `AppBar`: app title, no actions yet.
- Hero `StatusCard`: filled card, icon + device model + Android version.
  No fake root state — backend wiring is future work.
- `DeviceCard`: Model, Manufacturer, ABI, Build fingerprint (`Build.FINGERPRINT`) rows.
- `KernelCard`: kernel release row (`Os.uname().release` on Android — `/proc/version`
  is rewritten by stealth stacks; `/proc/version` only as non-Android fallback).
- Row style copies KSU `InfoCardItem`: icon + semibold label + body value.

## Data (`lib/device_info.dart` + `MainActivity` channel)

- Channel `com.geerxlabs.geergitroothelper/device_info`, method
  `getDeviceInfo`: `Build.MODEL/MANUFACTURER/DEVICE`,
  `VERSION.RELEASE/SDK_INT`, `SUPPORTED_ABIS`, `/proc/version`.
- Non-Android or channel failure → `Unavailable on this platform`
  fallback; UI never throws.
- After fetch the app writes `files/report.txt` (app internal storage) —
  device verification is `adb exec-out run-as <pkg> cat files/report.txt`,
  no screenshots.

## Theme

`ColorScheme.fromSeed(seedColor: 0xFF8AADF4)` (KSU Catppuccin blue),
light + dark, `useMaterial3: true`. No new dependencies.
