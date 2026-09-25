import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/task_series_scope.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/widgets/task_prompts.dart';

void main() {
  testWidgets(
    'completion prompt is shared and confirms open subtasks',
    (
      WidgetTester tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home:
              Scaffold(
            body:
                Builder(
              builder:
                  (context) {
                return TextButton(
                  onPressed:
                      () async {
                    result =
                        await TaskPrompts
                            .confirmCompletionIfNeeded(
                      context,
                      subtasks:
                          const [
                        TaskSubtask(
                          id:
                              'sub-1',
                          title:
                              'One',
                          sortOrder:
                              0,
                        ),
                      ],
                    );
                  },
                  child:
                      const Text(
                    'Open',
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Open',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Completare attività?',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Completa tutto',
        ),
        findsOneWidget,
      );
      expect(
        find.byIcon(
          Icons.check_circle_outline,
        ),
        findsOneWidget,
      );

      final iconCenter =
          tester.getCenter(
        find.byIcon(
          Icons.check_circle_outline,
        ),
      );

      final titleCenter =
          tester.getCenter(
        find.text(
          'Completare attività?',
        ),
      );

      expect(
        (iconCenter.dy -
                titleCenter.dy)
            .abs(),
        lessThan(
          12,
        ),
      );

      await tester.tap(
        find.text(
          'Completa tutto',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        result,
        isTrue,
      );
    },
  );

  testWidgets(
    'series-scope prompt returns the selected shared scope',
    (
      WidgetTester tester,
    ) async {
      TaskSeriesScope?
          selected;

      await tester.pumpWidget(
        MaterialApp(
          home:
              Scaffold(
            body:
                Builder(
              builder:
                  (context) {
                return TextButton(
                  onPressed:
                      () async {
                    selected =
                        await TaskPrompts
                            .chooseSeriesScope(
                      context,
                      action:
                          TaskSeriesPromptAction
                              .move,
                    );
                  },
                  child:
                      const Text(
                    'Open scope',
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Open scope',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'SPOSTA ATTIVITÀ',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Solo questa occorrenza',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tutta la serie',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sposta soltanto questo evento.',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          'Solo questa occorrenza',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        selected,
        TaskSeriesScope
            .occurrence,
      );
    },
  );

  testWidgets(
    'completion without open subtasks returns true without opening a dialog',
    (
      WidgetTester tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home:
              Scaffold(
            body:
                Builder(
              builder:
                  (context) {
                return TextButton(
                  onPressed:
                      () async {
                    result =
                        await TaskPrompts
                            .confirmCompletionIfNeeded(
                      context,
                      subtasks:
                          const [
                        TaskSubtask(
                          id:
                              'done',
                          title:
                              'Done',
                          sortOrder:
                              0,
                          isCompleted:
                              true,
                        ),
                      ],
                    );
                  },
                  child:
                      const Text(
                    'Complete',
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Complete',
        ),
      );

      await tester.pump();

      expect(
        result,
        isTrue,
      );
      expect(
        find.text(
          'Completare attività?',
        ),
        findsNothing,
      );
    },
  );
}
