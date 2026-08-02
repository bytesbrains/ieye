import 'package:flutter/material.dart';

import '../../theme/ieye_theme.dart';
import '../../widgets/bytesbrains_badge.dart';

/// The first screen — the security-first hub. iEye is one guardian for two
/// threats: it **secures your home** (iEye Secure, the front foot — value you feel
/// today, no setup) and **watches over the people in it** (iEye Watch, the deeper
/// welfare capability). Security leads; the watch is sequenced below, never
/// dropped. The welfare path still splits by role (buyer ≠ watched, PRD §3A).
class OnboardingEntryScreen extends StatelessWidget {
  const OnboardingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BeaconMark(),
                  const SizedBox(width: 14),
                  Text('iEye', style: text.displaySmall?.copyWith(fontSize: 40)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'A guardian for your home — and everyone in it.',
                style: text.headlineSmall?.copyWith(fontSize: 24, height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                'Watches over you, never watches you.',
                style: text.bodyLarge?.copyWith(color: IEyeColors.charcoalSoft),
              ),

              const SizedBox(height: 32),
              // FRONT FOOT: iEye Secure — the home scan. Immediate value, no setup.
              const _SecureHero(),

              const SizedBox(height: 32),
              const Divider(color: Color(0x22000000), height: 1),
              const SizedBox(height: 24),

              // THE DEEPER WATCH: iEye Watch (welfare). Sequenced below, still the
              // reason iEye exists. Two roles, because the buyer ≠ the watched.
              Semantics(
                header: true,
                child: Text(
                  'Watch over someone who lives alone',
                  style: text.titleLarge?.copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The deeper watch: if someone goes silent, the people they chose '
                'are told — so no one is left unseen.',
                style: text.bodyMedium?.copyWith(color: IEyeColors.charcoalSoft),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Set up iEye for myself',
                body:
                    'You just live. iEye reads signs of life and tells the people '
                    'you chose if you ever go quiet.',
                onTap: () => Navigator.of(context).pushNamed('/arm'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Set up iEye for someone I care about',
                body:
                    'For a parent or someone who may never open the app. You set up '
                    'the circle and the details; they just live.',
                onTap: () => Navigator.of(context).pushNamed('/arm'),
              ),

              const SizedBox(height: 28),
              Text(
                'iEye is not a medical or emergency service. It helps the people you '
                'chose reach you fast — in an emergency, always call your local '
                'emergency number.',
                style: text.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: IEyeColors.charcoalSoft,
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: BytesBrainsBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hero for iEye Secure — the front-foot home-security scan. A prominent
/// amber call to action, because this is the thing a new user can do *right now*
/// with no setup. Copy is calm and honest (protect you FROM being watched); it
/// never claims to make you "safe" (over-trust guardrail).
class _SecureHero extends StatelessWidget {
  const _SecureHero();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IEyeColors.amber, width: 1.5),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wifi_find_outlined,
                  color: IEyeColors.tealDeep, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'See what a stranger could reach in your home',
                  style: text.titleLarge?.copyWith(fontSize: 20, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Scan your Wi-Fi for exposed cameras, open devices, and weak spots a '
            'stranger could reach — in two taps. Nothing leaves your phone.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/security-scan'),
            icon: const Icon(Icons.radar),
            label: const Text('Scan my home'),
          ),
          const SizedBox(height: 6),
          // Same scan, pointed at the car's Wi-Fi hotspot — a growing surface as
          // cars (esp. EVs) ship hotspots and people plug in dashcams and dongles.
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/car-scan'),
            style: TextButton.styleFrom(
              foregroundColor: IEyeColors.tealDeep,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            icon: const Icon(Icons.directions_car_outlined, size: 20),
            label: const Text('Or scan your car’s Wi-Fi'),
          ),
        ],
      ),
    );
  }
}

/// The approved iEye brand mark (the "i = lighthouse"), from brand/ieye-appicon.png.
/// Guardian light / lighthouse, never a camera or an eye staring back.
class _BeaconMark extends StatelessWidget {
  const _BeaconMark();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/ieye-appicon.png',
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        // Decorative: the "iEye" wordmark sits right beside it, so don't let a
        // screen reader announce the name twice.
        excludeFromSemantics: true,
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: IEyeColors.paperDim,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: text.titleLarge?.copyWith(fontSize: 18),
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      color: IEyeColors.charcoalSoft, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(body, style: text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
