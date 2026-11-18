// Pro-app guards: the shared brand mark, Amharic lookup and the language
// switch.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:friend_professional/features/auth/brand_stub.dart';
import 'package:friend_professional/l10n/tr.dart';

void main() {
  testWidgets('Pro brand mark is the shared Akilil mark', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: proBrandMark(size: 48)))));
    expect(find.byType(AkililMark), findsOneWidget);
  });

  test('Pro strings switch to Amharic', () {
    trAmharic = true;
    expect(tr('Start session'), isNot('Start session'));
    expect(tr('Request payout'), isNot('Request payout'));
    trAmharic = false;
    expect(tr('Start session'), 'Start session');
  });

  testWidgets('language switch reports the tapped language', (tester) async {
    bool? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: FriendLanguageSwitch(amharic: false, onChanged: (v) => picked = v))),
    ));
    await tester.tap(find.text('አማ'));
    expect(picked, isTrue);
  });
}
