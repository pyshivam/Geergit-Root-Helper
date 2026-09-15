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
(`android14-6.1`) fallback. Prefers AnyKernel builds. No match → error
card pointing to Advanced mode.

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
