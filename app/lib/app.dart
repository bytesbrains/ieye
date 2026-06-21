import 'package:flutter/material.dart';

import 'core/checker.dart';
import 'core/circle.dart';
import 'core/detection_brain.dart';
import 'features/checker/checker_invite_screen.dart';
import 'features/circle/circle_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_entry_screen.dart';
import 'theme/ieye_theme.dart';

/// iEye app shell. Wires the shared detection brain (Tier-0 stub for now) and the
/// product-spine routes. No trigger sink is fired anywhere yet — the prototype
/// signs nothing and sends nothing off-device.
class IEyeApp extends StatefulWidget {
  const IEyeApp({super.key});

  @override
  State<IEyeApp> createState() => _IEyeAppState();
}

class _IEyeAppState extends State<IEyeApp> {
  // One circle, shared: the brain reads coverage from it, the circle screen edits
  // it — so a resignation flows straight into owner-visible coverage (#18).
  final CircleStore _circle = CircleStore(demoCircleMembers());
  late final DetectionBrain _brain = Tier0Brain(circle: _circle);

  @override
  void dispose() {
    _brain.dispose();
    _circle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iEye',
      debugShowCheckedModeBanner: false,
      theme: buildIEyeTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const OnboardingEntryScreen(),
        '/home': (_) => HomeScreen(brain: _brain),
        // Checkers arrive here from an invite link (#17). Demo invite until real
        // invites are wired; the handshake itself is fully functional.
        '/checker-invite':
            (_) => const CheckerInviteScreen(
              invite: CheckerInvite(ownerName: 'Sandeep'),
            ),
        // A checker viewing the circle they're part of (#18). Demo viewer until
        // real identity is wired.
        '/circle': (_) => CircleScreen(store: _circle, viewerId: 'maria'),
      },
    );
  }
}
