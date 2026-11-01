import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/application/task_actions.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/repositories/task_repository.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;
  late TaskActions actions;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = TaskRepository(database);
    actions = TaskActions(repository);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'all subtasks completed individually do not complete the parent',
    () async {
      final task = LifeTask(
        id: 'single-with-steps',
        title: 'Gioco',
        scheduledDate: DateTime(2026, 10, 31),
        startTimeMinutes: 18 * 60,
        durationMinutes: 180,
        subtasks: const [
          TaskSubtask(id: 'a', title: 'A', sortOrder: 0),
          TaskSubtask(id: 'b', title: 'B', sortOrder: 1),
        ],
      );
      await repository.addTask(task);

      for (final step in task.subtasks) {
        await actions.setSubtaskCompleted(
          task: task,
          subtask: step,
          completed: true,
        );
      }

      final stored = (await repository.watchAllTasks().first).single;
      expect(stored.subtasks.every((step) => step.isCompleted), isTrue);
      expect(stored.isCompleted, isFalse);

      await actions.setCompleted(task: task, completed: true);
      final completedParent = (await repository.watchAllTasks().first).single;
      expect(completedParent.isCompleted, isTrue);

      await actions.setSubtaskCompleted(
        task: task,
        subtask: task.subtasks.first,
        completed: false,
      );
      final reopened = (await repository.watchAllTasks().first).single;
      expect(reopened.isCompleted, isFalse);
      expect(reopened.subtasks.first.isCompleted, isFalse);
      expect(reopened.subtasks.last.isCompleted, isTrue);
    },
  );

  test(
    'recurring subtask status follows seriesDate after moving an occurrence',
    () async {
      final date = DateTime(2026, 10, 31);
      final movedDate = DateTime(2026, 11, 2);
      final task = LifeTask(
        id: 'daily-with-moved-step',
        title: 'Gioco',
        scheduledDate: DateTime(2026, 10, 30),
        startTimeMinutes: 10 * 60,
        durationMinutes: 180,
        recurrence: const TaskRecurrence.daily(),
        subtasks: const [TaskSubtask(id: 'step-a', title: 'A', sortOrder: 0)],
      );
      await repository.addTask(task);

      final original =
          (await repository.watchOccurrencesInRange(date, date).first).single;

      final edited = original.displayTask.copyWith(scheduledDate: movedDate);
      await repository.saveOccurrenceOverride(
        occurrence: original,
        editedTask: edited,
      );

      final onDestination = await repository
          .watchOccurrencesInRange(movedDate, movedDate)
          .first;
      final moved = onDestination.singleWhere(
        (occurrence) => occurrence.seriesDate == date,
      );
      expect(moved.date, movedDate);
      expect(moved.seriesDate, date);
      expect(moved.isCompleted, isFalse);

      await actions.setSubtaskCompleted(
        task: task,
        occurrence: moved,
        subtask: moved.subtasks.single,
        completed: true,
      );

      final after = await repository
          .watchOccurrencesInRange(movedDate, movedDate)
          .first;
      final updated = after.singleWhere(
        (occurrence) => occurrence.seriesDate == date,
      );
      final regularNovember2 = after.singleWhere(
        (occurrence) => occurrence.seriesDate == movedDate,
      );

      expect(updated.subtasks.single.isCompleted, isTrue);
      expect(updated.isCompleted, isFalse);
      expect(regularNovember2.subtasks.single.isCompleted, isFalse);
      expect(regularNovember2.isCompleted, isFalse);

      final originalDay = await repository
          .watchOccurrencesInRange(date, date)
          .first;
      expect(originalDay, isEmpty);
    },
  );

  test(
    'cross-midnight occurrence keeps one identity across both windows',
    () async {
      final task = LifeTask(
        id: 'midnight-game',
        title: 'Late game',
        scheduledDate: DateTime(2026, 10, 31),
        startTimeMinutes: 23 * 60 + 30,
        durationMinutes: 90,
        subtasks: const [
          TaskSubtask(id: 'late-step', title: 'Checkpoint', sortOrder: 0),
        ],
      );
      await repository.addTask(task);

      Future<TaskOccurrence> overlapping(DateTime start, DateTime end) async {
        final result = await repository
            .watchOccurrencesOverlappingWindow(start, end)
            .first;
        return result.single;
      }

      final firstWindow = await overlapping(
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
      );
      final secondWindow = await overlapping(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
      );
      expect(firstWindow.occurrenceKey, secondWindow.occurrenceKey);
      expect(firstWindow.date, DateTime(2026, 10, 31));
      expect(secondWindow.seriesDate, DateTime(2026, 10, 31));

      await actions.setSubtaskCompleted(
        task: task,
        occurrence: secondWindow,
        subtask: secondWindow.subtasks.single,
        completed: true,
      );
      final updated = await overlapping(
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
      );
      expect(updated.subtasks.single.isCompleted, isTrue);
      expect(updated.isCompleted, isFalse);
    },
  );
}
