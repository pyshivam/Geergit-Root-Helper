# 0003 — Boot image patcher (no root)

Turn the Patch tab from a read-only guide into the actual patcher: user
supplies a stock `boot.img`, the app swaps in a KernelSU/SUSFS AnyKernel
kernel and repacks, producing a patched image the user flashes from
fastboot. **No root is required or requested** — everything runs in the
app sandbox plus `magiskboot` as a child process.

Reference pipeline: `KernelSU-Next/userspace/ksud/src/boot_patch.rs`
(KMI regex + unpack/replace/repack shape). We do the AnyKernel variant:
replace the kernel, do not inject LKMs.

## Modes

- **Simple** (default): pick `boot.img` only. App parses the KMI from the
  image kernel, fetches the matching AnyKernel zip from WildKernels release
  repos, downloads it, patches.
- **Advanced**: pick `boot.img` + AnyKernel zip manually. App compares the
  zip's kernel against the boot image and warns on mismatch before patching.

## Version gates

1. After `boot.img` is picked: `magiskboot unpack` it, read the embedded
   `Linux version …` string, build the KMI (`android<NN>-<major>.<minor>`,
   same regex family as ksud `parse_kmi`). Compare against the device
   uname release (already on `DeviceInfo.kernelVersion`). Mismatch →
   warning card, "Continue anyway" is explicit.
   An Image carries the literal twice — the printk format string
   `Linux version %s (%s)` sits ahead of `linux_banner` — so scan every
   occurrence and take the first token that parses as a release.
2. Zip kernel (advanced): extract the zip's kernel entry (`Image` /
   `zImage` / `kernel`, first match), parse its KMI, compare with the boot
   image KMI. Mismatch → warning card, continue is explicit.

## Patching

Work dir `files/patchwork/<ts>/`: copy boot.img in, `magiskboot unpack
boot.img`, overwrite `kernel` with the zip kernel, `magiskboot repack
boot.img` → `new-boot.img`. Output is exported via SAF
(`ACTION_CREATE_DOCUMENT`) so the user can drop it anywhere, then flash:
`fastboot flash boot <file>`.

## magiskboot delivery

Bundled with the APK: the WildKernels nightly binaries ship as
`android/app/src/main/jniLibs/<abi>/libmagiskboot.so` and are executed
from `nativeLibraryDir`. Runtime download+exec from the files dir was
tried first and is dead: Android W^X denies `execute_no_trans` on
`app_data_file` (confirmed via avc denial on device — works under
`run-as` only because that domain is privileged). Bump the jniLibs from
the nightly release when magiskboot needs updating.

## AnyKernel zip sources

- `WildKernels/GKI_KernelSU_SUSFS/releases` — default
- `WildKernels/OnePlus_KernelSU_SUSFS/releases` — when manufacturer is
  oneplus / oppo / realme

Release list via GitHub API. Asset names carry the full release prefix
(`6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip`), matched in two
passes: exact patch-level tokens of the boot image release first, KMI
(`android14-6.1`) fallback.

A release carries **one asset per root manager per kernel build**
(KernelSU, KernelSU-Next, ReSukiSU in the GKI repo; `…_KSUN_…` in the
OnePlus repo). Simple mode lists one row per build available for the
picked kernel and the user selects the root to patch for; the first
patchable row is pre-selected so the flow still works in one tap.

Only the **newest release that publishes anything for this kernel** is
offered — walking the whole release history piled up 120 rows for a
`android13-5.15` image, since the KMI fallback matches every historical
release of the same line. Within that release a build appears once, and a
kernel-swap build beats a non-kernel-swap one. Builds from the older
WildKernels naming carry no manager token (`…-2023-06-Bypass-AnyKernel3.zip`)
and are labeled from the name (`Bypass`, `Other build`).

A row is patchable when it is an AnyKernel3 kernel-swap build — this app
replaces the boot image kernel, which is exactly what those builds ship
(registry: `lib/core/patch/root_manager.dart`). Non-AnyKernel assets in
the same release (e.g. `NoMount-Metamodule.zip`) never match a kernel
release, and anything that does match without being an AnyKernel3 build is
listed but not selectable. No match at all → error card pointing to
Advanced mode.

## New dependencies (required, user-requested feature)

`file_picker` (pick boot.img / zip — with `withData: false, withReadStream:
true`; file_selector was tried first and OOMs because its Android plugin
ships the whole picked file through the platform channel), `http` (GitHub
API + downloads), `archive` (zip kernel extraction). No Riverpod — flow
state lives in the screen, services are plain classes under
`lib/core/patch/`.

## Files

- `lib/core/patch/kernel_release.dart` — `Linux version` string → KMI parse + compare
- `lib/core/patch/magiskboot.dart` — binary ensure/download/exec
- `lib/core/patch/anykernel_zip.dart` — zip kernel entry find/extract
- `lib/core/patch/anykernel_repo.dart` — GitHub release fetch + KMI match
- `lib/core/patch/boot_patcher.dart` — unpack/replace/repack pipeline
- `lib/features/patch/screens/patch_landing_screen.dart` — Patch tab: mode cards + guide link
- `lib/features/patch/screens/patch_flow_screen.dart` — the flow (both modes)
- Router: `/patch` → landing, `/patch/guide` kept, `/patch/flow` pushed; home CTA → `/patch/flow`
- `MainActivity`: `exportFile` channel method (SAF save)
- Manifest: `INTERNET` permission
- Report: patch result appended to `files/report.txt` (file-over-screenshots rule)

## Field test — 2026-09-15, Pixel 7 (panther, Android 17, unrooted)

First flash of an app-produced image **bootlooped** (device fell back to
bootloader). Root cause was an app bug, not the kernel: the flow passed
the whole AnyKernel zip (`_zipBytes`) to `BootPatcher.patch()` instead of
the extracted kernel entry (`_zip.kernelBytes`), so the repacked boot
image contained a zip file (`PK\x03\x04`) as its "kernel" — invisible to
the old verification, which only checked output size and md5.

Fixes:
- `patch_flow_screen.dart`: patch with `zip.kernelBytes`.
- `boot_patcher.dart`: `looksLikeKernelImage()` guard — ARM64 Image
  magic (u32 LE `0x644D5241` at offset 56) — rejects non-kernel
  payloads before repack. Regression test in `test/boot_patcher_test.dart`
  pins the exact failure shape (full zip bytes must not pass).

Second flash of the fixed image: **boots clean** —
`uname -r` = `6.1.157-android14-Wild`, KernelSU manager reports
**Working** (driver 32615-2, GKI mode, SELinux Enforcing). Recovery
proven in the same session: A/B slot dance + local stock boot.img
restores stock in minutes.

Notes:
- `WildKernels/Pixel_KernelSU_SUSFS` exists but has no releases; the
  generic `GKI_KernelSU_SUSFS` zip works on Pixel 7.
- `WildKernels/Pixel_Kernels` is a source/build repo, no zips.
- KernelSU does not serve `su` to the adb shell (uid 2000); root is
  granted per-app via the manager. "Working" in the manager is the
  device-side proof.
- Manager/driver version skew (manager 32601 vs driver 32615) shows a
  warning banner; cosmetic — update the manager APK to match.
