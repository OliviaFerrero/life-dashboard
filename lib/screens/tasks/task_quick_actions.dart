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

/// Esito di un'azione di modifica/eliminazione, usato dalle schermate per
/// aggiornare il proprio stato senza duplicare navigazione e persistenza.
class TaskActionResult {
  final TaskSeriesScope scope;
  final LifeTask? updatedTask;
  final bool deleted;

  const TaskActionResult.updated(this.scope, this.updatedTask)
    : deleted = false;

  const TaskActionResult.deleted(this.scope)
    : updatedTask = null,
      deleted = true;
}

/// Coordinatore UI condiviso per modifica ed eliminazione delle attività.
///
/// Mostra gli stessi prompt e lo stesso editor da Dettaglio, Week e azioni
/// rapide. Le regole di persistenza restano in TaskActions/TaskRepository.
/// Spostamento e resize via gesture restano volutamente nella Week.
abstract final class TaskQuickActions {
  static Future<void> show({
    required BuildContext context,
    required LifeTask task,
    TaskOccurrence? occurrence,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) async {
    final action = await TaskPrompts.chooseQuickAction(context);
    if (!context.mounted || action == null) return;

    switch (action) {
      case TaskQuickAction.edit:
        await edit(
          context: context,
          task: task,
          occurrence: occurrence,
          taskRepository: taskRepository,
          categoryRepository: categoryRepository,
        );
        break;
      case TaskQuickAction.delete:
        await delete(
          context: context,
          task: task,
          occurrence: occurrence,
          taskRepository: taskRepository,
        );
        break;
    }
  }

  static Future<TaskActionResult?> edit({
    required BuildContext context,
    required LifeTask task,
    TaskOccurrence? occurrence,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
    LifeTask? seriesDraft,
    LifeTask? occurrenceDraft,
  }) async {
    final scope = await _chooseScope(
      context: context,
      task: task,
      occurrence: occurrence,
      action: TaskSeriesPromptAction.edit,
    );
    if (scope == null || !context.mounted) return null;

    final initialTask = scope == TaskSeriesScope.occurrence
        ? occurrenceDraft ?? draftForOccurrence(occurrence!)
        : seriesDraft ?? task;

    final result = await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          categoryRepository: categoryRepository,
          mode: scope == TaskSeriesScope.occurrence
              ? TaskEditorMode.editOccurrence
              : TaskEditorMode.edit,
          initialTask: initialTask,
        ),
      ),
    );
    if (!context.mounted || result == null) return null;

    // La conferma di cancellazione dal form è già stata chiesta dal form.
    if (result.shouldDelete) {
      await TaskActions(taskRepository)
          .delete(task: task, scope: scope, occurrence: occurrence);
      return TaskActionResult.deleted(scope);
    }

    final editedTask = result.task;
    if (editedTask == null) return null;

    if (scope == TaskSeriesScope.occurrence) {
      await taskRepository.saveOccurrenceOverride(
        occurrence: occurrence!,
        editedTask: editedTask,
      );
    } else {
      await taskRepository.updateTask(editedTask);
    }
    return TaskActionResult.updated(scope, editedTask);
  }

  static Future<TaskActionResult?> delete({
    required BuildContext context,
    required LifeTask task,
    TaskOccurrence? occurrence,
    required TaskRepository taskRepository,
  }) async {
    final scope = await _chooseScope(
      context: context,
      task: task,
      occurrence: occurrence,
      action: TaskSeriesPromptAction.delete,
    );
    if (scope == null || !context.mounted) return null;

    final confirmed = scope == TaskSeriesScope.occurrence
        ? await TaskPrompts.confirmDeleteOccurrence(context)
        : await TaskPrompts.confirmDeleteTask(context, task: task);
    if (!confirmed || !context.mounted) return null;

    await TaskActions(taskRepository)
        .delete(task: task, scope: scope, occurrence: occurrence);
    return TaskActionResult.deleted(scope);
  }

  static Future<TaskSeriesScope?> _chooseScope({
    required BuildContext context,
    required LifeTask task,
    required TaskOccurrence? occurrence,
    required TaskSeriesPromptAction action,
  }) {
    if (!task.recurrence.isRecurring ||
        occurrence == null ||
        !occurrence.isRecurring) {
      return Future.value(TaskSeriesScope.series);
    }
    return TaskPrompts.chooseSeriesScope(context, action: action);
  }

  static LifeTask draftForOccurrence(TaskOccurrence occurrence) {
    // La data visualizzata può essere diversa da seriesDate, che resta
    // l'identità persistente dell'eccezione (usata dal repository).
    return occurrence.displayTask.copyWith(
      scheduledDate: occurrence.date,
      recurrence: occurrence.task.recurrence,
      subtasks: occurrence.subtasks,
      isCompleted: occurrence.isCompleted,
    );
  }
}
