import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/core/homescan/home_scan_model.dart';
import 'package:ieye/core/homescan/lan_scanner.dart';

/// A fake network: no real sockets. It says which hosts answer on which ports and
/// what banner they hand back — enough to exercise the sweep + fingerprint wiring.
class _FakeProbe implements HostProbe {
  _FakeProbe(this.ports, this.http, this.rtsp);
  final Map<String, Set<int>> ports;
  final Map<String, String> http;
  final Map<String, RtspInfo> rtsp;

  @override
  Future<Set<int>> openPorts(String ip, List<int> wanted) async =>
      (ports[ip] ?? const {}).intersection(wanted.toSet());

  @override
  Future<String?> httpBanner(String ip) async => http[ip];

  @override
  Future<RtspInfo> rtspInfo(String ip) async => rtsp[ip] ?? const RtspInfo();
}

class _FakeSubnet implements SubnetSource {
  const _FakeSubnet(this.prefix);
  final String? prefix;
  @override
  Future<String?> localPrefix24() async => prefix;
}

void main() {
  DateTime clock() => DateTime.utc(2026, 8, 2);

  test('sweeps the /24 and fingerprints answering hosts via the real engine',
      () async {
    final probe = _FakeProbe(
      {
        '192.168.0.148': {80, 554, 8000, 8899, 34567}, // XM camera
        '192.168.0.1': {80}, // router
        // every other host is silent
      },
      {
        '192.168.0.148': 'IPC_GK7205V200_G4F_S38',
        '192.168.0.1': 'TP-LINK HTTPD/1.0',
      },
      const {},
    );
    final scanner = LanScanner(
      probe: probe,
      subnet: const _FakeSubnet('192.168.0'),
      now: clock,
    );

    final report = await scanner.scan();

    // Only the two answering hosts become devices.
    expect(report.deviceCount, 2);
    expect(report.criticalCount, 1);

    final camera =
        report.devices.firstWhere((d) => d.ip == '192.168.0.148');
    expect(camera.deviceClass, DeviceClass.ipCamera);
    expect(camera.worst, Severity.critical);

    final router = report.devices.firstWhere((d) => d.ip == '192.168.0.1');
    expect(router.deviceClass, DeviceClass.router);
    // Still passive: nothing was verified by touching a device.
    expect(report.devices.expand((d) => d.findings).every((f) => !f.verified),
        isTrue);
  });

  test('no private LAN address → an empty report, not a false all-clear',
      () async {
    final scanner = LanScanner(
      probe: _FakeProbe(const {}, const {}, const {}),
      subnet: const _FakeSubnet(null),
      now: clock,
    );
    final report = await scanner.scan();
    expect(report.deviceCount, 0);
    expect(report.anyFindings, isFalse);
  });
}
