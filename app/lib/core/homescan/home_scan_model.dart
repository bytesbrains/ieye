/// Home-network security scan — the domain model (day-one value feature).
///
/// WHY THIS LIVES IN iEye: welfare monitoring only proves its worth on the worst
/// day; a home-network scan delivers a visible "here is what we found in your
/// home" win the first time the app is opened. Same guardian-eye promise (you are
/// seen, you are protected), pointed at a threat the user can feel today.
///
/// THE SAME NON-NEGOTIABLES AS THE REST OF iEye (CLAUDE.md) APPLY HERE:
///  - "Watches OVER you, never watches you." This feature protects the user FROM
///    being watched (exposed cameras); it is never itself a surveillance tool.
///  - "The easier a trigger fires, the more harmless its payload must be." An app
///    anyone can run in two taps must NEVER attempt a login or touch a device it
///    is pointed at. On-device, passive tier = fingerprint + INFERENCE only; every
///    finding it emits is [Finding.verified] == false. Active verification and any
///    router changes live behind an ownership gate in a higher tier / a specialist.
///  - "Promise the MECHANISM, never the OUTCOME." Findings say what is *likely
///    exposed* and what to *do*; the scan never declares the home "secure". There
///    is no green all-clear shield here, for the same reason the coverage home has
///    none — over-trust is the headline risk.
///  - "Process at the edge, emit the bit." The device inventory a scan produces is
///    sensitive (it is a map of someone's home). It must stay on the phone — never
///    logged or synced. This model carries no transport; persistence is deliberately
///    out of scope for the engine.
library;

/// How serious a [Finding] is. Mirrors the labels used in the field audit that
/// seeds this engine (CRITICAL / MEDIUM / LOW / INFO), plus [high] for exposures
/// that are serious but not "viewable from the public internet" serious.
enum Severity {
  /// Very likely reachable/abusable from outside the home right now.
  critical,

  /// Serious weakness, but not confirmed internet-reachable on its own.
  high,

  /// Worth fixing; limited blast radius or needs another factor to bite.
  medium,

  /// Hygiene / hardening; not an active exposure.
  low,

  /// Neutral context — something we identified, no action implied.
  info,
}

/// What kind of weakness a [Finding] describes. Kept coarse and stable — the
/// user-facing copy lives on the [Finding], not here.
enum FindingKind {
  /// Camera family that reaches the vendor cloud (P2P) by default, making it
  /// reachable from the internet by serial number — no port-forward, NAT/CGNAT no
  /// defence. The scariest and most common real-world finding.
  exposedCameraCloudP2P,

  /// A camera's live video is being served on the network (an open RTSP/HTTP
  /// stream). Anyone on the Wi-Fi can try to watch it; if the router forwards the
  /// port, so can the internet. Detected by the open stream port — NEVER opened.
  exposedCameraStream,

  /// A video recorder (NVR/DVR) — where days/weeks of footage are STORED — is
  /// reachable on the network with its management/playback service open. Worse
  /// than a single live view: it's the whole archive. Detected, never signed into.
  exposedRecorder,

  /// Device family that ships with a blank / well-known default admin password
  /// that is frequently never changed. INFERRED from fingerprint, not tested.
  defaultCredentialsLikely,

  /// A device we believe carries credentials we could not passively verify — must
  /// be treated as "unverified, not safe", never assumed fine.
  credentialsUnverified,

  /// Firmware family with known public CVEs (e.g. the Mirai-era XM/Hisilicon line).
  knownVulnerableFirmware,

  /// The device auto-opens a hole in the router (UPnP) — checked at the router.
  upnpExposure,

  /// A NAS / storage box holding the household's files — ransomware target and
  /// often reachable from the internet via the maker's remote-access feature.
  storageDeviceFound,

  /// A network printer/MFP — commonly an open web UI, keeps scanned copies.
  printerFound,

  /// A smart-home hub/bridge that controls other devices — weak auth or internet
  /// exposure would hand over control of the home.
  smartHubFound,

  /// A TV / streaming device — controllable from the LAN, often tracks viewing.
  mediaDeviceFound,

  /// Plaintext remote login (Telnet, port 23) is open — the Mirai-botnet pattern.
  insecureTelnet,

  /// An open Android Debug Bridge (port 5555) — password-less remote code exec.
  openAdb,

  /// A database service (Redis/MongoDB/MySQL/…) reachable on the network — a full
  /// data leak if it has no password, which is a common home-server default.
  exposedDatabase,

  /// Wi-Fi is open/unencrypted, or on a weak cipher.
  weakWifi,

  /// A flat network: several sensitive devices (cameras, recorders, storage,
  /// hubs) are reachable from the vantage the scan ran on, so they aren't walled
  /// off from the other devices — and people — on that Wi-Fi. The premises
  /// failure mode (guest Wi-Fi reaching cameras/POS), and a home one too.
  flatNetwork,

  /// Something identified for context; no weakness asserted.
  informational,
}

/// Who can realistically close a [Finding]. Drives the funnel: the app guides the
/// self-fixable ones and hands the rest to a vetted specialist (the paid tier).
enum FixOwner {
  /// The user can do it from the app's guided walkthrough (set a password, disable
  /// cloud/P2P in the vendor app).
  user,

  /// Needs the router admin login, VLAN segmentation, or active verification —
  /// escalate to a specialist. This is also where any *active* test is allowed.
  specialist,
}

/// What kind of thing a device is, as far as we can tell passively.
enum DeviceClass {
  ipCamera,
  router,
  accessPoint,
  nvr,

  /// Network storage (NAS) — the box that holds photos, documents, backups.
  nas,

  /// A network printer / multifunction device.
  printer,

  /// A TV or streaming box (Chromecast, Roku, Android TV, …).
  mediaDevice,

  /// A smart-home hub/bridge that controls other devices (Home Assistant, Hue, …).
  smartHub,

  computer,
  iot,
  unknown,
}

/// The passive, on-device observation of one host. This is ALL the mass tier is
/// allowed to gather: open ports and the banners a service volunteers. No login,
/// no credential probe, no traffic capture.
class DeviceObservation {
  const DeviceObservation({
    required this.ip,
    this.openPorts = const {},
    this.httpServerBanner,
    this.rtspServerBanner,
    this.rtspMediaMagic,
    this.macVendor,
    this.mdnsName,
    this.mdnsServices = const {},
  });

  final String ip;

  /// TCP ports that answered. The XiongMai "Sofia" pair {8899, 34567} is the
  /// strongest single tell in the field audit.
  final Set<int> openPorts;

  /// e.g. "TP-LINK HTTPD/1.0", "nginx", the XM web UI's server string.
  final String? httpServerBanner;

  /// e.g. the RTSP `Server:`/`Content-Base` string (a broken `rtsp://ip:554//`
  /// content-base was itself a Group-B tell in the audit).
  final String? rtspServerBanner;

  /// First bytes of the RTSP `MEDIAINFO`/SDP, hex — `494D4B48` = "IMKH" flags the
  /// XiongMai family even when the proprietary port is absent (Group B).
  final String? rtspMediaMagic;

  /// OUI-derived vendor from the MAC, when the platform exposes the ARP entry.
  final String? macVendor;

  /// The friendly name a device advertises over mDNS/Bonjour (e.g. "Living Room
  /// TV", "DiskStation"). Passive — devices broadcast this; we only listen. Null
  /// when nothing was heard for this host.
  final String? mdnsName;

  /// The mDNS service types a device announces (e.g. `_googlecast._tcp`,
  /// `_ipp._tcp`). A strong, honest identity signal: the device says what it is.
  final Set<String> mdnsServices;

  bool hasPort(int p) => openPorts.contains(p);

  /// True if any advertised mDNS service type contains [needle] (case-insensitive).
  bool hasService(String needle) {
    final n = needle.toLowerCase();
    return mdnsServices.any((s) => s.toLowerCase().contains(n));
  }
}

/// A single thing the user should know, with plain-language meaning and a fix.
///
/// [verified] is the load-bearing honesty flag: in the on-device passive tier it
/// is ALWAYS false — the finding is inferred from the fingerprint, never confirmed
/// by touching the device. The UI must render inferred findings as "likely",
/// never as fact, and must never imply the scan logged in.
class Finding {
  const Finding({
    required this.kind,
    required this.severity,
    required this.title,
    required this.whatItMeans,
    required this.remediation,
    required this.fixOwner,
    this.verified = false,
    this.deviceIp,
  });

  final FindingKind kind;
  final Severity severity;

  /// Short, human, honest. "Likely" when [verified] is false.
  final String title;

  /// Plain-language explanation a non-expert can act on — no jargon.
  final String whatItMeans;

  /// Ordered steps to close it. May end in "book a specialist" for [FixOwner.specialist].
  final List<String> remediation;

  final FixOwner fixOwner;

  /// True only if we actively confirmed it (higher tier, behind an ownership gate).
  /// The mass on-device scan leaves this false — everything it reports is inferred.
  final bool verified;

  /// Which host this is about, when device-specific.
  final String? deviceIp;
}

/// What one device turned out to be, plus every [Finding] about it.
class DeviceReport {
  const DeviceReport({
    required this.observation,
    required this.deviceClass,
    required this.findings,
    this.vendorFamily,
    this.model,
  });

  final DeviceObservation observation;
  final DeviceClass deviceClass;

  /// e.g. "XiongMai / Sofia", "TP-Link". Free text — for display, not logic.
  final String? vendorFamily;

  /// e.g. "IPC_GK7205V200" when a banner reveals it.
  final String? model;

  final List<Finding> findings;

  String get ip => observation.ip;

  /// The worst thing about this device, for sorting/summary. Null if clean.
  Severity? get worst {
    if (findings.isEmpty) return null;
    return findings
        .map((f) => f.severity)
        .reduce((a, b) => a.index <= b.index ? a : b);
  }
}

/// Wi-Fi encryption, worst → best. [unavailable] is the honest gap: iOS exposes
/// NO Wi-Fi-security API, so on iPhone we simply cannot read this — that is
/// reported as "can't check", never as a pass.
enum WifiSecurity { open, wep, wpaTkip, wpa2, wpa3, unknown, unavailable }

/// What we could read about the Wi-Fi the phone is on. Network-level (not tied to
/// one host), so it rides on the [ScanReport] separately from the device list.
class WifiObservation {
  const WifiObservation({
    this.ssid,
    this.security = WifiSecurity.unavailable,
    this.band,
    this.channel,
  });

  /// Network name, when the platform lets us read it (needs entitlement on iOS).
  final String? ssid;
  final WifiSecurity security;

  /// "2.4 GHz" / "5 GHz", for the stats row.
  final String? band;
  final int? channel;

  /// False when the platform couldn't tell us the security (the iOS wall).
  bool get readable => security != WifiSecurity.unavailable;
}

/// The Wi-Fi observation plus any findings about it.
class WifiReport {
  const WifiReport({required this.observation, required this.findings});
  final WifiObservation observation;
  final List<Finding> findings;
}
