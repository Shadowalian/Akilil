// Pro-app smoke test. Same shape as the user-app test — design
// tokens + brand mark render correctly. Full app render is gated
// on a real /me response (Task 11 integration).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:friend_professional/features/auth/brand_stub.dart';

void main() {
  testWidgets('Pro brand mark renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: proBrandMark(size: 48))),
      ),
    );
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  test('Design tokens match the Akilil palette', () {
    expect(FriendColors.primary, const Color(0xFF1B4F9C));
    expect(FriendColors.accent, const Color(0xFFD4A017));
    expect(FriendColors.aqua, const Color(0xFF1B4F9C));
    expect(FriendColors.spark, const Color(0xFFF0A03C));
  });
}