import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../models/task_series_scope.dart';
import '../models/task_subtask.dart';
import 'life_choice_sheet.dart';
import 'life_confirmation_dialog.dart';

enum TaskSeriesPromptAction {
  edit,
  delete,
  move,
  resize,
}

abstract final class TaskPrompts {
  static Future<bool>
      confirmCompletionIfNeeded(
    BuildContext context, {
    required Iterable<TaskSubtask>
        subtasks,
  }) {
    final remaining =
        subtasks.where(
      (subtask) =>
          !subtask.isCompleted,
    ).length;

    if (remaining == 0) {
      return Future<bool>.value(
        true,
      );
    }

    return showLifeConfirmationDialog(
      context,
      title:
          'Completare attività?',
      message:
          remaining == 1
              ? 'C’è ancora 1 sottoattività da completare. '
                  'Completando l’attività verrà completata anche quella.'
              : 'Ci sono ancora $remaining sottoattività da completare. '
                  'Completando l’attività verranno completate tutte.',
      confirmLabel:
          'Completa tutto',
      icon:
          Icons.check_circle_outline,
    );
  }

  static Future<bool>
      confirmDeleteTask(
    BuildContext context, {
    required LifeTask task,
  }) {
    final recurring =
        task.recurrence.isRecurring;

    return showLifeConfirmationDialog(
      context,
      title:
          recurring
              ? 'Eliminare serie?'
              : 'Eliminare attività?',
      message:
          recurring
              ? 'Vuoi eliminare tutta la serie '
                  '"${task.title}"?'
              : 'Vuoi eliminare '
                  '"${task.title}"?',
      confirmLabel:
          'Elimina',
      destructive:
          true,
      icon:
          Icons.delete_outline,
    );
  }

  static Future<bool>
      confirmDeleteOccurrence(
    BuildContext context,
  ) {
    return showLifeConfirmationDialog(
      context,
      title:
          'Eliminare questa occorrenza?',
      message:
          'Verrà rimossa solo questa data. '
          'Le altre occorrenze della serie resteranno invariate.',
      confirmLabel:
          'Elimina',
      destructive:
          true,
      icon:
          Icons.event_busy_outlined,
    );
  }

  static Future<TaskSeriesScope?>
      chooseSeriesScope(
    BuildContext context, {
    required TaskSeriesPromptAction
        action,
  }) {
    final config =
        _seriesPromptConfig(
      action,
    );

    return showLifeChoiceSheet<
        TaskSeriesScope>(
      context,
      title:
          config.title,
      options: [
        LifeChoiceOption<
            TaskSeriesScope>(
          value:
              TaskSeriesScope
                  .occurrence,
          icon:
              config.occurrenceIcon,
          title:
              'Solo questa occorrenza',
          subtitle:
              config.occurrenceSubtitle,
          destructive:
              config.destructive,
        ),
        LifeChoiceOption<
            TaskSeriesScope>(
          value:
              TaskSeriesScope.series,
          icon:
              config.seriesIcon,
          title:
              'Tutta la serie',
          subtitle:
              config.seriesSubtitle,
          destructive:
              config.destructive,
        ),
      ],
    );
  }

  static _TaskSeriesPromptConfig
      _seriesPromptConfig(
    TaskSeriesPromptAction action,
  ) {
    switch (action) {
      case TaskSeriesPromptAction.edit:
        return const _TaskSeriesPromptConfig(
          title:
              'Modifica',
          occurrenceIcon:
              Icons.event_outlined,
          seriesIcon:
              Icons.repeat,
        );

      case TaskSeriesPromptAction.delete:
        return const _TaskSeriesPromptConfig(
          title:
              'Elimina',
          occurrenceIcon:
              Icons.event_busy_outlined,
          seriesIcon:
              Icons.delete_sweep_outlined,
          destructive:
              true,
        );

      case TaskSeriesPromptAction.move:
        return const _TaskSeriesPromptConfig(
          title:
              'Sposta attività',
          occurrenceIcon:
              Icons.event_outlined,
          seriesIcon:
              Icons.repeat,
          occurrenceSubtitle:
              'Sposta soltanto questo evento.',
          seriesSubtitle:
              'Sposta orario e giorni della serie.',
        );

      case TaskSeriesPromptAction.resize:
        return const _TaskSeriesPromptConfig(
          title:
              'Modifica durata',
          occurrenceIcon:
              Icons.event_outlined,
          seriesIcon:
              Icons.repeat,
          occurrenceSubtitle:
              'Modifica soltanto questa occorrenza.',
          seriesSubtitle:
              'Modifica la durata di tutta la serie.',
        );
    }
  }
}

class _TaskSeriesPromptConfig {
  final String title;
  final IconData occurrenceIcon;
  final IconData seriesIcon;
  final String? occurrenceSubtitle;
  final String? seriesSubtitle;
  final bool destructive;

  const _TaskSeriesPromptConfig({
    required this.title,
    required this.occurrenceIcon,
    required this.seriesIcon,
    this.occurrenceSubtitle,
    this.seriesSubtitle,
    this.destructive = false,
  });
}
