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
}
