import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tab/pages/crisis_support_page.dart';

void main() {
  testWidgets('care dialog opens the crisis support page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showCrisisSupportDialog(context),
                child: const Text('显示关怀'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示关怀'));
    await tester.pumpAndSettle();
    expect(find.text('查看热线'), findsOneWidget);

    await tester.tap(find.text('查看热线'));
    await tester.pumpAndSettle();

    expect(find.text('危机支持'), findsOneWidget);
    expect(find.text('心理援助热线'), findsOneWidget);
  });
}
