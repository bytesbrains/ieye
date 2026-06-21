import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/app.dart';

/// Shared E2E helpers. Keep finders + flows here so each new feature test reads
/// like prose and we don't duplicate brittle lookups as the app grows. Add a
/// finder/robot here whenever you add a screen, then write the flow in app_test.

/// Boot the real app and let it settle.
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const IEyeApp());
  await tester.pumpAndSettle();
}

// ---- onboarding ----
final forMyself = find.text('Set up iEye for myself');
final forSomeone = find.text('Set up iEye for someone I care about');
final brandLogo = find.image(const AssetImage('assets/ieye-appicon.png'));

// ---- home (honest coverage) ----
final watchingHeadline = find.text('Watching over you.');
final lastSignOfLife = find.textContaining('Last sign of life');
final peopleWatching = find.textContaining('watching');
final goingDarkButton = find.textContaining('going dark');
final resumeButton = find.textContaining('resume watching');
final pausedHeadline = find.textContaining('Paused');
// Over-trust guardrail (PRD §7): this word must NEVER appear on the home screen.
final fakeProtectedShield = find.textContaining('protected');

/// From onboarding, enter the home screen via the "for myself" role.
Future<void> goToHomeAsMyself(WidgetTester tester) async {
  await tester.tap(forMyself);
  await tester.pumpAndSettle();
}
