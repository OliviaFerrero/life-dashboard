import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/repositories/task_repository.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    repository =
        TaskRepository(
      database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<List<LifeTask>>
      readTasks() {
    return repository
        .watchAllTasks()
        .first
        .timeout(
          const Duration(
            seconds: 2,
          ),
        );
  }

  Future<List<TaskOccurrence>>
      readOccurrences(
    DateTime start,
    DateTime end,
  ) {
    return repository
        .watchOccurrencesInRange(
          start,
          end,
        )
        .first
        .timeout(
          const Duration(
            seconds: 2,
          ),
        );
  }

  TaskOccurrence occurrenceOn(
    List<TaskOccurrence> occurrences,
    DateTime date,
  ) {
    return occurrences.singleWhere(
      (occurrence) =>
          occurrence.date.year ==
              date.year &&
          occurrence.date.month ==
              date.month &&
          occurrence.date.day ==
              date.day,
    );
  }

  test(
    'persists an undated Inbox task with preferred time and duration',
    () async {
      final task =
          LifeTask(
        id: 'inbox-1',
        title: 'Inbox task',
        description:
            'Still has planning hints',
        scheduledDate: null,
        startTimeMinutes:
            10 * 60 + 15,
        durationMinutes: 45,
        priority:
            TaskPriority.high,
      );

      await repository.addTask(
        task,
      );

      final tasks =
          await readTasks();

      expect(
        tasks,
        hasLength(1),
      );

      final stored =
          tasks.single;

      expect(
        stored.id,
        'inbox-1',
      );
      expect(
        stored.scheduledDate,
        isNull,
      );
      expect(
        stored.startTimeMinutes,
        10 * 60 + 15,
      );
      expect(
        stored.durationMinutes,
        45,
      );
      expect(
        stored.priority,
        TaskPriority.high,
      );
      expect(
        stored.description,
        'Still has planning hints',
      );
    },
  );

  test(
    'cross-midnight task overlaps the following civil day without duplication',
    () async {
      final task =
          LifeTask(
        id: 'night-1',
        title: 'Late task',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        startTimeMinutes:
            23 * 60 + 30,
        durationMinutes: 90,
      );

      await repository.addTask(
        task,
      );

      final occurrences =
          await repository
              .watchOccurrencesOverlappingWindow(
                DateTime(
                  2026,
                  9,
                  25,
                ),
                DateTime(
                  2026,
                  9,
                  26,
                ),
              )
              .first
              .timeout(
                const Duration(
                  seconds: 2,
                ),
              );

      expect(
        occurrences,
        hasLength(1),
      );

      final occurrence =
          occurrences.single;

      expect(
        occurrence.date,
        DateTime(
          2026,
          9,
          24,
        ),
      );
      expect(
        occurrence.seriesDate,
        DateTime(
          2026,
          9,
          24,
        ),
      );
      expect(
        occurrence.timedStart,
        DateTime(
          2026,
          9,
          24,
          23,
          30,
        ),
      );
      expect(
        occurrence.timedEnd,
        DateTime(
          2026,
          9,
          25,
          1,
        ),
      );
    },
  );

  test(
    'daily recurrence generates occurrences with stable series dates',
    () async {
      final task =
          LifeTask(
        id: 'daily-1',
        title: 'Daily',
        scheduledDate:
            DateTime(
          2026,
          9,
          22,
        ),
        recurrence:
            const TaskRecurrence.daily(),
      );

      await repository.addTask(
        task,
      );

      final occurrences =
          await readOccurrences(
        DateTime(
          2026,
          9,
          23,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      );

      expect(
        occurrences.map(
          (occurrence) =>
              occurrence.date,
        ),
        [
          DateTime(
            2026,
            9,
            23,
          ),
          DateTime(
            2026,
            9,
            24,
          ),
          DateTime(
            2026,
            9,
            25,
          ),
        ],
      );

      for (final occurrence
          in occurrences) {
        expect(
          occurrence.seriesDate,
          occurrence.date,
        );

        expect(
          occurrence.occurrenceKey,
          startsWith(
            'daily-1@2026-09-',
          ),
        );
      }
    },
  );

  test(
    'weekly recurrence respects the selected weekday mask',
    () async {
      final task =
          LifeTask(
        id: 'weekly-1',
        title: 'Weekly',
        scheduledDate:
            DateTime(
          2026,
          9,
          21,
        ),
        recurrence:
            TaskRecurrence.weekly(
          const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
        ),
      );

      await repository.addTask(
        task,
      );

      final occurrences =
          await readOccurrences(
        DateTime(
          2026,
          9,
          21,
        ),
        DateTime(
          2026,
          9,
          27,
        ),
      );

      expect(
        occurrences.map(
          (occurrence) =>
              occurrence.date,
        ),
        [
          DateTime(
            2026,
            9,
            21,
          ),
          DateTime(
            2026,
            9,
            23,
          ),
          DateTime(
            2026,
            9,
            25,
          ),
        ],
      );
    },
  );

  test(
    'completing one recurring occurrence completes only its own parent and subtasks',
    () async {
      final task =
          LifeTask(
        id: 'daily-subtasks',
        title: 'Daily with subtasks',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id: 'sub-a',
            title: 'A',
            sortOrder: 0,
          ),
          TaskSubtask(
            id: 'sub-b',
            title: 'B',
            sortOrder: 1,
          ),
        ],
      );

      await repository.addTask(
        task,
      );

      final initial =
          await readOccurrences(
        DateTime(
          2026,
          9,
          24,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      );

      final first =
          occurrenceOn(
        initial,
        DateTime(
          2026,
          9,
          24,
        ),
      );

      await repository
          .setOccurrenceCompleted(
        first,
        true,
      );

      final updated =
          await readOccurrences(
        DateTime(
          2026,
          9,
          24,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      );

      final completed =
          occurrenceOn(
        updated,
        DateTime(
          2026,
          9,
          24,
        ),
      );

      final untouched =
          occurrenceOn(
        updated,
        DateTime(
          2026,
          9,
          25,
        ),
      );

      expect(
        completed.isCompleted,
        isTrue,
      );
      expect(
        completed.subtasks.every(
          (subtask) =>
              subtask.isCompleted,
        ),
        isTrue,
      );

      expect(
        untouched.isCompleted,
        isFalse,
      );
      expect(
        untouched.subtasks.every(
          (subtask) =>
              !subtask.isCompleted,
        ),
        isTrue,
      );

      final series =
          (await readTasks())
              .single;

      expect(
        series.isCompleted,
        isFalse,
      );
    },
  );

  test(
    'recurring subtask completion belongs only to the selected occurrence',
    () async {
      final task =
          LifeTask(
        id: 'daily-subtask-state',
        title: 'Daily subtask state',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id: 'sub-only',
            title: 'One subtask',
            sortOrder: 0,
          ),
        ],
      );

      await repository.addTask(
        task,
      );

      await repository
          .setSubtaskCompleted(
        task: task,
        subtask:
            task.subtasks.single,
        completed: true,
        occurrenceDate:
            DateTime(
          2026,
          9,
          24,
        ),
      );

      final occurrences =
          await readOccurrences(
        DateTime(
          2026,
          9,
          24,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      );

      final first =
          occurrenceOn(
        occurrences,
        DateTime(
          2026,
          9,
          24,
        ),
      );

      final second =
          occurrenceOn(
        occurrences,
        DateTime(
          2026,
          9,
          25,
        ),
      );

      expect(
        first.subtasks.single
            .isCompleted,
        isTrue,
      );

      expect(
        second.subtasks.single
            .isCompleted,
        isFalse,
      );

      await repository
          .setSubtaskCompleted(
        task: task,
        subtask:
            task.subtasks.single,
        completed: false,
        occurrenceDate:
            DateTime(
          2026,
          9,
          24,
        ),
      );

      final reopened =
          await readOccurrences(
        DateTime(
          2026,
          9,
          24,
        ),
        DateTime(
          2026,
          9,
          24,
        ),
      );

      expect(
        reopened.single
            .subtasks
            .single
            .isCompleted,
        isFalse,
      );
    },
  );

  test(
    'occurrence override moves display date while preserving series identity and completion',
    () async {
      final task =
          LifeTask(
        id: 'override-1',
        title: 'Original title',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        startTimeMinutes:
            9 * 60,
        durationMinutes: 60,
        recurrence:
            const TaskRecurrence.daily(),
      );

      await repository.addTask(
        task,
      );

      final original =
          (await readOccurrences(
        DateTime(
          2026,
          9,
          25,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      ))
              .single;

      final originalKey =
          original.occurrenceKey;

      await repository
          .setOccurrenceCompleted(
        original,
        true,
      );

      final edited =
          LifeTask(
        id: task.id,
        title: 'Moved occurrence',
        description:
            'Only this occurrence',
        scheduledDate:
            DateTime(
          2026,
          9,
          27,
        ),
        startTimeMinutes:
            14 * 60 + 30,
        durationMinutes: 75,
        priority:
            TaskPriority.high,
        recurrence:
            task.recurrence,
        subtasks:
            task.subtasks,
      );

      await repository
          .saveOccurrenceOverride(
        occurrence:
            original,
        editedTask:
            edited,
      );

      final onOldDate =
          await readOccurrences(
        DateTime(
          2026,
          9,
          25,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      );

      expect(
        onOldDate,
        isEmpty,
      );

      final destination =
          await readOccurrences(
        DateTime(
          2026,
          9,
          27,
        ),
        DateTime(
          2026,
          9,
          27,
        ),
      );

      final moved =
          destination.singleWhere(
        (occurrence) =>
            occurrence.seriesDate ==
            DateTime(
              2026,
              9,
              25,
            ),
      );

      expect(
        moved.date,
        DateTime(
          2026,
          9,
          27,
        ),
      );
      expect(
        moved.seriesDate,
        DateTime(
          2026,
          9,
          25,
        ),
      );
      expect(
        moved.occurrenceKey,
        originalKey,
      );
      expect(
        moved.hasOverride,
        isTrue,
      );
      expect(
        moved.isCompleted,
        isTrue,
      );
      expect(
        moved.displayTask.title,
        'Moved occurrence',
      );
      expect(
        moved.displayTask
            .startTimeMinutes,
        14 * 60 + 30,
      );
      expect(
        moved.displayTask
            .durationMinutes,
        75,
      );
      expect(
        moved.displayTask.priority,
        TaskPriority.high,
      );
    },
  );

  test(
    'deleting one recurring occurrence excludes only that date',
    () async {
      final task =
          LifeTask(
        id: 'delete-occurrence',
        title: 'Daily deletion',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        recurrence:
            const TaskRecurrence.daily(),
      );

      await repository.addTask(
        task,
      );

      final target =
          (await readOccurrences(
        DateTime(
          2026,
          9,
          25,
        ),
        DateTime(
          2026,
          9,
          25,
        ),
      ))
              .single;

      await repository
          .deleteOccurrence(
        target,
      );

      final occurrences =
          await readOccurrences(
        DateTime(
          2026,
          9,
          24,
        ),
        DateTime(
          2026,
          9,
          26,
        ),
      );

      expect(
        occurrences.map(
          (occurrence) =>
              occurrence.date,
        ),
        [
          DateTime(
            2026,
            9,
            24,
          ),
          DateTime(
            2026,
            9,
            26,
          ),
        ],
      );

      expect(
        await readTasks(),
        hasLength(1),
      );
    },
  );

  test(
    'non-recurring parent completion completes subtasks and reopening preserves them',
    () async {
      final task =
          LifeTask(
        id: 'single-completion',
        title:
            'Single task with subtasks',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        subtasks:
            const [
          TaskSubtask(
            id: 'single-a',
            title: 'A',
            sortOrder: 0,
          ),
          TaskSubtask(
            id: 'single-b',
            title: 'B',
            sortOrder: 1,
          ),
        ],
      );

      await repository.addTask(
        task,
      );

      await repository.setCompleted(
        task.id,
        true,
      );

      var stored =
          (await readTasks())
              .single;

      expect(
        stored.isCompleted,
        isTrue,
      );
      expect(
        stored.subtasks.every(
          (subtask) =>
              subtask.isCompleted,
        ),
        isTrue,
      );

      await repository.setCompleted(
        task.id,
        false,
      );

      stored =
          (await readTasks())
              .single;

      expect(
        stored.isCompleted,
        isFalse,
      );
      expect(
        stored.subtasks.every(
          (subtask) =>
              subtask.isCompleted,
        ),
        isTrue,
      );
    },
  );
  test(
    'priority uses the explicit stable storage code',
    () async {
      final task =
          LifeTask(
        id: 'priority-storage',
        title: 'Priority storage',
        priority:
            TaskPriority.high,
      );

      await repository.addTask(
        task,
      );

      final rawRow =
          await (database.select(
        database.taskItems,
      )..where(
                (row) =>
                    row.id.equals(
                  task.id,
                ),
              ))
              .getSingle();

      expect(
        rawRow.priority,
        TaskPriority.high.storageValue,
      );

      final stored =
          (await readTasks())
              .single;

      expect(
        stored.priority,
        TaskPriority.high,
      );
    },
  );


}
