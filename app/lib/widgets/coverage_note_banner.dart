import 'package:flutter/material.dart';

import '../theme/ieye_theme.dart';

/// The honest "your coverage has a gap" banner — shared by the home screen and
/// the circle screen so the warning reads identically and can't drift.
///
/// Accessibility + over-trust guardrails (PRD §6/§7):
///  - a `liveRegion` so a screen reader announces a drop the moment it appears —
///    this is the one message that must never be missed;
///  - a warning icon + a bold "Heads up" lead so it does NOT rely on colour
///    alone (low-vision / colour-blind);
///  - beacon-amber, never alarm-red — it's an honest nudge, not a panic.
class CoverageNoteBanner extends StatelessWidget {
  const CoverageNoteBanner(this.note, {super.key});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IEyeColors.amber.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: IEyeColors.amber, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: IEyeColors.amberDeep,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heads up',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: IEyeColors.amberDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: IEyeColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
