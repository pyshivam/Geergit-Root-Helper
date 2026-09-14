# 0001 — KSU-style home page

Counter placeholder → modern Material 3 home modeled on KernelSU-Next
manager `Home.kt`: hero status card, device card, kernel card.

## Layout (single screen, `lib/main.dart`)

- `AppBar`: app title, no actions yet.
- Hero `StatusCard`: filled card, icon + device model + Android version.
  No fake root state — backend wiring is future work.
- `DeviceCard`: Model, Manufacturer, Android release (SDK), ABI rows.
- `KernelCard`: kernel version row (`/proc/version` on Android) + build
  fingerprint row (`Build.FINGERPRINT`).
- Row style copies KSU `InfoCardItem`: icon + semibold label + body value.

## Data (`lib/device_info.dart` + `MainActivity` channel)

- Channel `com.geerxlabs.geergitroothelper/device_info`, method
  `getDeviceInfo`: `Build.MODEL/MANUFACTURER/DEVICE`,
  `VERSION.RELEASE/SDK_INT`, `SUPPORTED_ABIS`, `/proc/version`.
- Non-Android or channel failure → `Unavailable on this platform`
  fallback; UI never throws.

## Theme

`ColorScheme.fromSeed(seedColor: 0xFF8AADF4)` (KSU Catppuccin blue),
light + dark, `useMaterial3: true`. No new dependencies.
