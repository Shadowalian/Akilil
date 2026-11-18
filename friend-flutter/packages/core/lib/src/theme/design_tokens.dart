/// Akilil design tokens — v3 "Calm": creamy white, aqua blue, sunny yellow.
///
/// Principles
/// - Paper, ink and one brand colour. Warm off-white canvas, white surfaces
///   separated by hairlines rather than shadows, near-black ink.
/// - Deep teal is the only action colour. Clay is reserved for "live" and
///   urgent moments so it keeps its meaning. Each pillar has a muted hue
///   used for identification, never for buttons.
/// - No gradients and no glows. Legacy gradient tokens resolve to flat fills
///   so older call sites inherit the new look without edits.
/// - 4-point spacing grid, a short type scale, and few radii.
///
/// Token names from v1 are kept as aliases so every screen keeps compiling.
library;

import 'package:flutter/material.dart';

import '../util/i18n.dart';

class FriendColors {
  FriendColors._();

  // ── Canvas & surfaces: creamy white, warm and soft ───────────────────────
  static const background = Color(0xFFFFFAF0); // cream
  static const surface = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const recessed = Color(0xFFFBF3E2); // inputs, wells, tracks
  static const surfaceContainer = Color(0xFFFCF5E7);
  static const surfaceContainerHigh = Color(0xFFF8EEDA);
  static const surfaceVariant = Color(0xFFF1E6CF);

  // ── Ink: soft blue-slate rather than black ───────────────────────────────
  static const ink = Color(0xFF1E2B30);
  static const textPrimary = Color(0xFF1E2B30);
  static const textSecondary = Color(0xFF4A5A60);
  static const textMuted = Color(0xFF5E6E74); // 5:1 on cream

  // ── Lines: warm, barely there ────────────────────────────────────────────
  static const border = Color(0xFFEFE5D2);
  static const borderStrong = Color(0xFFE2D5BC);
  static const divider = Color(0xFFF4ECDC);

  // ── Aqua blue: the action colour ─────────────────────────────────────────
  /// Deep enough for white text on buttons (5:1).
  static const primary = Color(0xFF087A89);
  static const primaryDeep = Color(0xFF066672);
  /// Bright aqua for icons, selections, progress and the logo.
  static const aqua = Color(0xFF1FA5B8);
  static const primaryLight = Color(0xFFDFF4F6); // soft aqua fills
  static const primaryContainer = Color(0xFF1FA5B8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF053E45);

  /// Fill for selected chips, days, times and segments.
  static const selected = primary;

  // ── Sunny yellow: warmth, highlights, streaks ────────────────────────────
  static const accent = Color(0xFFF6C445);
  static const accentDeep = Color(0xFF8A5A00); // readable yellow-family text
  static const accentLight = Color(0xFFFFF3CF);
  static const onAccent = Color(0xFF1E2B30); // dark text on yellow
  static const yellow = accent;

  /// Live broadcasts and urgent moments: a soft coral, not alarm red.
  static const live = Color(0xFFE5604B);

  // ── Status ───────────────────────────────────────────────────────────────
  static const success = Color(0xFF2E8B57);
  static const successLight = Color(0xFFE3F5EA);
  static const warning = Color(0xFF8A5A00);
  static const warningLight = Color(0xFFFFF3CF);
  static const error = Color(0xFFC0392B);
  static const errorContainer = Color(0xFFFDECEA);
  static const onErrorContainer = Color(0xFF6B1D14);
  static const info = primary;

  // ── Pillars (identification only) ────────────────────────────────────────
  static const pillarSpiritual = Color(0xFF7B68B5); // soft lavender
  static const pillarSpiritualLight = Color(0xFFF0EDF8);
  static const pillarMind = aqua;
  static const pillarMindLight = primaryLight;
  static const pillarCooking = Color(0xFFD9961A); // golden
  static const pillarCookingLight = Color(0xFFFFF3CF);

  // ── v1 aliases ───────────────────────────────────────────────────────────
  static const secondaryFixed = aqua;
  static const secondaryFixedDim = primary;
  static const wood = pillarSpiritual;
  static const woodLight = pillarSpiritualLight;
  static const woodDeep = Color(0xFF5A4A92);
  static const green = primary;
  static const greenSoft = primaryLight;
  static const aquaSoft = primaryLight;
  static const sky = aqua;
  static const cream = background;
  static const peach = recessed;
  static const apricot = accentLight;
  static const sunset = accent;
  static const coral = live;
  static const spark = aqua;
  static const inkSoft = primary;
}

class FriendDarkColors {
  FriendDarkColors._();

  static const background = Color(0xFF111314);
  static const surface = Color(0xFF1B1E20);
  static const recessed = Color(0xFF25292B);

  static const primary = Color(0xFF6FB7BC);
  static const primaryLight = Color(0xFF1E3A3C);
  static const onPrimary = Color(0xFF062F32);

  static const accent = Color(0xFFE08A63);
  static const accentDeep = Color(0xFFC46F48);
  static const onAccent = Color(0xFF1A0F0A);

  static const aqua = primary;
  static const aquaSoft = primaryLight;

  static const textPrimary = Color(0xFFF2F1EE);
  static const textSecondary = Color(0xFFB3B6BA);

  static const border = Color(0xFF2E3336);
  static const divider = Color(0xFF25292B);

  static const error = Color(0xFFF2B8B5);
  static const info = primary;
}

/// Type sizes. One family (Geist, with Noto Sans Ethiopic for Amharic).
class FriendTypeScale {
  FriendTypeScale._();
  static const displayLarge = 34.0;
  static const displayMedium = 30.0;
  static const displaySmall = 26.0;
  static const headlineLarge = 28.0; // page titles
  static const headlineMedium = 22.0; // section heroes
  static const headlineSmall = 17.0; // card titles
  static const bodyLarge = 16.0;
  static const bodyMedium = 15.0;
  static const bodySmall = 13.0;
  static const caption = 12.0;
  static const micro = 11.0;
}

/// 4-point spacing grid.
class FriendSpace {
  FriendSpace._();
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x14 = 56.0;
}

class FriendRadii {
  FriendRadii._();
  static const small = 8.0; // badges, small tiles
  static const medium = 12.0; // inputs, buttons, list groups
  static const large = 16.0; // cards
  static const xl = 20.0;
  static const card = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0; // chips only
}

class FriendElevation {
  FriendElevation._();

  /// Surfaces rely on hairlines; this is a barely-there lift for cards that
  /// sit on paper.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A5A4A20), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Floating chrome: the tab bar, sheets, toasts.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0F5A4A20), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x145A4A20), blurRadius: 24, offset: Offset(0, 10)),
  ];

  // v1 names. Buttons no longer glow.
  static const List<BoxShadow> button = [];
  static const List<BoxShadow> glow = [];
  static const List<BoxShadow> glowPressed = [];

  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x33087A89), blurRadius: 0, spreadRadius: 3),
  ];
}

class FriendLayout {
  FriendLayout._();
  static const horizontal = 20.0;
  static const dockClearance = 24.0; // breathing room above the docked tab bar
  static const sectionGap = 32.0;
  static const maxContentWidth = 560.0;
}

/// v1 gradient tokens, now flat. Kept so older widgets render the new
/// language without a rewrite.
class FriendGradients {
  FriendGradients._();

  static const spectrum = LinearGradient(colors: [FriendColors.primary, FriendColors.primary]);
  static const spectrumHot = spectrum;
  static const spectrumHotPressed =
      LinearGradient(colors: [FriendColors.primaryDeep, FriendColors.primaryDeep]);
  static const hero = spectrum;
  static const accentRing = LinearGradient(colors: [FriendColors.primary, FriendColors.primary]);
  static const ink = spectrum;
  static const woodWash = LinearGradient(colors: [FriendColors.recessed, FriendColors.recessed]);

  static LinearGradient cardTint(Color color) {
    final c = Color.alphaBlend(color.withValues(alpha: 0.08), FriendColors.surface);
    return LinearGradient(colors: [c, c]);
  }
}

class FriendGreeting {
  FriendGreeting._();
  static String headline() {
    final h = DateTime.now().hour;
    if (h < 12) return coreTr('Good morning');
    if (h < 17) return coreTr('Good afternoon');
    return coreTr('Good evening');
  }
}

/// The single text style factory. Everything that used Google Fonts at
/// runtime now goes through here, so both apps render one bundled family
/// offline, with Ethiopic glyphs from Noto Sans Ethiopic.
TextStyle friendFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  Color? decorationColor,
  List<FontFeature>? fontFeatures,
  TextStyle? textStyle,
}) {
  final base = TextStyle(
    fontFamily: 'Geist',
    fontFamilyFallback: const ['NotoSansEthiopic'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationColor: decorationColor,
    fontFeatures: fontFeatures,
  );
  return textStyle == null ? base : textStyle.merge(base);
}

/// Tabular figures for prices, times and counts.
const friendTabular = [FontFeature.tabularFigures()];
