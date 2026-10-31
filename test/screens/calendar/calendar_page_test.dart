import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/app_clock.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/task_category.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/repositories/category_repository.dart';
import 'package:life_hub/repositories/task_repository.dart';
import 'package:life_hub/screens/calendar/calendar_page.dart';

class _FakeTaskRepository extends TaskRepository {
  _FakeTaskRepository(super.database);

  @override
  Stream<List<TaskOccurrence>> watchOccurrencesOverlappingWindow(
    DateTime windowStart,
    DateTime windowEnd, {
    DateTime? untimedAnchorDate,
  }) {
    return Stream<List<TaskOccurrence>>.value(const <TaskOccurrence>[]);
  }
}

class _FakeCategoryRepository extends CategoryRepository {
  _FakeCategoryRepository(super.database);

  @override
  Stream<Map<String, TaskCategory>> watchCategoryMap() {
    return Stream<Map<String, TaskCategory>>.value(
      const <String, TaskCategory>{},
    );
  }
}

void main() {
  Future<void> openCalendarView(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('Cambia vista calendario'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text(label));

    // Il pannello laterale completa prima la sua animazione inversa
    // (220 ms), poi CalendarPage applica il nuovo formato.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets(
    'Calendar view switches reset to today and Week navigation does not auto-highlight a weekday',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());

      final clock = AppClock(
        nowProvider: () => DateTime(2026, 10, 31, 10),
        autoStart: false,
      );

      addTearDown(clock.dispose);
      addTearDown(database.close);

      await tester.pumpWidget(
        AppClockScope(
          clock: clock,
          child: MaterialApp(
            home: CalendarPage(
              taskRepository: _FakeTaskRepository(database),
              categoryRepository: _FakeCategoryRepository(database),
            ),
          ),
        ),
      );

      // Gli stream finti consegnano il loro unico valore al frame successivo.
      await tester.pump();
      await tester.pump();

      expect(find.text('Sabato 31 ottobre 2026'), findsOneWidget);

      // Portiamo il Mese lontano da oggi.
      await tester.tap(find.byTooltip('Periodo precedente'));
      await tester.pump();

      expect(find.text('Mercoledì 30 settembre 2026'), findsOneWidget);

      // Mese -> Week deve sempre ripartire da oggi.
      await openCalendarView(tester, 'Settimana');

      expect(find.byTooltip('Nuova attività'), findsOneWidget);
      expect(find.text('Ott · Nov 2026'), findsOneWidget);
      expect(find.text('Sabato 31 ottobre 2026'), findsNothing);

      // Navigando alla settimana successiva la data di riferimento avanza
      // (utile per il tasto +), ma il sabato 7 non deve sembrare "oggi"
      // o restare selezionato automaticamente.
      await tester.tap(find.byTooltip('Settimana successiva'));
      await tester.pump();

      expect(find.text('Novembre 2026'), findsOneWidget);

      final november7Day = tester.widget<Container>(
        find.byKey(const ValueKey<String>('calendar_week_day_2026_11_7')),
      );

      final november7Decoration = november7Day.decoration as BoxDecoration;

      expect(november7Decoration.color, Colors.transparent);

      // Un tap sul vuoto della griglia seleziona l'intera colonna del giorno,
      // senza dover toccare per forza il numero nell'header.
      final emptyGrid = find.byKey(
        const ValueKey<String>('calendar_week_empty_grid'),
      );

      final gridRect = tester.getRect(emptyGrid);

      const gutterWidth = 54.0;
      final dayWidth = (gridRect.width - gutterWidth) / 7;

      // Venerdì 6 novembre = indice 4.
      await tester.tapAt(
        Offset(gridRect.left + gutterWidth + dayWidth * 4.5, 420),
      );
      await tester.pump();

      final november6Day = tester.widget<Container>(
        find.byKey(const ValueKey<String>('calendar_week_day_2026_11_6')),
      );

      final november6Decoration = november6Day.decoration as BoxDecoration;

      expect(november6Decoration.color, isNot(Colors.transparent));

      // Week -> Mese deve a sua volta ripartire da oggi, non dalla
      // settimana esplorata.
      await openCalendarView(tester, 'Mese');

      expect(find.text('Ottobre 2026'), findsOneWidget);
      expect(find.text('Sabato 31 ottobre 2026'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
