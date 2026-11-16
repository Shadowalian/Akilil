/// Akilil — design tokens from App Screens mockups (C01–C12).
/// Warm cream canvas, teal primary, amber accent, Geist-aligned type scale.
library;

import 'package:flutter/material.dart';

class FriendColors {
  FriendColors._();

  // Canvas — warm cream from mockups
  static const background = Color(0xFFF3EFE9);
  static const surface = Color(0xFFFAF8F5);
  static const recessed = Color(0xFFEEEAE4);
  static const surfaceContainer = Color(0xFFEEEAE4);
  static const surfaceContainerHigh = Color(0xFFECE8E2);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE0DAD2);

  // Primary teal
  static const primary = Color(0xFF0A6F7B);
  static const primaryDeep = Color(0xFF085A64);
  static const primaryLight = Color(0xFFE2F5F7);
  static const primaryContainer = Color(0xFF14B3C4);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF042F34);

  // Accent amber
  static const accent = Color(0xFFD9924A);
  static const accentDeep = Color(0xFFC47A33);
  static const onAccent = Color(0xFFFFFFFF);
  static const secondaryFixed = Color(0xFF14B3C4);
  static const secondaryFixedDim = Color(0xFF0A6F7B);

  // Legacy aliases mapped to mockup palette
  static const wood = Color(0xFFD9924A);
  static const woodLight = Color(0xFFF5E6D4);
  static const woodDeep = Color(0xFFA35E1E);
  static const green = Color(0xFF0A6F7B);
  static const greenSoft = Color(0xFFE2F5F7);
  static const aqua = primary;
  static const aquaSoft = primaryLight;
  static const sky = Color(0xFF14B3C4);
  static const cream = background;
  static const peach = recessed;
  static const apricot = Color(0xFFF5E6D4);
  static const sunset = accent;
  static const coral = Color(0xFFE0563B);
  static const spark = Color(0xFF14B3C4);

  static const ink = Color(0xFF121416);
  static const inkSoft = primary;

  static const textPrimary = Color(0xFF121416);
  static const textSecondary = Color(0xFF6A6E75);
  static const textMuted = Color(0xFF8E9298);

  static const border = Color(0xFFDDD5CB);
  static const divider = Color(0xFFE0DAD2);

  static const error = Color(0xFFB23A22);
  static const errorContainer = Color(0xFFFDECE8);
  static const onErrorContainer = Color(0xFF5C2B2E);
  static const success = primary;
  static const info = primary;
}

class FriendDarkColors {
  FriendDarkColors._();

  static const background = Color(0xFF1A1208);
  static const surface = Color(0xFF2A2622);
  static const recessed = Color(0xFF3A342E);

  static const primary = Color(0xFF14B3C4);
  static const primaryLight = Color(0xFF0A6F7B);
  static const onPrimary = Color(0xFF042F34);

  static const accent = Color(0xFFD9924A);
  static const accentDeep = Color(0xFFC47A33);
  static const onAccent = Color(0xFF1A1208);

  static const aqua = primary;
  static const aquaSoft = Color(0xFF0A6F7B);

  static const textPrimary = Color(0xFFFAF8F5);
  static const textSecondary = Color(0xFFB8B4AE);

  static const border = Color(0xFF4A4540);
  static const divider = Color(0xFF3A342E);

  static const error = Color(0xFFE0563B);
  static const info = primary;
}

class FriendTypeScale {
  FriendTypeScale._();
  static const displayLarge = 38.0;
  static const displayMedium = 32.0;
  static const displaySmall = 28.0;
  static const headlineLarge = 28.0;
  static const headlineMedium = 22.0;
  static const headlineSmall = 18.0;
  static const bodyLarge = 16.0;
  static const bodyMedium = 14.0;
  static const bodySmall = 13.0;
  static const caption = 12.0;
  static const micro = 10.0;
}

class FriendRadii {
  FriendRadii._();
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
  static const card = 20.0;
}

class FriendElevation {
  FriendElevation._();

  static List<BoxShadow> card = [
    const BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> button = [
    const BoxShadow(
      color: Color(0x330A6F7B),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> glow = button;
  static List<BoxShadow> glowPressed = const [
    BoxShadow(
      color: Color(0x220A6F7B),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> focusRing = [
    const BoxShadow(
      color: Color(0x330A6F7B),
      blurRadius: 0,
      spreadRadius: 4,
    ),
  ];
}

class FriendLayout {
  FriendLayout._();
  static const horizontal = 20.0;
  static const dockClearance = 108.0;
  static const sectionGap = 20.0;
}

class FriendGradients {
  FriendGradients._();

  static const spectrum = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0A6F7B), Color(0xFF14B3C4)],
  );

  static const spectrumHot = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A6F7B), Color(0xFF14B3C4)],
  );

  static const spectrumHotPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF085A64), Color(0xFF0A6F7B)],
  );

  static const hero = spectrumHot;

  static const accentRing = LinearGradient(
    colors: [Color(0xFFD9924A), Color(0xFF0A6F7B)],
  );

  static const ink = spectrum;

  static const woodWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5E6D4), Color(0xFFE2F5F7)],
  );

  static LinearGradient cardTint(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.08),
          FriendColors.surfaceLowest,
        ],
      );
}

class FriendGreeting {
  FriendGreeting._();
  static String headline() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
