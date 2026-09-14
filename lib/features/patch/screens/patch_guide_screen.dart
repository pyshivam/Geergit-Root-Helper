import 'package:flutter/material.dart';

/// Step-by-step guide for patching boot.img with an AnyKernel zip.
///
/// Shown both as the "Patch" tab (inside the shell) and as a pushed page
/// (from the home CTA card).
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
        'Bootloader is unlocked (OEM unlocking done, `fastboot flashing unlock`).',
        'Battery above 30% — an interrupted flash bricks nothing but wastes a boot.',
        'Stock boot.img backed up to a PC (rollback path if the new kernel fails).',
      ],
    ),
    (
      title: 'Get the right zip',
      icon: Icons.download_outlined,
      points: [
        'The AnyKernel zip must be built for your exact device codename.',
        'Check the codename in the Device tab before downloading.',
        'A zip for a different model is the most common cause of a bootloop.',
      ],
    ),
    (
      title: 'Flash',
      icon: Icons.flash_on_outlined,
      points: [
        'Open KernelSU Manager → Install.',
        'Choose the AnyKernel zip and confirm the flash.',
        'The manager writes the new kernel to the active boot slot.',
      ],
    ),
    (
      title: 'Verify',
      icon: Icons.verified_outlined,
      points: [
        'Reboot and open Settings › About phone › Kernel version.',
        'It must match the kernel shipped in the zip.',
        'If the device bootloops, flash the backed-up boot.img from fastboot.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patch boot.img')),
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
                      'Never flash a zip meant for another device. The only '
                      'reliable recovery from a bad kernel is the stock '
                      'boot.img backup.',
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
