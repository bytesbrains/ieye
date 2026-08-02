import 'package:flutter/material.dart';

import '../../core/homescan/scanner.dart';
import '../../theme/ieye_theme.dart';
import 'widgets/scan_report_view.dart';

/// What a scan is pointed at — one engine, honest framing per surface.
///
/// The [car] context reaches only the car's Wi-Fi hotspot and the aftermarket
/// gadgets on it (a dashcam, a tracker, a plug-in OBD dongle) — the same "cheap
/// exposed device" class the home scan already finds. It can NEVER see the systems
/// that drive the car (brakes, steering, ADAS, telematics), which ride isolated
/// buses a Wi-Fi scan can't touch. [scopeNote] says that plainly, so no one
/// mistakes a clean car Wi-Fi for a safe car — a false sense of car safety is
/// worse than none (D-031: promise the mechanism, never the outcome).
enum ScanContext {
  home(
    title: 'Home Security Scan',
    introHeadline: 'Look for exposed devices in your home',
    introBody:
        'iEye can look at the devices on your Wi-Fi and flag cameras or gadgets '
        'a stranger might be able to reach. It checks for known patterns — it '
        'never signs in to anything, and it can’t promise your home is safe.',
    consent: 'This is my own home network, and I’m allowed to scan it.',
    action: 'Scan my home',
    surface: 'the devices on your network',
    scopeNote: null,
  ),
  car(
    title: 'Car Wi-Fi Scan',
    introHeadline: 'Look for exposed gadgets on your car’s Wi-Fi',
    introBody:
        'Many cars run a Wi-Fi hotspot, and the gadgets people add to it — a '
        'dashcam, a tracker, a plug-in OBD dongle — can sit wide open. iEye looks '
        'for the same exposures it finds at home. It checks known patterns, never '
        'signs in, and can’t promise your car is safe.',
    consent: 'This is my own car, and I’m allowed to scan its Wi-Fi.',
    action: 'Scan my car',
    surface: 'the gadgets on your car’s Wi-Fi',
    scopeNote:
        'This reaches your car’s Wi-Fi and the gadgets on it — a dashcam, a '
        'tracker, a plug-in dongle. It can’t see the systems that drive your car '
        '(brakes, steering, the maker’s own connection); for those, talk to your '
        'car’s maker or a specialist.',
  );

  const ScanContext({
    required this.title,
    required this.introHeadline,
    required this.introBody,
    required this.consent,
    required this.action,
    required this.surface,
    required this.scopeNote,
  });

  /// App-bar title.
  final String title;

  /// Intro headline + body.
  final String introHeadline;
  final String introBody;

  /// The ownership affirmation copy (the consent gate).
  final String consent;

  /// The primary action label ("Scan my home" / "Scan my car").
  final String action;

  /// What the scan looks over, for the scanning-state line ("Looking over …").
  final String surface;

  /// The honest boundary, shown as a banner — or null when there's none to draw
  /// (home). For the car, this is the whole point: Wi-Fi, not the car itself.
  final String? scopeNote;
}

/// The Home Security Scan surface — the day-one-value feature. It looks for
/// devices on the user's own network a stranger might reach (exposed cameras) and
/// tells them plainly what to do. The same engine also scans a car's Wi-Fi hotspot
/// ([ScanContext.car]). Same brand: watches OVER you, never watches you; promises
/// the mechanism (we look for known patterns), never the outcome (never "you're
/// now safe").
///
/// [scanner] is injectable so tests / the future real scanner drop straight in.
/// Defaults to the [StubScanner] (demo data, no native code) so the whole flow is
/// exercisable today. [scanContext] swaps the framing (home vs car) and, for the
/// car, draws the honest-scope banner.
class SecurityScanScreen extends StatefulWidget {
  const SecurityScanScreen({
    super.key,
    this.scanner = const StubScanner(),
    this.scanContext = ScanContext.home,
  });

  final NetworkScanner scanner;
  final ScanContext scanContext;

  @override
  State<SecurityScanScreen> createState() => _SecurityScanScreenState();
}

class _SecurityScanScreenState extends State<SecurityScanScreen> {
  ScanReport? _report;
  bool _scanning = false;
  // Structural ownership gate: no scan runs until the user affirms this is their
  // own network. The more powerful the capability, the harder the consent — the
  // same rule that keeps the mass tier passive (CLAUDE.md).
  bool _consented = false;

  Future<void> _runScan() async {
    if (!_consented) return;
    setState(() => _scanning = true);
    try {
      final report = await widget.scanner.scan();
      if (!mounted) return;
      setState(() {
        _report = report;
        _scanning = false;
      });
    } catch (_) {
      // Never leave the spinner stuck — recover to the intro and say so plainly.
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The scan couldn’t finish. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: IEyeColors.paper,
        foregroundColor: IEyeColors.charcoal,
        elevation: 0,
        title: Text(
          widget.scanContext.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: _scanning
              ? _Scanning(scanContext: widget.scanContext)
              : _report == null
              ? _Intro(
                  scanContext: widget.scanContext,
                  consented: _consented,
                  onConsentChanged: (v) => setState(() => _consented = v),
                  onScan: _runScan,
                )
              : _Results(
                  report: _report!,
                  scanContext: widget.scanContext,
                  onRescan: _runScan,
                ),
        ),
      ),
    );
  }
}

/// First run: what this does, honestly, the ownership gate, and the one amber
/// action (enabled only once the user affirms this is their own network).
class _Intro extends StatelessWidget {
  const _Intro({
    required this.scanContext,
    required this.consented,
    required this.onConsentChanged,
    required this.onScan,
  });

  final ScanContext scanContext;
  final bool consented;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Icon(
          Icons.wifi_find_outlined,
          color: IEyeColors.tealDeep,
          size: 48,
        ),
        const SizedBox(height: 20),
        Text(
          scanContext.introHeadline,
          style: text.headlineSmall?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 14),
        Text(scanContext.introBody, style: text.bodyLarge),
        const SizedBox(height: 20),
        // The honest boundary (car: Wi-Fi, not the car's driving systems). Draws
        // nothing for the home scan, which has no such caveat.
        _ScopeBanner(scanContext.scopeNote),
        // The ownership gate — scanning stays disabled until this is affirmed.
        _ConsentTile(
          label: scanContext.consent,
          value: consented,
          onChanged: onConsentChanged,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          // Disabled (null) until consent is given.
          onPressed: consented ? onScan : null,
          icon: const Icon(Icons.radar),
          label: Text(scanContext.action),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline,
              color: IEyeColors.charcoalMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your phone may ask to find devices on your local network — that’s '
                'this scan. Nothing it finds ever leaves this phone.',
                style: text.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: IEyeColors.charcoalMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The ownership affirmation ("this is my own …"). Tappable across the whole row.
class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      checked: value,
      child: Material(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          // The whole row is the ONE tap target. The checkbox is display-only
          // (IgnorePointer) so a tap on it passes through here — no double toggle.
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IgnorePointer(
                  child: ExcludeSemantics(
                    child: Checkbox(
                      value: value,
                      onChanged: (_) {},
                      activeColor: IEyeColors.amberDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: IEyeColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The honest boundary for a scan, as an amber-bordered note. For the car this is
/// the whole point — we see the Wi-Fi, not the car. Renders nothing when the
/// context has no caveat to draw (home), so callers can place it unconditionally.
class _ScopeBanner extends StatelessWidget {
  const _ScopeBanner(this.note);
  final String? note;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    if (note == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IEyeColors.amber, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: IEyeColors.amberDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: text.bodyMedium?.copyWith(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({required this.scanContext});
  final ScanContext scanContext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          const _ScanningPulse(),
          const SizedBox(height: 32),
          Text(
            'Looking over ${scanContext.surface}…',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 10),
          Text(
            'This stays on your phone. It only reads what each device '
            'volunteers — it never signs in.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              fontSize: 14,
              color: IEyeColors.charcoalMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A calm radar "ping" — a beacon looking out over the network. Two teal rings
/// expand and fade around a central beacon icon. On brand (a lighthouse sweeping),
/// never an anxious spinner; teal (calm), never amber alarm. It repeats only for
/// as long as the scan runs (this widget leaves the tree with the scanning
/// state), and honours reduced-motion by holding a static frame — like the
/// CRITICAL chip, the motion is an enhancement, never the information.
class _ScanningPulse extends StatefulWidget {
  const _ScanningPulse();
  @override
  State<_ScanningPulse> createState() => _ScanningPulseState();
}

class _ScanningPulseState extends State<_ScanningPulse>
    with SingleTickerProviderStateMixin {
  // Created in initState, not the field initializer — the ticker provider is
  // only guaranteed ready once initState runs (review #81 / wrokin).
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    final scale = 0.45 + t * 0.55; // 0.45 → 1.0
    return Opacity(
      opacity: ((1 - t) * 0.45).clamp(0.0, 1.0),
      child: Container(
        width: 116 * scale,
        height: 116 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: IEyeColors.teal, width: 2),
        ),
      ),
    );
  }

  /// The static frame for reduced-motion: two rings held mid-sweep.
  Widget _frame(double t) => Stack(
    alignment: Alignment.center,
    children: [_ring(t), _ring((t + 0.5) % 1.0), _beacon()],
  );

  Widget _beacon() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: IEyeColors.tealDeep.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.wifi_find_outlined,
      color: IEyeColors.tealDeep,
      size: 28,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox(
      width: 116,
      height: 116,
      child: reduceMotion
          ? _frame(0.6)
          : AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _frame(_c.value),
            ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.report,
    required this.scanContext,
    required this.onRescan,
  });
  final ScanReport report;
  final ScanContext scanContext;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Restate the boundary on the report itself (car): a clean Wi-Fi is not a
        // safe car. Draws nothing for the home scan.
        _ScopeBanner(scanContext.scopeNote),
        ScanReportView(report),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: onRescan,
          style: OutlinedButton.styleFrom(
            foregroundColor: IEyeColors.charcoal,
            side: const BorderSide(color: IEyeColors.charcoalMuted),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text(
            'Scan again',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
