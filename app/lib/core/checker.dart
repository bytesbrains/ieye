/// Checker consent — the product's spine (PRD §3D, #17). The checkers are the
/// people who agree to be contacted, and at the sharp end to physically go check.
/// Their onboarding is where welfare apps live or die, so consent here is an
/// ACTIVE accept stating plainly what they're agreeing to — never silent
/// enrolment, never a pre-ticked box. Mode-agnostic: this is pure consent state,
/// it makes no assumption about Easy vs Sovereign delivery.
library;

/// What a named person is asked to agree to, stated in plain welfare terms.
class CheckerInvite {
  const CheckerInvite({required this.ownerName, this.silenceWindowHours = 14});

  final String ownerName;
  final int silenceWindowHours;

  /// The plain-language expectation, shown verbatim on the invite — what it
  /// actually costs them (a few texts a year; very rarely a "go check").
  String get expectation =>
      '$ownerName asked you to be one of the people contacted if their phone goes '
      'silent for about $silenceWindowHours hours. Roughly: you might get a '
      '“please call $ownerName” text a few times a year, and — very rarely — a '
      '“please go check on them.”';
}

/// How a checker can help — the bit the escalation ladder respects (PRD §3E).
/// "I'm 2 hours away — don't make me rung 4" is a first-class choice, not a
/// fallback.
enum CheckerReach {
  /// Close enough to physically go check — eligible for the physical-check rung.
  canGoInPerson,

  /// Can call or message, but too far to be sent to the door.
  callOnly,
}

extension CheckerReachCopy on CheckerReach {
  String get label => switch (this) {
    CheckerReach.canGoInPerson => 'I can go check in person',
    CheckerReach.callOnly => 'I can call or message',
  };

  String get blurb => switch (this) {
    CheckerReach.canGoInPerson =>
      'You’re close enough to drop by if it ever comes to that.',
    CheckerReach.callOnly =>
      'You’ll be asked to call or message — never sent to the door.',
  };
}

/// The result of the handshake. A checker is only `isActive` after THREE things:
/// an explicit accept, an availability choice, and a completed rehearsal — so a
/// checker can never be silently enrolled or arrive cold to a real alert.
class CheckerConsent {
  const CheckerConsent({
    required this.accepted,
    required this.reach,
    required this.rehearsalCompleted,
  });

  final bool accepted;
  final CheckerReach? reach;
  final bool rehearsalCompleted;

  bool get isActive => accepted && reach != null && rehearsalCompleted;

  /// Whether the ladder may escalate this checker to the physical-check rung.
  bool get eligibleForPhysicalCheck =>
      accepted && reach == CheckerReach.canGoInPerson;
}
