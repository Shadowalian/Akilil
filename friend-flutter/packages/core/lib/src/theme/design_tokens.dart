/// Akilil design tokens — v4 "Warm & bright": cream canvas, orange for
/// energy, aqua for calm, yellow for optimism, lavender for reflection,
/// green for growth.
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

  // ── Canvas: warm cream ───────────────────────────────────────────────────
  static const background = Color(0xFFFFF8EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const recessed = Color(0xFFFFF0DC);
  static const surfaceContainer = Color(0xFFFFF3E3);
  static const surfaceContainerHigh = Color(0xFFFDEAD2);
  static const surfaceVariant = Color(0xFFF7DFC2);

  // ── Ink ──────────────────────────────────────────────────────────────────
  static const ink = Color(0xFF1F2A37);
  static const textPrimary = Color(0xFF1F2A37);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF6B7280);

  // ── Lines ────────────────────────────────────────────────────────────────
  static const border = Color(0xFFF3E3CC);
  static const borderStrong = Color(0xFFE8D2B4);
  static const divider = Color(0xFFF7EBDA);

  // ── Orange: energy and encouragement, the action colour ──────────────────
  /// Deep enough for white text (4.6:1).
  static const primary = Color(0xFFCC4A0A);
  static const primaryDeep = Color(0xFFA83C08);
  /// Vivid orange for icons, highlights and the top of button gradients.
  static const orange = Color(0xFFF97316);
  static const primaryLight = Color(0xFFFFEDD5);
  static const primaryContainer = orange;
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF6B2304);

  /// Fill for selected chips, days, times and segments.
  static const selected = primary;

  // ── Aqua: calm and trust ─────────────────────────────────────────────────
  static const aqua = Color(0xFF0EA5B7);
  static const aquaDeep = Color(0xFF0E7C8C);
  static const aquaLight = Color(0xFFD9F6F9);

  // ── Sunny yellow: optimism ───────────────────────────────────────────────
  static const accent = Color(0xFFFBBF24);
  static const accentDeep = Color(0xFF92400E);
  static const accentLight = Color(0xFFFEF3C7);
  static const onAccent = Color(0xFF1F2A37);
  static const yellow = accent;

  // ── Lavender: reflection and faith ───────────────────────────────────────
  static const lavender = Color(0xFF7C5CD6);
  static const lavenderLight = Color(0xFFEDE7FC);

  // ── Green: growth and progress ───────────────────────────────────────────
  static const green = Color(0xFF16A34A);
  static const greenDeep = Color(0xFF15803D);
  static const greenSoft = Color(0xFFDCFCE7);

  // ── Rose: live and urgent ────────────────────────────────────────────────
  static const live = Color(0xFFE11D48);
  static const roseLight = Color(0xFFFFE4E6);

  // ── Status ───────────────────────────────────────────────────────────────
  static const success = greenDeep;
  static const successLight = greenSoft;
  static const warning = accentDeep;
  static const warningLight = accentLight;
  static const error = Color(0xFFDC2626);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onErrorContainer = Color(0xFF7F1D1D);
  static const info = aquaDeep;

  // ── Pillars ──────────────────────────────────────────────────────────────
  static const pillarMind = aqua;
  static const pillarMindLight = aquaLight;
  static const pillarSpiritual = lavender;
  static const pillarSpiritualLight = lavenderLight;
  static const pillarCooking = Color(0xFFF59E0B);
  static const pillarCookingLight = accentLight;

  /// The cheerful set used to colour tiles, avatars and charts in turn.
  static const vivid = [orange, aqua, lavender, green, Color(0xFFF59E0B), Color(0xFFEC4899)];

  // ── v1/v2 aliases ────────────────────────────────────────────────────────
  static const secondaryFixed = aqua;
  static const secondaryFixedDim = aquaDeep;
  static const wood = lavender;
  static const woodLight = lavenderLight;
  static const woodDeep = Color(0xFF5B3FB8);
  static const aquaSoft = aquaLight;
  static const sky = aqua;
  static const cream = background;
  static const peach = recessed;
  static const apricot = primaryLight;
  static const sunset = orange;
  static const coral = live;
  static const spark = orange;
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
    BoxShadow(color: Color(0x33F97316), blurRadius: 0, spreadRadius: 3),
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
/// Gradients for the few hero surfaces and the primary button.
class FriendGradients {
  FriendGradients._();

  /// Primary buttons: vivid orange into deep orange.
  static const action = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF26A1B), Color(0xFFCC4A0A)],
  );

  /// Calm hero (next session, focus cards): aqua into deep teal.
  static const calm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8CC), Color(0xFF0E7C8C)],
  );

  /// Warm hero (welcome, earnings): orange into rose.
  static const sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFE5486B)],
  );

  /// Reflective hero (faith, journal): lavender into indigo.
  static const dusk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B6CE0), Color(0xFF5B3FB8)],
  );

  // v1 names.
  static const spectrum = action;
  static const spectrumHot = action;
  static const spectrumHotPressed = LinearGradient(colors: [Color(0xFFCC4A0A), Color(0xFFA83C08)]);
  static const hero = calm;
  static const accentRing = action;
  static const ink = action;
  static const woodWash = LinearGradient(colors: [FriendColors.recessed, FriendColors.recessed]);

  static LinearGradient cardTint(Color color) {
    final c = Color.alphaBlend(color.withValues(alpha: 0.10), FriendColors.surface);
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
