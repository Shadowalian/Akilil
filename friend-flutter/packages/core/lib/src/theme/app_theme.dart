import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';

/// Akilil theme — cream canvas, teal primary, amber accent, Geist.
class FriendAppTheme {
  FriendAppTheme._();

  static const _geistFallbacks = ['NotoSansEthiopic', 'Geist'];

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: FriendColors.primary,
      onPrimary: FriendColors.onPrimary,
      secondary: FriendColors.accent,
      onSecondary: FriendColors.onAccent,
      tertiary: FriendColors.sky,
      onTertiary: FriendColors.onPrimary,
      error: FriendColors.error,
      onError: Colors.white,
      surface: FriendColors.surfaceLowest,
      onSurface: FriendColors.textPrimary,
      surfaceContainerHighest: FriendColors.surfaceContainerHigh,
      outline: FriendColors.border,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: FriendDarkColors.primary,
      onPrimary: FriendDarkColors.onPrimary,
      secondary: FriendDarkColors.accent,
      onSecondary: FriendDarkColors.onAccent,
      tertiary: FriendDarkColors.aqua,
      onTertiary: FriendDarkColors.onPrimary,
      error: FriendDarkColors.error,
      onError: FriendColors.background,
      surface: FriendDarkColors.surface,
      onSurface: FriendDarkColors.textPrimary,
      surfaceContainerHighest: FriendDarkColors.recessed,
      outline: FriendDarkColors.border,
    );
    return _buildTheme(colorScheme);
  }

  static TextStyle _geist(
    ColorScheme cs, {
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
    double letterSpacing = -0.2,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Geist',
      fontFamilyFallback: _geistFallbacks,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? cs.onSurface,
    );
  }

  static ThemeData _buildTheme(ColorScheme cs) {
    final textTheme = TextTheme(
      displayLarge: _geist(
        cs,
        size: FriendTypeScale.displayLarge,
        weight: FontWeight.w700,
        height: 0.98,
        letterSpacing: -1.4,
      ),
      displayMedium: _geist(
        cs,
        size: FriendTypeScale.displayMedium,
        weight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -1.0,
      ),
      displaySmall: _geist(
        cs,
        size: FriendTypeScale.displaySmall,
        weight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      headlineLarge: _geist(
        cs,
        size: FriendTypeScale.headlineLarge,
        weight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineMedium: _geist(
        cs,
        size: FriendTypeScale.headlineMedium,
        weight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineSmall: _geist(
        cs,
        size: FriendTypeScale.headlineSmall,
        weight: FontWeight.w600,
      ),
      titleLarge: _geist(
        cs,
        size: FriendTypeScale.headlineSmall,
        weight: FontWeight.w600,
      ),
      titleMedium: _geist(
        cs,
        size: FriendTypeScale.bodyLarge,
        weight: FontWeight.w600,
      ),
      titleSmall: _geist(
        cs,
        size: FriendTypeScale.bodyMedium,
        weight: FontWeight.w600,
      ),
      bodyLarge: _geist(
        cs,
        size: FriendTypeScale.bodyLarge,
        weight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: _geist(
        cs,
        size: FriendTypeScale.bodyMedium,
        weight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: _geist(
        cs,
        size: FriendTypeScale.bodySmall,
        weight: FontWeight.w400,
        color: FriendColors.textSecondary,
      ),
      labelLarge: _geist(
        cs,
        size: FriendTypeScale.bodyMedium,
        weight: FontWeight.w600,
      ),
      labelMedium: _geist(
        cs,
        size: FriendTypeScale.bodySmall,
        weight: FontWeight.w500,
      ),
      labelSmall: _geist(
        cs,
        size: FriendTypeScale.caption,
        weight: FontWeight.w500,
        color: FriendColors.textMuted,
      ),
    );

    final isLight = cs.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: cs.onSurface,
        titleTextStyle: textTheme.headlineMedium,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FriendRadii.large),
          side: const BorderSide(color: FriendColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FriendColors.primary,
          foregroundColor: FriendColors.onPrimary,
          disabledBackgroundColor: FriendColors.primary.withValues(alpha: 0.35),
          disabledForegroundColor: FriendColors.onPrimary.withValues(alpha: 0.7),
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FriendRadii.pill),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.1,
            color: FriendColors.onPrimary,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FriendColors.accent,
          foregroundColor: FriendColors.onAccent,
          disabledBackgroundColor: FriendColors.accent.withValues(alpha: 0.35),
          disabledForegroundColor: FriendColors.onAccent.withValues(alpha: 0.7),
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FriendRadii.pill),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FriendColors.primaryDeep,
          backgroundColor: FriendColors.surface,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          side: const BorderSide(color: FriendColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FriendRadii.pill),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FriendColors.primaryDeep,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FriendColors.primary,
        foregroundColor: FriendColors.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FriendRadii.large),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FriendColors.surface.withValues(alpha: 0.92),
        indicatorColor: FriendColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? FriendColors.primaryDeep : FriendColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? FriendColors.primaryDeep : FriendColors.textMuted,
          );
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FriendColors.surface.withValues(alpha: 0.92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          borderSide: const BorderSide(color: FriendColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          borderSide: const BorderSide(color: FriendColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          borderSide: const BorderSide(color: FriendColors.primary, width: 1.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: FriendColors.textSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: FriendColors.textMuted,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: FriendColors.surface,
        selectedColor: FriendColors.primaryLight,
        secondarySelectedColor: FriendColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FriendRadii.pill),
          side: const BorderSide(color: FriendColors.border),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outline.withValues(alpha: 0.8),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FriendRadii.medium),
        ),
      ),
    );
  }
}
