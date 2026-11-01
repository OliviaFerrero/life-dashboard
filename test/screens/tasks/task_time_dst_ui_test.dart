import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/id/id_generator.dart';
import 'package:life_hub/core/time/app_clock.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_category.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/repositories/category_repository.dart';
import 'package:life_hub/repositories/task_repository.dart';
import 'package:life_hub/screens/tasks/task_detail_page.dart';
import 'package:life_hub/screens/tasks/task_editor_mode.dart';
import 'package:life_hub/screens/tasks/task_form_page.dart';
import 'package:life_hub/screens/tasks/tasks_page.dart';

class _FixedTasksRepository extends TaskRepository {
  final List<TaskOccurrence> occurrences;
  _FixedTasksRepository(super.database, this.occurrences);

  @override
  Stream<List<LifeTask>> watchAllTasks() =>
      Stream.value(occurrences.map((occurrence) => occurrence.task).toList());

  @override
  Stream<List<TaskOccurrence>> watchScheduleOverview(DateTime referenceTime) =>
      Stream.value(occurrences);
}

class _EmptyCategoryRepository extends CategoryRepository {
  _EmptyCategoryRepository(super.database);

  @override
  Stream<Map<String, TaskCategory>> watchCategoryMap() =>
      Stream.value(const <String, TaskCategory>{});
}

bool get _italianSpringTransition =>
    DateTime(2026, 3, 29, 1, 30).timeZoneOffset == const Duration(hours: 1) &&
    DateTime(2026, 3, 29, 3, 30).timeZoneOffset == const Duration(hours: 2);

void main() {
  testWidgets(
    'Attività keeps a future recurring occurrence among current tasks',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final clock = AppClock(
        nowProvider: () => DateTime(2026, 11, 1, 10),
        autoStart: false,
      );
      addTearDown(clock.dispose);
      addTearDown(db.close);

      final series = LifeTask(
        id: 'recurring-future',
        title: 'Evento ricorrente futuro',
        scheduledDate: DateTime(2026, 10, 1),
        startTimeMinutes: 15 * 60,
        durationMinutes: 60,
        recurrence: const TaskRecurrence.daily(),
      );
      final occurrence = TaskOccurrence(
        task: series,
        date: DateTime(2026, 11, 2),
        seriesDate: DateTime(2026, 11, 2),
        isCompleted: false,
      );

      await tester.pumpWidget(
        AppClockScope(
          clock: clock,
          child: MaterialApp(
            home: TasksPage(
              taskRepository: _FixedTasksRepository(db, [occurrence]),
              categoryRepository: _EmptyCategoryRepository(db),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evento ricorrente futuro'), findsOneWidget);
      expect(find.text('Passate'), findsNothing);
    },
  );

  testWidgets('Attività shows the elapsed-time end after spring DST', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final clock = AppClock(
      nowProvider: () => DateTime(2026, 3, 29, 3, 45),
      autoStart: false,
    );
    addTearDown(clock.dispose);
    addTearDown(db.close);

    final task = LifeTask(
      id: 'dst-tasks',
      title: 'Attività nel cambio ora',
      scheduledDate: DateTime(2026, 3, 29),
      startTimeMinutes: 90,
      durationMinutes: 120,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 3, 29),
      isCompleted: false,
    );

    await tester.pumpWidget(
      AppClockScope(
        clock: clock,
        child: MaterialApp(
          home: TasksPage(
            taskRepository: _FixedTasksRepository(db, [occurrence]),
            categoryRepository: _EmptyCategoryRepository(db),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('fino alle 04:30'), findsOneWidget);
    expect(find.text('Passate'), findsNothing);
  }, skip: !_italianSpringTransition);

  testWidgets('Dettaglio does not mark an overnight task as overdue early', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final clock = AppClock(
      nowProvider: () => DateTime(2026, 3, 29, 3, 45),
      autoStart: false,
    );
    addTearDown(clock.dispose);
    addTearDown(db.close);

    final task = LifeTask(
      id: 'overnight-detail',
      title: 'Task oltre mezzanotte',
      scheduledDate: DateTime(2026, 3, 28),
      startTimeMinutes: 23 * 60 + 30,
      durationMinutes: 240,
    );

    await tester.pumpWidget(
      AppClockScope(
        clock: clock,
        child: MaterialApp(
          home: TaskDetailPage(
            task: task,
            taskRepository: TaskRepository(db),
            categoryRepository: _EmptyCategoryRepository(db),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Da riprogrammare'), findsNothing);
    expect(find.text('04:30 (+1 giorno)'), findsOneWidget);
  }, skip: !_italianSpringTransition);

  testWidgets('Form displays a wall-clock end based on elapsed duration', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final task = LifeTask(
      id: 'dst-form',
      title: 'Modifica attività DST',
      scheduledDate: DateTime(2026, 3, 29),
      startTimeMinutes: 90,
      durationMinutes: 120,
    );
    final clock = AppClock(
      nowProvider: () => DateTime(2026, 3, 28, 12),
      autoStart: false,
    );
    addTearDown(clock.dispose);

    await tester.pumpWidget(
      IdGeneratorScope(
        generator: IdGenerator(),
        child: AppClockScope(
          clock: clock,
          child: MaterialApp(
            home: TaskFormPage(
              categoryRepository: _EmptyCategoryRepository(db),
              mode: TaskEditorMode.edit,
              initialTask: task,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('04:30'), findsWidgets);
  }, skip: !_italianSpringTransition);
}
