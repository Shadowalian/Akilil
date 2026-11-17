// Guards for things that broke before: the brand mark, Amharic lookup,
// money formatting and readable selected chips.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:friend_user/features/brand/brand_assets.dart';
import 'package:friend_user/l10n/tr.dart';

void main() {
  testWidgets('Akilil brand mark renders', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: BrandAssets.mark(size: 48)))));
    expect(find.byType(AkililMark), findsOneWidget);
  });

  test('tr switches to Amharic and falls back to English', () {
    trAmharic = false;
    expect(tr('Welcome back'), 'Welcome back');
    trAmharic = true;
    expect(tr('Welcome back'), isNot('Welcome back'));
    expect(tr('A sentence nobody translated'), 'A sentence nobody translated');
    trAmharic = false;
  });

  test('money is written as amount then currency, with grouped thousands', () {
    expect(formatMoney(576000, 'ETB'), '5,760 ETB');
    expect(formatMoney(120050, 'ETB'), '1,200.50 ETB');
    expect(formatMoney(0), '0');
  });

  test('selected chips have a white label on the ink fill', () {
    final theme = FriendAppTheme.light().chipTheme;
    final color = theme.labelStyle!.color;
    expect(color, isA<WidgetStateColor>());
    final resolved = (color! as WidgetStateColor).resolve({WidgetState.selected});
    expect(resolved, Colors.white);
    expect(theme.color!.resolve({WidgetState.selected}), FriendColors.ink);
  });
}
