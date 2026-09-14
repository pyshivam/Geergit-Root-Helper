# Developer Guide

Practical guide for developing the Geergit Root Helper (`geergit_root_helper`).

> Agents MUST read this guide before starting any work in this repo (root `AGENTS.md` mandates it).

## Stack

- Flutter, SDK pinned to 3.47.4 by `.fvmrc` (`fvm`-managed; Dart 3.13).
- One codebase, four targets: `android`, `linux`, `macos`, `windows`.
- Display name `Geergit Root Helper`; application id `com.geerxlabs.geergitroothelper`.

## Setup

```bash
fvm install            # installs the pinned SDK
fvm flutter pub get
```

Run every command through `fvm flutter …` so it uses the pinned SDK (plain `flutter` works when the fvm default already matches the pin).

## Run & verify

```bash
fvm flutter analyze
fvm flutter test
fvm flutter devices            # what the toolchain can see
fvm flutter run -d linux       # Linux desktop
fvm flutter run -d <device>    # first connected Android device
```

Builds:

```bash
fvm flutter build linux --debug
fvm flutter build apk --debug   # → build/app/outputs/flutter-apk/app-debug.apk
```

Windows and macOS targets cannot be built from Linux; run those builds on their own OS. A change that touches `windows/` or `macos/` is unverified until someone builds it there — say so rather than claiming success.

### Verifying a build

Linux, headless-safe:

```bash
xvfb-run -a --server-args="-screen 0 1280x800x24" bash -c \
  './build/linux/x64/debug/bundle/geergit_root_helper >/tmp/gg.log 2>&1 & APP=$!; sleep 6; xwininfo -root -tree | grep -i geergit; kill $APP'
```

Expect a window titled `Geergit Root Helper` with WM_CLASS `com.geerxlabs.geergitroothelper`.

Android, identity check on the built artifact:

```bash
$ANDROID_HOME/build-tools/37.0.0/aapt2 dump badging build/app/outputs/flutter-apk/app-debug.apk | head -3
```

Expect `package: name='com.geerxlabs.geergitroothelper'` and `application-label:'Geergit Root Helper'`.

### Verifying values on device: file over screenshots

When you need to see runtime values on a device (versions, identifiers, flags,
fetched data), **never loop on screenshots**. Have the app write the values to
a file in its internal storage and pull it:

```bash
adb exec-out run-as com.geerxlabs.geergitroothelper cat files/report.txt
```

Screenshots are only for visual/layout verification. Text values are pulled
from files — they are exact, greppable, and immune to lock screens and screen
timeouts. Follow the existing pattern: a channel method that returns
`filesDir`, a `toReport()` on the data class, and a write after fetch that
never throws into the UI.

## Task closeout: commit & push

After every completed task, commit and push the work before moving on — do not wait for a reminder:

```bash
git add <explicit paths>   # never `git add -u`; stage only your files
git commit -m "<scope>: <summary>"
git push
```

Repo: `pyshivam/Geergit-Root-Helper` (`origin`, branch `main`).

## Conventions

- Read the DOX chain (`AGENTS.md` files) before editing; docs before code; update the closest owning `AGENTS.md` and its Child DOX Index after meaningful changes.
- No new dependencies without explicit approval.
- `graft/` is a local, gitignored cache — run `graft build` after large code changes.
