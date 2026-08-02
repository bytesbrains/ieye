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
      case DeviceClass.iot:
      case DeviceClass.computer:
      case DeviceClass.unknown:
        break;
    }

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

  /// Camera findings. The two big ones are INFERRED from the family, matching the
  /// audit's CRITICAL calls (§5.1–5.2) but without ever attempting a login.
  List<Finding> _cameraFindings(DeviceObservation obs, String? family) {
    final out = <Finding>[];
    final isXm = family != null && family.startsWith('XiongMai');

    // The live stream itself, served on the LAN (RTSP/554). Distinct from the
    // cloud/P2P path: this is the raw feed offered to anyone who reaches the
    // network. We see the door is open; we never walk through it.
    if (obs.hasPort(554)) out.add(_streamExposure(obs.ip));

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
  /// serve RTSP). It flags that the video is *offered* on the network — detected
  /// from the open stream port, never by opening the stream (guardian eye, never a
  /// lens; the exposure, never the content).
  Finding _streamExposure(String ip) => Finding(
    kind: FindingKind.exposedCameraStream,
    severity: Severity.high,
    deviceIp: ip,
    title: 'Its live video is being served on your network',
    whatItMeans:
        'The camera offers its video over a standard streaming port (RTSP). Any '
        'device on your Wi-Fi can try to watch it, and if your router forwards '
        'that port, so could someone on the internet. iEye can see the stream is '
        'offered here — it never opens it.',
    remediation: const [
      'Set a strong password on the camera so the stream isn’t open to anyone.',
      'Make sure your router isn’t forwarding the camera’s ports to the internet.',
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
    if (obs.hasPort(554)) out.add(_streamExposure(obs.ip));
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

  /// Pull a model string like "IPC_GK7205V200" out of a banner if present.
  String? _grepModel(String? banner) {
    if (banner == null) return null;
    final m = RegExp(r'(IPC_[A-Z0-9_]+)').firstMatch(banner);
    return m?.group(1);
  }
}
