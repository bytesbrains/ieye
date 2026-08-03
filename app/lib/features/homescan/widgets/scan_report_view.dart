import 'package:flutter/material.dart';

import '../../../core/homescan/home_scan_model.dart';
import '../../../core/homescan/scanner.dart';
import '../../../theme/ieye_theme.dart';
import '../../../widgets/bytesbrains_badge.dart';

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
    // Expose the report to descendants so the specialist CTA can attach it to a
    // support request without threading it through every widget.
    return _ScanReportScope(
      report: report,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExposureOverview(report),
          const SizedBox(height: 24),
          if (report.wifi != null) ...[
            _WifiSection(report.wifi!),
            const SizedBox(height: 16),
          ],
          if (report.networkFindings.isNotEmpty) ...[
            _NetworkSection(report.networkFindings),
            const SizedBox(height: 16),
          ],
          for (final device in report.flagged) ...[
            _DeviceCard(device),
            const SizedBox(height: 16),
          ],
          if (report.cleanDeviceCount > 0)
            _CleanDevicesNote(report.cleanDeviceCount),
          const SizedBox(height: 20),
          const _HonestFooter(),
        ],
      ),
    );
  }
}

/// Carries the current [ScanReport] down to the specialist CTA, so tapping "Talk
/// to a specialist" can attach the scan to the support request.
class _ScanReportScope extends InheritedWidget {
  const _ScanReportScope({required this.report, required super.child});
  final ScanReport report;

  static ScanReport? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ScanReportScope>()
      ?.report;

  @override
  bool updateShouldNotify(_ScanReportScope old) => old.report != report;
}

/// The exposure overview — the report's headline card: an honest urgency
/// statement, a directly-labelled severity bar chart (worst-first, so urgency
/// reads top-down), and at-a-glance counts. Severity is a STATUS encoding: icon +
/// WORD + count, never colour alone, all within the warm palette (never alarm-red).
class _ExposureOverview extends StatelessWidget {
  const _ExposureOverview(this.report);
  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final worst = report.worst;

    // The critical headline counts DEVICES, not findings — one camera can emit
    // several critical findings and "5 devices" when 3 are affected overstates.
    // A worst of INFO reads as the calm state: info notes identify devices, they
    // don't call for action (alarm-fatigue guardrail).
    final criticalDevices = report.criticalDeviceCount;
    final (icon, accent, headline) = switch (worst) {
      null => (
        Icons.wb_incandescent_outlined,
        IEyeColors.tealDeep,
        'No known exposures found on ${report.deviceCount} devices',
      ),
      Severity.critical => (
        Icons.visibility_off_outlined,
        IEyeColors.amberDeep,
        '$criticalDevices device${criticalDevices == 1 ? '' : 's'} '
            'may be reachable from the internet',
      ),
      Severity.info => (
        Icons.wb_incandescent_outlined,
        IEyeColors.tealDeep,
        'Nothing needing action — '
            '${report.findingCount} note${report.findingCount == 1 ? '' : 's'} '
            'below',
      ),
      _ => (
        Icons.warning_amber_rounded,
        IEyeColors.amberDeep,
        '${report.findingCount} thing${report.findingCount == 1 ? '' : 's'} '
            'to look at on your network',
      ),
    };

    final needsLook = report.attentionCount;
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
          // A gently pulsing alert when something may be reachable from outside
          // the home right now — the one place the report earns urgency.
          if (worst == Severity.critical) ...[
            _CriticalAlertChip(criticalDevices),
            const SizedBox(height: 16),
          ],
          Semantics(
            header: true,
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accent, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    headline,
                    style: text.headlineSmall?.copyWith(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
          if (report.findingCount > 0) ...[
            const SizedBox(height: 20),
            Text(
              // "Findings", not "exposure" — INFO rows identify devices without
              // asserting exposure, and the label must not oversell them.
              'FINDINGS BY SEVERITY',
              style: text.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: IEyeColors.charcoalMuted,
              ),
            ),
            const SizedBox(height: 12),
            _SeverityBars(report.severityCounts),
          ],
          // "Nothing found ≠ safe" whenever nothing rose above INFO — info notes
          // are identification, so this honest caveat still applies with them on
          // screen (previously gated on zero findings, which presence notes made
          // unreachable on any normal smart home).
          if (report.nothingAboveInfo) ...[
            const SizedBox(height: 14),
            const _NoFindingsCaveat(),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x22000000)),
          const SizedBox(height: 16),
          // At-a-glance counts — scannable, honest (a fact, not an all-clear).
          Row(
            children: [
              _Stat(label: 'Devices seen', value: '${report.deviceCount}'),
              const _StatDivider(),
              _Stat(
                label: 'Need a look',
                value: '$needsLook',
                accent: needsLook > 0
                    ? IEyeColors.amberDeep
                    : IEyeColors.tealDeep,
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

/// A gently pulsing CRITICAL chip — draws the eye to an exposure that may be
/// reachable from outside the home right now. [count] is the number of affected
/// DEVICES (matching the headline), not findings.
///
/// Deliberately NOT a strobe: it breathes at ~0.8 Hz (a slow beacon pulse), well
/// under the WCAG 2.3.1 flashing threshold — a hard blink is a seizure risk and
/// off-brand (a lighthouse sweeps, it doesn't flash an alarm). Warm beacon-amber,
/// never alarm-red. The motion is only an ENHANCEMENT on top of icon + WORD +
/// count, and it honours reduced-motion (renders static then), so nothing depends
/// on the animation to be understood. It breathes a handful of times and then
/// rests — the eye has been drawn by then, and a finite animation lets the frame
/// pipeline (and pumpAndSettle in tests) go quiet.
class _CriticalAlertChip extends StatefulWidget {
  const _CriticalAlertChip(this.count);
  final int count;

  @override
  State<_CriticalAlertChip> createState() => _CriticalAlertChipState();
}

class _CriticalAlertChipState extends State<_CriticalAlertChip>
    with SingleTickerProviderStateMixin {
  /// Full breaths (dim-and-back) before the chip comes to rest, bright.
  static const _breaths = 4;

  late final AnimationController _c;
  int _breathsDone = 0;

  @override
  void initState() {
    super.initState();
    // Created here, not in the field initializer — the ticker provider is only
    // guaranteed ready once initState runs (review #81 / wrokin).
    // A manual ping-pong rather than repeat(reverse:) — repeat() never emits a
    // terminal status, so it could not be counted or brought to rest.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _c.addStatusListener((status) {
      // Bottom of a breath: come back up.
      if (status == AnimationStatus.dismissed) {
        _c.forward();
        return;
      }
      // Top of a breath (the controller is at its bright end, which is also
      // where it starts) — count it, then either breathe again or rest here.
      // Resting is only ever decided at the top, so the chip can never be left
      // stuck mid-dim, whatever the status parity.
      if (status != AnimationStatus.completed) return;
      _breathsDone += 1;
      if (_breathsDone > _breaths) return;
      _c.reverse();
    });
    _c.reverse(from: 1.0); // start bright, dim first
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = IEyeColors.amberDeep;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.priority_high_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            widget.count == 1
                ? 'CRITICAL EXPOSURE'
                : 'CRITICAL EXPOSURE · ${widget.count}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      // No liveRegion here — the headline just below is already one, and two
      // stacked live regions announce over each other. excludeSemantics stops
      // the chip's own text being read out a second time after the label.
      label: 'Critical exposure: ${widget.count}',
      excludeSemantics: true,
      child: reduceMotion
          ? chip
          : FadeTransition(
              opacity: _c.drive(
                Tween(begin: 0.55, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: chip,
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
          Text(
            value,
            style: text.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: accent ?? IEyeColors.charcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodyMedium?.copyWith(
              fontSize: 13,
              color: IEyeColors.charcoalMuted,
            ),
          ),
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

/// The exposure-by-severity chart: one directly-labelled horizontal bar per
/// severity present, worst-first. Bar length is relative to the largest count;
/// the exact count is printed beside it, so the bar is a glanceable cue, never the
/// source of truth. Every bar carries its icon + WORD (status, never colour alone).
class _SeverityBars extends StatelessWidget {
  const _SeverityBars(this.counts);
  final Map<Severity, int> counts;

  static const _order = [
    Severity.critical,
    Severity.high,
    Severity.medium,
    Severity.low,
    Severity.info,
  ];

  @override
  Widget build(BuildContext context) {
    final present = _order.where((s) => (counts[s] ?? 0) > 0).toList();
    if (present.isEmpty) return const SizedBox.shrink();
    final maxCount = present
        .map((s) => counts[s]!)
        .reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var i = 0; i < present.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _SeverityBar(
            severity: present[i],
            count: counts[present[i]]!,
            maxCount: maxCount,
          ),
        ],
      ],
    );
  }
}

class _SeverityBar extends StatelessWidget {
  const _SeverityBar({
    required this.severity,
    required this.count,
    required this.maxCount,
  });
  final Severity severity;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (label, color, icon) = _severityStyle(severity);
    return Semantics(
      label: '$label: $count',
      // The label already says it all — don't let the row's own text nodes be
      // read out again after it.
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 124,
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 12,
                color: const Color(0x14000000), // recessive track
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (count / maxCount).clamp(0.06, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: IEyeColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared severity style (label, colour, icon) — status, never colour alone.
/// High is the lighter amber so it reads distinct from critical's deep amber;
/// medium is calm teal; low/info recede to muted charcoal. Never alarm-red.
(String, Color, IconData) _severityStyle(Severity s) => switch (s) {
  Severity.critical => (
    'CRITICAL',
    IEyeColors.amberDeep,
    Icons.priority_high_rounded,
  ),
  Severity.high => ('HIGH', IEyeColors.amber, Icons.error_outline),
  Severity.medium => ('MEDIUM', IEyeColors.tealDeep, Icons.shield_outlined),
  Severity.low => ('LOW', IEyeColors.charcoalMuted, Icons.tune),
  Severity.info => ('INFO', IEyeColors.charcoalMuted, Icons.info_outline),
};

/// One device, its plain identity, and every finding about it.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard(this.device);
  final DeviceReport device;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // A left accent stripe in the device's worst-severity colour, so the card's
    // urgency reads at a glance (device is flagged, so worst is non-null).
    final accent = _severityStyle(device.worst ?? Severity.info).$2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Container(
                color: IEyeColors.paperDim,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _deviceIcon(device.deviceClass),
                          color: IEyeColors.charcoal,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deviceTitle(device),
                                style: text.titleLarge?.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _deviceSubtitle(device),
                                style: text.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: IEyeColors.charcoalMuted,
                                ),
                              ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network-level findings (segmentation) — about how the network is *arranged*,
/// not one device. Styled like the Wi-Fi section; reuses the finding block.
class _NetworkSection extends StatelessWidget {
  const _NetworkSection(this.findings);
  final List<Finding> findings;

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
              const Icon(Icons.hub_outlined,
                  color: IEyeColors.charcoal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How your network is arranged',
                  style: text.titleLarge?.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          for (final f in findings) ...[
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
                child: Text(
                  o.ssid == null ? 'Your Wi-Fi' : 'Wi-Fi · ${o.ssid}',
                  style: text.titleLarge?.copyWith(fontSize: 18),
                ),
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
                    color: IEyeColors.charcoal,
                    fontWeight: FontWeight.w600,
                  ),
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
        const Icon(
          Icons.help_outline,
          color: IEyeColors.charcoalMuted,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'This phone can’t check your Wi-Fi encryption — the system doesn’t '
            'allow it. A laptop scan or the iEye box can see whether your Wi-Fi is '
            'open or weakly encrypted.',
            style: text.bodyMedium?.copyWith(
              fontSize: 14,
              color: IEyeColors.charcoalSoft,
            ),
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
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
        Text(
          finding.title,
          style: text.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          finding.whatItMeans,
          style: text.bodyMedium?.copyWith(color: IEyeColors.charcoalSoft),
        ),
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
              const Text(
                'What to do',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: IEyeColors.charcoal,
                ),
              ),
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
                  Text(
                    '${i + 1}.',
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: IEyeColors.charcoal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      finding.remediation[i],
                      style: text.bodyMedium?.copyWith(fontSize: 15),
                    ),
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
    final (label, color, icon) = _severityStyle(severity);
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
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
        child: const Text(
          'Likely · not confirmed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: IEyeColors.charcoalSoft,
          ),
        ),
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
      FixOwner.user => (
        'You can fix this',
        IEyeColors.tealDeep,
        Icons.check_circle_outline,
      ),
      FixOwner.specialist => (
        'Best with a specialist',
        IEyeColors.amberDeep,
        Icons.support_agent,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SpecialistButton extends StatelessWidget {
  const _SpecialistButton();

  // Open the request flow, attaching the current scan so the user can (opt-in)
  // share it. The report rides in as a route argument, read from the scope.
  // (This replaces the earlier email/clipboard stopgap from #81.)
  void _talkToSpecialist(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/support-request',
      arguments: _ScanReportScope.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _talkToSpecialist(context),
      style: TextButton.styleFrom(
        foregroundColor: IEyeColors.tealDeep,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      icon: const Icon(Icons.support_agent, size: 18),
      label: const Text(
        'Talk to a specialist',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Shown when the scan found nothing — the "not a clean bill of health" moment.
/// Absence of findings is a LIMIT of a passive scan (devices block inspection;
/// cloud cameras never show), not proof of safety. Keeps the user alert and
/// offers a deeper professional check — honest caution, never fear-selling.
class _NoFindingsCaveat extends StatelessWidget {
  const _NoFindingsCaveat();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: IEyeColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IEyeColors.amber, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: IEyeColors.amberDeep,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A good sign — but not a clean bill of health',
                  style: text.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: IEyeColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This check is passive — it only sees what each device chooses to '
            'reveal, and many block a closer look. Some of the worst exposures, '
            'like a camera quietly streaming to a maker’s cloud, never show up in '
            'a scan like this. So “nothing found” can just mean “couldn’t look '
            'deeper.” Stay alert — and to be sure, a specialist can check what '
            'this scan can’t.',
            style: text.bodyMedium?.copyWith(
              fontSize: 14,
              color: IEyeColors.charcoalSoft,
            ),
          ),
          const _SpecialistButton(),
        ],
      ),
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
        const Icon(
          Icons.check_circle_outline,
          color: IEyeColors.charcoalMuted,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$count other device${count == 1 ? '' : 's'} showed nothing familiar — '
            'but a passive scan can’t fully inspect a device that doesn’t reveal '
            'much, so that’s “nothing we could see”, not a clean bill of health.',
            style: text.bodyMedium?.copyWith(
              fontSize: 14,
              color: IEyeColors.charcoalMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Mechanism, never outcome: say plainly what the scan can and can't promise —
/// and that absence of findings is a limit of the scan, not proof of safety.
class _HonestFooter extends StatelessWidget {
  const _HonestFooter();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This scan looks for known patterns on your own network and never signs '
          'in. Finding nothing is not proof you’re safe — it’s passive, many '
          'devices don’t reveal much, and cloud-connected cameras never show here. '
          'Stay aware. Nothing it finds leaves this phone.',
          style: text.bodyMedium?.copyWith(
            fontSize: 13,
            color: IEyeColors.charcoalMuted,
          ),
        ),
        const SizedBox(height: 4),
        // Professional help goes deeper than a passive scan can — always offered,
        // never fear-sold.
        const _SpecialistButton(),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: BytesBrainsBadge(centered: false),
        ),
      ],
    );
  }
}

IconData _deviceIcon(DeviceClass c) => switch (c) {
  DeviceClass.ipCamera => Icons.videocam_outlined,
  DeviceClass.nvr => Icons.dvr_outlined,
  DeviceClass.router => Icons.router_outlined,
  DeviceClass.accessPoint => Icons.wifi_tethering,
  DeviceClass.nas => Icons.storage_outlined,
  DeviceClass.printer => Icons.print_outlined,
  DeviceClass.mediaDevice => Icons.tv_outlined,
  DeviceClass.smartHub => Icons.hub_outlined,
  DeviceClass.computer => Icons.computer,
  DeviceClass.iot => Icons.devices_other_outlined,
  DeviceClass.unknown => Icons.help_outline,
};

/// The generic name for a device class — the fallback title, and the type label
/// shown in the subtitle when a device advertises its own friendly mDNS name.
String _classLabel(DeviceClass c) => switch (c) {
  DeviceClass.ipCamera => 'Camera',
  DeviceClass.nvr => 'Video recorder',
  DeviceClass.router => 'Router',
  DeviceClass.accessPoint => 'Wi-Fi access point',
  DeviceClass.nas => 'Storage (NAS)',
  DeviceClass.printer => 'Printer',
  DeviceClass.mediaDevice => 'TV / streaming device',
  DeviceClass.smartHub => 'Smart-home hub',
  DeviceClass.computer => 'Computer',
  DeviceClass.iot => 'Smart device',
  DeviceClass.unknown => 'Unknown device',
};

/// Prefer the device's own advertised name (mDNS/Bonjour) — "Living Room TV"
/// reads far better than "TV / streaming device" — falling back to the class.
String _deviceTitle(DeviceReport d) {
  final name = d.observation.mdnsName?.trim();
  return (name != null && name.isNotEmpty) ? name : _classLabel(d.deviceClass);
}

String _deviceSubtitle(DeviceReport d) {
  final name = d.observation.mdnsName?.trim();
  final parts = <String>[
    // When the title is the friendly name, still say what kind of thing it is.
    if (name != null && name.isNotEmpty) _classLabel(d.deviceClass),
    if (d.vendorFamily != null) d.vendorFamily!,
    if (d.model != null) d.model!,
    d.ip,
  ];
  return parts.join('  ·  ');
}
