import 'package:flutter/material.dart';
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
    await tester.pumpAndSettle();

    // Report state: the CRITICAL finding surfaces, badged by WORD (not colour).
    expect(find.textContaining('reachable from the internet'), findsOneWidget);
    expect(find.text('CRITICAL'), findsWidgets);

    // Honesty: passive findings are tagged "not confirmed", never claimed proven.
    expect(find.textContaining('not confirmed'), findsWidgets);

    // The funnel: at least one finding routes to a specialist.
    expect(find.text('Talk to a specialist'), findsWidgets);

    // The Wi-Fi section renders with its encryption stat.
    expect(find.textContaining('Wi-Fi'), findsWidgets);
    expect(find.text('WPA/TKIP · old'), findsOneWidget);
  });
}
