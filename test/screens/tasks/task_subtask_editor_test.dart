import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/screens/tasks/task_form_subtask_widgets.dart';

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
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'subtask editor adds a step inline and keeps the input ready',
    (tester) async {
      String? added;

      await tester.pumpWidget(
        _app(
          TaskSubtaskEditor(
            subtasks:
                const [],
            onAdd: (title) {
              added = title;
            },
            onRename:
                (_, _) {},
            onDelete:
                (_) {},
            onReorder:
                (_, _) {},
          ),
        ),
      );

      expect(
        find.text(
          'Aggiungi piccoli passi per rendere '
          'l’attività più semplice da seguire.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byType(
          TextField,
        ),
        '  Preparare documenti  ',
      );

      await tester.testTextInput
          .receiveAction(
        TextInputAction.done,
      );

      await tester.pump();

      expect(
        added,
        'Preparare documenti',
      );

      final field =
          tester.widget<TextField>(
        find.byType(
          TextField,
        ),
      );

      expect(
        field.controller?.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'subtask title is edited inline without opening a sheet',
    (tester) async {
      String? renamedId;
      String? renamedTitle;

      await tester.pumpWidget(
        _app(
          TaskSubtaskEditor(
            subtasks:
                const [
              TaskSubtask(
                id: 's1',
                title: 'Vecchio titolo',
                sortOrder: 0,
              ),
            ],
            onAdd:
                (_) {},
            onRename:
                (id, title) {
              renamedId = id;
              renamedTitle = title;
            },
            onDelete:
                (_) {},
            onReorder:
                (_, _) {},
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Vecchio titolo',
        ),
      );

      await tester.pump();

      expect(
        find.byType(
          TextField,
        ),
        findsNWidgets(
          2,
        ),
      );

      final editField =
          find.widgetWithText(
        TextField,
        'Vecchio titolo',
      );

      expect(
        editField,
        findsOneWidget,
      );

      await tester.enterText(
        editField,
        'Nuovo titolo',
      );

      await tester.testTextInput
          .receiveAction(
        TextInputAction.done,
      );

      await tester.pump();

      expect(
        renamedId,
        's1',
      );

      expect(
        renamedTitle,
        'Nuovo titolo',
      );
    },
  );

  testWidgets(
    'subtask editor deletes the requested item',
    (tester) async {
      String? deletedId;

      await tester.pumpWidget(
        _app(
          TaskSubtaskEditor(
            subtasks:
                const [
              TaskSubtask(
                id: 's1',
                title: 'Uno',
                sortOrder: 0,
              ),
              TaskSubtask(
                id: 's2',
                title: 'Due',
                sortOrder: 1,
              ),
            ],
            onAdd:
                (_) {},
            onRename:
                (_, _) {},
            onDelete: (id) {
              deletedId = id;
            },
            onReorder:
                (_, _) {},
          ),
        ),
      );

      final deleteButtons =
          find.byTooltip(
        'Rimuovi sottoattività',
      );

      expect(
        deleteButtons,
        findsNWidgets(
          2,
        ),
      );

      await tester.tap(
        deleteButtons.first,
      );

      await tester.pump();

      expect(
        deletedId,
        's1',
      );
    },
  );

  testWidgets(
    'blank new subtask is not submitted',
    (tester) async {
      var addCount = 0;

      await tester.pumpWidget(
        _app(
          TaskSubtaskEditor(
            subtasks:
                const [],
            onAdd: (_) {
              addCount += 1;
            },
            onRename:
                (_, _) {},
            onDelete:
                (_) {},
            onReorder:
                (_, _) {},
          ),
        ),
      );

      await tester.enterText(
        find.byType(
          TextField,
        ),
        '   ',
      );

      await tester.testTextInput
          .receiveAction(
        TextInputAction.done,
      );

      await tester.pump();

      expect(
        addCount,
        0,
      );
    },
  );
}
