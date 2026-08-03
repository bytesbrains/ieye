import 'dart:async';
import 'dart:io';

import 'fingerprint_rules.dart';
import 'home_scan_model.dart';
import 'scanner.dart';

/// The REAL scanner — sweeps the user's own /24 with TCP-connect discovery and
/// feeds each host through the shared [FingerprintEngine]. Pure `dart:io`: no
/// platform channel is needed for sockets or interface enumeration. On iOS the
/// first connect triggers the Local Network prompt (Info.plist declares why).
///
/// SAME NON-NEGOTIABLES (CLAUDE.md): this is passive — it only opens TCP
/// connections and reads what a service volunteers in a banner. It NEVER attempts
/// a login or a credential, so every [Finding] it yields stays inferred
/// ([Finding.verified] == false). The device inventory it builds stays on the
/// phone — this class returns it, it never transmits it.
///
/// The low-level socket work is behind [HostProbe]/[SubnetSource] so the sweep
/// logic is unit-testable with a fake, and the real [SocketHostProbe] is the only
/// part that touches the network.
class LanScanner implements NetworkScanner {
  LanScanner({
    HostProbe? probe,
    SubnetSource? subnet,
    WifiSource? wifi,
    MdnsSource? mdns,
    this.engine = const FingerprintEngine(),
    this.discoveryPorts = defaultDiscoveryPorts,
    this.maxConcurrent = 48,
    DateTime Function() now = DateTime.now,
  })  : _probe = probe ?? const SocketHostProbe(),
        _subnet = subnet ?? const InterfaceSubnetSource(),
        _wifi = wifi ?? const UnsupportedWifiSource(),
        _mdns = mdns ?? const NoMdnsSource(),
        _now = now;

  final HostProbe _probe;
  final SubnetSource _subnet;
  final WifiSource _wifi;
  final MdnsSource _mdns;
  final FingerprintEngine engine;

  /// The ports whose presence tells us a host is worth a closer look. This list
  /// must cover every port the [FingerprintEngine]'s rules key off — a rule whose
  /// port is never swept can never fire (review #81 §1). Cost: [SocketHostProbe]
  /// probes one host's ports concurrently under a ~400ms connect timeout, so a
  /// longer list widens each host's probe fan-out, not the sweep's wall-clock
  /// (still ≈ 254 hosts / [maxConcurrent] × timeout).
  final List<int> discoveryPorts;
  final int maxConcurrent;
  final DateTime Function() _now;

  static const List<int> defaultDiscoveryPorts = [
    // Camera/recorder tells — the flagship findings (XM Sofia pair, RTSP,
    // web UIs, Dahua DVRIP).
    80, 443, 554, 8000, 8080, 8899, 34567, 37777,
    // Cross-cutting killers: remote login + the open Android debug bridge.
    22, 23, 5555,
    // NAS (SMB + Synology DSM), printer (IPP, JetDirect), TV/streaming
    // (Chromecast, Roku), smart-home hub (Home Assistant).
    445, 5000, 5001, 631, 9100, 8008, 8009, 8060, 8123,
    // Databases that should never face the LAN unauthenticated.
    6379, 27017, 3306, 5432, 9200,
  ];

  @override
  Future<ScanReport> scan() async {
    final prefix = await _subnet.localPrefix24();
    // No private LAN address → we can't responsibly sweep. Return an empty (not a
    // reassuring) report; the UI states plainly that it couldn't read the network.
    if (prefix == null) {
      return ScanReport(startedAt: _now(), devices: const []);
    }

    // Phase 1 — discovery: which of .1–.254 answer on any discovery port.
    final alive = <String, Set<int>>{};
    final hosts = [for (var i = 1; i <= 254; i++) '$prefix.$i'];
    await _forEachBounded(hosts, maxConcurrent, (ip) async {
      final ports = await _probe.openPorts(ip, discoveryPorts);
      if (ports.isNotEmpty) alive[ip] = ports;
    });

    // mDNS/Bonjour: devices broadcast a friendly name + what they are. Passive
    // (we listen to multicast, we don't touch a host). It also surfaces devices
    // that answer no TCP port, so union its IPs into the inventory.
    final names = await _mdns.discover();
    final allIps = {...alive.keys, ...names.keys};

    // Phase 2 — fingerprint: grab a banner only from hosts that answered a port,
    // fold in the mDNS name/services, then classify with the shared engine.
    // Bounded too (banner reads block on I/O).
    final reports = <DeviceReport>[];
    await _forEachBounded(allIps, maxConcurrent, (ip) async {
      final ports = alive[ip] ?? const <int>{};
      final http = ports.contains(80) ? await _probe.httpBanner(ip) : null;
      final rtsp = ports.contains(554)
          ? await _probe.rtspInfo(ip)
          : const RtspInfo();
      final mdns = names[ip];
      final obs = DeviceObservation(
        ip: ip,
        openPorts: ports,
        httpServerBanner: http,
        rtspServerBanner: rtsp.server,
        rtspMediaMagic: rtsp.mediaMagic,
        mdnsName: mdns?.name,
        mdnsServices: mdns?.services ?? const {},
      );
      reports.add(engine.assess(obs));
    });

    reports.sort((a, b) => _octet(a.ip).compareTo(_octet(b.ip)));

    // Wi-Fi is network-level and platform-gated (unreadable on iOS). We still
    // attach the observation so the UI can state the gap honestly.
    final wifiObs = await _wifi.current();
    final wifi = WifiReport(
      observation: wifiObs,
      findings: engine.assessWifi(wifiObs),
    );

    return ScanReport(
      startedAt: _now(),
      devices: reports,
      wifi: wifi,
      networkFindings: engine.assessNetwork(reports),
    );
  }

  static int _octet(String ip) => int.tryParse(ip.split('.').last) ?? 0;

  /// Run [fn] over [items] with at most [max] in flight. A shared iterator is safe
  /// on Dart's single-threaded event loop — moveNext/current are synchronous, so
  /// no two workers ever claim the same item.
  static Future<void> _forEachBounded<T>(
    Iterable<T> items,
    int max,
    Future<void> Function(T) fn,
  ) async {
    final it = items.iterator;
    Future<void> worker() async {
      while (it.moveNext()) {
        await fn(it.current);
      }
    }

    await Future.wait([for (var i = 0; i < max; i++) worker()]);
  }
}

/// What an RTSP probe learned — kept tiny and const-friendly.
class RtspInfo {
  const RtspInfo({this.mediaMagic, this.server});
  final String? mediaMagic;
  final String? server;
}

/// Low-level, network-touching probing — the ONLY part that hits real sockets.
/// Abstracted so [LanScanner]'s logic is testable with a fake.
abstract interface class HostProbe {
  /// Which of [ports] accept a TCP connection on [ip] within a short timeout.
  Future<Set<int>> openPorts(String ip, List<int> ports);

  /// The HTTP `Server:` header (and any embedded model string) from :80, if any.
  Future<String?> httpBanner(String ip);

  /// RTSP hints from :554 — the media magic (hex) and/or the server string.
  Future<RtspInfo> rtspInfo(String ip);
}

/// Discovers the local IPv4 /24 prefix to sweep (e.g. "192.168.0").
abstract interface class SubnetSource {
  Future<String?> localPrefix24();
}

/// Reads the current Wi-Fi's name/encryption. This needs a native plugin
/// (Android: WifiManager + Location permission; iOS: no security API exists), so
/// it is deliberately behind an interface. The default [UnsupportedWifiSource]
/// returns "unavailable" — the honest state on iOS and until the plugin lands.
abstract interface class WifiSource {
  Future<WifiObservation> current();
}

/// The default: we can't read Wi-Fi yet, so say so. Never guesses "secure".
class UnsupportedWifiSource implements WifiSource {
  const UnsupportedWifiSource();

  @override
  Future<WifiObservation> current() async =>
      const WifiObservation(security: WifiSecurity.unavailable);
}

/// One host's mDNS/Bonjour identity: the friendly name it advertises and the
/// service types it announces (`_googlecast._tcp`, `_ipp._tcp`, …).
class MdnsRecord {
  const MdnsRecord({this.name, this.services = const {}});
  final String? name;
  final Set<String> services;
}

/// Discovers mDNS/Bonjour identities on the LAN, keyed by IP. Passive — it listens
/// to the multicast announcements devices broadcast; it never probes a host. Like
/// [WifiSource] the real implementation needs platform/multicast access (and the
/// iOS multicast entitlement — see signing #79), so it sits behind an interface;
/// the default [NoMdnsSource] returns nothing and the report simply shows no names.
abstract interface class MdnsSource {
  Future<Map<String, MdnsRecord>> discover();
}

/// The default: no mDNS yet, so no names. Never invents an identity.
class NoMdnsSource implements MdnsSource {
  const NoMdnsSource();

  @override
  Future<Map<String, MdnsRecord>> discover() async => const {};
}

/// Real probing over `dart:io`. Passive by construction: connect, read a banner,
/// hang up. It sends an HTTP GET and an RTSP DESCRIBE — never a credential.
class SocketHostProbe implements HostProbe {
  const SocketHostProbe({
    this.connectTimeout = const Duration(milliseconds: 400),
    this.readTimeout = const Duration(milliseconds: 700),
  });

  final Duration connectTimeout;
  final Duration readTimeout;

  @override
  Future<Set<int>> openPorts(String ip, List<int> ports) async {
    final open = <int>{};
    await Future.wait(ports.map((p) async {
      try {
        final s = await Socket.connect(ip, p, timeout: connectTimeout);
        s.destroy();
        open.add(p);
      } catch (_) {
        // Closed/filtered/unreachable — not open, nothing to record.
      }
    }));
    return open;
  }

  @override
  Future<String?> httpBanner(String ip) async {
    final resp = await _exchange(
      ip,
      80,
      'GET / HTTP/1.0\r\nHost: $ip\r\nUser-Agent: iEye-scan\r\n'
          'Connection: close\r\n\r\n',
    );
    if (resp == null) return null;
    final server = _headerValue(resp, 'server');
    final model = RegExp(r'IPC_[A-Z0-9_]+').firstMatch(resp)?.group(0);
    // Return whatever helps the engine: the Server header (routers) and/or the
    // model token (XM cameras). Null if the response revealed neither.
    final parts = [?server, ?model];
    return parts.isEmpty ? null : parts.join(' ');
  }

  @override
  Future<RtspInfo> rtspInfo(String ip) async {
    final resp = await _exchange(
      ip,
      554,
      'DESCRIBE rtsp://$ip:554/ RTSP/1.0\r\nCSeq: 1\r\n'
          'Accept: application/sdp\r\n\r\n',
    );
    if (resp == null) return const RtspInfo();
    // "IMKH" in the media description unmasks the XiongMai family even when the
    // proprietary port is hidden behind nginx (the Group-B tell in the audit).
    final magic = resp.contains('IMKH') ? '494d4b48' : null;
    return RtspInfo(mediaMagic: magic, server: _headerValue(resp, 'server'));
  }

  /// Connect, send [request], read up to a few KB of reply as latin1, hang up.
  Future<String?> _exchange(String ip, int port, String request) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, port, timeout: connectTimeout);
      s.write(request);
      await s.flush();
      final chunks = <int>[];
      await for (final data in s.timeout(readTimeout)) {
        chunks.addAll(data);
        if (chunks.length > 4096) break;
      }
      return String.fromCharCodes(chunks);
    } catch (_) {
      return null;
    } finally {
      s?.destroy();
    }
  }

  static String? _headerValue(String response, String name) {
    for (final line in response.split('\n')) {
      final i = line.indexOf(':');
      if (i > 0 && line.substring(0, i).trim().toLowerCase() == name) {
        return line.substring(i + 1).trim();
      }
    }
    return null;
  }
}

/// Reads the device's own private IPv4 to derive the /24 to sweep.
class InterfaceSubnetSource implements SubnetSource {
  const InterfaceSubnetSource();

  @override
  Future<String?> localPrefix24() async {
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final ni in ifaces) {
        for (final a in ni.addresses) {
          if (_isPrivateV4(a.address)) {
            final o = a.address.split('.');
            return '${o[0]}.${o[1]}.${o[2]}';
          }
        }
      }
    } catch (_) {
      // Interface enumeration can fail on some platforms — treat as "unknown".
    }
    return null;
  }

  static bool _isPrivateV4(String ip) {
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('10.')) return true;
    final o = ip.split('.');
    if (o.length == 4 && o[0] == '172') {
      final second = int.tryParse(o[1]) ?? 0;
      return second >= 16 && second <= 31; // 172.16.0.0 – 172.31.255.255
    }
    return false;
  }
}
