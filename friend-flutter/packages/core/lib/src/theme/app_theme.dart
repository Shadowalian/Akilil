import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';

/// Akilil theme v2 — see design_tokens.dart for the principles.
///
/// Every stock Material control is styled here so screens never need
/// one-off colours, radii or font sizes.
class FriendAppTheme {
  FriendAppTheme._();

  static const _fallbacks = ['NotoSansEthiopic'];

  static ThemeData light() {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: FriendColors.primary,
      onPrimary: FriendColors.onPrimary,
      primaryContainer: FriendColors.primaryLight,
      onPrimaryContainer: FriendColors.onPrimaryContainer,
      secondary: FriendColors.aqua,
      onSecondary: FriendColors.onPrimary,
      secondaryContainer: FriendColors.aquaLight,
      onSecondaryContainer: FriendColors.onPrimaryContainer,
      tertiary: FriendColors.accent,
      onTertiary: FriendColors.onAccent,
      error: FriendColors.error,
      onError: Colors.white,
      errorContainer: FriendColors.errorContainer,
      onErrorContainer: FriendColors.onErrorContainer,
      surface: FriendColors.surface,
      onSurface: FriendColors.textPrimary,
      onSurfaceVariant: FriendColors.textSecondary,
      surfaceContainerLowest: FriendColors.surface,
      surfaceContainerLow: FriendColors.background,
      surfaceContainer: FriendColors.surfaceContainer,
      surfaceContainerHigh: FriendColors.surfaceContainerHigh,
      surfaceContainerHighest: FriendColors.recessed,
      outline: FriendColors.borderStrong,
      outlineVariant: FriendColors.border,
      shadow: FriendColors.ink,
      scrim: Color(0x6617191C),
      inverseSurface: FriendColors.ink,
      onInverseSurface: Colors.white,
      inversePrimary: FriendColors.orange,
      surfaceTint: Colors.transparent,
    );
    return _build(cs);
  }

  static ThemeData dark() {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: FriendDarkColors.primary,
      onPrimary: FriendDarkColors.onPrimary,
      secondary: FriendDarkColors.primary,
      onSecondary: FriendDarkColors.onPrimary,
      tertiary: FriendDarkColors.accent,
      onTertiary: FriendDarkColors.onAccent,
      error: FriendDarkColors.error,
      onError: Color(0xFF601410),
      surface: FriendDarkColors.surface,
      onSurface: FriendDarkColors.textPrimary,
      surfaceContainerHighest: FriendDarkColors.recessed,
      outline: FriendDarkColors.border,
      surfaceTint: Colors.transparent,
    );
    return _build(cs);
  }

  static TextStyle _t(
    ColorScheme cs, {
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
    double letterSpacing = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Geist',
      fontFamilyFallback: _fallbacks,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? cs.onSurface,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static ThemeData _build(ColorScheme cs) {
    final light = cs.brightness == Brightness.light;
    final secondaryInk = light ? FriendColors.textSecondary : FriendDarkColors.textSecondary;
    final mutedInk = light ? FriendColors.textMuted : FriendDarkColors.textSecondary;

    final text = TextTheme(
      displayLarge: _t(cs, size: FriendTypeScale.displayLarge, weight: FontWeight.w600, height: 1.1, letterSpacing: -1.0),
      displayMedium: _t(cs, size: FriendTypeScale.displayMedium, weight: FontWeight.w600, height: 1.12, letterSpacing: -0.8),
      displaySmall: _t(cs, size: FriendTypeScale.displaySmall, weight: FontWeight.w600, height: 1.15, letterSpacing: -0.6),
      headlineLarge: _t(cs, size: FriendTypeScale.headlineLarge, weight: FontWeight.w600, height: 1.15, letterSpacing: -0.6),
      headlineMedium: _t(cs, size: FriendTypeScale.headlineMedium, weight: FontWeight.w600, height: 1.2, letterSpacing: -0.4),
      headlineSmall: _t(cs, size: FriendTypeScale.headlineSmall, weight: FontWeight.w600, height: 1.3, letterSpacing: -0.2),
      titleLarge: _t(cs, size: 19, weight: FontWeight.w600, height: 1.25, letterSpacing: -0.3),
      titleMedium: _t(cs, size: FriendTypeScale.bodyLarge, weight: FontWeight.w600, height: 1.3, letterSpacing: -0.15),
      titleSmall: _t(cs, size: FriendTypeScale.bodyMedium, weight: FontWeight.w600, height: 1.3, letterSpacing: -0.1),
      bodyLarge: _t(cs, size: FriendTypeScale.bodyLarge, height: 1.5),
      bodyMedium: _t(cs, size: FriendTypeScale.bodyMedium, height: 1.5),
      bodySmall: _t(cs, size: FriendTypeScale.bodySmall, height: 1.45, color: secondaryInk),
      labelLarge: _t(cs, size: FriendTypeScale.bodyMedium, weight: FontWeight.w600, height: 1.2),
      labelMedium: _t(cs, size: FriendTypeScale.bodySmall, weight: FontWeight.w500, height: 1.3),
      labelSmall: _t(cs, size: FriendTypeScale.caption, weight: FontWeight.w500, height: 1.3, color: mutedInk),
    );

    final controlRadius = BorderRadius.circular(FriendRadii.medium);
    const buttonSize = Size(0, 52);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22);
    final buttonText = text.labelLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1);

    final inputBorder = OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: const BorderSide(color: FriendColors.borderStrong),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: light ? FriendColors.background : FriendDarkColors.background,
      canvasColor: light ? FriendColors.background : FriendDarkColors.background,
      textTheme: text,
      primaryTextTheme: text,
      fontFamily: 'Geist',
      fontFamilyFallback: _fallbacks,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: FriendColors.divider,
      highlightColor: FriendColors.ink.withValues(alpha: 0.03),
      splashColor: FriendColors.ink.withValues(alpha: 0.05),
      hoverColor: FriendColors.ink.withValues(alpha: 0.03),

      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      }),

      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.arrow_back_rounded, size: 24),
        closeButtonIconBuilder: (_) => const Icon(Icons.close_rounded, size: 24),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: cs.onSurface,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FriendRadii.card),
          side: const BorderSide(color: FriendColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FriendColors.primary,
          foregroundColor: FriendColors.onPrimary,
          disabledBackgroundColor: FriendColors.recessed,
          disabledForegroundColor: FriendColors.textMuted,
          minimumSize: buttonSize,
          padding: buttonPadding,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: buttonText,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FriendColors.selected,
          foregroundColor: Colors.white,
          disabledBackgroundColor: FriendColors.recessed,
          disabledForegroundColor: FriendColors.textMuted,
          minimumSize: buttonSize,
          padding: buttonPadding,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FriendColors.textPrimary,
          backgroundColor: FriendColors.surface,
          minimumSize: buttonSize,
          padding: buttonPadding,
          side: const BorderSide(color: FriendColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FriendColors.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FriendRadii.small)),
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FriendColors.textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FriendColors.selected,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FriendRadii.large)),
        extendedTextStyle: buttonText,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FriendColors.surface,
        indicatorColor: FriendColors.primaryLight,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? FriendColors.textPrimary : FriendColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 22, color: selected ? FriendColors.primary : FriendColors.textMuted);
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FriendColors.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(borderSide: const BorderSide(color: FriendColors.border)),
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: FriendColors.primary, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: FriendColors.error)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: FriendColors.error, width: 1.5)),
        labelStyle: text.bodyMedium?.copyWith(color: FriendColors.textSecondary),
        floatingLabelStyle: text.bodySmall?.copyWith(color: FriendColors.primary, fontWeight: FontWeight.w500),
        hintStyle: text.bodyMedium?.copyWith(color: FriendColors.textMuted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: FriendColors.error),
        prefixIconColor: FriendColors.textMuted,
        suffixIconColor: FriendColors.textMuted,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: FriendColors.surface,
        selectedColor: FriendColors.selected,
        secondarySelectedColor: FriendColors.selected,
        disabledColor: FriendColors.recessed,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.selected) ? FriendColors.selected : FriendColors.borderStrong,
            )),
        shape: const StadiumBorder(),
        // Selected chips are ink, so their label must flip to white.
        labelStyle: text.labelMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : FriendColors.textPrimary,
          ),
        ),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: Colors.white),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? FriendColors.selected : FriendColors.surface),
        iconTheme: const IconThemeData(size: 16),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? FriendColors.selected : FriendColors.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? Colors.white : FriendColors.textPrimary),
          side: const WidgetStatePropertyAll(BorderSide(color: FriendColors.borderStrong)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: controlRadius)),
          textStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        ),
        selectedIcon: const Icon(Icons.check_rounded, size: 16),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? FriendColors.green : FriendColors.surfaceVariant),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? FriendColors.primary : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: FriendColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? FriendColors.primary : FriendColors.borderStrong),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: FriendColors.primary,
        inactiveTrackColor: FriendColors.recessed,
        thumbColor: FriendColors.primary,
        overlayColor: FriendColors.primary.withValues(alpha: 0.08),
        trackHeight: 4,
        year2023: false,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FriendColors.primary,
        linearTrackColor: FriendColors.recessed,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
        year2023: false,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: FriendColors.textPrimary,
        unselectedLabelColor: FriendColors.textMuted,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: FriendColors.selected,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: FriendColors.divider,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: FriendColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: FriendColors.accent,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FriendColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: FriendColors.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: FriendColors.surfaceVariant,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FriendRadii.sheet)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: FriendColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FriendRadii.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: FriendColors.textSecondary),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: FriendColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: FriendColors.surface,
        headerForegroundColor: FriendColors.textPrimary,
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
        todayBorder: const BorderSide(color: FriendColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FriendRadii.xl)),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: FriendColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FriendRadii.xl)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: controlRadius),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: FriendColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: FriendColors.ink.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: controlRadius,
          side: const BorderSide(color: FriendColors.border),
        ),
        textStyle: text.bodyMedium,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: FriendColors.ink, borderRadius: BorderRadius.circular(FriendRadii.small)),
        textStyle: text.labelMedium?.copyWith(color: Colors.white),
      ),

      dividerTheme: const DividerThemeData(color: FriendColors.divider, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
        iconColor: FriendColors.textSecondary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),

      badgeTheme: const BadgeThemeData(backgroundColor: FriendColors.live, textColor: Colors.white),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: FriendColors.primary,
        selectionColor: FriendColors.primary.withValues(alpha: 0.18),
        selectionHandleColor: FriendColors.primary,
      ),
    );
  }
}
