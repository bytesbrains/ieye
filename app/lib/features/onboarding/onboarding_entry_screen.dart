import 'package:flutter/material.dart';

import '../../theme/ieye_theme.dart';

/// The first screen (PRD §3A): two entry flows, because the buyer ≠ the watched.
/// The configurer is usually the adult child; the watched is usually the parent
/// who may never open the app.
class OnboardingEntryScreen extends StatelessWidget {
  const OnboardingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const _BeaconMark(),
                              const SizedBox(width: 14),
                              Text(
                                'iEye',
                                style: text.displaySmall?.copyWith(fontSize: 40),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Someone is keeping watch.\nYou will not go unseen.',
                            style: text.bodyLarge?.copyWith(
                              color: IEyeColors.charcoalSoft,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _RoleCard(
                            title: 'Set up iEye for myself',
                            body:
                                'You just live. iEye reads signs of life and tells the people '
                                'you chose if you ever go quiet.',
                            onTap:
                                () => Navigator.of(context).pushNamed('/home'),
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            title: 'Set up iEye for someone I care about',
                            body:
                                'For a parent or someone who may never open the app. You set up '
                                'the circle and the details; they just live.',
                            onTap:
                                () => Navigator.of(context).pushNamed('/home'),
                          ),
                          const Spacer(),
                          Text(
                            'iEye is not a medical or emergency service. It helps the people you '
                            'chose reach you fast — in an emergency, always call your local '
                            'emergency number.',
                            style: text.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: IEyeColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ),
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: text.titleLarge?.copyWith(fontSize: 20),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: IEyeColors.charcoalSoft,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(body, style: text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
