/// The welfare signal — the ONLY thing a trigger sink is ever handed.
///
/// NON-NEGOTIABLE, STRUCTURAL (PRD §4, CLAUDE.md): the welfare Beat is benign and
/// recoverable ("go check on me at [address]"). It must NEVER carry or trigger an
/// irreversible secret / will payload — that is a SEPARATE Maktub Beat, with a
/// separate key, in a separate app. A dead battery while hiking must never deliver
/// a will to your heirs.
///
/// We enforce this *structurally, not by convention*: this is the only payload
/// type the [TriggerSink] accepts, and it is a `final` class whose fields can hold
/// nothing but benign, recoverable welfare data. There is deliberately no
/// free-form blob, no `bytes`, no `payload`, no `secret` — so a secret/will is not
/// merely discouraged, it is *unrepresentable* here. The type system is the guard.
final class WelfareSignal {
  const WelfareSignal._({
    required this.kind,
    required this.rung,
    this.addressNote,
  });

  /// Slow silence (Tier-0 today) or, later, a fast acute event. Either way the
  /// payload stays benign.
  final WelfareKind kind;

  /// Which rung of the escalation ladder this signal is for.
  final WelfareRung rung;

  /// A short, owner-pre-authorised static note for the physical-check rung only
  /// (e.g. "side gate, spare key under the third pot"). Opt-in, recoverable,
  /// never a live location, never a secret. Null below rung 4.
  final String? addressNote;

  /// The "we've gone quiet" signal. An addressNote is *structurally* dropped
  /// unless this is the physical-check rung — so even a careless caller cannot
  /// attach it earlier. At rung 4 it is benign + opt-in, never a secret/will.
  factory WelfareSignal.silence({
    required WelfareRung rung,
    String? addressNote,
  }) {
    return WelfareSignal._(
      kind: WelfareKind.silence,
      rung: rung,
      addressNote: rung == WelfareRung.physicalCheck ? addressNote : null,
    );
  }
}

enum WelfareKind {
  /// Prolonged absence of life — the slow path (PRD §1, Tier-0 launch).
  silence,

  /// A fast acute event (fall / crash / cardiac). Reserved for later tiers; the
  /// payload is still benign.
  acuteEvent,
}

/// Re-exported alias so callers can stay in welfare terms.
typedef WelfareRung = EscalationRung;

/// The escalation ladder (PRD §3E). Cheap filters catch battery-died cases early;
/// only genuine silence reaches the expensive physical-check rung.
enum EscalationRung {
  /// Rung 0 — silent pre-check. No human is bothered; re-check cheap signals and
  /// the battery-death label. Protects the whole ladder from alarm fatigue.
  silentPrecheck,

  /// Rung 1 — ping the owner (full-screen, easy one-tap "I'm fine" cancel).
  pingOwner,

  /// Rung 2 — the circle, cheap contact first ("call him, takes 30 seconds").
  circle,

  /// Rung 3 — widen the circle.
  widenCircle,

  /// Rung 4 — physical check. Carries the opt-in address note; never the will.
  physicalCheck,
}

extension EscalationRungLabel on EscalationRung {
  /// Human label — never protocol words (PRD §6).
  String get label => switch (this) {
    EscalationRung.silentPrecheck => 'Quiet double-check',
    EscalationRung.pingOwner => 'Checking you’re okay',
    EscalationRung.circle => 'Telling the people you chose',
    EscalationRung.widenCircle => 'Widening the circle',
    EscalationRung.physicalCheck => 'Asking someone to come by',
  };
}
