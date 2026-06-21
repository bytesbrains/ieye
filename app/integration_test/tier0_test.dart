// On-device E2E for Tier-0 phone-only sensing (#14). Drives the rhythm rule via
// the (stub) signal source and asserts the home surfaces phone-only limits
// honestly — a low/dead battery never reads as a confident all-clear, and the
// Tier-0 caveat is always disclosed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ieye/core/detection_brain.dart';
import 'package:ieye/core/phone_signals.dart';
import 'package:ieye/features/home/home_screen.dart';

import 'finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  PhoneSignals signals({
    int battery = 80,
    bool charging = false,
    bool reachable = true,
  }) => PhoneSignals(
    lastInteraction: DateTime.now().subtract(const Duration(minutes: 5)),
    batteryPercent: battery,
    charging: charging,
    reachable: reachable,
  );

  group('tier-0 honest sensing on the home', () {
    testWidgets(
      'healthy signals → watching, with the Tier-0 limits disclosed',
      (tester) async {
        final src = StubPhoneSignalsSource(signals());
        addTearDown(src.dispose);
        final brain = Tier0Brain(signals: src, sink: ReachSink()); // brain owns a safe demo circle
        addTearDown(brain.dispose);

        await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
        await tester.pumpAndSettle();

        expect(watchingHeadline, findsOneWidget);
        // The phone-only limit is always disclosed, even when all is well.
        expect(
          find.textContaining('watches using your phone alone'),
          findsOneWidget,
        );
        expect(fakeProtectedShield, findsNothing);
      },
    );

    testWidgets('low battery degrades the home with the dead-phone caveat', (
      tester,
    ) async {
      final src = StubPhoneSignalsSource(signals());
      addTearDown(src.dispose);
      final brain = Tier0Brain(signals: src, sink: ReachSink());
      addTearDown(brain.dispose);

      await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
      await tester.pumpAndSettle();
      expect(watchingHeadline, findsOneWidget);

      src.update(signals(battery: 8)); // battery drops
      await tester.pumpAndSettle();

      expect(watchingHeadline, findsNothing); // not a false all-clear
      expect(find.textContaining('Battery low'), findsOneWidget);
    });

    testWidgets('an unreachable phone shows "not a confident all-clear"', (
      tester,
    ) async {
      final src = StubPhoneSignalsSource(signals());
      addTearDown(src.dispose);
      final brain = Tier0Brain(signals: src, sink: ReachSink());
      addTearDown(brain.dispose);

      await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
      await tester.pumpAndSettle();

      src.update(signals(reachable: false)); // phone off / dead / killed
      await tester.pumpAndSettle();

      expect(watchingHeadline, findsNothing);
      expect(find.textContaining('promise you'), findsOneWidget);
    });
  });
}
