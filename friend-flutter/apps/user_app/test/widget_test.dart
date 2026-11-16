// Smoke test for the user app — verifies that the design tokens and
// brand assets the app depends on are intact.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:friend_user/features/brand/brand_assets.dart';

void main() {
  testWidgets('Akilil brand mark renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: BrandAssets.mark(size: 48))),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('Design tokens expose the Akilil brand colors', () {
    expect(FriendColors.primary, const Color(0xFF1B4F9C));
    expect(FriendColors.accent, const Color(0xFFD4A017));
    expect(FriendColors.aqua, const Color(0xFF1B4F9C));
    expect(FriendColors.background, const Color(0xFFF7F6F3));
  });
}
