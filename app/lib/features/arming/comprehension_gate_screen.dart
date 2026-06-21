import 'package:flutter/material.dart';

import '../../core/delivery_mode.dart';
import '../../theme/ieye_theme.dart';

/// The comprehension gate (#25, PRD §8). Over-trust is product risk #1, so before
/// iEye ever starts watching, the user must take in three truths and ACTIVELY
/// acknowledge the first — "found, not rescued". No arm without it. The honest
/// promise is mode-aware at the leaf: Easy never says "inevitable"; Sovereign
/// (Beta) states the on-chain reality and is a coming-soon shell in V1.
class ComprehensionGateScreen extends StatefulWidget {
  const ComprehensionGateScreen({
    super.key,
    this.mode = DeliveryMode.easy,
    this.onArmed,
  });

  final DeliveryMode mode;

  /// Called when the user arms — only reachable after the micro-check.
  final VoidCallback? onArmed;

  @override
  State<ComprehensionGateScreen> createState() =>
      _ComprehensionGateScreenState();
}

class _ComprehensionGateScreenState extends State<ComprehensionGateScreen> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The gravity gate: "Slow down. This one matters."
                    Text(
                      'Slow down. This one matters.',
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: IEyeColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Before iEye starts watching, three honest truths. They set '
                      'what to expect — and what not to.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: IEyeColors.charcoalSoft,
                      ),
                    ),
                    const SizedBox(height: 28),

                    const _Truth(
                      n: '1',
                      title: 'iEye finds you — it doesn’t save you.',
                      body:
                          'It shrinks the time until someone knows from weeks to '
                          'hours. It is not a doctor, an ambulance, or an emergency '
                          'service.',
                    ),
                    const _Truth(
                      n: '2',
                      title: 'It can miss — and here’s when.',
                      body:
                          'A dead phone, a phone that puts iEye to sleep to save '
                          'battery, or going off-grid can all create gaps. iEye '
                          'shows you when it loses contact, instead of pretending '
                          'all is well.',
                    ),
                    const _Truth(
                      n: '3',
                      title: 'False alarms are the design, not a bug.',
                      body:
                          'iEye would rather ask “are you okay?” a few times for '
                          'nothing than miss the once it matters — so every false '
                          'alarm is cheap: a quick “I’m fine.”',
                    ),

                    const SizedBox(height: 8),
                    _HonestPromise(mode: widget.mode),
                  ],
                ),
              ),
            ),
            // Pinned action footer — the micro-check + Arm are ALWAYS on screen,
            // so the button is never lost below a long scroll (a grandmother
            // never wonders where it went).
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              decoration: BoxDecoration(
                color: IEyeColors.paper,
                border: Border(
                  top: BorderSide(
                    color: IEyeColors.charcoal.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active acknowledgement, never pre-ticked.
                  _MicroCheck(
                    checked: _acknowledged,
                    onToggle:
                        () => setState(() => _acknowledged = !_acknowledged),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      // No arm without the acknowledgement.
                      onPressed: _acknowledged ? widget.onArmed : null,
                      child: const Text('Start watching over me'),
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

class _Truth extends StatelessWidget {
  const _Truth({required this.n, required this.title, required this.body});

  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: IEyeColors.amber.withValues(alpha: 0.25),
            child: Text(
              n,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: IEyeColors.amberDeep,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: IEyeColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: IEyeColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode-aware honest promise. Shows the active mode plainly, and surfaces
/// Sovereign as a coming-soon shell with its on-chain reality stated (#25 AC).
class _HonestPromise extends StatelessWidget {
  const _HonestPromise({required this.mode});

  final DeliveryMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How help reaches them (${mode.title})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: IEyeColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mode.honestPromise,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: IEyeColors.charcoalSoft,
          ),
        ),
        if (mode == DeliveryMode.easy) ...[
          const SizedBox(height: 10),
          // Plain coming-soon teaser — no jargon for a V1 (Easy) audience. The
          // on-chain reality lives in the real Sovereign gate when it ships.
          const Text(
            'There’s also a future option that keeps working even if iEye’s '
            'company ever goes away. It’s not ready yet.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: IEyeColors.charcoalSoft,
            ),
          ),
        ],
      ],
    );
  }
}

class _MicroCheck extends StatelessWidget {
  const _MicroCheck({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: checked,
      label: 'I understand: iEye finds me, it doesn’t save me.',
      child: ExcludeSemantics(
        child: Material(
          color:
              checked
                  ? IEyeColors.amber.withValues(alpha: 0.16)
                  : IEyeColors.paperDim,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: checked ? IEyeColors.amberDeep : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                    color:
                        checked
                            ? IEyeColors.amberDeep
                            : IEyeColors.charcoalMuted,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'I understand: iEye finds me, it doesn’t save me.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: IEyeColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
