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

  /// Pull a model string like "IPC_GK7205V200" out of a banner if present.
  String? _grepModel(String? banner) {
    if (banner == null) return null;
    final m = RegExp(r'(IPC_[A-Z0-9_]+)').firstMatch(banner);
    return m?.group(1);
  }
}
