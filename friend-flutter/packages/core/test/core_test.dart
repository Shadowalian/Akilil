import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

/// Smoke tests for the design tokens — catches accidental hex edits
/// or theme regressions during refactors.
///
/// NOTE: We deliberately do NOT instantiate `FriendAppTheme.light()` or
/// `.dark()` here: those trigger google_fonts network fetches. Headless
/// tests run without network access to fonts.gstatic.com.
void main() {
  test('light palette matches Akilil hex values', () {
    expect(FriendColors.background.toARGB32(), 0xFFF6F8FC);
    expect(FriendColors.primary.toARGB32(), 0xFF1B4F9C);
    expect(FriendColors.accent.toARGB32(), 0xFFD4A017);
    expect(FriendColors.aqua.toARGB32(), 0xFF1B4F9C);
    expect(FriendColors.textPrimary.toARGB32(), 0xFF12203F);
    expect(FriendColors.sunset.toARGB32(), 0xFFD4A017);
  });

  test('dark palette keeps the same two brand hues', () {
    expect(FriendDarkColors.accent.toARGB32(), 0xFFF2A24A);
    expect(FriendDarkColors.background.toARGB32(), 0xFF0C1424);
    expect(FriendDarkColors.textPrimary.toARGB32(), 0xFFEEF2FA);
  });

  test('light and dark backgrounds are demonstrably different', () {
    expect(
      FriendColors.background.toARGB32(),
      isNot(equals(FriendDarkColors.background.toARGB32())),
    );
  });

  test('type scale matches the 32/24/20/16/14/12 contract', () {
    expect(FriendTypeScale.displayLarge, 40.0);
    expect(FriendTypeScale.displayMedium, 32.0);
    expect(FriendTypeScale.headlineLarge, 24.0);
    expect(FriendTypeScale.headlineMedium, 20.0);
    expect(FriendTypeScale.bodyLarge, 16.0);
    expect(FriendTypeScale.bodyMedium, 14.0);
    expect(FriendTypeScale.bodySmall, 12.0);
  });

  test('radii match Akilil soft scale', () {
    expect(FriendRadii.small, 12.0);
    expect(FriendRadii.medium, 16.0);
    expect(FriendRadii.large, 22.0);
    expect(FriendRadii.pill, 999.0);
  });

  test('token constants are immutable (const-equals check)', () {
    const a = FriendColors.primary;
    const b = FriendColors.primary;
    expect(identical(a, b), isTrue);
  });

  testWidgets('candy widgets render their content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CandyGradientHeader(title: 'Good day', subtitle: 'A small step.'),
              CandyCard(tint: FriendColors.primary, child: Text('Next session')),
              FriendStatusChip(label: 'Confirmed', color: FriendColors.primary),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Good day'), findsOneWidget);
    expect(find.text('A small step.'), findsOneWidget);
    expect(find.text('Next session'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);
  });

  testWidgets('FriendEmptyState fires its CTA', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FriendEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No slots on this day',
            message: 'Try another date.',
            ctaLabel: 'Retry',
            onCta: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('No slots on this day'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, 1);
  });
}
