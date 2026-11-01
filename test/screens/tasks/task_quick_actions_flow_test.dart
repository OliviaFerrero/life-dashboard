import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/id/id_generator.dart';
import 'package:life_hub/core/time/app_clock.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_series_scope.dart';
import 'package:life_hub/repositories/category_repository.dart';
import 'package:life_hub/repositories/task_repository.dart';
import 'package:life_hub/screens/tasks/task_form_page.dart';
import 'package:life_hub/screens/tasks/task_quick_actions.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;
  late CategoryRepository categories;
  late AppClock clock;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = TaskRepository(database);
    categories = CategoryRepository(database);
    clock = AppClock(
      nowProvider: () => DateTime(2026, 11, 1, 12),
      autoStart: false,
    );
  });

  tearDown(() async {
    clock.dispose();
    await database.close();
  });

  Future<void> pumpFlow(
    WidgetTester tester,
    Future<TaskActionResult?> Function(BuildContext) run,
    void Function(TaskActionResult?) onResult,
  ) async {
    await tester.pumpWidget(
      IdGeneratorScope(
        generator: IdGenerator(nowProvider: () => DateTime(2026, 11, 1)),
        child: AppClockScope(
          clock: clock,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => onResult(await run(context)),
                  child: const Text('Avvia azione'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Avvia azione'));
    await tester.pumpAndSettle();
  }

  testWidgets('single delete asks for confirmation and removes only the task', (
    tester,
  ) async {
    final task = LifeTask(id: 'single', title: 'Acquisti');
    await repository.addTask(task);
    TaskActionResult? result;

    await pumpFlow(
      tester,
      (context) => TaskQuickActions.delete(
        context: context,
        task: task,
        taskRepository: repository,
      ),
      (value) => result = value,
    );

    expect(find.text('Eliminare attività?'), findsOneWidget);
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(result?.deleted, isTrue);
    expect(result?.scope, TaskSeriesScope.series);
    expect(await repository.watchAllTasks().first, isEmpty);
  });

  testWidgets('cancel deletion preserves the task', (tester) async {
    final task = LifeTask(id: 'cancel', title: 'Da tenere');
    await repository.addTask(task);
    TaskActionResult? result;
    await pumpFlow(
      tester,
      (context) => TaskQuickActions.delete(
        context: context,
        task: task,
        taskRepository: repository,
      ),
      (value) => result = value,
    );

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect((await repository.watchAllTasks().first).single.id, 'cancel');
  });

  testWidgets('recurring delete uses seriesDate for only one occurrence', (
    tester,
  ) async {
    final task = LifeTask(
      id: 'series',
      title: 'Corsa',
      scheduledDate: DateTime(2026, 11, 1),
      recurrence: const TaskRecurrence.daily(),
    );
    await repository.addTask(task);
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 11, 4),
      seriesDate: DateTime(2026, 11, 2),
      isCompleted: false,
      subtasks: const [],
    );
    TaskActionResult? result;

    await pumpFlow(
      tester,
      (context) => TaskQuickActions.delete(
        context: context,
        task: task,
        occurrence: occurrence,
        taskRepository: repository,
      ),
      (value) => result = value,
    );

    await tester.tap(find.text('Solo questa occorrenza'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare questa occorrenza?'), findsOneWidget);
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(result?.scope, TaskSeriesScope.occurrence);
    expect(result?.deleted, isTrue);
    final remaining = await repository
        .watchOccurrencesInRange(DateTime(2026, 11, 1), DateTime(2026, 11, 3))
        .first;
    expect(remaining.map((e) => e.seriesDate.day), [1, 3]);
    expect((await repository.watchAllTasks().first).single.id, 'series');
  });

  testWidgets('recurring delete can remove the entire series', (tester) async {
    final task = LifeTask(
      id: 'whole-series',
      title: 'Camminata',
      scheduledDate: DateTime(2026, 11, 1),
      recurrence: const TaskRecurrence.daily(),
    );
    await repository.addTask(task);
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 11, 2),
      seriesDate: DateTime(2026, 11, 2),
      isCompleted: false,
      subtasks: const [],
    );
    TaskActionResult? result;
    await pumpFlow(
      tester,
      (context) => TaskQuickActions.delete(
        context: context,
        task: task,
        occurrence: occurrence,
        taskRepository: repository,
      ),
      (value) => result = value,
    );

    await tester.tap(find.text('Tutta la serie'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare serie?'), findsOneWidget);
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(result?.scope, TaskSeriesScope.series);
    expect(result?.deleted, isTrue);
    expect(await repository.watchAllTasks().first, isEmpty);
  });

  testWidgets('edit form delete result is not confirmed twice', (tester) async {
    final task = LifeTask(id: 'delete-from-form', title: 'Rimuovere');
    await repository.addTask(task);
    TaskActionResult? result;
    await pumpFlow(
      tester,
      (context) => TaskQuickActions.edit(
        context: context,
        task: task,
        taskRepository: repository,
        categoryRepository: categories,
      ),
      (value) => result = value,
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pop(const TaskFormResult.delete());
    await tester.pumpAndSettle();

    expect(result?.deleted, isTrue);
    expect(find.text('Eliminare attività?'), findsNothing);
    expect(await repository.watchAllTasks().first, isEmpty);
  });

  testWidgets('edit single persists returned form result', (tester) async {
    final task = LifeTask(id: 'edit-single', title: 'Prima');
    await repository.addTask(task);
    TaskActionResult? result;

    await pumpFlow(
      tester,
      (context) => TaskQuickActions.edit(
        context: context,
        task: task,
        taskRepository: repository,
        categoryRepository: categories,
      ),
      (value) => result = value,
    );

    expect(find.text('Modifica attività'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop(TaskFormResult.save(task.copyWith(title: 'Dopo')));
    await tester.pumpAndSettle();

    expect(result?.scope, TaskSeriesScope.series);
    expect(result?.updatedTask?.title, 'Dopo');
    expect((await repository.watchAllTasks().first).single.title, 'Dopo');
  });

  testWidgets('edit moved occurrence preserves stable series identity', (
    tester,
  ) async {
    final task = LifeTask(
      id: 'edit-series',
      title: 'Ripetizione',
      scheduledDate: DateTime(2026, 11, 1),
      recurrence: const TaskRecurrence.daily(),
    );
    await repository.addTask(task);
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 11, 5),
      seriesDate: DateTime(2026, 11, 3),
      isCompleted: false,
      subtasks: const [],
    );
    TaskActionResult? result;

    await pumpFlow(
      tester,
      (context) => TaskQuickActions.edit(
        context: context,
        task: task,
        occurrence: occurrence,
        taskRepository: repository,
        categoryRepository: categories,
      ),
      (value) => result = value,
    );

    await tester.tap(find.text('Solo questa occorrenza'));
    await tester.pumpAndSettle();
    expect(find.text('Modifica occorrenza'), findsOneWidget);

    final edited = task.copyWith(
      title: 'Solo il 3 novembre, spostato',
      scheduledDate: DateTime(2026, 11, 5),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pop(TaskFormResult.save(edited));
    await tester.pumpAndSettle();

    expect(result?.scope, TaskSeriesScope.occurrence);
    final stored = await repository
        .watchOccurrencesInRange(DateTime(2026, 11, 5), DateTime(2026, 11, 5))
        .first;
    final changed = stored.singleWhere(
      (e) => e.seriesDate == DateTime(2026, 11, 3),
    );
    expect(changed.date, DateTime(2026, 11, 5));
    expect(changed.displayTask.title, 'Solo il 3 novembre, spostato');
    expect(
      (await repository.watchAllTasks().first).single.title,
      'Ripetizione',
    );
  });
}
