// On-device E2E for circle visibility + graceful exit + coverage-drop (#18).
// Asserts the guardrails: the roster is visible and nearest-first (no raw
// locations), a one-step resignation is graceful + undoable, and a coverage drop
// surfaces honestly on the owner's home — silent gaps are impossible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ieye/core/circle.dart';
import 'package:ieye/core/detection_brain.dart';
import 'package:ieye/features/circle/circle_screen.dart';
import 'package:ieye/features/home/home_screen.dart';

import 'finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<CircleStore> pumpCircle(
    WidgetTester tester, {
    String viewer = 'maria',
  }) async {
    final store = CircleStore(demoCircleMembers());
    await tester.pumpWidget(
      MaterialApp(home: CircleScreen(store: store, viewerId: viewer)),
    );
    await tester.pumpAndSettle();
    return store;
  }

  group('circle visibility', () {
    testWidgets('shows the roster, nearest-first, with "You" marked', (
      tester,
    ) async {
      await pumpCircle(tester);

      expect(find.text('Maria · You'), findsOneWidget);
      expect(find.text('Tom'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);

      // Nearest-first ordering (proximity, never raw location).
      final maria = tester.getTopLeft(find.text('Maria · You')).dy;
      final tom = tester.getTopLeft(find.text('Tom')).dy;
      final priya = tester.getTopLeft(find.text('Priya')).dy;
      expect(maria, lessThan(tom));
      expect(tom, lessThan(priya));
    });
  });

  group('graceful exit', () {
    testWidgets('step down in one tap → stepped-down + undo restores', (
      tester,
    ) async {
      final store = await pumpCircle(tester); // viewer = maria

      // Destructive action confirms first (it's a life-safety circle).
      await tester.tap(find.text('Step down'));
      await tester.pumpAndSettle();
      expect(find.text('Yes, step down'), findsOneWidget);
      await tester.tap(find.text('Yes, step down'));
      await tester.pumpAndSettle();

      expect(find.textContaining('stepped down'), findsWidgets);
      expect(
        store.circle.total,
        2,
      ); // owner-visible coverage updated immediately

      await tester.tap(find.textContaining('Undo'));
      await tester.pumpAndSettle();
      expect(store.circle.total, 3); // graceful — fully reversible
      expect(find.text('Maria · You'), findsOneWidget);
    });
  });

  group('coverage drop surfaces on the home (no silent gaps)', () {
    testWidgets('resigning the only in-person checker degrades the home', (
      tester,
    ) async {
      final store = CircleStore(demoCircleMembers());
      final brain = Tier0Brain(circle: store);
      addTearDown(brain.dispose);

      await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
      await tester.pumpAndSettle();

      // Safe to start.
      expect(watchingHeadline, findsOneWidget);
      expect(find.textContaining('none within driving distance'), findsNothing);

      // The only canGoInPerson checker steps down — read through the engine.
      store.resign('maria');
      await tester.pumpAndSettle();

      expect(watchingHeadline, findsNothing); // no longer "all good"
      expect(
        find.textContaining('no one close enough to come over'),
        findsOneWidget,
      );
      expect(fakeProtectedShield, findsNothing); // still never "protected"
    });
  });
}
