import 'package:flutter/material.dart';

import '../../core/homescan/scanner.dart';
import '../../theme/ieye_theme.dart';
import '../../widgets/bytesbrains_badge.dart';

/// Shown on Linux/Windows, where the Firebase-backed specialist request isn't
/// available. The scan is the desktop value; for a specialist we point to the
/// phone or Mac app (and the inbox) — a friendly hand-off, never a crash or a
/// dead end.
class SupportUnavailableScreen extends StatelessWidget {
  const SupportUnavailableScreen({super.key, this.report});

  /// The scan that would have been attached — unused here, kept so the route
  /// signature matches the real screen.
  final ScanReport? report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: IEyeColors.paper,
        foregroundColor: IEyeColors.charcoal,
        elevation: 0,
        title: const Text(
          'Talk to a specialist',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.support_agent,
                  color: IEyeColors.tealDeep, size: 44),
              const SizedBox(height: 18),
              Text(
                'Request a specialist from your phone or Mac',
                style: text.headlineSmall?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'The desktop app runs the scan, but sending a specialist request '
                'needs the iEye app on Android or Mac. Open it there to book a '
                'callback — or email us and we’ll pick it up.',
                style: text.bodyLarge?.copyWith(color: IEyeColors.charcoalSoft),
              ),
              const SizedBox(height: 24),
              SelectableText(
                kBytesBrainsContactEmail,
                style: text.titleMedium?.copyWith(
                  color: IEyeColors.tealDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const BytesBrainsBadge(centered: false),
            ],
          ),
        ),
      ),
    );
  }
}
