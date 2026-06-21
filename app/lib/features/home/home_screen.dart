import 'package:flutter/material.dart';

import '../../core/coverage.dart';
import '../../core/detection_brain.dart';
import '../../theme/ieye_theme.dart';
import '../../widgets/coverage_note_banner.dart';

/// The honest-coverage home screen (PRD §6) — the one surface the watched person
/// may see. It tells the TRUTH: last sign of life, battery, how many people are
/// watching, and — crucially — degraded/paused states with a plain reason. There
/// is deliberately NO green "you're protected" shield (over-trust is the #1
/// product risk, §7; honest coverage is a launch blocker).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.brain});

  final DetectionBrain brain;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<CoverageState>(
          stream: widget.brain.coverage,
          initialData: widget.brain.current,
          builder: (context, snapshot) {
            final c = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusHeadline(c),
                  const SizedBox(height: 24),
                  _CoverageFacts(c),
                  if (c.note != null) ...[
                    const SizedBox(height: 16),
                    // A coverage gap is a warning (icon + lead + live region);
                    // a planned "going dark" pause is calm.
                    c.status == CoverageStatus.degraded
                        ? CoverageNoteBanner(c.note!)
                        : _HonestNote(c.note!),
                  ],
                  const SizedBox(height: 32),
                  _GoingDarkControls(
                    coverage: c,
                    onGoDark:
                        () => widget.brain.goDark(
                          until: DateTime.now().add(const Duration(days: 3)),
                        ),
                    onResume: widget.brain.resume,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'iEye watches over you, never watches you. It reads a sign of '
                    'life only — nothing about your day leaves this phone. It is not '
                    'a medical or emergency service.',
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: IEyeColors.charcoalSoft,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Honest Tier-0 limits (#14): never pretend phone-only is more
                  // than it is. Distinct block (header + plain two sentences) so
                  // it doesn't blur into the privacy line above, and a screen
                  // reader announces it as its own section.
                  Semantics(
                    header: true,
                    child: Text(
                      'What iEye can and can’t do yet',
                      style: text.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: IEyeColors.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For now, iEye watches using your phone alone. If the phone is '
                    'off or the battery runs out, iEye can lose contact — and when '
                    'that happens it tells you, instead of pretending all is well.',
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: IEyeColors.charcoalSoft,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline(this.c);
  final CoverageState c;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Distinct glyph AND colour per state — never colour alone (colour-blind).
    final (headline, accent, icon) = switch (c.status) {
      CoverageStatus.watching => (
        'Watching over you.',
        IEyeColors.tealDeep,
        Icons.wb_incandescent_outlined, // a lamp "left on for you"
      ),
      // Degraded uses beacon-amber (attention), never alarm-red.
      CoverageStatus.degraded => (
        'Watching — but you should know something.',
        IEyeColors.amberDeep,
        Icons.warning_amber_rounded,
      ),
      CoverageStatus.pausedGoingDark => (
        'Paused — you told us you’re away.',
        IEyeColors.charcoalSoft,
        Icons.dark_mode_outlined,
      ),
      CoverageStatus.notArmed => (
        'Not watching yet.',
        IEyeColors.charcoalSoft,
        Icons.power_settings_new,
      ),
    };
    return Row(
      children: [
        Icon(icon, color: accent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            headline,
            style: text.headlineSmall?.copyWith(fontSize: 26),
          ),
        ),
      ],
    );
  }
}

class _CoverageFacts extends StatelessWidget {
  const _CoverageFacts(this.c);
  final CoverageState c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Fact(
          Icons.favorite_border,
          'Last sign of life',
          _ago(c.lastSignOfLife),
        ),
        if (c.batteryPercent != null)
          _Fact(
            Icons.battery_5_bar_outlined,
            'Phone battery',
            '${c.batteryPercent}%',
          ),
        _Fact(
          Icons.people_outline,
          'People watching',
          c.checkerCount == 0
              ? 'No one yet'
              : '${c.checkerCount} watching · ${c.checkersNearby} can reach you fast',
        ),
      ],
    );
  }

  static String _ago(DateTime? t) {
    if (t == null) return 'Unknown';
    final m = DateTime.now().difference(t).inMinutes;
    if (m < 1) return 'Just now';
    if (m < 60) return '$m min ago';
    final h = (m / 60).floor();
    return '$h hr ago';
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: IEyeColors.charcoalMuted, size: 22),
          const SizedBox(width: 14),
          Text(label, style: text.bodyMedium),
          const SizedBox(width: 12),
          // Value flexes + right-aligns so long lines wrap instead of overflowing
          // on narrow screens (caught by the on-device E2E).
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(
                color: IEyeColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Degraded/paused reason, shown plainly — the anti-fake-green-shield surface.
class _HonestNote extends StatelessWidget {
  const _HonestNote(this.note);
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IEyeColors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        note,
        style: const TextStyle(
          color: IEyeColors.charcoal,
          fontSize: 15,
          height: 1.45,
        ),
      ),
    );
  }
}

/// "Going dark" — the most important flow (PRD §3C). Pre-emptively suspends the
/// watch and tells the circle it's planned, killing most weekly false alarms.
class _GoingDarkControls extends StatelessWidget {
  const _GoingDarkControls({
    required this.coverage,
    required this.onGoDark,
    required this.onResume,
  });

  final CoverageState coverage;
  final VoidCallback onGoDark;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final paused = coverage.status == CoverageStatus.pausedGoingDark;
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        backgroundColor: IEyeColors.paperDim,
        foregroundColor: IEyeColors.charcoal,
        minimumSize: const Size.fromHeight(56),
      ),
      onPressed: paused ? onResume : onGoDark,
      icon: Icon(paused ? Icons.visibility_outlined : Icons.dark_mode_outlined),
      label: Text(
        paused
            ? 'I’m back — resume watching'
            : 'I’m going to be away (going dark)',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
