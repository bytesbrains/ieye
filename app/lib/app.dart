import 'package:flutter/material.dart';

import 'core/checker.dart';
import 'core/circle.dart';
import 'core/delivery_mode.dart';
import 'core/detection_brain.dart';
import 'core/homescan/lan_scanner.dart';
import 'features/homescan/platform_wifi_source.dart';
import 'core/rhythm.dart';
import 'core/trigger_sink.dart';
import 'features/arming/comprehension_gate_screen.dart';
import 'features/checker/checker_invite_screen.dart';
import 'features/circle/circle_screen.dart';
import 'features/home/home_screen.dart';
import 'features/homescan/security_scan_screen.dart';
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
  // The green-lit prototype signs nothing and sends nothing off-device, so the
  // delivery boundary is the no-op sink. The brain folds its (lack of) reach into
  // honest coverage, so the home tells the truth: it can watch, but can't yet
  // summon anyone — no fake green shield (#27).
  // Per-person rhythm (#64): "watch the pattern, not the clock." It learns this
  // person's normal quiet stretches on-device and falls back honestly to the fixed
  // window until it has — so first-run behaviour is unchanged, then it tightens.
  late final DetectionBrain _brain = Tier0Brain(
    circle: _circle,
    sink: LocalNoopSink(),
    rhythm: RhythmModel(),
  );

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
        // Comprehension gate before arming (#25): no arm without acknowledging
        // "found, not rescued". On arm → the honest-coverage home.
        '/arm':
            (context) => ComprehensionGateScreen(
              mode:
                  DeliveryMode
                      .easy, // explicit; Sovereign is a V1 coming-soon shell
              // Make home a root on arm — no back-door to onboarding / re-arm.
              onArmed:
                  () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/home', (route) => false),
            ),
        '/home': (_) => HomeScreen(brain: _brain),
        // Home Security Scan — day-one value (finds exposed cameras/IoT on the
        // user's own network). Uses the real dart:io LAN scanner; the screen's
        // own default is the StubScanner (demo data) for previews/tests.
        '/security-scan': (_) => SecurityScanScreen(
              scanner: LanScanner(wifi: const PlatformWifiSource()),
            ),
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
