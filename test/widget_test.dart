import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Flutter test environment works',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Life Dashboard'),
          ),
        ),
      );

      expect(
        find.text('Life Dashboard'),
        findsOneWidget,
      );
    },
  );
}