import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tab/pages/privacy_lock_page.dart';

void main() {
  testWidgets(
      'privacy lock rejects an incorrect PIN and accepts the correct PIN',
      (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyLockPage(
          expectedPin: '1234',
          onUnlocked: () => unlocked = true,
        ),
      ),
    );

    final pinField = find.byKey(const ValueKey('privacy-pin-field'));
    await tester.enterText(pinField, '0000');
    await tester.pump();
    expect(find.text('PIN 码错误，请重试'), findsOneWidget);
    expect(unlocked, isFalse);

    await tester.enterText(pinField, '1234');
    await tester.pump();
    expect(unlocked, isTrue);
  });
}
