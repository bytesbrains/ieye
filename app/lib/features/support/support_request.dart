import '../../core/homescan/scanner.dart';

/// When the user would like to be called back. Coarse on purpose — a specialist
/// slots them in; we don't pretend to book an exact minute.
enum PreferredTime { morning, afternoon, evening, anytime }

extension PreferredTimeLabel on PreferredTime {
  String get label => switch (this) {
    PreferredTime.morning => 'Morning',
    PreferredTime.afternoon => 'Afternoon',
    PreferredTime.evening => 'Evening',
    PreferredTime.anytime => 'Anytime',
  };
}

/// One request for professional help, as the user fills it in. Identity (who they
/// are) comes from the signed-in [AuthUser] at submit time — never typed here, so
/// there's no unverified email to get wrong. Everything optional-to-share is
/// opt-in and defaults to NOT shared: the home inventory is sensitive, so we send
/// it only when the user says so.
class SupportRequest {
  const SupportRequest({
    required this.callbackNumber,
    required this.preferredTime,
    required this.note,
    this.shareFindings = false,
    this.findingsSummary,
    this.shareLocation = false,
    this.timezone,
    this.area,
  });

  /// A number a specialist can call back on (the user's own; not their identity).
  final String callbackNumber;
  final PreferredTime preferredTime;

  /// A free-text note (supports voice-to-text on the screen).
  final String note;

  /// Opt-in: attach a summary of the scan so the specialist arrives informed.
  final bool shareFindings;

  /// The scan summary attached when [shareFindings] — see [summarizeReport].
  final Map<String, dynamic>? findingsSummary;

  /// Opt-in: share timezone + a typed area (never GPS) so a callback lands at a
  /// sane local hour.
  final bool shareLocation;
  final String? timezone;
  final String? area;

  /// The one place that decides what counts as a callable number — the screen's
  /// submit button and [isValid] must never drift apart.
  static bool isValidCallbackNumber(String number) =>
      number.trim().length >= 6;

  bool get isValid => isValidCallbackNumber(callbackNumber);
}

/// A privacy-conscious, specialist-useful summary of a scan — counts, the worst
/// severity, and per-flagged-device findings (type, friendly name, finding kinds).
/// It carries NO secrets: the passive scan never had a credential to leak, and it
/// only travels when the user opts to share it.
Map<String, dynamic> summarizeReport(ScanReport r) => {
  'deviceCount': r.deviceCount,
  'findingCount': r.findingCount,
  'criticalCount': r.criticalCount,
  'worst': r.worst?.name,
  'severityCounts': {
    for (final e in r.severityCounts.entries) e.key.name: e.value,
  },
  'wifi': r.wifi == null ? null : {'security': r.wifi!.observation.security.name},
  'devices': [
    for (final d in r.flagged)
      {
        'type': d.deviceClass.name,
        if (d.observation.mdnsName != null) 'name': d.observation.mdnsName,
        if (d.vendorFamily != null) 'vendor': d.vendorFamily,
        'ip': d.ip,
        'findings': [
          for (final f in d.findings)
            {'kind': f.kind.name, 'severity': f.severity.name, 'title': f.title},
        ],
      },
  ],
};
