import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/core/homescan/scanner.dart';
import 'package:ieye/features/homescan/security_scan_screen.dart';
import 'package:ieye/theme/ieye_theme.dart';

void main() {
  Widget harness() => MaterialApp(
        theme: buildIEyeTheme(),
        // Zero settle delay so the scan resolves within the test pump.
        home: const SecurityScanScreen(
          scanner: StubScanner(settleDelay: Duration.zero),
        ),
      );

  testWidgets('scan is gated on the ownership affirmation', (tester) async {
    await tester.pumpWidget(harness());

    // Before consent, the scan action is disabled.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.textContaining("my own home network"));
    await tester.pump();

    final enabled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('intro → consent → scan → report renders the CRITICAL exposure', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    // Intro state: the one amber action, and the honest promise.
    expect(find.text('Scan my home'), findsOneWidget);
    expect(find.textContaining('can’t promise your home is safe'), findsWidgets);

    // Affirm ownership, then scan.
    await tester.tap(find.textContaining("my own home network"));
    await tester.pump();
    await tester.tap(find.text('Scan my home'));
    // The report's CRITICAL chip breathes for a few seconds; pump the report
    // into place (settleDelay is zero) rather than waiting it out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Report state: the CRITICAL finding surfaces, badged by WORD (not colour).
    // (Match the headline's exact phrasing — several findings also mention being
    // "reachable from the internet".)
    expect(
      find.textContaining('may be reachable from the internet'),
      findsOneWidget,
    );
    expect(find.text('CRITICAL'), findsWidgets);

    // The pulsing critical alert draws the eye to internet-reachable exposure.
    expect(find.textContaining('CRITICAL EXPOSURE'), findsOneWidget);

    // Stream-exposure and recorder findings both surface (detect-not-view).
    expect(
      find.textContaining('live video is being served'),
      findsWidgets,
    );
    expect(
      find.textContaining('recorder holding your saved footage'),
      findsOneWidget,
    );

    // mDNS gives devices their real names — a friendly title beats a generic one.
    expect(find.text('Living Room TV'), findsOneWidget);

    // Honesty: passive findings are tagged "not confirmed", never claimed proven.
    expect(find.textContaining('not confirmed'), findsWidgets);

    // The funnel: at least one finding routes to a specialist.
    expect(find.text('Talk to a specialist'), findsWidgets);

    // The Wi-Fi section renders with its encryption stat.
    expect(find.textContaining('Wi-Fi'), findsWidgets);
    expect(find.text('WPA/TKIP · old'), findsOneWidget);
  });

  testWidgets('the CRITICAL chip breathes, then comes to rest at full opacity',
      (tester) async {
    // A finite pulse: it draws the eye and stops. An endless one would repaint
    // the report forever and leave pumpAndSettle unusable for every later test.
    await tester.pumpWidget(harness());
    await tester.tap(find.textContaining('my own home network'));
    await tester.pump();
    await tester.tap(find.text('Scan my home'));
    await tester.pump();

    // pumpAndSettle returning at all proves the animation terminates.
    await tester.pumpAndSettle();
    expect(find.textContaining('CRITICAL EXPOSURE'), findsOneWidget);

    final fade = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.textContaining('CRITICAL EXPOSURE'),
        matching: find.byType(FadeTransition),
      ).first,
    );
    // At rest it must be fully legible, never stuck mid-dim.
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('a clean scan is honest — "not a clean bill of health", never safe',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildIEyeTheme(),
      home: const SecurityScanScreen(scanner: _CleanScanner()),
    ));

    await tester.tap(find.textContaining('my own home network'));
    await tester.pump();
    await tester.tap(find.text('Scan my home'));
    await tester.pumpAndSettle();

    // Absence of findings is a LIMIT of a passive scan, not proof of safety.
    expect(find.textContaining('not a clean bill of health'), findsOneWidget);
    expect(find.textContaining('couldn’t look deeper'), findsWidgets);
    // Still offers the deeper professional check.
    expect(find.text('Talk to a specialist'), findsWidgets);
    // Never a green all-clear (over-trust guardrail).
    expect(find.textContaining('protected'), findsNothing);
  });

  /// Drive the clean-scan report to the specialist CTA and tap it, with the
  /// clipboard channel behaving as [onCopy] dictates.
  Future<void> tapSpecialist(
    WidgetTester tester, {
    required Future<Object?> Function() onCopy,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.setData' ? await onCopy() : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(MaterialApp(
      theme: buildIEyeTheme(),
      home: const SecurityScanScreen(scanner: _CleanScanner()),
    ));
    await tester.tap(find.textContaining('my own home network'));
    await tester.pump();
    await tester.tap(find.text('Scan my home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Talk to a specialist').first);
    await tester.pump(); // run the handler up to the awaited clipboard write
    await tester.pump(); // write settles → showSnackBar is called
    await tester.pump(const Duration(milliseconds: 400)); // SnackBar animates in
    // (don't pumpAndSettle — it would fast-forward past the 4s auto-dismiss.)
  }

  testWidgets('the specialist CTA points to the BytesBrains contact email',
      (tester) async {
    await tapSpecialist(tester, onCopy: () async => null);

    expect(find.textContaining('contact@bytesbrains.com'), findsOneWidget);
    expect(find.textContaining('we’ve copied it for you'), findsOneWidget);
  });

  testWidgets('a denied clipboard still gives the address, minus the claim',
      (tester) async {
    // The write is awaited so the message can't claim something that didn't
    // happen — if the platform refuses, say the address, don't say "copied".
    await tapSpecialist(
      tester,
      onCopy: () async => throw PlatformException(code: 'denied'),
    );

    expect(find.textContaining('contact@bytesbrains.com'), findsOneWidget);
    expect(find.textContaining('copied'), findsNothing);
  });

  testWidgets(
    'car scan is honestly scoped — Wi-Fi, never the systems that drive the car',
    (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildIEyeTheme(),
        home: const SecurityScanScreen(
          scanner: StubScanner(settleDelay: Duration.zero),
          scanContext: ScanContext.car,
        ),
      ));

      // The car framing leads, and the honest boundary is stated up front: the
      // scan sees the car's Wi-Fi, not the systems that drive it (D-031).
      expect(find.text('Car Wi-Fi Scan'), findsOneWidget); // app-bar title
      expect(find.textContaining('exposed gadgets on your car'), findsOneWidget);
      expect(find.textContaining('systems that drive your car'), findsWidgets);

      // Own-car ownership gate, then scan with the car action label. The car
      // intro is taller (scope banner + longer body), so bring controls on-screen.
      await tester.ensureVisible(find.textContaining('my own car'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('my own car'));
      await tester.pump();
      await tester.ensureVisible(find.text('Scan my car'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan my car'));
      // Report animates (pulsing critical chip) — pump it in rather than settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The report still finds the same exposures the engine finds anywhere…
      expect(find.text('CRITICAL'), findsWidgets);
      // …and the boundary is RESTATED on the report — a clean Wi-Fi is not a safe
      // car — and it never claims the car is "safe" or "protected".
      expect(find.textContaining('systems that drive your car'), findsWidgets);
      expect(find.textContaining('protected'), findsNothing);
    },
  );
}

/// A scanner that finds nothing — to exercise the honest "clean" state.
class _CleanScanner implements NetworkScanner {
  const _CleanScanner();
  @override
  Future<ScanReport> scan() async =>
      ScanReport(startedAt: DateTime(2026), devices: const []);
}
