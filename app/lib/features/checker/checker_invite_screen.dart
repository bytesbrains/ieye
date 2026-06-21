import 'package:flutter/material.dart';

import '../../core/checker.dart';
import '../../theme/ieye_theme.dart';

/// The checker consent handshake (#17, PRD §3D). A named person arrives here from
/// an invite and walks four steps: read the plain expectation → ACTIVELY accept →
/// set how they can help → rehearse one practice alert → done. No silent
/// enrolment; nothing is delivered off-device (mode-agnostic).
class CheckerInviteScreen extends StatefulWidget {
  const CheckerInviteScreen({super.key, required this.invite, this.onAccepted});

  final CheckerInvite invite;

  /// Called once the handshake is complete (accepted + availability + rehearsed).
  final void Function(CheckerConsent consent)? onAccepted;

  @override
  State<CheckerInviteScreen> createState() => _CheckerInviteScreenState();
}

enum _Step { invite, availability, rehearsal, done, declined }

class _CheckerInviteScreenState extends State<CheckerInviteScreen> {
  _Step _step = _Step.invite;
  CheckerReach? _reach;

  String get _owner => widget.invite.ownerName;

  void _go(_Step s) => setState(() => _step = s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_step) {
          _Step.invite => _invite(),
          _Step.availability => _availability(),
          _Step.rehearsal => _rehearsal(),
          _Step.done => _done(),
          _Step.declined => _declined(),
        },
      ),
    );
  }

  // ---- Step 1: the invite + ACTIVE accept (no pre-ticked box) ----
  Widget _invite() {
    return _StepScaffold(
      title: '$_owner asked you to watch over them.',
      progress: 'Step 1 of 3',
      children: [
        Text(
          widget.invite.expectation,
          style: const TextStyle(
            fontSize: 18,
            height: 1.5,
            color: IEyeColors.charcoalSoft,
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Yes, I’ll be one of $_owner’s people',
          onPressed: () => _go(_Step.availability),
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'I can’t right now',
          onPressed: () => _go(_Step.declined),
        ),
      ],
    );
  }

  // ---- Step 2: availability the ladder respects ----
  Widget _availability() {
    return _StepScaffold(
      title: 'If $_owner goes quiet, how can you help?',
      subtitle: 'Pick what’s true for you — you won’t be asked to do more.',
      onBack: () => _go(_Step.invite),
      progress: 'Step 2 of 3',
      children: [
        for (final reach in CheckerReach.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceCard(
              title: reach.label,
              blurb: reach.blurb,
              selected: _reach == reach,
              onTap: () => setState(() => _reach = reach),
            ),
          ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Continue',
          onPressed: _reach == null ? null : () => _go(_Step.rehearsal),
        ),
      ],
    );
  }

  // ---- Step 3: rehearse one real-looking alert ----
  Widget _rehearsal() {
    return _StepScaffold(
      title: 'One practice run, so it’s familiar.',
      subtitle:
          'Before it’s ever real, here’s exactly what you’d get — so if the day '
          'ever comes, you’ll know just what to do.',
      onBack: () => _go(_Step.availability),
      progress: 'Step 3 of 3',
      children: [
        _PracticeAlert(owner: _owner),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'I’ve seen the drill — I’m ready',
          onPressed: () {
            widget.onAccepted?.call(
              CheckerConsent(
                accepted: true,
                reach: _reach,
                rehearsalCompleted: true,
              ),
            );
            _go(_Step.done);
          },
        ),
      ],
    );
  }

  // ---- Step 4: done ----
  Widget _done() {
    final eligible = _reach == CheckerReach.canGoInPerson;
    return _StepScaffold(
      title: 'You’re set. You’re one of $_owner’s people now.',
      children: [
        _DoneRow(
          Icons.check_circle_outline,
          'You accepted — no surprises later.',
        ),
        _DoneRow(
          eligible ? Icons.directions_walk : Icons.call_outlined,
          eligible
              ? 'If it ever comes to it, you may be asked to go check in person.'
              : 'You’ll be asked to call or message — never sent to the door.',
        ),
        _DoneRow(
          Icons.notifications_active_outlined,
          'You’ve seen the practice alert, so the real one won’t be a surprise.',
        ),
        const SizedBox(height: 28),
        Text(
          'Thank you. Most of the time this asks nothing of you at all — it just '
          'means $_owner won’t go unseen.',
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: IEyeColors.charcoalMuted,
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Done',
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _declined() {
    return _StepScaffold(
      title: 'No problem.',
      children: [
        Text(
          'We’ll let $_owner know you can’t right now. You can always say yes '
          'later if things change — there’s no hard feelings here.',
          style: const TextStyle(
            fontSize: 18,
            height: 1.5,
            color: IEyeColors.charcoalSoft,
          ),
        ),
        const SizedBox(height: 28),
        // The copy promises "you can say yes later" — so offer the way back.
        _PrimaryButton(
          label: 'Actually, I’ll help',
          onPressed: () => _go(_Step.invite),
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'Close',
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}

/// Common step layout: scrollable, generous, one clear headline.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    this.subtitle,
    this.onBack,
    this.progress,
    required this.children,
  });

  final String title;
  final String? subtitle;

  /// When set, a labelled "Back" affordance is shown — so a checker can return
  /// to re-read what they're agreeing to before committing (consent flow).
  final VoidCallback? onBack;

  /// e.g. "Step 2 of 3".
  final String? progress;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: IEyeColors.charcoalSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              const Spacer(),
              if (progress != null)
                Text(
                  progress!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: IEyeColors.charcoalMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: IEyeColors.charcoal,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: IEyeColors.charcoalSoft,
              ),
            ),
          ],
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.blurb,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String blurb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Announce as a selectable button with its state — this is a consent choice,
    // it must be operable and clear via a screen reader, not just visually.
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $blurb',
      child: ExcludeSemantics(
        child: Material(
          color:
              selected
                  ? IEyeColors.amber.withValues(alpha: 0.16)
                  : IEyeColors.paperDim,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? IEyeColors.amberDeep : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color:
                        selected
                            ? IEyeColors.amberDeep
                            : IEyeColors.charcoalMuted,
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
                            color: IEyeColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          blurb,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: IEyeColors.charcoalSoft,
                          ),
                        ),
                      ],
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

/// A faithful sample of a real check-in request — clearly marked PRACTICE, and
/// always carrying the cheap action ("call, takes 30 seconds").
class _PracticeAlert extends StatelessWidget {
  const _PracticeAlert({required this.owner});
  final String owner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IEyeColors.amber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: IEyeColors.amberDeep,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'PRACTICE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: IEyeColors.amberDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$owner has been quiet longer than usual. Please call them — takes 30 '
            'seconds. Probably nothing.',
            style: const TextStyle(
              fontSize: 17,
              height: 1.45,
              color: IEyeColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: IEyeColors.tealDeep, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: IEyeColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width primary action — wraps/centers long copy (e.g. a long owner name in
/// "Yes, I'll be one of … 's people") instead of clipping. onPressed null = disabled.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: IEyeColors.charcoalSoft,
          ),
        ),
      ),
    );
  }
}
