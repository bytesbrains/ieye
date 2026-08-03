import 'home_scan_model.dart';

/// The fingerprint → risk → remediation engine. Pure Dart, no I/O — it turns a
/// passive [DeviceObservation] into a [DeviceReport]. This is the shared asset
/// every tier reuses (mobile now, laptop and the Pi box later); only the thing
/// that *produces* observations differs by platform.
///
/// SEED DATA: a representative real-world XiongMai deployment (exposed cameras on
/// a home LAN). The rules below encode what a hands-on audit concludes — but by
/// INFERENCE from the fingerprint, never by logging in. Every finding emitted
/// here is [Finding.verified] == false; active confirmation is a higher tier.
class FingerprintEngine {
  const FingerprintEngine();

  /// The XiongMai proprietary "Sofia"/DVRIP port pair. Its presence is the single
  /// strongest camera tell in the audit (ports 8899 + 34567).
  static const _xmSofiaPorts = {8899, 34567};

  /// "IMKH" as hex — the magic at the start of the XM-family RTSP media stream,
  /// which unmasks Group-B units that hide the proprietary port behind nginx.
  static const _imkhMagicHex = '494d4b48';

  DeviceReport assess(DeviceObservation obs) {
    final (deviceClass, family, model) = _classify(obs);
    final findings = <Finding>[];

    switch (deviceClass) {
      case DeviceClass.ipCamera:
        findings.addAll(_cameraFindings(obs, family));
      case DeviceClass.router:
      case DeviceClass.accessPoint:
        findings.addAll(_routerFindings(obs));
      case DeviceClass.nvr:
        findings.addAll(_recorderFindings(obs));
      case DeviceClass.nas:
        findings.addAll(_nasFindings(obs));
      case DeviceClass.printer:
        findings.addAll(_printerFindings(obs));
      case DeviceClass.mediaDevice:
        findings.addAll(_mediaFindings(obs));
      case DeviceClass.smartHub:
        findings.addAll(_hubFindings(obs));
      case DeviceClass.iot:
      case DeviceClass.computer:
      case DeviceClass.unknown:
        break;
    }

    // Cross-cutting exposures — independent of what the device *is*. An open
    // Telnet, an open ADB bridge, or a reachable database is a problem on any
    // host, so these run for every device (even ones we couldn't classify).
    findings.addAll(_crossCuttingFindings(obs));

    return DeviceReport(
      observation: obs,
      deviceClass: deviceClass,
      vendorFamily: family,
      model: model,
      findings: findings,
    );
  }

  /// Passive classification from ports + banners. Returns (class, vendorFamily?,
  /// model?).
  (DeviceClass, String?, String?) _classify(DeviceObservation obs) {
    final banner = (obs.httpServerBanner ?? '').toLowerCase();
    final magic = (obs.rtspMediaMagic ?? '').toLowerCase();

    final isXmFamily =
        _xmSofiaPorts.every(obs.hasPort) || magic.startsWith(_imkhMagicHex);

    // The camera/recorder tells carry the flagship CRITICAL findings, so they
    // ALWAYS win over an mDNS identity: a HomeKit or Cast-enabled camera
    // advertises `_hap`/`_googlecast` too, and letting the announced name
    // classify it would silently drop exposedCameraCloudP2P (review #81 §2).
    final hasCameraTell = isXmFamily ||
        obs.hasPort(554) ||
        obs.hasPort(37777) ||
        banner.contains('dvr') ||
        banner.contains('nvr');

    // mDNS service types are the strongest, most honest identity signal — the
    // device announces what it is — but only where no camera/recorder tell is
    // present (above). The banner still contributes vendor/model: a device's
    // name says WHAT it is, its banner says WHOSE it is (review #81 §3).
    if (!hasCameraTell) {
      final byMdns = _classifyByService(obs, banner);
      if (byMdns != null) {
        final vendor = switch (byMdns) {
          DeviceClass.nas => _nasVendor(banner),
          _ => null,
        };
        return (byMdns, vendor, _grepModel(obs.httpServerBanner));
      }
    }

    if (isXmFamily) {
      // XiongMai / Sofia / Hisilicon line — the Mirai-era camera family.
      final model = _grepModel(obs.httpServerBanner);
      return (DeviceClass.ipCamera, 'XiongMai / Sofia', model);
    }

    // A recorder (NVR/DVR) — where stored footage lives. The Dahua DVRIP port
    // (37777) is a strong recorder tell; some also serve an explicit DVR/NVR
    // banner. Checked before the generic camera rule so a recorder that also
    // restreams RTSP isn't mistaken for a plain camera.
    final isRecorder =
        obs.hasPort(37777) || banner.contains('dvr') || banner.contains('nvr');
    if (isRecorder) {
      return (DeviceClass.nvr, null, _grepModel(obs.httpServerBanner));
    }

    // Storage (NAS) — the box holding the household's files. Synology DSM
    // (5000/5001) or a vendor banner is the tell; SMB (445) corroborates.
    final isNas = banner.contains('synology') ||
        banner.contains('qnap') ||
        banner.contains('diskstation') ||
        (obs.hasPort(445) && (obs.hasPort(5000) || obs.hasPort(5001)));
    if (isNas) {
      return (DeviceClass.nas, _nasVendor(banner), null);
    }

    // Printer / MFP — raw print (9100), IPP (631), or a printer banner.
    final isPrinter = obs.hasPort(9100) ||
        obs.hasPort(631) ||
        banner.contains('jetdirect') ||
        banner.contains('printer');
    if (isPrinter) {
      return (DeviceClass.printer, null, null);
    }

    // TV / streaming — Chromecast (8008/8009), Roku (8060), or a media banner.
    final isMedia = obs.hasPort(8008) ||
        obs.hasPort(8009) ||
        obs.hasPort(8060) ||
        banner.contains('roku') ||
        banner.contains('chromecast');
    if (isMedia) {
      return (DeviceClass.mediaDevice, null, null);
    }

    // Smart-home hub — Home Assistant (8123) or a Philips Hue bridge.
    final isHub = obs.hasPort(8123) ||
        banner.contains('home assistant') ||
        banner.contains('ipbridge') || // Hue bridge's server string
        banner.contains('hue');
    if (isHub) {
      return (DeviceClass.smartHub, null, null);
    }

    // A device serving RTSP (554) alongside a web UI, without the XM pair, is
    // still most likely a camera/NVR.
    if (obs.hasPort(554) && obs.hasPort(80)) {
      return (DeviceClass.ipCamera, null, null);
    }

    if (banner.contains('tp-link') || banner.contains('httpd')) {
      return (DeviceClass.router, 'TP-Link', null);
    }
    if (obs.macVendor != null &&
        (obs.macVendor!.toLowerCase().contains('tenda'))) {
      return (DeviceClass.accessPoint, obs.macVendor, null);
    }

    return (DeviceClass.unknown, obs.macVendor, null);
  }

  /// Classify a device from the mDNS service types it advertises — the device's
  /// own declaration of what it is. Returns null when no service type is a
  /// confident tell (the caller then falls back to port/banner heuristics).
  /// Only consulted when no camera/recorder tell is present — the caller guards
  /// that, so a HomeKit/Cast camera keeps its vulnerable-family findings.
  DeviceClass? _classifyByService(DeviceObservation obs, String banner) {
    if (obs.hasService('_googlecast') ||
        obs.hasService('_airplay') ||
        obs.hasService('_raop') ||
        obs.hasService('_roku') ||
        obs.hasService('androidtvremote') ||
        obs.hasService('_spotify-connect')) {
      return DeviceClass.mediaDevice;
    }
    if (obs.hasService('_ipp') ||
        obs.hasService('_printer') ||
        obs.hasService('_pdl-datastream') ||
        obs.hasService('_scanner') ||
        obs.hasService('_uscan')) {
      return DeviceClass.printer;
    }
    if (obs.hasService('_smb') ||
        obs.hasService('_afpovertcp') ||
        obs.hasService('_nfs') ||
        obs.hasService('_adisk')) {
      // File-sharing services alone don't make a NAS — a Mac with File Sharing
      // on advertises the exact same set (review #81 §5). Call it a NAS only
      // with corroboration (a DSM/QNAP admin port or a vendor banner);
      // otherwise it's a computer sharing files, which is not a finding.
      final nasCorroborated = obs.hasPort(5000) ||
          obs.hasPort(5001) ||
          banner.contains('synology') ||
          banner.contains('qnap') ||
          banner.contains('diskstation');
      return nasCorroborated ? DeviceClass.nas : DeviceClass.computer;
    }
    if (obs.hasService('_hue') ||
        obs.hasService('_home-assistant') ||
        obs.hasService('_homekit') ||
        obs.hasService('_hap')) {
      return DeviceClass.smartHub;
    }
    return null;
  }

  /// Camera findings. The two big ones are INFERRED from the family, matching the
  /// audit's CRITICAL calls (§5.1–5.2) but without ever attempting a login.
  List<Finding> _cameraFindings(DeviceObservation obs, String? family) {
    final out = <Finding>[];
    final isXm = family != null && family.startsWith('XiongMai');

    // The live stream itself, served on the LAN (RTSP/554). Distinct from the
    // cloud/P2P path: this is the raw feed offered to anyone who reaches the
    // network. We see the door is open; we never walk through it.
    if (obs.hasPort(554)) out.add(_streamExposure(obs.ip, 'camera'));

    if (isXm) {
      // §5.2 — cloud/P2P by default → reachable from the internet by serial. NAT
      // and even CGNAT are no defence (the tunnel is built outbound).
      out.add(Finding(
        kind: FindingKind.exposedCameraCloudP2P,
        severity: Severity.critical,
        deviceIp: obs.ip,
        title: 'This camera is likely viewable from the internet',
        whatItMeans:
            'It belongs to a family of cameras that connect out to a maker’s '
            'cloud on their own. That lets someone reach it from anywhere using '
            'just its serial number — your router does not block this, even if you '
            'have no public address. Serial numbers for these are not secret.',
        remediation: const [
          'Turn off cloud / P2P (sometimes called “XMEye” or “Cloud”) in the '
              'camera app unless you truly need to watch from outside home.',
          'Set a strong password on the camera (see the next step).',
          'Best fix: stop the camera reaching the internet at all — a specialist '
              'can block it at the router so it still records but can’t phone out.',
        ],
        fixOwner: FixOwner.user,
      ));

      // §5.1 — ships with a blank admin password, very often never changed.
      out.add(Finding(
        kind: FindingKind.defaultCredentialsLikely,
        severity: Severity.high,
        deviceIp: obs.ip,
        title: 'This camera may still have no password',
        whatItMeans:
            'Cameras like this ship with the admin account set to a blank '
            'password, and most people never change it. If it’s blank, its serial '
            'number is the only thing between a stranger and your live video.',
        remediation: const [
          'Open the camera’s app and set a strong, unique admin password now.',
          'We show “likely” because a safe scan doesn’t try passwords — confirming '
              'it needs the deeper check, which we run only on cameras you confirm '
              'are yours.',
        ],
        fixOwner: FixOwner.user,
      ));

      // §4 note — GK7205/XM generation carries known CVEs (Mirai family).
      out.add(Finding(
        kind: FindingKind.knownVulnerableFirmware,
        severity: Severity.medium,
        deviceIp: obs.ip,
        title: 'Camera runs firmware with known security holes',
        whatItMeans:
            'This chip-and-firmware generation is the one behind large botnets and '
            'several published vulnerabilities. Even with a password set, it should '
            'be kept off the open internet and updated.',
        remediation: const [
          'Check the vendor app for a firmware update and apply it.',
          'Keep it on a network that can’t reach your phones and laptops '
              '(a specialist can set this up).',
        ],
        fixOwner: FixOwner.specialist,
      ));
    } else {
      // A camera we can see but can’t place → treat as unverified, not safe (§5.3).
      out.add(Finding(
        kind: FindingKind.credentialsUnverified,
        severity: Severity.medium,
        deviceIp: obs.ip,
        title: 'Camera found — its security couldn’t be confirmed safely',
        whatItMeans:
            'We can see a camera here but a safe scan can’t confirm whether it has '
            'a real password or reaches the internet. Treat it as “not yet checked”, '
            'not as safe.',
        remediation: const [
          'Confirm it has a strong password in its own app.',
          'Have the deeper check run on it to confirm it isn’t exposed.',
        ],
        fixOwner: FixOwner.specialist,
      ));
    }
    return out;
  }

  /// The live-stream-reachable finding, shared by cameras and recorders (both
  /// serve RTSP) — [what] names the device so the copy reads right on either.
  /// It flags that the video is *offered* on the network — detected from the
  /// open stream port, never by opening the stream (guardian eye, never a lens;
  /// the exposure, never the content). MEDIUM, not high: a LAN-served stream is
  /// the normal state of nearly every IP camera — it only bites with another
  /// factor (weak password, a forwarded port), and crying HIGH on every camera
  /// is the alarm-fatigue failure mode (review #81 §4).
  Finding _streamExposure(String ip, String what) => Finding(
    kind: FindingKind.exposedCameraStream,
    severity: Severity.medium,
    deviceIp: ip,
    title: 'Its live video is being served on your network',
    whatItMeans:
        'The $what offers its video over a standard streaming port (RTSP). Any '
        'device on your Wi-Fi can try to watch it, and if your router forwards '
        'that port, so could someone on the internet. iEye can see the stream is '
        'offered here — it never opens it.',
    remediation: [
      'Set a strong password on the $what so the stream isn’t open to anyone.',
      'Make sure your router isn’t forwarding the $what’s ports to the internet.',
      'Best: put cameras on their own network so only you can reach the stream '
          '(a specialist can set this up).',
    ],
    fixOwner: FixOwner.user,
  );

  /// Recorder (NVR/DVR) findings — the box that STORES footage. Its exposure is
  /// worse in kind than a single live view: it holds days or weeks of history.
  List<Finding> _recorderFindings(DeviceObservation obs) {
    final out = <Finding>[
      Finding(
        kind: FindingKind.exposedRecorder,
        severity: Severity.high,
        deviceIp: obs.ip,
        title: 'A recorder holding your saved footage is reachable here',
        whatItMeans:
            'This is a video recorder (an NVR/DVR) — it keeps days or weeks of '
            'footage from your cameras. It’s answering on your network with its '
            'management and playback service open. If its password is weak or '
            'still the factory default, someone who reaches it could watch your '
            'saved recordings, not just the live view. iEye can see it’s '
            'reachable — it never signs in.',
        remediation: const [
          'Set a strong, unique password on the recorder now.',
          'Don’t forward the recorder’s ports to the internet.',
          'Best: keep the recorder on its own network, reachable only by you '
              '(a specialist can set this up).',
        ],
        fixOwner: FixOwner.specialist,
      ),
    ];
    // A recorder usually restreams its cameras' live video too (RTSP).
    if (obs.hasPort(554)) out.add(_streamExposure(obs.ip, 'recorder'));
    return out;
  }

  String? _nasVendor(String banner) {
    if (banner.contains('synology') || banner.contains('diskstation')) {
      return 'Synology';
    }
    if (banner.contains('qnap')) return 'QNAP';
    return null;
  }

  /// NAS / storage — it holds the household's files and is a top ransomware
  /// target. Detected here; whether it's already locked down we can't see, so this
  /// is honest hardening guidance, not an assertion of exposure — INFO, because
  /// presence is not exposure and inflating it is the alarm-fatigue failure mode.
  List<Finding> _nasFindings(DeviceObservation obs) => [
    Finding(
      kind: FindingKind.storageDeviceFound,
      severity: Severity.info,
      deviceIp: obs.ip,
      title: 'A storage box holding your files is on the network',
      whatItMeans:
          'This looks like a NAS — the drive that keeps your photos, documents '
          'and backups. These are a favourite target for ransomware, and many '
          'are left reachable from the internet through the maker’s remote-access '
          'feature. iEye can see it’s here; it can’t see whether it’s locked down.',
      remediation: const [
        'Give it a strong admin password and switch off the default admin account.',
        'Turn off internet/remote access (QuickConnect, myQNAPcloud) unless you '
            'truly need it.',
        'Keep one offline backup — the copy ransomware can’t reach.',
      ],
      fixOwner: FixOwner.user,
    ),
  ];

  /// Printer / MFP — commonly an open web page with no password, and it keeps
  /// copies of what it scans. Not an emergency on its own; worth closing. INFO —
  /// presence, not exposure.
  List<Finding> _printerFindings(DeviceObservation obs) => [
    Finding(
      kind: FindingKind.printerFound,
      severity: Severity.info,
      deviceIp: obs.ip,
      title: 'A printer is open on the network',
      whatItMeans:
          'Network printers often have an open settings page with no password, '
          'keep copies of what they scan, and are frequently left reachable from '
          'the internet. On its own that’s low-risk, but it’s worth closing.',
      remediation: const [
        'Set an admin password on the printer’s settings page.',
        'Turn off protocols you don’t use (FTP, Telnet, printing from outside).',
      ],
      fixOwner: FixOwner.user,
    ),
  ];

  /// TV / streaming device — usually low-risk, but it can be told what to play by
  /// anything on the Wi-Fi and often tracks viewing. The real teeth (an open ADB
  /// debug port on cheap Android boxes) are added by the cross-cutting pass.
  List<Finding> _mediaFindings(DeviceObservation obs) => [
    Finding(
      kind: FindingKind.mediaDeviceFound,
      severity: Severity.info,
      deviceIp: obs.ip,
      title: 'A TV or streaming device is on the network',
      whatItMeans:
          'Smart TVs and streaming boxes can be told what to play by anything on '
          'your Wi-Fi, and many track what you watch. Usually low-risk on its own.',
      remediation: const [
        'Keep it updated, and turn off “viewing data” / ACR in its privacy settings.',
      ],
      fixOwner: FixOwner.user,
    ),
  ];

  /// Smart-home hub — it controls other devices (possibly lights, locks, cameras).
  /// Being on your own network is normal; being weakly protected is the risk.
  /// INFO — presence, not exposure.
  List<Finding> _hubFindings(DeviceObservation obs) => [
    Finding(
      kind: FindingKind.smartHubFound,
      severity: Severity.info,
      deviceIp: obs.ip,
      title: 'A smart-home hub is on the network',
      whatItMeans:
          'This controls your smart devices — which may include lights, locks and '
          'cameras. If it has a weak password or is reachable from the internet, '
          'someone could control your home. Being on your own network is normal; '
          'being weakly secured is the risk.',
      remediation: const [
        'Give it a strong, unique password and turn on two-factor if it offers it.',
        'Don’t expose it directly to the internet — reach it through the maker’s '
            'app or a VPN.',
      ],
      fixOwner: FixOwner.user,
    ),
  ];

  /// Exposures that don't depend on what the device is — run for every host.
  List<Finding> _crossCuttingFindings(DeviceObservation obs) {
    final out = <Finding>[];

    // Open Telnet (23) — the Mirai pattern: unencrypted remote login, almost
    // always with a factory password on IoT gear. Should never be open.
    if (obs.hasPort(23)) {
      out.add(Finding(
        kind: FindingKind.insecureTelnet,
        severity: Severity.high,
        deviceIp: obs.ip,
        title: 'This device allows old, insecure remote login (Telnet)',
        whatItMeans:
            'Telnet is an old remote-control service with no encryption, and the '
            'devices that still run it usually ship with a default password. This '
            'is exactly how large IoT botnets are built. It should be turned off.',
        remediation: const [
          'Turn off Telnet in the device’s settings, or update its firmware.',
          'If you can’t, a specialist can block it and stop the device phoning out.',
        ],
        fixOwner: FixOwner.specialist,
      ));
    }

    // Open Android Debug Bridge (5555) — password-less remote code execution,
    // common on cheap Android TV boxes; there are worms that scan for it.
    if (obs.hasPort(5555)) {
      out.add(Finding(
        kind: FindingKind.openAdb,
        severity: Severity.high,
        deviceIp: obs.ip,
        title: 'A device is wide open to remote control (ADB debug port)',
        whatItMeans:
            'An Android debug port is open. Anyone on the network — and worms '
            'that hunt for it — can install and run software on this device with '
            'no password. It’s common on cheap Android TV boxes.',
        remediation: const [
          'Turn off “USB debugging” / “ADB over network” in developer settings.',
          'Consider replacing cheap boxes that ship with this switched on.',
        ],
        fixOwner: FixOwner.user,
      ));
    }

    // A database reachable on the network. If it has no password (a common
    // home-server default) it's a full read/wipe of everything in it.
    const dbPorts = {
      6379: 'Redis',
      27017: 'MongoDB',
      3306: 'MySQL',
      5432: 'PostgreSQL',
      9200: 'Elasticsearch',
    };
    for (final e in dbPorts.entries) {
      if (obs.hasPort(e.key)) {
        out.add(Finding(
          kind: FindingKind.exposedDatabase,
          severity: Severity.high,
          deviceIp: obs.ip,
          title: 'A database (${e.value}) is reachable on your network',
          whatItMeans:
              'A ${e.value} database is answering on your network. On home '
              'servers these are often set up with no password — if so, anyone '
              'who reaches it can read or wipe everything in it.',
          remediation: const [
            'Require a password and bind the database to localhost only.',
            'Never forward its port to the internet.',
          ],
          fixOwner: FixOwner.specialist,
        ));
        // No break — a host running two exposed databases has two problems.
      }
    }

    return out;
  }

  /// Router/AP findings — mostly pointers to checks that need the admin login,
  /// which is a specialist job (the audit couldn’t get into the Archer C80 either).
  List<Finding> _routerFindings(DeviceObservation obs) {
    return [
      Finding(
        kind: FindingKind.upnpExposure,
        severity: Severity.low,
        deviceIp: obs.ip,
        title: 'Router should be checked for auto-opened holes',
        whatItMeans:
            'Routers often let devices punch their own holes to the internet '
            '(UPnP) and may still use a default admin password. Confirming this '
            'needs the router’s admin login.',
        remediation: const [
          'Make sure the router’s own admin password isn’t the factory default.',
          'A specialist can turn off UPnP and confirm nothing is forwarded to your '
              'cameras.',
        ],
        fixOwner: FixOwner.specialist,
      ),
    ];
  }

  /// Turn a [WifiObservation] into findings. Open/WEP/old-WPA are the ones that
  /// bite; WPA2/WPA3 are fine (shown as a stat, never as a green all-clear).
  /// [WifiSecurity.unavailable] yields nothing — the UI states the gap honestly.
  List<Finding> assessWifi(WifiObservation w) {
    switch (w.security) {
      case WifiSecurity.open:
        return const [
          Finding(
            kind: FindingKind.weakWifi,
            severity: Severity.high,
            verified: true, // we read the cipher directly — this one IS confirmed
            title: 'Your Wi-Fi has no password',
            whatItMeans:
                'Anyone within range can join your Wi-Fi and reach the devices '
                'on it — including your cameras — without needing anything from '
                'you. On an open network, nearby traffic can also be read.',
            remediation: [
              'In your router’s app or settings, set Wi-Fi security to WPA2 or '
                  'WPA3 and choose a strong password.',
              'Reconnect your devices with the new password.',
            ],
            fixOwner: FixOwner.user,
          ),
        ];
      case WifiSecurity.wep:
        return const [
          Finding(
            kind: FindingKind.weakWifi,
            severity: Severity.high,
            verified: true,
            title: 'Your Wi-Fi uses WEP — that’s broken',
            whatItMeans:
                'WEP encryption can be cracked in minutes with free tools, so the '
                'password barely protects you. It’s effectively an open network to '
                'anyone determined.',
            remediation: [
              'Switch your Wi-Fi security to WPA2 or WPA3 in the router settings.',
              'If the router only offers WEP, it’s old — consider replacing it.',
            ],
            fixOwner: FixOwner.user,
          ),
        ];
      case WifiSecurity.wpaTkip:
        return const [
          Finding(
            kind: FindingKind.weakWifi,
            severity: Severity.medium,
            verified: true,
            title: 'Your Wi-Fi uses older WPA/TKIP encryption',
            whatItMeans:
                'The original WPA (TKIP) has known weaknesses and is much weaker '
                'than modern Wi-Fi security. It still has a password, but it '
                'should be upgraded.',
            remediation: [
              'Set your Wi-Fi security to WPA2 (AES) or WPA3 in the router.',
            ],
            fixOwner: FixOwner.user,
          ),
        ];
      case WifiSecurity.wpa2:
      case WifiSecurity.wpa3:
      case WifiSecurity.unknown:
      case WifiSecurity.unavailable:
        // Fine, indeterminate, or unreadable — no finding. WPA2/WPA3 are shown as
        // a reassuring stat in the UI, not asserted here as "safe".
        return const [];
    }
  }

  /// Network-LEVEL findings: not about one device, but how the network is
  /// *arranged*. The segmentation check — when several sensitive devices
  /// (cameras, recorders, storage, hubs) are reachable from the vantage the scan
  /// ran on, they share a flat network, so anything else on that Wi-Fi (a guest's
  /// phone, a visitor's laptop, a compromised gadget) can reach them too. This is
  /// the premises failure mode (guest Wi-Fi reaching cameras/POS) and a home one.
  /// Inference only ([Finding.verified] == false), like every mass-tier finding.
  List<Finding> assessNetwork(Iterable<DeviceReport> devices) {
    const sensitive = {
      DeviceClass.ipCamera,
      DeviceClass.nvr,
      DeviceClass.nas,
      DeviceClass.smartHub,
    };
    final reachable = [
      for (final d in devices)
        if (sensitive.contains(d.deviceClass)) d.deviceClass,
    ];
    // One sensitive device on your own LAN is normal-ish and already covered by
    // its per-device findings. The segmentation risk is the *cluster*: several
    // reachable from a single vantage means a flat, unsegmented network.
    if (reachable.length < 2) return const [];

    final summary = _summariseClasses(reachable);
    return [
      Finding(
        kind: FindingKind.flatNetwork,
        severity: Severity.medium,
        title: 'Cameras and other sensitive devices share this network',
        whatItMeans:
            'From the Wi-Fi this scan ran on, it could reach $summary. They sit '
            'on one flat network, so anything else on this Wi-Fi — a guest’s '
            'phone, a visitor’s laptop, a compromised gadget — can reach them '
            'too. Ideally they’re walled off (segmented) from the devices and '
            'people that don’t need them. If others ever join this Wi-Fi — a '
            'rental, a café, an office — guests should never reach these at all.',
        remediation: const [
          'Put cameras, recorders and storage on their own network, separate '
              'from phones, laptops and guests (a specialist can set this up).',
          'If people join your Wi-Fi as guests, give them a fully isolated guest '
              'network that can’t see anything else.',
        ],
        fixOwner: FixOwner.specialist,
      ),
    ];
  }

  /// "2 cameras, a video recorder and storage" from a bag of device classes.
  String _summariseClasses(List<DeviceClass> classes) {
    const label = {
      DeviceClass.ipCamera: 'camera',
      DeviceClass.nvr: 'video recorder',
      DeviceClass.nas: 'storage drive',
      DeviceClass.smartHub: 'smart-home hub',
    };
    final counts = <DeviceClass, int>{};
    for (final c in classes) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final parts = <String>[
      // Stable order: cameras, recorders, storage, hubs.
      for (final c in const [
        DeviceClass.ipCamera,
        DeviceClass.nvr,
        DeviceClass.nas,
        DeviceClass.smartHub,
      ])
        if ((counts[c] ?? 0) > 0)
          counts[c] == 1 ? 'a ${label[c]}' : '${counts[c]} ${label[c]}s',
    ];
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }

  /// Pull a model string like "IPC_GK7205V200" out of a banner if present.
  String? _grepModel(String? banner) {
    if (banner == null) return null;
    final m = RegExp(r'(IPC_[A-Z0-9_]+)').firstMatch(banner);
    return m?.group(1);
  }
}
