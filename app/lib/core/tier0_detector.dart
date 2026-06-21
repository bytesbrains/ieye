import 'phone_signals.dart';

/// The Tier-0 phone-only rhythm rule (#14, PRD §11). It turns raw [PhoneSignals]
/// into an HONEST assessment — and its whole point is to surface the phone-only
/// limits rather than hide them. The dominant Tier-0 failure is that a dead or
/// silent phone cannot be told apart from a person in trouble; this rule never
/// dresses that up as an all-clear.
enum SensingStatus {
  /// Recent sign of life, healthy battery, phone reporting in.
  watching,

  /// Battery is low — if it dies we lose contact (an honest, pre-emptive caveat).
  batteryLow,

  /// No sign of life beyond the expected window — the actual "go check" signal.
  silenceConcern,

  /// Phone isn't reporting in (off / dead / OS-killed). NOT an all-clear.
  lostContact,
}

class Tier0Config {
  const Tier0Config({
    this.silenceWindow = const Duration(hours: 14),
    this.lowBatteryPercent = 20,
  });

  /// How long without a sign of life before it's a concern (PRD: learned per
  /// person; a fixed default for Tier-0).
  final Duration silenceWindow;
  final int lowBatteryPercent;
}

class Tier0Assessment {
  const Tier0Assessment({
    required this.status,
    required this.lastSignOfLife,
    required this.batteryPercent,
    this.limitNote,
  });

  final SensingStatus status;
  final DateTime lastSignOfLife;
  final int batteryPercent;

  /// The honest phone-only caveat for this state (null when healthy). Surfaced in
  /// coverage so a Tier-0 limit is always visible, never hidden.
  final String? limitNote;

  bool get isHealthy => status == SensingStatus.watching;
}

class Tier0Detector {
  const Tier0Detector([this.config = const Tier0Config()]);

  final Tier0Config config;

  Tier0Assessment assess(PhoneSignals s, DateTime now) {
    // Lost contact dominates everything: phone-only can't distinguish a dead
    // battery from a collapsed person, so this is never a confident all-clear.
    if (!s.reachable) {
      return Tier0Assessment(
        status: SensingStatus.lostContact,
        lastSignOfLife: s.lastInteraction,
        batteryPercent: s.batteryPercent,
        limitNote:
            'We’ve lost contact with your phone. With phone-only watching this '
            'could just be the battery running out — so iEye can’t promise '
            'you’re okay.',
      );
    }
    if (now.difference(s.lastInteraction) >= config.silenceWindow) {
      return Tier0Assessment(
        status: SensingStatus.silenceConcern,
        lastSignOfLife: s.lastInteraction,
        batteryPercent: s.batteryPercent,
        limitNote:
            'No sign of life for a while. If iEye still can’t tell you’re okay, '
            'it will start reaching the people watching over you.',
      );
    }
    if (!s.charging && s.batteryPercent <= config.lowBatteryPercent) {
      return Tier0Assessment(
        status: SensingStatus.batteryLow,
        lastSignOfLife: s.lastInteraction,
        batteryPercent: s.batteryPercent,
        limitNote:
            'Battery low. If the battery runs out, iEye loses contact — and '
            'phone-only watching can’t tell that apart from an emergency. Charge '
            'when you can.',
      );
    }
    return Tier0Assessment(
      status: SensingStatus.watching,
      lastSignOfLife: s.lastInteraction,
      batteryPercent: s.batteryPercent,
    );
  }
}
