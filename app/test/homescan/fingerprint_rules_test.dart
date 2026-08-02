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

    test('flags the open live stream (RTSP served on the LAN)', () {
      final stream = engine
          .assess(obs)
          .findings
          .firstWhere((f) => f.kind == FindingKind.exposedCameraStream);
      // MEDIUM, not high: a LAN-served stream is the normal state of nearly
      // every IP camera, so crying HIGH on all of them is alarm fatigue. The
      // CRITICAL cloud/P2P finding is what carries the urgency here.
      expect(stream.severity, Severity.medium);
      // Detect-not-view: we report the stream is offered, never that we opened it.
      expect(stream.whatItMeans, contains('never opens it'));
      expect(stream.whatItMeans, contains('camera offers its video'));
      expect(stream.verified, isFalse);
    });
  });

  group('Recorder — an NVR/DVR holding stored footage', () {
    // A Dahua-style recorder: DVRIP (37777) + a DVR web UI, restreaming RTSP.
    final obs = const DeviceObservation(
      ip: '192.168.0.201',
      openPorts: {80, 554, 37777},
      httpServerBanner: 'DVR-Webs',
    );

    test('classifies as an NVR/DVR, not a plain camera', () {
      expect(engine.assess(obs).deviceClass, DeviceClass.nvr);
    });

    test('flags the reachable recorder — the stored archive, not just live', () {
      final r = engine.assess(obs);
      final rec = r.findings
          .firstWhere((f) => f.kind == FindingKind.exposedRecorder);
      expect(rec.severity, Severity.high);
      expect(rec.whatItMeans, contains('saved recordings'));
      // A recorder restreams too, so the open-stream finding rides along —
      // worded for a recorder, not a camera, since the copy is shared.
      final stream = r.findings
          .firstWhere((f) => f.kind == FindingKind.exposedCameraStream);
      expect(stream.whatItMeans, contains('recorder offers its video'));
      // Passive tier: inferred from the open port, never signed into.
      expect(r.findings.every((f) => f.verified == false), isTrue);
    });

    test('a recorder without an RTSP port flags storage but not a stream', () {
      final kinds = engine
          .assess(
            const DeviceObservation(
              ip: '192.168.0.202',
              openPorts: {80, 37777},
              httpServerBanner: 'NVR',
            ),
          )
          .findings
          .map((f) => f.kind)
          .toSet();
      expect(kinds, contains(FindingKind.exposedRecorder));
      expect(kinds, isNot(contains(FindingKind.exposedCameraStream)));
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

  group('Smart-home device classes (NAS, printer, TV, hub)', () {
    ({DeviceClass cls, FindingKind kind}) assessOne(DeviceObservation o) {
      final r = engine.assess(o);
      return (cls: r.deviceClass, kind: r.findings.first.kind);
    }

    test('a Synology NAS is classed as storage with hardening guidance', () {
      final r = engine.assess(const DeviceObservation(
        ip: '192.168.0.20',
        openPorts: {80, 443, 445, 5000, 5001},
        httpServerBanner: 'Synology DiskStation',
      ));
      expect(r.deviceClass, DeviceClass.nas);
      expect(r.vendorFamily, 'Synology');
      expect(r.findings.map((f) => f.kind),
          contains(FindingKind.storageDeviceFound));
    });

    test('merely finding a device is INFO — presence is not exposure', () {
      // Identifying a NAS/printer/TV/hub is context, not a call to action. If
      // these counted as MEDIUM the "need a look" number would put every normal
      // smart home on alert, and the honest "nothing found" state — the one
      // that says a passive scan proves nothing — could never be reached.
      Severity worstOf(DeviceObservation o) => engine.assess(o).worst!;
      expect(
        worstOf(const DeviceObservation(
          ip: '192.168.0.20',
          openPorts: {445, 5000},
        )),
        Severity.info,
      );
      expect(
        worstOf(const DeviceObservation(ip: '192.168.0.30', openPorts: {9100})),
        Severity.info,
      );
      expect(
        worstOf(const DeviceObservation(ip: '192.168.0.41', openPorts: {8009})),
        Severity.info,
      );
      expect(
        worstOf(const DeviceObservation(ip: '192.168.0.50', openPorts: {8123})),
        Severity.info,
      );
    });

    test('a JetDirect printer is classed as a printer', () {
      final r = assessOne(const DeviceObservation(
        ip: '192.168.0.30',
        openPorts: {80, 161, 9100},
        httpServerBanner: 'HP JetDirect',
      ));
      expect(r.cls, DeviceClass.printer);
      expect(r.kind, FindingKind.printerFound);
    });

    test('a Chromecast/Android TV is classed as a media device', () {
      final r = engine.assess(
        const DeviceObservation(ip: '192.168.0.41', openPorts: {8008, 8009}),
      );
      expect(r.deviceClass, DeviceClass.mediaDevice);
    });

    test('Home Assistant (8123) is classed as a smart hub', () {
      final r = assessOne(const DeviceObservation(
        ip: '192.168.0.50',
        openPorts: {8123},
        httpServerBanner: 'Home Assistant',
      ));
      expect(r.cls, DeviceClass.smartHub);
      expect(r.kind, FindingKind.smartHubFound);
    });
  });

  group('mDNS identity — the device announces what it is', () {
    test('a _googlecast service classifies a media device with NO open ports', () {
      // The whole point of mDNS: a speaker that answers no TCP port is still found
      // and correctly classified from what it broadcasts.
      final r = engine.assess(const DeviceObservation(
        ip: '192.168.0.55',
        openPorts: {},
        mdnsName: 'Kitchen Speaker',
        mdnsServices: {'_googlecast._tcp'},
      ));
      expect(r.deviceClass, DeviceClass.mediaDevice);
      expect(r.observation.mdnsName, 'Kitchen Speaker');
    });

    test('_ipp → printer, _home-assistant → hub', () {
      DeviceClass cls(String svc) => engine
          .assess(DeviceObservation(ip: '192.168.0.9', mdnsServices: {svc}))
          .deviceClass;
      expect(cls('_ipp._tcp'), DeviceClass.printer);
      expect(cls('_home-assistant._tcp'), DeviceClass.smartHub);
    });

    test('file sharing alone is a computer, not a NAS (no ransomware scare)', () {
      // A Mac with File Sharing / Time Machine on advertises exactly these. It
      // must not be called a NAS and handed storage-hardening advice.
      final mac = engine.assess(const DeviceObservation(
        ip: '192.168.0.11',
        openPorts: {445},
        mdnsName: 'Sandeep’s MacBook',
        mdnsServices: {'_smb._tcp', '_afpovertcp._tcp', '_adisk._tcp'},
      ));
      expect(mac.deviceClass, DeviceClass.computer);
      expect(mac.findings, isEmpty);

      // With corroboration (a DSM admin port), it IS a NAS.
      final nas = engine.assess(const DeviceObservation(
        ip: '192.168.0.20',
        openPorts: {445, 5000},
        mdnsServices: {'_smb._tcp'},
      ));
      expect(nas.deviceClass, DeviceClass.nas);
    });

    test('mDNS keeps the banner vendor and model', () {
      // The device's name says WHAT it is; its banner says WHOSE it is. A NAS
      // identified over mDNS must not lose "Synology" from the report subtitle.
      final r = engine.assess(const DeviceObservation(
        ip: '192.168.0.20',
        openPorts: {80, 443, 445, 5000, 5001},
        httpServerBanner: 'Synology DiskStation',
        mdnsName: 'DiskStation',
        mdnsServices: {'_smb._tcp', '_afpovertcp._tcp'},
      ));
      expect(r.deviceClass, DeviceClass.nas);
      expect(r.vendorFamily, 'Synology');
    });

    test('mDNS never masks the vulnerable XM camera family', () {
      // A camera that also advertises _rtsp must still get its CRITICAL findings —
      // the name must not short-circuit the family fingerprint.
      final r = engine.assess(const DeviceObservation(
        ip: '192.168.0.148',
        openPorts: {80, 554, 8899, 34567},
        httpServerBanner: 'IPC_GK7205V200_G4F_S38',
        mdnsName: 'Front Door Cam',
        mdnsServices: {'_rtsp._tcp'},
      ));
      expect(r.deviceClass, DeviceClass.ipCamera);
      expect(r.worst, Severity.critical);
      expect(r.observation.mdnsName, 'Front Door Cam'); // name still available
    });

    test('a HomeKit/Cast camera keeps its CRITICAL findings', () {
      // THE regression: HomeKit cameras advertise _hap and Google cameras
      // _googlecast. If the announced identity won, assess() would dispatch to
      // the hub/media rules and silently drop exposedCameraCloudP2P.
      for (final svc in ['_hap._tcp', '_googlecast._tcp']) {
        final r = engine.assess(DeviceObservation(
          ip: '192.168.0.149',
          openPorts: const {80, 554, 8899, 34567},
          httpServerBanner: 'IPC_GK7205V200_G4F_S38',
          mdnsName: 'Nursery Cam',
          mdnsServices: {svc},
        ));
        expect(r.deviceClass, DeviceClass.ipCamera, reason: svc);
        expect(
          r.findings.map((f) => f.kind),
          contains(FindingKind.exposedCameraCloudP2P),
          reason: svc,
        );
      }
    });

    test('a recorder announcing itself over mDNS is still a recorder', () {
      final r = engine.assess(const DeviceObservation(
        ip: '192.168.0.201',
        openPorts: {80, 37777},
        httpServerBanner: 'DVR-Webs',
        mdnsName: 'Hallway NVR',
        mdnsServices: {'_googlecast._tcp'},
      ));
      expect(r.deviceClass, DeviceClass.nvr);
      expect(
        r.findings.map((f) => f.kind),
        contains(FindingKind.exposedRecorder),
      );
    });
  });

  group('Cross-cutting exposures (any host, Mirai-class killers)', () {
    test('open Telnet (23) is HIGH — the botnet pattern — on any host', () {
      final r = engine.assess(
        const DeviceObservation(ip: '192.168.0.70', openPorts: {23}),
      );
      // Even an unclassified host must surface it.
      expect(r.deviceClass, DeviceClass.unknown);
      final t =
          r.findings.firstWhere((f) => f.kind == FindingKind.insecureTelnet);
      expect(t.severity, Severity.high);
      expect(t.verified, isFalse);
    });

    test('open ADB (5555) is HIGH — password-less remote code execution', () {
      final kinds = engine
          .assess(const DeviceObservation(ip: '192.168.0.40', openPorts: {8009, 5555}))
          .findings
          .map((f) => f.kind);
      // The TV class is found AND the open debug bridge is flagged.
      expect(kinds, contains(FindingKind.mediaDeviceFound));
      expect(kinds, contains(FindingKind.openAdb));
    });

    test('a reachable database (Redis 6379) is HIGH and names the engine', () {
      final r = engine.assess(
        const DeviceObservation(ip: '192.168.0.71', openPorts: {6379}),
      );
      final db =
          r.findings.firstWhere((f) => f.kind == FindingKind.exposedDatabase);
      expect(db.severity, Severity.high);
      expect(db.title, contains('Redis'));
    });

    test('every reachable database is named — two open means two findings', () {
      final titles = engine
          .assess(
            const DeviceObservation(
              ip: '192.168.0.72',
              openPorts: {6379, 5432},
            ),
          )
          .findings
          .where((f) => f.kind == FindingKind.exposedDatabase)
          .map((f) => f.title)
          .toList();
      expect(titles, hasLength(2));
      expect(titles.any((t) => t.contains('Redis')), isTrue);
      expect(titles.any((t) => t.contains('PostgreSQL')), isTrue);
    });

    test('a plain host with no risky ports still invents nothing', () {
      final r = engine.assess(
        const DeviceObservation(ip: '192.168.0.139', openPorts: {}),
      );
      expect(r.findings, isEmpty);
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
