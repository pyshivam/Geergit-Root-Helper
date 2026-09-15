# 0004 — File-based session logging with log export

## Problem

The APK is shared with people who have no adb and no root. When their
patch fails we get "it didn't work" with nothing to diagnose. logcat is
not an option for remote users. Root modules solve this the same way:
write per-process log files under the app's own `files/` dir, read them
back without logcat. Here there is no root on the receiving side either,
so the user needs a one-tap export.

## Design

### Session log (the root-module pattern, host side)

- One log file per app launch: `files/logs/session-<yyyyMMdd-HHmmss>.log`.
- `AppLogger.log(tag, message)` appends a timestamped line
  (`2026-09-15 13:34:02.123 I/PatchFlow message`) and `debugPrint`s it,
  so desktop `flutter run` output is unchanged.
- Each patch attempt inside a session gets a banner line
  (`===== PATCH TRY mode=simple =====`) — "per try" is a section, not a
  file: a try is useless without the session's device context around it.
- Retention: last 10 session files; older ones pruned at init.
- Initialized in `main()` before `runApp`; off-Android it falls back to
  the system temp dir so desktop runs still log.

### Crash capture

- `FlutterError.onError` and `PlatformDispatcher.instance.onError` both
  write the exception + stack to the log before the framework's default
  handling. A hard crash therefore still leaves a readable tail in the
  session file — the exact thing needed when a shared-APK user reports
  "the app closed".

### What gets logged

Startup: device facts (model, manufacturer, Android release, SDK, ABIs,
kernel release, fingerprint). Pipeline: picked file names/sizes,
magiskboot invocations (binary path, args, exit code, stderr tail),
parsed kernel releases, gate decisions (match / acknowledged mismatch),
zip search (repo, release, chosen asset name/tag/URL), download size,
zip kernel compare, output size, export destination, and every error
card message.

### Export

`Patch` landing screen gains an "Export logs" card: bundles every
`files/logs/*.log` into `files/logs-export.zip` via the already-present
`archive` package and hands it to the existing SAF `exportFile` channel
(same path `new-boot.img` uses). The shared-APK user saves the zip,
sends it over any chat app, and the developer reads plain-text logs.
The flow's done state also offers "Export logs" for the
patched-but-something-looks-wrong case.

## Non-goals

- No in-app log viewer (export + any text editor covers it).
- No log upload / telemetry.
- No per-try separate files (banner sections instead).

## Verification

- Unit test: logger writes timestamped lines to its session file and the
  export bundle zip contains the session files.
- On device: run a patch, export the zip, pull it, confirm it contains
  the session log with the try banner and pipeline lines.
