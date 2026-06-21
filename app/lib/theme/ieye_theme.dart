import 'package:flutter/material.dart';

/// iEye brand palette — warm, calm, trustworthy. The guardrail is the brief:
/// iEye watches *over* you, never watches *you*. Guardian eye / lighthouse, never
/// a camera. Beacon-amber is "you are seen / help is coming"; twilight-teal is the
/// calm horizon. NEVER alarm-red, and NEVER a green "you're protected" shield
/// (over-trust guardrail — PRD §7). Mirrors the landing-site palette.
abstract final class IEyeColors {
  static const paper = Color(0xFFF4EFE1); // warm off-white / sand
  static const paperDim = Color(0xFFECE4D2);
  static const charcoal = Color(
    0xFF2B2722,
  ); // deep warm charcoal (not pure black)
  static const charcoalSoft = Color(0xFF55504A);
  static const charcoalMuted = Color(0xFF867E72);

  static const amber = Color(0xFFE6A23C); // the beacon — the one accent/action
  static const amberDeep = Color(0xFFC07E1B);

  static const teal = Color(0xFF2F6F6B); // twilight horizon / links
  static const tealDeep = Color(0xFF1F4F4C);
}

ThemeData buildIEyeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: IEyeColors.amber,
    primary: IEyeColors.amberDeep,
    secondary: IEyeColors.tealDeep,
    surface: IEyeColors.paper,
    onSurface: IEyeColors.charcoal,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: IEyeColors.paper,
    // Big type, few words, generous measure — the audience skews older (PRD §6).
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: IEyeColors.charcoal,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      headlineSmall: TextStyle(
        color: IEyeColors.charcoal,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: IEyeColors.charcoal,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: IEyeColors.charcoalSoft,
        fontSize: 18,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: IEyeColors.charcoalSoft,
        fontSize: 16,
        height: 1.5,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: IEyeColors.amberDeep,
        foregroundColor: IEyeColors.paper,
        minimumSize: const Size.fromHeight(
          56,
        ), // ≥44px tap target (PRD §7 a11y)
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
