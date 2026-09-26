import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/widgets/task_prompts.dart';

Widget _app(
  Widget child,
) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'quick task actions can return edit',
    (tester) async {
      TaskQuickAction? result;

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result =
                      await TaskPrompts
                          .chooseQuickAction(
                    context,
                  );
                },
                child:
                    const Text(
                  'Apri',
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Apri',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Modifica',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Elimina',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          'Modifica',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        result,
        TaskQuickAction.edit,
      );
    },
  );

  testWidgets(
    'quick task actions can return delete',
    (tester) async {
      TaskQuickAction? result;

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result =
                      await TaskPrompts
                          .chooseQuickAction(
                    context,
                  );
                },
                child:
                    const Text(
                  'Apri',
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Apri',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(
          'Elimina',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        result,
        TaskQuickAction.delete,
      );
    },
  );
}
