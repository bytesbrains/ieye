import 'package:flutter/material.dart';

import '../../../core/homescan/home_scan_model.dart';
import '../../../core/homescan/scanner.dart';
import '../../../theme/ieye_theme.dart';

/// Renders a [ScanReport] for a reader who is not technical and may be older
/// (PRD §6 audience): big type, plain words, one finding per calm card. Severity
/// is carried by an ICON + a WORD, never colour alone (colour-blind / low-vision),
/// and within the warm brand palette — beacon-amber for the worst, never alarm-red
/// and never a green "you're safe" shield (over-trust guardrail).
class ScanReportView extends StatelessWidget {
  const ScanReportView(this.report, {super.key});

  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Summary(report),
        const SizedBox(height: 24),
        if (report.wifi != null) ...[
          _WifiSection(report.wifi!),
          const SizedBox(height: 16),
        ],
        for (final device in report.flagged) ...[
          _DeviceCard(device),
          const SizedBox(height: 16),
        ],
        if (report.cleanDeviceCount > 0) _CleanDevicesNote(report.cleanDeviceCount),
        const SizedBox(height: 20),
        const _HonestFooter(),
      ],
    );
  }
}

/// The headline: how many things need attention, stated as a fact — never spun
/// into an all-clear.
class _Summary extends StatelessWidget {
  const _Summary(this.report);
  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final worst = report.worst;

    final (icon, accent, headline) = switch (worst) {
      null => (
        Icons.wb_incandescent_outlined,
        IEyeColors.tealDeep,
        'No known exposures found on ${report.deviceCount} devices',
      ),
      Severity.critical => (
        Icons.visibility_off_outlined,
        IEyeColors.amberDeep,
        '${report.criticalCount} device${report.criticalCount == 1 ? '' : 's'} '
            'may be reachable from the internet',
      ),
      _ => (
        Icons.warning_amber_rounded,
        IEyeColors.amberDeep,
        '${report.findingCount} thing${report.findingCount == 1 ? '' : 's'} '
            'to look at on your network',
      ),
    };

    final flagged = report.flagged.length;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accent, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(headline,
                      style: text.headlineSmall?.copyWith(fontSize: 22)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // At-a-glance counts — scannable, honest (a fact, not an all-clear).
          Row(
            children: [
              _Stat(label: 'Devices seen', value: '${report.deviceCount}'),
              const _StatDivider(),
              _Stat(
                label: 'Need a look',
                value: '$flagged',
                accent: flagged > 0 ? IEyeColors.amberDeep : IEyeColors.tealDeep,
              ),
              const _StatDivider(),
              _Stat(label: 'Fixes', value: '${report.findingCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

/// One at-a-glance count in the summary card.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent});
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: text.headlineSmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: accent ?? IEyeColors.charcoal)),
          const SizedBox(height: 2),
          Text(label,
              style: text.bodyMedium
                  ?.copyWith(fontSize: 13, color: IEyeColors.charcoalMuted)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0x22000000),
      );
}

/// One device, its plain identity, and every finding about it.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard(this.device);
  final DeviceReport device;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_deviceIcon(device.deviceClass),
                  color: IEyeColors.charcoal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_deviceTitle(device),
                        style: text.titleLarge?.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(_deviceSubtitle(device),
                        style: text.bodyMedium?.copyWith(
                            fontSize: 13, color: IEyeColors.charcoalMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final f in device.findings) ...[
            const Divider(height: 24, color: Color(0x22000000)),
            _FindingBlock(f),
          ],
        ],
      ),
    );
  }
}

/// The Wi-Fi & router network stats: name, encryption, band — plus any Wi-Fi
/// finding. When the platform can't read security (iOS), it says so honestly and
/// points up the tier ladder, instead of showing a misleading "OK".
class _WifiSection extends StatelessWidget {
  const _WifiSection(this.wifi);
  final WifiReport wifi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final o = wifi.observation;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, color: IEyeColors.charcoal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(o.ssid == null ? 'Your Wi-Fi' : 'Wi-Fi · ${o.ssid}',
                    style: text.titleLarge?.copyWith(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!o.readable)
            _WifiUnavailable()
          else ...[
            _WifiStatRow(
              label: 'Encryption',
              child: _EncryptionBadge(o.security),
            ),
            if (o.band != null)
              _WifiStatRow(
                label: 'Band',
                child: Text(
                  o.channel != null ? '${o.band}  ·  ch ${o.channel}' : o.band!,
                  style: text.bodyMedium?.copyWith(
                      color: IEyeColors.charcoal, fontWeight: FontWeight.w600),
                ),
              ),
          ],
          for (final f in wifi.findings) ...[
            const Divider(height: 24, color: Color(0x22000000)),
            _FindingBlock(f),
          ],
        ],
      ),
    );
  }
}

/// The honest iOS gap — and the tier-ladder nudge.
class _WifiUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.help_outline, color: IEyeColors.charcoalMuted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'This phone can’t check your Wi-Fi encryption — the system doesn’t '
            'allow it. A laptop scan or the iEye box can see whether your Wi-Fi is '
            'open or weakly encrypted.',
            style: text.bodyMedium
                ?.copyWith(fontSize: 14, color: IEyeColors.charcoalSoft),
          ),
        ),
      ],
    );
  }
}

class _WifiStatRow extends StatelessWidget {
  const _WifiStatRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: text.bodyMedium),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

/// Encryption as a stat badge — factual, colour + WORD. WPA2/WPA3 read calm-teal
/// (a fact, NOT a green "you're safe" shield); open/WEP read beacon-amber.
class _EncryptionBadge extends StatelessWidget {
  const _EncryptionBadge(this.security);
  final WifiSecurity security;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (security) {
      WifiSecurity.open => ('Open · no password', IEyeColors.amberDeep),
      WifiSecurity.wep => ('WEP · broken', IEyeColors.amberDeep),
      WifiSecurity.wpaTkip => ('WPA/TKIP · old', IEyeColors.amberDeep),
      WifiSecurity.wpa2 => ('WPA2', IEyeColors.tealDeep),
      WifiSecurity.wpa3 => ('WPA3', IEyeColors.tealDeep),
      WifiSecurity.unknown => ('Unknown', IEyeColors.charcoalMuted),
      WifiSecurity.unavailable => ('Not checked', IEyeColors.charcoalMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _FindingBlock extends StatelessWidget {
  const _FindingBlock(this.finding);
  final Finding finding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SeverityChip(finding.severity),
            const SizedBox(width: 8),
            if (!finding.verified) const _LikelyTag(),
          ],
        ),
        const SizedBox(height: 10),
        Text(finding.title,
            style: text.titleLarge?.copyWith(
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(finding.whatItMeans,
            style: text.bodyMedium?.copyWith(color: IEyeColors.charcoalSoft)),
        const SizedBox(height: 12),
        _WhatToDo(finding),
      ],
    );
  }
}

/// The remediation steps + who should do it (the funnel: self-fix vs specialist).
class _WhatToDo extends StatelessWidget {
  const _WhatToDo(this.finding);
  final Finding finding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IEyeColors.paper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('What to do',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: IEyeColors.charcoal)),
              const Spacer(),
              _FixOwnerChip(finding.fixOwner),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < finding.remediation.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}.',
                      style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: IEyeColors.charcoal)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(finding.remediation[i],
                        style: text.bodyMedium?.copyWith(fontSize: 15)),
                  ),
                ],
              ),
            ),
          if (finding.fixOwner == FixOwner.specialist) ...[
            const SizedBox(height: 4),
            _SpecialistButton(),
          ],
        ],
      ),
    );
  }
}

/// A severity badge: icon + WORD, so it never relies on colour. All within the
/// warm palette — the worst is deep beacon-amber, not alarm-red.
class _SeverityChip extends StatelessWidget {
  const _SeverityChip(this.severity);
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (severity) {
      Severity.critical => ('CRITICAL', IEyeColors.amberDeep, Icons.priority_high_rounded),
      Severity.high => ('HIGH', IEyeColors.amberDeep, Icons.error_outline),
      Severity.medium => ('MEDIUM', IEyeColors.tealDeep, Icons.shield_outlined),
      Severity.low => ('LOW', IEyeColors.charcoalMuted, Icons.tune),
      Severity.info => ('INFO', IEyeColors.charcoalMuted, Icons.info_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: color)),
        ],
      ),
    );
  }
}

/// The honesty tag on every passive finding: we inferred it, we did not sign in.
class _LikelyTag extends StatelessWidget {
  const _LikelyTag();
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Likely, not confirmed',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: IEyeColors.charcoalMuted.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text('Likely · not confirmed',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: IEyeColors.charcoalSoft)),
      ),
    );
  }
}

class _FixOwnerChip extends StatelessWidget {
  const _FixOwnerChip(this.owner);
  final FixOwner owner;
  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (owner) {
      FixOwner.user => ('You can fix this', IEyeColors.tealDeep, Icons.check_circle_outline),
      FixOwner.specialist => ('Best with a specialist', IEyeColors.amberDeep, Icons.support_agent),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _SpecialistButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Specialist help is coming soon — we’ll connect you '
              'with a vetted expert to close this safely.'),
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: IEyeColors.tealDeep,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      icon: const Icon(Icons.support_agent, size: 18),
      label: const Text('Talk to a specialist',
          style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _CleanDevicesNote extends StatelessWidget {
  const _CleanDevicesNote(this.count);
  final int count;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        const Icon(Icons.check_circle_outline,
            color: IEyeColors.charcoalMuted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$count other device${count == 1 ? '' : 's'} showed no known issues '
            '— this isn’t a guarantee, only that we spotted nothing familiar.',
            style: text.bodyMedium?.copyWith(
                fontSize: 14, color: IEyeColors.charcoalMuted),
          ),
        ),
      ],
    );
  }
}

/// Mechanism, never outcome: say plainly what the scan can and can't promise.
class _HonestFooter extends StatelessWidget {
  const _HonestFooter();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Text(
      'This scan looks for known patterns on your own network and never signs in '
      'to your devices. It can miss things and can’t prove your home is safe — it '
      'points you to what’s worth fixing. Nothing it finds leaves this phone.',
      style: text.bodyMedium?.copyWith(fontSize: 13, color: IEyeColors.charcoalMuted),
    );
  }
}

IconData _deviceIcon(DeviceClass c) => switch (c) {
      DeviceClass.ipCamera => Icons.videocam_outlined,
      DeviceClass.nvr => Icons.dvr_outlined,
      DeviceClass.router => Icons.router_outlined,
      DeviceClass.accessPoint => Icons.wifi_tethering,
      DeviceClass.computer => Icons.computer,
      DeviceClass.iot => Icons.devices_other_outlined,
      DeviceClass.unknown => Icons.help_outline,
    };

String _deviceTitle(DeviceReport d) => switch (d.deviceClass) {
      DeviceClass.ipCamera => 'Camera',
      DeviceClass.nvr => 'Video recorder',
      DeviceClass.router => 'Router',
      DeviceClass.accessPoint => 'Wi-Fi access point',
      DeviceClass.computer => 'Computer',
      DeviceClass.iot => 'Smart device',
      DeviceClass.unknown => 'Unknown device',
    };

String _deviceSubtitle(DeviceReport d) {
  final parts = <String>[
    if (d.vendorFamily != null) d.vendorFamily!,
    if (d.model != null) d.model!,
    d.ip,
  ];
  return parts.join('  ·  ');
}
