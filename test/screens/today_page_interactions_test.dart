import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/app_clock.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_category.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/repositories/category_repository.dart';
import 'package:life_hub/repositories/task_repository.dart';
import 'package:life_hub/screens/tasks/task_detail_page.dart';
import 'package:life_hub/screens/today_page.dart';
import 'package:life_hub/services/day_settings_controller.dart';
import 'package:life_hub/services/day_settings_store.dart';

class _MemoryDaySettingsStore implements DaySettingsStore {
  @override
  Future<StoredDaySettings?> load() async => null;

  @override
  Future<void> save({
    required int startMinutes,
    required int endMinutes,
  }) async {}
}

class _RecordingTaskRepository extends TaskRepository {
  _RecordingTaskRepository(super.database, this.occurrence);

  final TaskOccurrence occurrence;
  final completions = <({String subtaskId, bool completed, DateTime? date})>[];
  final parentChanges = <bool>[];

  @override
  Stream<List<LifeTask>> watchAllTasks() => Stream.value([occurrence.task]);

  @override
  Stream<List<TaskOccurrence>> watchOccurrencesOverlappingWindow(
    DateTime windowStart,
    DateTime windowEnd, {
    DateTime? untimedAnchorDate,
  }) => Stream.value([occurrence]);

  @override
  Stream<int> watchIncompleteOverviewCount(DateTime referenceTime) =>
      Stream.value(1);

  @override
  Future<void> setSubtaskCompleted({
    required LifeTask task,
    required TaskSubtask subtask,
    required bool completed,
    DateTime? occurrenceDate,
  }) async {
    completions.add((
      subtaskId: subtask.id,
      completed: completed,
      date: occurrenceDate,
    ));
  }

  @override
  Future<void> setOccurrenceCompleted(
    TaskOccurrence occurrence,
    bool completed,
  ) async {
    parentChanges.add(completed);
  }
}

class _RecordingCategoryRepository extends CategoryRepository {
  _RecordingCategoryRepository(super.database);

  @override
  Stream<Map<String, TaskCategory>> watchCategoryMap() =>
      Stream.value(const <String, TaskCategory>{});
}

void main() {
  testWidgets(
    'Oggi forwards visible subtask taps using the original series date',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(database.close);

      final clock = AppClock(
        nowProvider: () => DateTime(2026, 10, 31, 6),
        autoStart: false,
      );
      addTearDown(clock.dispose);

      final settings = DaySettingsController(store: _MemoryDaySettingsStore());
      await settings.load();
      addTearDown(settings.dispose);

      // The visible day differs from seriesDate, as with a moved occurrence.
      final seriesDate = DateTime(2026, 10, 30);
      final visibleDate = DateTime(2026, 10, 31);
      final task = LifeTask(
        id: 'daily-game',
        title: 'Gioco',
        scheduledDate: seriesDate,
        startTimeMinutes: 10 * 60 + 30,
        durationMinutes: 180,
        recurrence: const TaskRecurrence.daily(),
        subtasks: const [
          TaskSubtask(id: 'step-a', title: 'Passo A', sortOrder: 0),
          TaskSubtask(id: 'step-b', title: 'Passo B', sortOrder: 1),
          TaskSubtask(id: 'step-c', title: 'Passo C', sortOrder: 2),
        ],
      );

      final occurrence = TaskOccurrence(
        task: task,
        date: visibleDate,
        seriesDate: seriesDate,
        isCompleted: false,
        subtasks: task.subtasks,
      );
      final taskRepository = _RecordingTaskRepository(database, occurrence);
      final categoryRepository = _RecordingCategoryRepository(database);

      await tester.pumpWidget(
        AppClockScope(
          clock: clock,
          child: MaterialApp(
            home: TodayPage(
              taskRepository: taskRepository,
              categoryRepository: categoryRepository,
              daySettingsController: settings,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Gioco'), findsOneWidget);
      expect(find.text('Passo A'), findsOneWidget);

      await tester.tap(find.text('Passo A'));
      await tester.pump();
      expect(taskRepository.completions, hasLength(1));
      expect(taskRepository.completions.single.subtaskId, 'step-a');
      expect(taskRepository.completions.single.completed, isTrue);
      expect(taskRepository.completions.single.date, seriesDate);
      expect(taskRepository.parentChanges, isEmpty);
      expect(find.byType(TaskDetailPage), findsNothing);

      await tester.tap(find.text('Gioco'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TaskDetailPage), findsOneWidget);
      expect(taskRepository.completions, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
