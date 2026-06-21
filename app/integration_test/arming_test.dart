// On-device E2E for the comprehension gate (#25). The over-trust guardrail:
// three truths installed, "found, not rescued" actively acknowledged, and NO
// arming without it. Honest promise is mode-aware (Easy never says "inevitable").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ieye/core/delivery_mode.dart';
import 'package:ieye/features/arming/comprehension_gate_screen.dart';

import 'finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpGate(
    WidgetTester tester, {
    DeliveryMode mode = DeliveryMode.easy,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: ComprehensionGateScreen(mode: mode)),
    );
    await tester.pumpAndSettle();
  }

  group('comprehension gate', () {
    testWidgets('installs the three truths and the gravity gate', (
      tester,
    ) async {
      await pumpGate(tester);
      expect(gravityGate, findsOneWidget);
      expect(foundNotRescued, findsOneWidget);
      expect(find.textContaining('It can miss'), findsOneWidget);
      expect(
        find.textContaining('False alarms are the design'),
        findsOneWidget,
      );
    });

    testWidgets('NO arm without the micro-check, then arming works', (
      tester,
    ) async {
      var armed = false;
      await tester.pumpWidget(
        MaterialApp(home: ComprehensionGateScreen(onArmed: () => armed = true)),
      );
      await tester.pumpAndSettle();

      // Arm is disabled until the user acknowledges "found, not rescued".
      final before = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start watching over me'),
      );
      expect(before.onPressed, isNull);

      await tester.ensureVisible(microCheck);
      await tester.pumpAndSettle();
      await tester.tap(microCheck);
      await tester.pumpAndSettle();

      final after = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start watching over me'),
      );
      expect(after.onPressed, isNotNull);

      await tester.ensureVisible(armButton);
      await tester.pumpAndSettle();
      await tester.tap(armButton);
      await tester.pumpAndSettle();
      expect(armed, isTrue);
    });

    testWidgets('Easy mode states server-dependency and never "inevitable"', (
      tester,
    ) async {
      await pumpGate(tester);
      expect(find.textContaining('depends on iEye’s servers'), findsOneWidget);
      expect(find.textContaining('inevitable'), findsNothing);
      // No on-chain jargon for V1 (Easy) users — just a plain coming-soon teaser.
      expect(find.textContaining('blockchain'), findsNothing);
      expect(find.textContaining('public and permanent'), findsNothing);
      expect(find.textContaining('not ready yet'), findsOneWidget);
    });
  });
}
