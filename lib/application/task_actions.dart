import '../models/life_task.dart';
import '../models/task_occurrence.dart';
import '../models/task_series_scope.dart';
import '../models/task_subtask.dart';
import '../repositories/task_repository.dart';

class TaskActions {
  final TaskRepository repository;

  const TaskActions(
    this.repository,
  );

  Future<void> setCompleted({
    required LifeTask task,
    required bool completed,
    TaskOccurrence? occurrence,
  }) {
    if (task.recurrence.isRecurring) {
      if (occurrence == null ||
          !occurrence.isRecurring) {
        throw ArgumentError(
          'Il completamento di una task ricorrente '
          'richiede l’occorrenza corrente.',
        );
      }

      return repository
          .setOccurrenceCompleted(
        occurrence,
        completed,
      );
    }

    return repository.setCompleted(
      task.id,
      completed,
    );
  }

  Future<void> setSubtaskCompleted({
    required LifeTask task,
    required TaskSubtask subtask,
    required bool completed,
    TaskOccurrence? occurrence,
  }) {
    final occurrenceDate =
        task.recurrence.isRecurring
            ? occurrence?.seriesDate
            : null;

    if (task.recurrence.isRecurring &&
        occurrenceDate == null) {
      throw ArgumentError(
        'Una sottoattività ricorrente richiede '
        'l’occorrenza corrente.',
      );
    }

    return repository
        .setSubtaskCompleted(
      task:
          task,
      subtask:
          subtask,
      completed:
          completed,
      occurrenceDate:
          occurrenceDate,
    );
  }

  Future<void> delete({
    required LifeTask task,
    required TaskSeriesScope scope,
    TaskOccurrence? occurrence,
  }) {
    if (scope ==
        TaskSeriesScope.occurrence) {
      if (occurrence == null ||
          !occurrence.isRecurring) {
        throw ArgumentError(
          'L’eliminazione della singola occorrenza '
          'richiede un’occorrenza ricorrente.',
        );
      }

      return repository.deleteOccurrence(
        occurrence,
      );
    }

    return repository.deleteTask(
      task.id,
    );
  }
}
