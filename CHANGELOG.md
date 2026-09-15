# Changelog

All notable changes to GRoot Helper are documented here. Release builds are
versioned `1.0.0-<commit>+<build>` — the build number increments on every
release; the commit identifies exactly what was built.

## [1.0.0] — initial public release

- Patch a stock `boot.img` with KernelSU on-device, no root and no PC
  - Simple mode: auto-picks the AnyKernel zip for the kernel's patch level
    from the Wild Kernels GKI repo
  - Advanced mode: bring your own AnyKernel zip
  - `magiskboot` runs in-app via JNI; ARM64 kernel-image guard before patching
  - Zip-vs-boot-image kernel verification with patch-level prompts
  - Step-by-step fastboot flashing guide
- File-based session logging with crash hooks, device facts, 10-session
  retention, and zip export via the share sheet
- Full Material 3 theming: light/dark/system, persistence, navy palette from
  the user-authored G logo, designed dark surfaces, Comfortaa font
- KernelSU-style home: large title, kernel-first device card, Patreon
  support card
- Settings: inline app header with live version, credits page (Wild Kernels
  special thanks, 17 entries), support links
- One-time flashing-risk disclaimer on first launch
- Signed release APKs built by CI on every merge to `main`; version stamped
  with the build commit

[1.0.0]: https://github.com/pyshivam/Geergit-Root-Helper/releases
