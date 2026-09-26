import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/screens/tasks/task_detail_notes.dart';
import 'package:life_hub/screens/tasks/task_notes_editor.dart';

Widget _app(
  Widget child,
) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child:
            child,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'TaskNotesEditor edits the existing controller inline',
    (tester) async {
      final controller =
          TextEditingController(
        text:
            'Nota iniziale',
      );

      addTearDown(
        controller.dispose,
      );

      await tester.pumpWidget(
        _app(
          TaskNotesEditor(
            controller:
                controller,
          ),
        ),
      );

      final field =
          find.byKey(
        const Key(
          'task_notes_inline_field',
        ),
      );

      expect(
        field,
        findsOneWidget,
      );

      await tester.enterText(
        field,
        'Nota aggiornata',
      );

      expect(
        controller.text,
        'Nota aggiornata',
      );
    },
  );

  testWidgets(
    'expanded notes editor saves back into the form controller',
    (tester) async {
      final controller =
          TextEditingController(
        text:
            'Breve',
      );

      addTearDown(
        controller.dispose,
      );

      await tester.pumpWidget(
        _app(
          TaskNotesEditor(
            controller:
                controller,
          ),
        ),
      );

      await tester.tap(
        find.byTooltip(
          'Espandi note',
        ),
      );
      await tester.pumpAndSettle();

      final expandedField =
          find.byKey(
        const Key(
          'task_notes_expanded_field',
        ),
      );

      expect(
        expandedField,
        findsOneWidget,
      );

      await tester.enterText(
        expandedField,
        'Nota molto più lunga\ncon una seconda riga.',
      );

      await tester.tap(
        find.text(
          'Fine',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller.text,
        'Nota molto più lunga\ncon una seconda riga.',
      );
    },
  );

  testWidgets(
    'canceling expanded notes editor preserves the previous note',
    (tester) async {
      final controller =
          TextEditingController(
        text:
            'Da mantenere',
      );

      addTearDown(
        controller.dispose,
      );

      await tester.pumpWidget(
        _app(
          TaskNotesEditor(
            controller:
                controller,
          ),
        ),
      );

      await tester.tap(
        find.byTooltip(
          'Espandi note',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const Key(
            'task_notes_expanded_field',
          ),
        ),
        'Da scartare',
      );

      await tester.tap(
        find.text(
          'Annulla',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller.text,
        'Da mantenere',
      );
    },
  );

  testWidgets(
    'short detail note is fully visible without expand action',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const TaskDetailNotesSection(
            text:
                'Ricordarsi di portare i documenti.',
            accentColor:
                Colors.teal,
          ),
        ),
      );

      expect(
        find.text(
          'Ricordarsi di portare i documenti.',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Mostra tutto',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'long detail note can be expanded and collapsed',
    (tester) async {
      final longNote =
          List.generate(
        40,
        (index) =>
            'Dettaglio ${index + 1}',
      ).join(
        ' ',
      );

      await tester.pumpWidget(
        _app(
          TaskDetailNotesSection(
            text:
                longNote,
            accentColor:
                Colors.teal,
          ),
        ),
      );

      var noteText =
          tester.widget<Text>(
        find.byKey(
          const Key(
            'task_detail_note_text',
          ),
        ),
      );

      expect(
        noteText.maxLines,
        7,
      );

      expect(
        find.text(
          'Mostra tutto',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          'Mostra tutto',
        ),
      );
      await tester.pumpAndSettle();

      noteText =
          tester.widget<Text>(
        find.byKey(
          const Key(
            'task_detail_note_text',
          ),
        ),
      );

      expect(
        noteText.maxLines,
        isNull,
      );

      expect(
        find.text(
          'Mostra meno',
        ),
        findsOneWidget,
      );
    },
  );
}
