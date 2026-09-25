import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_subtask.dart';

void main() {
  test(
    'TaskPriority storage codes are explicit and stable',
    () {
      expect(TaskPriority.low.storageValue, 0);
      expect(TaskPriority.normal.storageValue, 1);
      expect(TaskPriority.high.storageValue, 2);

      expect(
        TaskPriority.fromStorage(0),
        TaskPriority.low,
      );
      expect(
        TaskPriority.fromStorage(1),
        TaskPriority.normal,
      );
      expect(
        TaskPriority.fromStorage(2),
        TaskPriority.high,
      );

      expect(
        TaskPriority.fromStorage(99),
        TaskPriority.normal,
      );
    },
  );

  test(
    'copyWith preserves untouched fields and does not mutate the source',
    () {
      final original =
          LifeTask(
        id: 'task-1',
        title: 'Originale',
        description: 'Descrizione',
        scheduledDate:
            DateTime(
          2026,
          9,
          25,
          18,
          30,
        ),
        startTimeMinutes:
            9 * 60,
        durationMinutes: 45,
        categoryId: 'work',
        allDay: false,
        priority:
            TaskPriority.high,
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id: 'sub-1',
            title: 'Subtask',
            sortOrder: 0,
          ),
        ],
      );

      final edited =
          original.copyWith(
        title: 'Modificata',
        isCompleted: true,
      );

      expect(original.title, 'Originale');
      expect(original.isCompleted, isFalse);
      expect(edited.title, 'Modificata');
      expect(edited.isCompleted, isTrue);
      expect(
        edited.description,
        original.description,
      );
      expect(
        edited.scheduledDate,
        original.scheduledDate,
      );
      expect(
        edited.startTimeMinutes,
        original.startTimeMinutes,
      );
      expect(
        edited.durationMinutes,
        original.durationMinutes,
      );
      expect(
        edited.categoryId,
        original.categoryId,
      );
      expect(
        edited.priority,
        original.priority,
      );
      expect(
        edited.recurrence,
        original.recurrence,
      );
      expect(
        edited.subtasks,
        original.subtasks,
      );
    },
  );

  test(
    'copyWith can explicitly clear nullable fields',
    () {
      final original =
          LifeTask(
        id: 'task-2',
        title: 'Pianificata',
        scheduledDate:
            DateTime(
          2026,
          9,
          25,
        ),
        startTimeMinutes:
            10 * 60,
        durationMinutes: 60,
        categoryId: 'personal',
      );

      final cleared =
          original.copyWith(
        clearScheduledDate: true,
        clearStartTimeMinutes: true,
        clearDurationMinutes: true,
        clearCategoryId: true,
      );

      expect(cleared.scheduledDate, isNull);
      expect(cleared.startTimeMinutes, isNull);
      expect(cleared.durationMinutes, isNull);
      expect(cleared.categoryId, isNull);

      expect(
        original.scheduledDate,
        isNotNull,
      );
      expect(
        original.startTimeMinutes,
        isNotNull,
      );
      expect(
        original.durationMinutes,
        isNotNull,
      );
      expect(
        original.categoryId,
        isNotNull,
      );
    },
  );

  test(
    'copyWith keeps subtask lists immutable',
    () {
      final edited =
          LifeTask(
        id: 'task-3',
        title: 'Task',
      ).copyWith(
        subtasks:
            const [
          TaskSubtask(
            id: 'sub-1',
            title: 'A',
            sortOrder: 0,
          ),
        ],
      );

      expect(
        () => edited.subtasks.add(
          const TaskSubtask(
            id: 'sub-2',
            title: 'B',
            sortOrder: 1,
          ),
        ),
        throwsUnsupportedError,
      );
    },
  );
}
