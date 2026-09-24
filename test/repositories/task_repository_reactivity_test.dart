import 'dart:async';

import 'package:drift/drift.dart';
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

  Future<T> nextValue<T>(
    StreamIterator<T> iterator,
  ) async {
    final hasValue =
        await iterator
            .moveNext()
            .timeout(
              const Duration(
                seconds: 2,
              ),
            );

    expect(
      hasValue,
      isTrue,
    );

    return iterator.current;
  }

  test(
    'watchAllTasks reacts when only a subtask row changes',
    () async {
      final task =
          LifeTask(
        id: 'react-subtask',
        title: 'Reactive subtask',
        scheduledDate:
            DateTime(
          2026,
          9,
          24,
        ),
        subtasks:
            const [
          TaskSubtask(
            id: 'react-subtask-a',
            title: 'A',
            sortOrder: 0,
          ),
        ],
      );

      await repository.addTask(
        task,
      );

      final iterator =
          StreamIterator(
        repository.watchAllTasks(),
      );

      try {
        final initial =
            await nextValue(
          iterator,
        );

        expect(
          initial.single
              .subtasks
              .single
              .isCompleted,
          isFalse,
        );

        await repository
            .setSubtaskCompleted(
          task: task,
          subtask:
              task.subtasks.single,
          completed: true,
        );

        final updated =
            await nextValue(
          iterator,
        );

        expect(
          updated.single
              .subtasks
              .single
              .isCompleted,
          isTrue,
        );
      } finally {
        await iterator.cancel();
      }
    },
  );

  test(
    'occurrence stream reacts to occurrence completion state changes',
    () async {
      final date =
          DateTime(
        2026,
        9,
        24,
      );

      final task =
          LifeTask(
        id: 'react-occurrence',
        title:
            'Reactive occurrence',
        scheduledDate:
            date,
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id: 'react-occurrence-sub',
            title: 'Subtask',
            sortOrder: 0,
          ),
        ],
      );

      await repository.addTask(
        task,
      );

      final iterator =
          StreamIterator<
              List<TaskOccurrence>>(
        repository
            .watchOccurrencesInRange(
          date,
          date,
        ),
      );

      try {
        final initial =
            await nextValue(
          iterator,
        );

        final occurrence =
            initial.single;

        expect(
          occurrence.isCompleted,
          isFalse,
        );

        await repository
            .setOccurrenceCompleted(
          occurrence,
          true,
        );

        final updated =
            await nextValue(
          iterator,
        );

        expect(
          updated.single
              .isCompleted,
          isTrue,
        );

        expect(
          updated.single
              .subtasks
              .every(
                (subtask) =>
                    subtask
                        .isCompleted,
              ),
          isTrue,
        );
      } finally {
        await iterator.cancel();
      }
    },
  );

  test(
    'occurrence stream reacts when an override moves one occurrence',
    () async {
      final task =
          LifeTask(
        id: 'react-override',
        title:
            'Reactive override',
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

      final iterator =
          StreamIterator<
              List<TaskOccurrence>>(
        repository
            .watchOccurrencesInRange(
          DateTime(
            2026,
            9,
            25,
          ),
          DateTime(
            2026,
            9,
            27,
          ),
        ),
      );

      try {
        final initial =
            await nextValue(
          iterator,
        );

        final target =
            initial.singleWhere(
          (occurrence) =>
              occurrence.seriesDate ==
              DateTime(
                2026,
                9,
                25,
              ),
        );

        await repository
            .saveOccurrenceOverride(
          occurrence:
              target,
          editedTask:
              LifeTask(
            id: task.id,
            title:
                'Moved',
            scheduledDate:
                DateTime(
              2026,
              9,
              27,
            ),
            startTimeMinutes:
                14 * 60,
            durationMinutes:
                90,
            recurrence:
                task.recurrence,
          ),
        );

        final updated =
            await nextValue(
          iterator,
        );

        final moved =
            updated.singleWhere(
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
          moved.hasOverride,
          isTrue,
        );

        expect(
          moved.displayTask.title,
          'Moved',
        );
      } finally {
        await iterator.cancel();
      }
    },
  );
}
