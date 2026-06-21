import 'package:flutter/foundation.dart';

import 'welfare_signal.dart';

/// The pluggable delivery seam (PRD §5, #12). The detection brain is shared; only
/// the trigger sink swaps. "Mode" is a delivery backend, not two apps.
///
/// The seam takes ONLY a [WelfareSignal] — never a raw blob — so a sink can never
/// be handed a secret/will (see welfare_signal.dart). Concrete sinks land later:
///   • SovereignSink — on-chain Beat + scoped session key (#30/#31/#32)
///   • EasySink      — backend timer + multi-channel dispatch, D-041-gated (#20)
abstract interface class TriggerSink {
  String get name;

  /// Honesty flag: does firing this sink sign or send anything off-device?
  /// The green-lit prototype runs only sinks where this is `false` ("signs
  /// nothing" — CLAUDE.md). The UI uses this to never overclaim reach.
  bool get sendsOffDevice;

  Future<void> fire(WelfareSignal signal);
}

/// The only sink wired today. Signs NOTHING, sends NOTHING off-device — it just
/// records intent locally so the escalation logic can be built and tested without
/// any on-chain key or backend. This is what keeps the prototype inside the
/// green-light ("provided it signs nothing").
class LocalNoopSink implements TriggerSink {
  final List<WelfareSignal> fired = <WelfareSignal>[];

  @override
  String get name => 'Local (no-op)';

  @override
  bool get sendsOffDevice => false;

  @override
  Future<void> fire(WelfareSignal signal) async {
    fired.add(signal);
    debugPrint(
      '[iEye] LocalNoopSink: would escalate "${signal.rung.label}" '
      '(${signal.kind.name}) — nothing sent off-device.',
    );
  }
}
