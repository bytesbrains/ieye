import 'package:flutter/material.dart';

import '../../core/homescan/scanner.dart';
import '../../theme/ieye_theme.dart';
import 'widgets/scan_report_view.dart';

/// The Home Security Scan surface — the day-one-value feature. It looks for
/// devices on the user's own network a stranger might reach (exposed cameras) and
/// tells them plainly what to do. Same brand: watches OVER you, never watches you;
/// promises the mechanism (we look for known patterns), never the outcome (never
/// "you're now safe").
///
/// [scanner] is injectable so tests / the future real scanner drop straight in.
/// Defaults to the [StubScanner] (demo data, no native code) so the whole flow is
/// exercisable today.
class SecurityScanScreen extends StatefulWidget {
  const SecurityScanScreen({super.key, this.scanner = const StubScanner()});

  final NetworkScanner scanner;

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
    final report = await widget.scanner.scan();
    if (!mounted) return;
    setState(() {
      _report = report;
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: IEyeColors.paper,
        foregroundColor: IEyeColors.charcoal,
        elevation: 0,
        title: const Text('Home Security Scan',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: _scanning
              ? const _Scanning()
              : _report == null
                  ? _Intro(
                      consented: _consented,
                      onConsentChanged: (v) => setState(() => _consented = v),
                      onScan: _runScan,
                    )
                  : _Results(
                      report: _report!,
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
    required this.consented,
    required this.onConsentChanged,
    required this.onScan,
  });

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
        const Icon(Icons.wifi_find_outlined,
            color: IEyeColors.tealDeep, size: 48),
        const SizedBox(height: 20),
        Text('Look for exposed devices in your home',
            style: text.headlineSmall?.copyWith(fontSize: 26)),
        const SizedBox(height: 14),
        Text(
          'iEye can look at the devices on your Wi-Fi and flag cameras or gadgets '
          'a stranger might be able to reach. It checks for known patterns — it '
          'never signs in to anything, and it can’t promise your home is safe.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: 24),
        // The ownership gate — scanning stays disabled until this is affirmed.
        _ConsentTile(value: consented, onChanged: onConsentChanged),
        const SizedBox(height: 20),
        FilledButton.icon(
          // Disabled (null) until consent is given.
          onPressed: consented ? onScan : null,
          icon: const Icon(Icons.radar),
          label: const Text('Scan my network'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline,
                color: IEyeColors.charcoalMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your phone may ask to find devices on your local network — that’s '
                'this scan. Nothing it finds ever leaves this phone.',
                style: text.bodyMedium?.copyWith(
                    fontSize: 14, color: IEyeColors.charcoalMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The "this is my own network" affirmation. Tappable across the whole row.
class _ConsentTile extends StatelessWidget {
  const _ConsentTile({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: IEyeColors.paperDim,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: IEyeColors.amberDeep,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'This is my own home network, and I’m allowed to scan it.',
                  style: text.bodyMedium
                      ?.copyWith(fontSize: 15, color: IEyeColors.charcoal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const CircularProgressIndicator(color: IEyeColors.amberDeep),
          const SizedBox(height: 28),
          Text('Looking at the devices on your network…',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontSize: 19)),
          const SizedBox(height: 10),
          Text('This stays on your phone. It only reads what each device '
              'volunteers — it never signs in.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                  fontSize: 14, color: IEyeColors.charcoalMuted)),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.report, required this.onRescan});
  final ScanReport report;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScanReportView(report),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: onRescan,
          style: OutlinedButton.styleFrom(
            foregroundColor: IEyeColors.charcoal,
            side: const BorderSide(color: IEyeColors.charcoalMuted),
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Scan again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
