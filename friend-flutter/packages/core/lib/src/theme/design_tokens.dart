/// Akilil design tokens — v2 "Calm".
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

  // ── Canvas & surfaces ────────────────────────────────────────────────────
  static const background = Color(0xFFF6F4EF); // paper
  static const surface = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const recessed = Color(0xFFEFECE6); // inputs, wells, segmented tracks
  static const surfaceContainer = Color(0xFFF1EEE8);
  static const surfaceContainerHigh = Color(0xFFEAE6DF);
  static const surfaceVariant = Color(0xFFE4DFD6);

  // ── Ink ──────────────────────────────────────────────────────────────────
  static const ink = Color(0xFF17191C);
  static const textPrimary = Color(0xFF17191C);
  static const textSecondary = Color(0xFF5D6168);
  static const textMuted = Color(0xFF73777D); // 4.5:1 on paper

  // ── Lines ────────────────────────────────────────────────────────────────
  static const border = Color(0xFFE3DED5); // hairline around surfaces
  static const borderStrong = Color(0xFFD3CCC1); // inputs, outlined buttons
  static const divider = Color(0xFFECE8E1);

  // ── Brand: deep teal (the only action colour) ────────────────────────────
  static const primary = Color(0xFF0D5C63);
  static const primaryDeep = Color(0xFF094A50);
  static const primaryLight = Color(0xFFE6EFEE); // selected fills, soft badges
  static const primaryContainer = Color(0xFF3B8C91);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF062F32);

  // ── Clay: live, urgent, and the occasional warm highlight ────────────────
  static const accent = Color(0xFFB4582F);
  static const accentDeep = Color(0xFF8F4524);
  static const accentLight = Color(0xFFF7EAE2);
  static const onAccent = Color(0xFFFFFFFF);
  static const live = Color(0xFFC63D2F);

  // ── Status ───────────────────────────────────────────────────────────────
  static const success = Color(0xFF2F7A4F);
  static const successLight = Color(0xFFE5F2EA);
  static const warning = Color(0xFF9A6410);
  static const warningLight = Color(0xFFF8EED9);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFBEAE8);
  static const onErrorContainer = Color(0xFF5F1A14);
  static const info = primary;

  // ── Pillars (identification only) ────────────────────────────────────────
  static const pillarSpiritual = Color(0xFF6A5A8C); // muted plum
  static const pillarSpiritualLight = Color(0xFFEFECF4);
  static const pillarMind = primary;
  static const pillarMindLight = primaryLight;
  static const pillarCooking = Color(0xFFB0702A); // saffron
  static const pillarCookingLight = Color(0xFFF7EEDF);

  // ── v1 aliases ───────────────────────────────────────────────────────────
  static const secondaryFixed = primaryContainer;
  static const secondaryFixedDim = primary;
  static const wood = pillarSpiritual;
  static const woodLight = pillarSpiritualLight;
  static const woodDeep = Color(0xFF4F4270);
  static const green = primary;
  static const greenSoft = primaryLight;
  static const aqua = primary;
  static const aquaSoft = primaryLight;
  static const sky = primaryContainer;
  static const cream = background;
  static const peach = recessed;
  static const apricot = pillarCookingLight;
  static const sunset = accent;
  static const coral = live;
  static const spark = primaryContainer;
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
    BoxShadow(color: Color(0x0A17191C), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Floating chrome: the tab bar, sheets, toasts.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0F17191C), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1417191C), blurRadius: 24, offset: Offset(0, 10)),
  ];

  // v1 names. Buttons no longer glow.
  static const List<BoxShadow> button = [];
  static const List<BoxShadow> glow = [];
  static const List<BoxShadow> glowPressed = [];

  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x330D5C63), blurRadius: 0, spreadRadius: 3),
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
