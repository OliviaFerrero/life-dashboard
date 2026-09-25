import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/application/task_actions.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_series_scope.dart';
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

    repository =
        TaskRepository(
      database,
    );

    actions =
        TaskActions(
      repository,
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

  test(
    'reopening a non-recurring subtask reopens the completed parent',
    () async {
      final task =
          LifeTask(
        id: 'single-invariant',
        title:
            'Single invariant',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        subtasks:
            const [
          TaskSubtask(
            id: 'single-sub',
            title: 'Subtask',
            sortOrder: 0,
          ),
        ],
      );

      await repository.addTask(
        task,
      );

      await actions.setCompleted(
        task:
            task,
        completed:
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
        stored.subtasks
            .single
            .isCompleted,
        isTrue,
      );

      await actions
          .setSubtaskCompleted(
        task:
            stored,
        subtask:
            stored
                .subtasks
                .single,
        completed:
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
        stored.subtasks
            .single
            .isCompleted,
        isFalse,
      );
    },
  );

  test(
    'reopening a recurring subtask reopens only that occurrence parent',
    () async {
      final task =
          LifeTask(
        id: 'recurring-invariant',
        title:
            'Recurring invariant',
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
            id: 'recurring-sub',
            title: 'Subtask',
            sortOrder: 0,
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
          initial.first;

      await actions.setCompleted(
        task:
            task,
        occurrence:
            first,
        completed:
            true,
      );

      var updated =
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

      var completedOccurrence =
          updated.firstWhere(
        (occurrence) =>
            occurrence.seriesDate ==
            DateTime(
              2026,
              9,
              24,
            ),
      );

      expect(
        completedOccurrence
            .isCompleted,
        isTrue,
      );

      await actions
          .setSubtaskCompleted(
        task:
            task,
        occurrence:
            completedOccurrence,
        subtask:
            completedOccurrence
                .subtasks
                .single,
        completed:
            false,
      );

      updated =
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

      completedOccurrence =
          updated.firstWhere(
        (occurrence) =>
            occurrence.seriesDate ==
            DateTime(
              2026,
              9,
              24,
            ),
      );

      final nextOccurrence =
          updated.firstWhere(
        (occurrence) =>
            occurrence.seriesDate ==
            DateTime(
              2026,
              9,
              25,
            ),
      );

      expect(
        completedOccurrence
            .isCompleted,
        isFalse,
      );
      expect(
        completedOccurrence
            .subtasks
            .single
            .isCompleted,
        isFalse,
      );
      expect(
        nextOccurrence
            .isCompleted,
        isFalse,
      );
    },
  );

  test(
    'delete routes occurrence and series scopes to the correct persistence action',
    () async {
      final task =
          LifeTask(
        id: 'delete-routing',
        title:
            'Delete routing',
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

      await actions.delete(
        task:
            task,
        occurrence:
            target,
        scope:
            TaskSeriesScope
                .occurrence,
      );

      final remaining =
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
        remaining.map(
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

      await actions.delete(
        task:
            task,
        scope:
            TaskSeriesScope.series,
      );

      expect(
        await readTasks(),
        isEmpty,
      );
    },
  );

  test(
    'recurring completion without an occurrence is rejected',
    () async {
      final task =
          LifeTask(
        id: 'missing-occurrence',
        title:
            'Missing occurrence',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        recurrence:
            const TaskRecurrence.daily(),
      );

      expect(
        () =>
            actions.setCompleted(
          task:
              task,
          completed:
              true,
        ),
        throwsArgumentError,
      );
    },
  );
}
