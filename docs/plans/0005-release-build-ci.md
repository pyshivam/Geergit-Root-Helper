# 0005 — Signed release builds and tag-triggered CI releases

## Problem

The app builds debug APKs only: the release buildType signs with the
debug key, and shipping means hand-building from this workstation. We
need a proper release signing identity and GitHub Releases automation so
a tag is the only step between `main` and a downloadable signed APK.

## Keystore

- `keytool -genkeypair`, RSA 2048, 10 000 days, alias `grh`, single
  generated password for store and key (small project, one secret to
  rotate).
- File: `android/app/geergit-root-helper.keystore` — **never committed**
  (`.gitignore`). Canonical copy lives in GitHub Secrets as base64.
- Local builds read `android/keystore.properties` (also gitignored):
  `RELEASE_KEYSTORE_PATH`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS`,
  `RELEASE_KEY_PASSWORD`. The same four values exist as repo secrets for
  CI, so local and CI builds sign identically.

## Gradle wiring

`android/app/build.gradle.kts` gains a `release` signingConfig that
reads env vars first, then `keystore.properties`. When no secrets are
present (fresh clone, forks) the release buildType falls back to the
debug key — analyze/test and unsigned release builds keep working
everywhere; signed builds need the secrets.

## Version

Bump `pubspec.yaml` to `1.1.0+2` — first signed release; the feature
set since 1.0.0 is the whole patch pipeline + logging.

## Workflow

`.github/workflows/release.yml`, trigger: push of tags `v*`:

1. Checkout, JDK 17 (matches `compileOptions`), Flutter pinned to the
   `.fvmrc` version (3.47.4) via `subosito/flutter-action`.
2. Quality gate: `flutter analyze` + `flutter test` — a failing gate
   never ships.
3. Decode `RELEASE_KEYSTORE_BASE64` into `android/app/`, export the
   password secrets, `flutter build apk --release`.
4. Publish `app-release.apk` to a GitHub Release for the tag
   (`softprops/action-gh-release`), with auto-generated notes.

Tag ↔ version rule: tag `v1.1.0` must match `version: 1.1.0+N` in
pubspec — the workflow could check this; instead it is documented here
and enforced by review.

## Verification

- Local: `flutter build apk --release` signs with the new keystore;
  `apksigner verify --print-certs` shows the `grh` certificate.
- CI: `git tag v1.1.0 && git push origin v1.1.0` → workflow runs,
  release appears with the APK attached; download and confirm the cert
  matches the local one.
