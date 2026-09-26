import 'package:flutter/material.dart';

import '../../application/task_actions.dart';
import '../../models/life_task.dart';
import '../../models/task_occurrence.dart';
import '../../models/task_series_scope.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../widgets/task_prompts.dart';
import 'task_editor_mode.dart';
import 'task_form_page.dart';

abstract final class TaskQuickActions {
  static Future<void> show({
    required BuildContext context,
    required LifeTask task,
    TaskOccurrence? occurrence,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) async {
    final action =
        await TaskPrompts
            .chooseQuickAction(
      context,
    );

    if (!context.mounted ||
        action == null) {
      return;
    }

    switch (action) {
      case TaskQuickAction.edit:
        await _edit(
          context:
              context,
          task:
              task,
          occurrence:
              occurrence,
          taskRepository:
              taskRepository,
          categoryRepository:
              categoryRepository,
        );
        break;

      case TaskQuickAction.delete:
        await _delete(
          context:
              context,
          task:
              task,
          occurrence:
              occurrence,
          taskRepository:
              taskRepository,
        );
        break;
    }
  }

  static Future<void> _edit({
    required BuildContext context,
    required LifeTask task,
    required TaskOccurrence? occurrence,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) async {
    if (!task.recurrence.isRecurring ||
        occurrence == null ||
        !occurrence.isRecurring) {
      await _editSeries(
        context:
            context,
        task:
            task,
        taskRepository:
            taskRepository,
        categoryRepository:
            categoryRepository,
      );
      return;
    }

    final scope =
        await TaskPrompts
            .chooseSeriesScope(
      context,
      action:
          TaskSeriesPromptAction.edit,
    );

    if (!context.mounted ||
        scope == null) {
      return;
    }

    switch (scope) {
      case TaskSeriesScope.occurrence:
        await _editOccurrence(
          context:
              context,
          task:
              task,
          occurrence:
              occurrence,
          taskRepository:
              taskRepository,
          categoryRepository:
              categoryRepository,
        );
        break;

      case TaskSeriesScope.series:
        await _editSeries(
          context:
              context,
          task:
              task,
          taskRepository:
              taskRepository,
          categoryRepository:
              categoryRepository,
        );
        break;
    }
  }

  static Future<void> _editSeries({
    required BuildContext context,
    required LifeTask task,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) async {
    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              categoryRepository,
          mode:
              TaskEditorMode.edit,
          initialTask:
              task,
        ),
      ),
    );

    if (!context.mounted ||
        result == null) {
      return;
    }

    if (result.shouldDelete) {
      await TaskActions(
        taskRepository,
      ).delete(
        task:
            task,
        scope:
            TaskSeriesScope.series,
      );
      return;
    }

    final updatedTask =
        result.task;

    if (updatedTask == null) {
      return;
    }

    await taskRepository.updateTask(
      updatedTask,
    );
  }

  static Future<void> _editOccurrence({
    required BuildContext context,
    required LifeTask task,
    required TaskOccurrence occurrence,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) async {
    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              categoryRepository,
          mode:
              TaskEditorMode
                  .editOccurrence,
          initialTask:
              _occurrenceTaskForEditing(
            task,
            occurrence,
          ),
        ),
      ),
    );

    if (!context.mounted ||
        result == null) {
      return;
    }

    if (result.shouldDelete) {
      await TaskActions(
        taskRepository,
      ).delete(
        task:
            task,
        occurrence:
            occurrence,
        scope:
            TaskSeriesScope.occurrence,
      );
      return;
    }

    final editedTask =
        result.task;

    if (editedTask == null) {
      return;
    }

    await taskRepository
        .saveOccurrenceOverride(
      occurrence:
          occurrence,
      editedTask:
          editedTask,
    );
  }

  static Future<void> _delete({
    required BuildContext context,
    required LifeTask task,
    required TaskOccurrence? occurrence,
    required TaskRepository taskRepository,
  }) async {
    if (!task.recurrence.isRecurring ||
        occurrence == null ||
        !occurrence.isRecurring) {
      final confirmed =
          await TaskPrompts
              .confirmDeleteTask(
        context,
        task:
            task,
      );

      if (!confirmed ||
          !context.mounted) {
        return;
      }

      await TaskActions(
        taskRepository,
      ).delete(
        task:
            task,
        scope:
            TaskSeriesScope.series,
      );
      return;
    }

    final scope =
        await TaskPrompts
            .chooseSeriesScope(
      context,
      action:
          TaskSeriesPromptAction.delete,
    );

    if (!context.mounted ||
        scope == null) {
      return;
    }

    switch (scope) {
      case TaskSeriesScope.occurrence:
        final confirmed =
            await TaskPrompts
                .confirmDeleteOccurrence(
          context,
        );

        if (!confirmed ||
            !context.mounted) {
          return;
        }

        await TaskActions(
          taskRepository,
        ).delete(
          task:
              task,
          occurrence:
              occurrence,
          scope:
              TaskSeriesScope.occurrence,
        );
        break;

      case TaskSeriesScope.series:
        final confirmed =
            await TaskPrompts
                .confirmDeleteTask(
          context,
          task:
              task,
        );

        if (!confirmed ||
            !context.mounted) {
          return;
        }

        await TaskActions(
          taskRepository,
        ).delete(
          task:
              task,
          scope:
              TaskSeriesScope.series,
        );
        break;
    }
  }

  static LifeTask
      _occurrenceTaskForEditing(
    LifeTask seriesTask,
    TaskOccurrence occurrence,
  ) {
    final displayTask =
        occurrence.displayTask;

    return LifeTask(
      id:
          seriesTask.id,
      title:
          displayTask.title,
      description:
          displayTask.description,
      scheduledDate:
          occurrence.date,
      startTimeMinutes:
          displayTask
              .startTimeMinutes,
      durationMinutes:
          displayTask
              .durationMinutes,
      categoryId:
          displayTask.categoryId,
      allDay:
          displayTask.allDay,
      priority:
          displayTask.priority,
      recurrence:
          seriesTask.recurrence,
      subtasks:
          occurrence.subtasks,
      isCompleted:
          occurrence.isCompleted,
    );
  }
}
