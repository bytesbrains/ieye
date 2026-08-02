import 'fingerprint_rules.dart';
import 'home_scan_model.dart';

/// The result of one scan: every device we saw, each already assessed by the
/// [FingerprintEngine]. Pure data — it holds no transport and is never synced
/// (the inventory is a map of someone's home; it stays on the phone).
class ScanReport {
  ScanReport({required this.startedAt, required this.devices, this.wifi});

  final DateTime startedAt;
  final List<DeviceReport> devices;

  /// Network-level Wi-Fi findings (open/weak encryption), null if not gathered.
  final WifiReport? wifi;

  Iterable<Finding> get _allFindings => [
        ...devices.expand((d) => d.findings),
        ...?wifi?.findings,
      ];

  int get deviceCount => devices.length;

  /// Devices that had at least one finding, worst-first (for the report list).
  List<DeviceReport> get flagged {
    final list = devices.where((d) => d.findings.isNotEmpty).toList();
    list.sort((a, b) => (a.worst!.index).compareTo(b.worst!.index));
    return list;
  }

  int get cleanDeviceCount => deviceCount - flagged.length;

  int get findingCount => _allFindings.length;

  int get criticalCount =>
      _allFindings.where((f) => f.severity == Severity.critical).length;

  bool get anyFindings => findingCount > 0;

  /// The single worst severity across the whole scan (null if nothing found).
  Severity? get worst {
    Severity? w;
    for (final f in _allFindings) {
      if (w == null || f.severity.index < w.index) w = f.severity;
    }
    return w;
  }
}

/// Produces [ScanReport]s. The only thing that differs by platform is the
/// implementation: [StubScanner] now (demo data, zero native code), a real
/// socket-discovery scanner behind a platform channel later. Everything downstream
/// — the engine, the UI — is written against this interface, so the real scanner
/// drops in with no UI change.
abstract interface class NetworkScanner {
  Future<ScanReport> scan();
}

/// Demo scanner: replays a representative vulnerable network through the real
/// [FingerprintEngine], so the whole flow (button → progress → report) is
/// exercisable before any native discovery code exists. It stays honest by using
/// the SAME engine the real scanner will — only the observations are canned.
class StubScanner implements NetworkScanner {
  const StubScanner({
    this.engine = const FingerprintEngine(),
    this.settleDelay = const Duration(milliseconds: 1600),
  });

  final FingerprintEngine engine;

  /// A brief pause so the UI's "scanning…" state is real, not a flash.
  final Duration settleDelay;

  @override
  Future<ScanReport> scan() async {
    await Future<void>.delayed(settleDelay);
    final devices = [for (final o in _demoObservations) engine.assess(o)];
    // Representative Wi-Fi: an older WPA/TKIP network, to demo the encryption
    // stat + a MEDIUM finding. Generic name — not a real SSID.
    const wifiObs = WifiObservation(
      ssid: 'home-network',
      security: WifiSecurity.wpaTkip,
      band: '2.4 GHz',
      channel: 6,
    );
    return ScanReport(
      startedAt: DateTime.now(),
      devices: devices,
      wifi: WifiReport(observation: wifiObs, findings: engine.assessWifi(wifiObs)),
    );
  }

  /// Representative demo devices: four XiongMai cameras (cloud/P2P on), two units
  /// hidden behind nginx, a TP-Link router, and one quiet host. Private RFC1918
  /// addresses and public product strings only — no serials, no credentials.
  static const List<DeviceObservation> _demoObservations = [
    DeviceObservation(
      ip: '192.168.0.148',
      openPorts: {80, 554, 8000, 8899, 34567},
      httpServerBanner: 'IPC_GK7205V200_G4F_S38',
    ),
    DeviceObservation(
      ip: '192.168.0.151',
      openPorts: {80, 554, 8000, 8899, 34567},
      httpServerBanner: 'IPC_GK7205V200_G4F_S38',
    ),
    DeviceObservation(
      ip: '192.168.0.192',
      openPorts: {80, 554, 8000, 8899, 34567},
      httpServerBanner: 'IPC_GK7205V200_G4F_S38',
    ),
    DeviceObservation(
      ip: '192.168.0.216',
      openPorts: {80, 554, 8000, 8899, 34567},
      httpServerBanner: 'IPC_GK7205V200_G4H_S38',
    ),
    DeviceObservation(
      ip: '192.168.0.3',
      openPorts: {80, 554, 8000},
      httpServerBanner: 'nginx',
      rtspMediaMagic: '494D4B48',
    ),
    DeviceObservation(
      ip: '192.168.0.4',
      openPorts: {80, 554, 8000},
      httpServerBanner: 'nginx',
      rtspMediaMagic: '494D4B48',
    ),
    DeviceObservation(
      ip: '192.168.0.1',
      openPorts: {80},
      httpServerBanner: 'TP-LINK HTTPD/1.0',
    ),
    DeviceObservation(ip: '192.168.0.139', openPorts: {}),
  ];
}
