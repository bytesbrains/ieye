import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/core/homescan/fingerprint_rules.dart';
import 'package:ieye/core/homescan/home_scan_model.dart';

/// Seeded from a representative XiongMai deployment: the engine must reach the
/// same verdicts a hands-on audit reaches — but by inference, never by logging in.
void main() {
  const engine = FingerprintEngine();

  group('Group A — XiongMai/Sofia cameras (the CRITICAL finding)', () {
    // A representative XiongMai camera: the XM Sofia port pair + web UI.
    final obs = const DeviceObservation(
      ip: '192.168.0.148',
      openPorts: {80, 554, 8000, 8899, 34567},
      httpServerBanner: 'IPC_GK7205V200_G4F_S38',
    );

    test('classifies as a XiongMai IP camera', () {
      final r = engine.assess(obs);
      expect(r.deviceClass, DeviceClass.ipCamera);
      expect(r.vendorFamily, startsWith('XiongMai'));
      expect(r.model, 'IPC_GK7205V200_G4F_S38');
    });

    test('flags internet exposure as CRITICAL', () {
      final r = engine.assess(obs);
      expect(r.worst, Severity.critical);
      final exposure = r.findings
          .firstWhere((f) => f.kind == FindingKind.exposedCameraCloudP2P);
      expect(exposure.severity, Severity.critical);
    });

    test('every mass-tier finding is INFERRED, never verified', () {
      // The load-bearing safety property: the passive scan touches nothing, so it
      // must not claim to have confirmed anything.
      final r = engine.assess(obs);
      expect(r.findings, isNotEmpty);
      expect(r.findings.every((f) => f.verified == false), isTrue);
    });

    test('surfaces likely-blank password and known-CVE firmware', () {
      final kinds = engine.assess(obs).findings.map((f) => f.kind).toSet();
      expect(kinds, contains(FindingKind.defaultCredentialsLikely));
      expect(kinds, contains(FindingKind.knownVulnerableFirmware));
    });
  });

  group('Group B — XM family hidden behind nginx (RTSP magic tell)', () {
    // No proprietary XM port, but the RTSP media starts with "IMKH".
    final obs = const DeviceObservation(
      ip: '192.168.0.3',
      openPorts: {80, 554, 8000},
      httpServerBanner: 'nginx',
      rtspMediaMagic: '494D4B48',
    );

    test('still unmasked as a XiongMai camera via the IMKH magic', () {
      final r = engine.assess(obs);
      expect(r.deviceClass, DeviceClass.ipCamera);
      expect(r.vendorFamily, startsWith('XiongMai'));
    });
  });

  group('Router — TP-Link (specialist escalation, no false alarm)', () {
    final obs = const DeviceObservation(
      ip: '192.168.0.1',
      openPorts: {80},
      httpServerBanner: 'TP-LINK HTTPD/1.0',
    );

    test('classified as a router and escalated to a specialist, not CRITICAL', () {
      final r = engine.assess(obs);
      expect(r.deviceClass, DeviceClass.router);
      expect(r.worst, isNot(Severity.critical));
      expect(r.findings.every((f) => f.fixOwner == FixOwner.specialist), isTrue);
    });
  });

  group('Unknown host — no finding invented', () {
    test('a plain host produces no scary findings', () {
      final r = engine.assess(
        const DeviceObservation(ip: '192.168.0.139', openPorts: {}),
      );
      expect(r.deviceClass, DeviceClass.unknown);
      expect(r.findings, isEmpty);
      expect(r.worst, isNull);
    });
  });

  group('Wi-Fi encryption rules', () {
    Finding? only(WifiSecurity s) {
      final f = engine.assessWifi(WifiObservation(security: s));
      return f.isEmpty ? null : f.single;
    }

    test('open Wi-Fi is a HIGH, confirmed (we read the cipher directly)', () {
      final f = only(WifiSecurity.open)!;
      expect(f.severity, Severity.high);
      expect(f.kind, FindingKind.weakWifi);
      expect(f.verified, isTrue); // unlike inferred device findings
    });

    test('WEP is HIGH, WPA/TKIP is MEDIUM', () {
      expect(only(WifiSecurity.wep)!.severity, Severity.high);
      expect(only(WifiSecurity.wpaTkip)!.severity, Severity.medium);
    });

    test('WPA2/WPA3/unknown/unavailable raise nothing (no false all-clear)', () {
      expect(only(WifiSecurity.wpa2), isNull);
      expect(only(WifiSecurity.wpa3), isNull);
      expect(only(WifiSecurity.unknown), isNull);
      expect(only(WifiSecurity.unavailable), isNull);
    });
  });
}
