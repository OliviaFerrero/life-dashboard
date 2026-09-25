import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/id/id_generator.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/screens/tasks/task_editor_controller.dart';
import 'package:life_hub/screens/tasks/task_editor_mode.dart';

void main() {
  IdGenerator fixedGenerator([
    int start = 1000,
  ]) {
    return IdGenerator(
      nowProvider:
          () => DateTime
              .fromMicrosecondsSinceEpoch(
        start,
      ),
    );
  }

  test(
    'create initializes an empty draft from optional scheduling hints',
    () {
      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.create,
        idGenerator:
            fixedGenerator(),
        initialDate:
            DateTime(
          2026,
          9,
          25,
          14,
          30,
        ),
        initialStartTimeMinutes:
            9 * 60 + 15,
      );
      addTearDown(controller.dispose);
      expect(controller.selectedDate, DateTime(2026, 9, 25));
      expect(controller.startTime?.hour, 9);
      expect(controller.startTime?.minute, 15);
      expect(controller.durationMinutes, isNull);
      expect(controller.priority, TaskPriority.normal);
      expect(controller.recurrence.type, TaskRecurrenceType.none);
      expect(controller.subtasks, isEmpty);
    },
  );

  test(
    'edit loads existing task state without altering subtask completion',
    () {
      final task = LifeTask(
        id: 'task-1',
        title: 'Titolo',
        description: 'Note',
        scheduledDate: DateTime(2026, 9, 26),
        startTimeMinutes: 8 * 60,
        durationMinutes: 75,
        categoryId: 'cat-1',
        priority: TaskPriority.high,
        recurrence: const TaskRecurrence.daily(),
        subtasks: const [
          TaskSubtask(
            id: 'sub-1',
            title: 'Uno',
            sortOrder: 0,
            isCompleted: true,
          ),
        ],
        isCompleted: true,
      );
      final controller = TaskEditorController(
        mode: TaskEditorMode.edit,
        idGenerator: fixedGenerator(),
        initialTask: task,
      );
      addTearDown(controller.dispose);
      expect(controller.titleController.text, 'Titolo');
      expect(controller.descriptionController.text, 'Note');
      expect(controller.selectedCategoryId, 'cat-1');
      expect(controller.priority, TaskPriority.high);
      expect(controller.recurrence.type, TaskRecurrenceType.daily);
      expect(controller.subtasks.single.isCompleted, isTrue);
    },
  );

  test(
    'duplicate resets recurrence and subtask completion with fresh IDs',
    () {
      final task = LifeTask(
        id: 'task-1',
        title: 'Titolo',
        recurrence: const TaskRecurrence.daily(),
        subtasks: const [
          TaskSubtask(id: 'old-1', title: 'Uno', sortOrder: 0, isCompleted: true),
          TaskSubtask(id: 'old-2', title: 'Due', sortOrder: 1, isCompleted: true),
        ],
      );
      final controller = TaskEditorController(
        mode: TaskEditorMode.duplicate,
        idGenerator: fixedGenerator(),
        initialTask: task,
      );
      addTearDown(controller.dispose);
      expect(controller.recurrence.type, TaskRecurrenceType.none);
      expect(controller.subtasks.map((e) => e.id).toList(), ['subtask_1000_0', 'subtask_1000_1']);
      expect(controller.subtasks.every((e) => !e.isCompleted), isTrue);
    },
  );

  test(
    'clearing date also clears all-day and recurrence',
    () {
      final task = LifeTask(
        id: 'task-1',
        title: 'Titolo',
        scheduledDate: DateTime(2026, 9, 25),
        allDay: true,
        recurrence: const TaskRecurrence.daily(),
      );
      final controller = TaskEditorController(
        mode: TaskEditorMode.edit,
        idGenerator: fixedGenerator(),
        initialTask: task,
      );
      addTearDown(controller.dispose);
      controller.clearDate();
      expect(controller.selectedDate, isNull);
      expect(controller.allDay, isFalse);
      expect(controller.recurrence.type, TaskRecurrenceType.none);
    },
  );

  test(
    'center placement follows duration until start time is edited manually',
    () {
      final controller = TaskEditorController(
        mode: TaskEditorMode.create,
        idGenerator: fixedGenerator(),
        initialCenterTimeMinutes: 10 * 60,
      );
      addTearDown(controller.dispose);
      expect(controller.startTime, const TimeOfDay(hour: 9, minute: 45));
      controller.setDuration(60);
      expect(controller.startTime, const TimeOfDay(hour: 9, minute: 30));
      controller.setStartTime(const TimeOfDay(hour: 8, minute: 0));
      controller.setDuration(120);
      expect(controller.startTime, const TimeOfDay(hour: 8, minute: 0));
    },
  );

  test(
    'subtask commands add rename reorder and remove with normalized order',
    () {
      final controller = TaskEditorController(
        mode: TaskEditorMode.create,
        idGenerator: fixedGenerator(),
      );
      addTearDown(controller.dispose);
      controller.addSubtask('Uno');
      controller.addSubtask('Due');
      final firstId = controller.subtasks[0].id;
      final secondId = controller.subtasks[1].id;
      controller.renameSubtask(firstId, 'Uno rinominato');
      controller.reorderSubtasks(0, 1);
      expect(controller.subtasks[0].id, secondId);
      expect(controller.subtasks[0].sortOrder, 0);
      expect(controller.subtasks[1].title, 'Uno rinominato');
      expect(controller.subtasks[1].sortOrder, 1);
      controller.removeSubtask(secondId);
      expect(controller.subtasks, hasLength(1));
      expect(controller.subtasks.single.sortOrder, 0);
    },
  );

  test(
    'buildTask create creates a fresh task and normalizes undated recurrence',
    () {
      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.create,
        idGenerator:
            fixedGenerator(
          3000,
        ),
      );

      addTearDown(
        controller.dispose,
      );

      controller.titleController.text =
          '  Nuova attività  ';
      controller.descriptionController.text =
          '  Nota  ';
      controller.setRecurrence(
        const TaskRecurrence.daily(),
      );
      controller.setPriority(
        TaskPriority.high,
      );
      controller.addSubtask(
        'Uno',
      );

      final task =
          controller.buildTask(
        validatedCategoryId:
            'cat-1',
      );

      expect(
        task.id,
        '3001',
      );
      expect(
        task.title,
        'Nuova attività',
      );
      expect(
        task.description,
        'Nota',
      );
      expect(
        task.categoryId,
        'cat-1',
      );
      expect(
        task.priority,
        TaskPriority.high,
      );
      expect(
        task.recurrence.type,
        TaskRecurrenceType.none,
      );
      expect(
        task.isCompleted,
        isFalse,
      );
      expect(
        task.subtasks.single.title,
        'Uno',
      );
    },
  );

  test(
    'buildTask edit preserves identity and completion while applying draft changes',
    () {
      final source =
          LifeTask(
        id:
            'task-edit',
        title:
            'Prima',
        description:
            'Vecchia',
        scheduledDate:
            DateTime(
          2026,
          9,
          25,
        ),
        priority:
            TaskPriority.low,
        subtasks:
            const [
          TaskSubtask(
            id:
                's1',
            title:
                'Uno',
            sortOrder:
                0,
          ),
        ],
        isCompleted:
            true,
      );

      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.edit,
        idGenerator:
            fixedGenerator(
          4000,
        ),
        initialTask:
            source,
      );

      addTearDown(
        controller.dispose,
      );

      controller.titleController.text =
          'Dopo';
      controller.setPriority(
        TaskPriority.high,
      );

      final task =
          controller.buildTask(
        validatedCategoryId:
            null,
      );

      expect(
        task.id,
        'task-edit',
      );
      expect(
        task.title,
        'Dopo',
      );
      expect(
        task.priority,
        TaskPriority.high,
      );
      expect(
        task.isCompleted,
        isTrue,
      );
    },
  );

  test(
    'buildTask duplicate creates a new incomplete non-recurring copy',
    () {
      final source =
          LifeTask(
        id:
            'task-source',
        title:
            'Da duplicare',
        scheduledDate:
            DateTime(
          2026,
          9,
          25,
        ),
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id:
                'old-sub',
            title:
                'Uno',
            sortOrder:
                0,
            isCompleted:
                true,
          ),
        ],
        isCompleted:
            true,
      );

      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.duplicate,
        idGenerator:
            fixedGenerator(
          5000,
        ),
        initialTask:
            source,
      );

      addTearDown(
        controller.dispose,
      );

      final task =
          controller.buildTask(
        validatedCategoryId:
            null,
      );

      expect(
        task.id,
        '5001',
      );
      expect(
        task.id,
        isNot(
          source.id,
        ),
      );
      expect(
        task.isCompleted,
        isFalse,
      );
      expect(
        task.recurrence.type,
        TaskRecurrenceType.none,
      );
      expect(
        task.subtasks.single.id,
        'subtask_5000_0',
      );
      expect(
        task.subtasks.single.isCompleted,
        isFalse,
      );
    },
  );

  test(
    'buildTask editOccurrence preserves series recurrence and source subtasks',
    () {
      final source =
          LifeTask(
        id:
            'series-1',
        title:
            'Occorrenza',
        scheduledDate:
            DateTime(
          2026,
          9,
          25,
        ),
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id:
                'series-sub',
            title:
                'Serie',
            sortOrder:
                0,
            isCompleted:
                true,
          ),
        ],
        isCompleted:
            true,
      );

      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.editOccurrence,
        idGenerator:
            fixedGenerator(),
        initialTask:
            source,
      );

      addTearDown(
        controller.dispose,
      );

      controller.setRecurrence(
        const TaskRecurrence.none(),
      );
      controller.addSubtask(
        'Da ignorare nel salvataggio occorrenza',
      );

      final task =
          controller.buildTask(
        validatedCategoryId:
            null,
      );

      expect(
        task.id,
        'series-1',
      );
      expect(
        task.recurrence.type,
        TaskRecurrenceType.daily,
      );
      expect(
        task.subtasks,
        source.subtasks,
      );
      expect(
        task.isCompleted,
        isTrue,
      );
    },
  );

  test(
    'buildTask reschedule preserves metadata and clears recurrence when date is removed',
    () {
      final source =
          LifeTask(
        id:
            'task-reschedule',
        title:
            'Originale',
        description:
            'Descrizione',
        scheduledDate:
            DateTime(
          2026,
          9,
          20,
        ),
        categoryId:
            'cat-original',
        priority:
            TaskPriority.high,
        recurrence:
            const TaskRecurrence.daily(),
        subtasks:
            const [
          TaskSubtask(
            id:
                'sub-original',
            title:
                'Originale',
            sortOrder:
                0,
            isCompleted:
                true,
          ),
        ],
        isCompleted:
            true,
      );

      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.reschedule,
        idGenerator:
            fixedGenerator(),
        initialTask:
            source,
      );

      addTearDown(
        controller.dispose,
      );

      controller.titleController.text =
          'Non deve cambiare';
      controller.descriptionController.text =
          'Non deve cambiare';
      controller.setPriority(
        TaskPriority.low,
      );
      controller.clearDate();

      expect(
        controller.categoryIdForValidation,
        'cat-original',
      );

      final task =
          controller.buildTask(
        validatedCategoryId:
            'cat-original',
      );

      expect(
        task.id,
        'task-reschedule',
      );
      expect(
        task.title,
        'Originale',
      );
      expect(
        task.description,
        'Descrizione',
      );
      expect(
        task.priority,
        TaskPriority.high,
      );
      expect(
        task.categoryId,
        'cat-original',
      );
      expect(
        task.scheduledDate,
        isNull,
      );
      expect(
        task.recurrence.type,
        TaskRecurrenceType.none,
      );
      expect(
        task.subtasks,
        source.subtasks,
      );
      expect(
        task.isCompleted,
        isTrue,
      );
    },
  );

  test(
    'buildTask uses validated category result and all-day suppresses start time',
    () {
      final controller =
          TaskEditorController(
        mode:
            TaskEditorMode.create,
        idGenerator:
            fixedGenerator(
          6000,
        ),
        initialDate:
            DateTime(
          2026,
          9,
          25,
        ),
        initialStartTimeMinutes:
            10 * 60,
      );

      addTearDown(
        controller.dispose,
      );

      controller.setSelectedCategoryId(
        'deleted-category',
      );
      controller.setAllDay(
        true,
      );

      expect(
        controller.categoryIdForValidation,
        'deleted-category',
      );

      final task =
          controller.buildTask(
        validatedCategoryId:
            null,
      );

      expect(
        task.categoryId,
        isNull,
      );
      expect(
        task.allDay,
        isTrue,
      );
      expect(
        task.startTimeMinutes,
        isNull,
      );
    },
  );
}
