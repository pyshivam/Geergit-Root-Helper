import 'package:flutter/material.dart';

/// Step-by-step guide for the app's own flow: patch inside the app,
/// export, flash from fastboot, verify, recover. Lessons written here
/// are from the 2026-09-15 field test on a Pixel 7 (see
/// `docs/plans/0003-boot-patch-pipeline.md`).
class PatchGuideScreen extends StatefulWidget {
  const PatchGuideScreen({super.key});

  @override
  State<PatchGuideScreen> createState() => _PatchGuideScreenState();
}

class _PatchGuideScreenState extends State<PatchGuideScreen> {
  int _step = 0;

  static const _steps = [
    (
      title: 'Prepare',
      icon: Icons.shield_outlined,
      points: [
        'Bootloader unlocked (developer options → OEM unlocking, then '
            '`fastboot flashing unlock`).',
        'Stock boot.img for THIS device and firmware, copied to the '
            'phone and to a PC — it is the only reliable rollback.',
        'Battery above 30%.',
      ],
    ),
    (
      title: 'Patch in the app',
      icon: Icons.auto_fix_high,
      points: [
        'Simple: pick the stock boot.img. The app reads its kernel '
            'version, checks it against the running kernel, fetches the '
            'exact patch-level AnyKernel zip, and repacks — no root needed.',
        'Advanced: pick boot.img + a zip built for the full platform '
            'release (e.g. 6.1.157-android14) — patch level matters, not '
            'just the KMI (android14-6.1).',
        'Heed the mismatch warnings: a wrong-version kernel usually '
            'means the boot.img or zip is not from this firmware.',
      ],
    ),
    (
      title: 'Export and flash',
      icon: Icons.flash_on_outlined,
      points: [
        'Tap “Save patched boot.img…” and store it in Downloads, then '
            'copy it to a PC with adb/fastboot.',
        '`adb reboot bootloader`, then '
            '`fastboot flash boot new-boot.img`, then `fastboot reboot`.',
        'Pixel 7 / Tensor: the kernel lives in the boot partition — '
            'flash boot. Devices with a separate init_boot keep only the '
            'ramdisk there.',
      ],
    ),
    (
      title: 'Verify',
      icon: Icons.verified_outlined,
      points: [
        'First boot takes a little longer — give it a minute.',
        'Your root manager (KernelSU, KernelSU-Next, ReSukiSU…) must show '
            '“Working”. That status is the proof: the manager queried the '
            'in-kernel driver.',
        'Root is granted per app in the manager’s Superuser tab. `su` '
            'is intentionally not served to the adb shell.',
      ],
    ),
    (
      title: 'If it fails to boot',
      icon: Icons.restore_outlined,
      points: [
        'A bad kernel drops the device back to the bootloader screen — '
            'expected, not bricked.',
        'Flash the stock backup: `fastboot flash boot boot.img` (use '
            'the slot shown by `fastboot getvar current-slot`), then '
            '`fastboot reboot`.',
        'A/B devices: the other slot may still boot — try '
            '`fastboot --set-active=a` or `=b` before reflashing.',
        'Stuck? Use “Export logs” in the Patch tab and attach the zip '
            'when asking for help — every try is recorded.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patch and flash boot.img')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Stepper(
            currentStep: _step,
            onStepTapped: (i) => setState(() => _step = i),
            physics: const ClampingScrollPhysics(),
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              for (final (i, s) in _steps.indexed)
                Step(
                  title: Text(s.title),
                  isActive: i <= _step,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final point in s.points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  '),
                              Expanded(child: Text(point)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Match the patch level, keep the stock boot.img '
                      'backup on a PC, and never interrupt a fastboot '
                      'write.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
