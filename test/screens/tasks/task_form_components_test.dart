import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/screens/tasks/task_category_setting_row.dart';
import 'package:life_hub/screens/tasks/task_form_subtask_widgets.dart';
import 'package:life_hub/screens/tasks/task_priority_selector.dart';

void main() {
  testWidgets(
    'TaskCategorySettingRow is independently usable',
    (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCategorySettingRow(
              onTap: () {
                taps += 1;
              },
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Nessuna categoria',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          'Nessuna categoria',
        ),
      );
      await tester.pump();

      expect(
        taps,
        1,
      );
    },
  );

  testWidgets(
    'TaskPrioritySelector exposes priority changes',
    (tester) async {
      TaskPriority? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskPrioritySelector(
              value:
                  TaskPriority.normal,
              labelBuilder:
                  (priority) =>
                      priority.name,
              colorBuilder:
                  (_) =>
                      Colors.blue,
              onChanged:
                  (priority) {
                selected =
                    priority;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.text(
          TaskPriority.high.name,
        ),
      );
      await tester.pump();

      expect(
        selected,
        TaskPriority.high,
      );
    },
  );

  testWidgets(
    'TaskSubtaskFormRow works outside TaskFormPage library',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:
                ReorderableListView(
              onReorderItem:
                  (oldIndex, newIndex) {},
              children: [
                TaskSubtaskFormRow(
                  key:
                      const ValueKey(
                    'subtask-1',
                  ),
                  subtask:
                      const TaskSubtask(
                    id:
                        'subtask-1',
                    title:
                        'Controllo indipendente',
                    sortOrder:
                        0,
                  ),
                  index:
                      0,
                  onTap: () {
                    tapped = true;
                  },
                  onDelete:
                      () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Controllo indipendente',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          'Controllo indipendente',
        ),
      );
      await tester.pump();

      expect(
        tapped,
        isTrue,
      );
    },
  );
}
