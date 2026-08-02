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

  /// Devices carrying at least one CRITICAL finding. The headline counts
  /// DEVICES ("N devices may be reachable…"), and one camera can emit several
  /// critical findings — so it must not count findings ([criticalCount]).
  int get criticalDeviceCount => devices
      .where((d) => d.findings.any((f) => f.severity == Severity.critical))
      .length;

  /// Devices with at least one finding above INFO — the "Need a look" number.
  /// Info findings are identification ("a printer is here"), not a call to
  /// action; counting them would put every normal smart home on alert
  /// (alarm-fatigue guardrail).
  int get attentionCount => devices
      .where(
        (d) => d.findings.any((f) => f.severity.index < Severity.info.index),
      )
      .length;

  /// True when the scan surfaced no finding above INFO — the "nothing found ≠
  /// safe" state. Info notes may still be present; they identify devices, they
  /// don't assert exposure.
  bool get nothingAboveInfo =>
      _allFindings.every((f) => f.severity == Severity.info);

  bool get anyFindings => findingCount > 0;

  /// The single worst severity across the whole scan (null if nothing found).
  Severity? get worst {
    Severity? w;
    for (final f in _allFindings) {
      if (w == null || f.severity.index < w.index) w = f.severity;
    }
    return w;
  }

  /// Findings grouped by severity — powers the exposure-by-severity overview chart.
  Map<Severity, int> get severityCounts {
    final counts = <Severity, int>{};
    for (final f in _allFindings) {
      counts[f.severity] = (counts[f.severity] ?? 0) + 1;
    }
    return counts;
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
      wifi: WifiReport(
        observation: wifiObs,
        findings: engine.assessWifi(wifiObs),
      ),
    );
  }

  /// Representative demo devices: four XiongMai cameras (cloud/P2P on), two units
  /// hidden behind nginx, a DVR holding stored footage, a TP-Link router, and one
  /// quiet host. Private RFC1918 addresses and public product strings only — no
  /// serials, no credentials.
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
    // A network video recorder — the box that stores the footage. Dahua-style
    // DVRIP (37777) + a DVR web UI, restreaming over RTSP.
    DeviceObservation(
      ip: '192.168.0.201',
      openPorts: {80, 554, 37777},
      httpServerBanner: 'DVR-Webs',
    ),
    // A NAS holding the household's files — Synology DSM (5000/5001) + SMB, and
    // it announces itself over mDNS so the report can show its real name.
    DeviceObservation(
      ip: '192.168.0.20',
      openPorts: {80, 443, 445, 5000, 5001},
      httpServerBanner: 'Synology DiskStation',
      mdnsName: 'DiskStation',
      mdnsServices: {'_smb._tcp', '_afpovertcp._tcp'},
    ),
    // A network printer — raw print (9100) + JetDirect web UI; named via mDNS.
    DeviceObservation(
      ip: '192.168.0.30',
      openPorts: {80, 161, 9100},
      httpServerBanner: 'HP JetDirect',
      mdnsName: 'HP OfficeJet Pro',
      mdnsServices: {'_ipp._tcp', '_printer._tcp'},
    ),
    // A cheap Android TV box with the ADB debug bridge (5555) left wide open;
    // mDNS gives it a friendly name.
    DeviceObservation(
      ip: '192.168.0.40',
      openPorts: {8009, 5555},
      mdnsName: 'Living Room TV',
      mdnsServices: {'_googlecast._tcp'},
    ),
    // A smart-home hub (Home Assistant) that controls the house.
    DeviceObservation(
      ip: '192.168.0.50',
      openPorts: {8123},
      httpServerBanner: 'Home Assistant',
      mdnsName: 'Home Assistant',
      mdnsServices: {'_home-assistant._tcp'},
    ),
    // A speaker that answers NO scan port — found and classified only because it
    // broadcasts its name + service over mDNS (the whole point of adding mDNS).
    DeviceObservation(
      ip: '192.168.0.55',
      openPorts: {},
      mdnsName: 'Kitchen Speaker',
      mdnsServices: {'_googlecast._tcp'},
    ),
    // A little home server left wide open — plaintext Telnet + a no-auth database.
    DeviceObservation(ip: '192.168.0.70', openPorts: {23, 6379}),
    DeviceObservation(
      ip: '192.168.0.1',
      openPorts: {80},
      httpServerBanner: 'TP-LINK HTTPD/1.0',
    ),
    DeviceObservation(ip: '192.168.0.139', openPorts: {}),
  ];
}
