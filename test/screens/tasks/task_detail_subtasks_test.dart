import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/screens/tasks/task_detail_subtasks.dart';

Widget _app(
  Widget child,
) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),
          child:
              child,
        ),
      ),
    ),
  );
}

List<TaskSubtask> _subtasks(
  int count, {
  int completed = 0,
}) {
  return List.generate(
    count,
    (index) =>
        TaskSubtask(
      id:
          's$index',
      title:
          'Passo ${index + 1}',
      sortOrder:
          index,
      isCompleted:
          index < completed,
    ),
  );
}

void main() {
  testWidgets(
    'shows progress and remaining count',
    (tester) async {
      await tester.pumpWidget(
        _app(
          TaskDetailSubtasksSection(
            subtasks:
                _subtasks(
              4,
              completed:
                  2,
            ),
            accentColor:
                Colors.teal,
            onToggle:
                (_) {},
          ),
        ),
      );

      expect(
        find.text(
          '2/4',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          '2 da completare',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Passo 1',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Passo 4',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'collapses long lists without changing order',
    (tester) async {
      await tester.pumpWidget(
        _app(
          TaskDetailSubtasksSection(
            subtasks:
                _subtasks(
              9,
            ),
            accentColor:
                Colors.teal,
            onToggle:
                (_) {},
          ),
        ),
      );

      expect(
        find.text(
          'Passo 1',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Passo 6',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Passo 7',
        ),
        findsNothing,
      );

      expect(
        find.text(
          'Mostra altre 3',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'expands and collapses a long list',
    (tester) async {
      await tester.pumpWidget(
        _app(
          TaskDetailSubtasksSection(
            subtasks:
                _subtasks(
              8,
            ),
            accentColor:
                Colors.teal,
            onToggle:
                (_) {},
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Mostra altre 2',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Passo 8',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Mostra meno',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          'Mostra meno',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Passo 8',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'forwards the tapped subtask to the toggle callback',
    (tester) async {
      TaskSubtask? toggled;

      final items =
          _subtasks(
        2,
      );

      await tester.pumpWidget(
        _app(
          TaskDetailSubtasksSection(
            subtasks:
                items,
            accentColor:
                Colors.teal,
            onToggle:
                (subtask) {
              toggled =
                  subtask;
            },
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Passo 2',
        ),
      );

      await tester.pump();

      expect(
        toggled?.id,
        's1',
      );
    },
  );

  testWidgets(
    'shows completed state summary when all subtasks are done',
    (tester) async {
      await tester.pumpWidget(
        _app(
          TaskDetailSubtasksSection(
            subtasks:
                _subtasks(
              3,
              completed:
                  3,
            ),
            accentColor:
                Colors.teal,
            onToggle:
                (_) {},
          ),
        ),
      );

      expect(
        find.text(
          '3/3',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Tutto completato',
        ),
        findsOneWidget,
      );
    },
  );
}
