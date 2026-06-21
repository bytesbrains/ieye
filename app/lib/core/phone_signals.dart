import 'package:flutter/foundation.dart';

/// Tier-0 phone-only signals (#14). The only things a phone can know about life
/// on its own: when the owner last interacted (a proxy for "alive and about"),
/// the battery, and whether the phone is reporting in at all. Liveness is read at
/// the edge — these are the raw inputs to the rhythm rule, never synced anywhere.
@immutable
class PhoneSignals {
  const PhoneSignals({
    required this.lastInteraction,
    required this.batteryPercent,
    required this.charging,
    required this.reachable,
  });

  /// Last time the owner used the phone — the phone-only proxy for a sign of life.
  final DateTime lastInteraction;
  final int batteryPercent;
  final bool charging;

  /// Is the phone reporting in right now? False = off / dead / OS killed the app
  /// in the background — the dominant phone-only blind spot.
  final bool reachable;
}

/// Source of [PhoneSignals]. The REAL implementation reads battery + activity +
/// background pings via platform plugins (later); this interface lets the brain
/// and tests stay independent of the platform.
abstract interface class PhoneSignalsSource implements Listenable {
  PhoneSignals get current;

  /// Release resources. Disposal is part of the contract so an owner can tear a
  /// source down without knowing its concrete type (no casts).
  void dispose();
}

/// In-memory source — healthy by default, and drivable (battery drop, silence,
/// lost contact) so the rhythm rule can be exercised end-to-end with no hardware.
/// The platform source replaces this behind the same interface.
class StubPhoneSignalsSource extends ChangeNotifier
    implements PhoneSignalsSource {
  StubPhoneSignalsSource([PhoneSignals? initial])
    : _current = initial ?? healthy();

  PhoneSignals _current;

  @override
  PhoneSignals get current => _current;

  void update(PhoneSignals signals) {
    _current = signals;
    notifyListeners();
  }

  static PhoneSignals healthy() => PhoneSignals(
    lastInteraction: DateTime.now().subtract(const Duration(minutes: 12)),
    batteryPercent: 80,
    charging: false,
    reachable: true,
  );
}
