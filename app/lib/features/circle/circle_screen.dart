import 'package:flutter/material.dart';

import '../../core/checker.dart';
import '../../core/circle.dart';
import '../../theme/ieye_theme.dart';
import '../../widgets/coverage_note_banner.dart';

/// Circle visibility + graceful exit (#18, PRD §3D). A checker sees who else is
/// watching and roughly who's nearest — killing both duplicate-response and the
/// "someone else will go" bystander gap — and can step down in one action, with
/// the owner's coverage updated immediately (no silent gaps).
class CircleScreen extends StatefulWidget {
  const CircleScreen({
    super.key,
    required this.store,
    required this.viewerId,
    this.ownerName = 'Sandeep',
  });

  final CircleStore store;

  /// Which member is "you" (the checker viewing their own circle).
  final String viewerId;
  final String ownerName;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  // Local, so the stepped-down screen is tied to THIS viewer's own action — not
  // the store's global undo flag (which a later resignation could overwrite).
  bool _steppedDown = false;

  // Stepping down drops someone from a life-safety circle, so confirm first;
  // the stepped-down screen then still offers a one-tap undo. Deliberate, not
  // a multi-screen ordeal — and the owner's coverage updates immediately.
  Future<void> _confirmStepDown() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Step down from ${widget.ownerName}’s circle?'),
            content: Text(
              '${widget.ownerName} will be told their coverage changed. '
              'You can undo this right after.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, step down'),
              ),
            ],
          ),
    );
    if (ok == true) {
      widget.store.resign(widget.viewerId);
      if (mounted) setState(() => _steppedDown = true);
    }
  }

  void _undo() {
    widget.store.undoLastResign();
    setState(() => _steppedDown = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            if (_steppedDown) {
              return _SteppedDown(
                ownerName: widget.ownerName,
                onUndo: _undo,
                onClose: () => Navigator.maybePop(context),
              );
            }
            return _Roster(
              circle: widget.store.circle,
              viewerId: widget.viewerId,
              ownerName: widget.ownerName,
              onStepDown: _confirmStepDown,
            );
          },
        ),
      ),
    );
  }
}

String _reachLabel(CheckerReach r) =>
    r == CheckerReach.canGoInPerson ? 'Can go in person' : 'Call or message';

class _Roster extends StatelessWidget {
  const _Roster({
    required this.circle,
    required this.viewerId,
    required this.ownerName,
    required this.onStepDown,
  });

  final Circle circle;
  final String viewerId;
  final String ownerName;
  final VoidCallback onStepDown;

  @override
  Widget build(BuildContext context) {
    final note = circle.coverageNote;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$ownerName’s circle',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: IEyeColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The people watching over $ownerName. You can see who else is here and '
            'roughly who’s nearest — so no one assumes someone else will go.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: IEyeColors.charcoalSoft,
            ),
          ),

          // Checkers see coverage gaps too — honesty isn't only for the owner.
          if (note != null) ...[
            const SizedBox(height: 20),
            CoverageNoteBanner(note),
          ],

          const SizedBox(height: 24),
          for (final m in circle.byProximity)
            _MemberRow(
              member: m,
              isViewer: m.id == viewerId,
              onStepDown: m.id == viewerId ? onStepDown : null,
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isViewer,
    this.onStepDown,
  });

  final CircleMember member;
  final bool isViewer;
  final VoidCallback? onStepDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merge name + proximity + reach into ONE screen-reader announcement
          // (e.g. "Maria, you. Nearby. Can go in person.") instead of fragments.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isViewer ? '${member.name} · You' : member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: IEyeColors.charcoal,
                        ),
                      ),
                    ),
                    Text(
                      member.proximity.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: IEyeColors.tealDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _reachLabel(member.reach),
                  style: const TextStyle(
                    fontSize: 14,
                    color: IEyeColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
          if (isViewer && onStepDown != null) ...[
            const SizedBox(height: 8),
            // One action to step down (it confirms, then is undoable). 48dp+
            // tap target for elderly / tremor users.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onStepDown,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Step down'),
                style: TextButton.styleFrom(
                  foregroundColor: IEyeColors.charcoalSoft,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SteppedDown extends StatelessWidget {
  const _SteppedDown({
    required this.ownerName,
    required this.onUndo,
    required this.onClose,
  });

  final String ownerName;
  final VoidCallback onUndo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You’ve stepped down.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: IEyeColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$ownerName has been told their coverage changed, so the gap is never '
            'a surprise. Thank you for the time you gave.',
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: IEyeColors.charcoalSoft,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUndo,
              child: const Text('Undo — I’ll stay'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: onClose,
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IEyeColors.charcoalSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
