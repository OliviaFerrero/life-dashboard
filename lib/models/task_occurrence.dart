import 'life_task.dart';
import 'task_subtask.dart';

class TaskOccurrence {
  /// Definizione della serie/task da cui nasce l'occorrenza.
  final LifeTask task;

  /// Data effettiva mostrata all'utente.
  ///
  /// Può differire da [seriesDate] quando questa singola occorrenza
  /// è stata spostata.
  final DateTime date;

  /// Data originaria generata dalla regola della serie.
  ///
  /// È l'identità stabile dell'occorrenza e viene usata per stato
  /// completato, subtasks ed eventuali override.
  final DateTime seriesDate;

  final bool isCompleted;
  final List<TaskSubtask> subtasks;

  /// Valori effettivi di questa sola occorrenza quando esiste un override.
  ///
  /// La ricorrenza e la struttura delle subtasks restano comunque
  /// proprietà della serie in [task].
  final LifeTask? effectiveTask;

  TaskOccurrence({
    required this.task,
    required DateTime date,
    DateTime? seriesDate,
    required this.isCompleted,
    List<TaskSubtask> subtasks = const [],
    this.effectiveTask,
  })  : date = DateTime(
          date.year,
          date.month,
          date.day,
        ),
        seriesDate = DateTime(
          (seriesDate ?? date).year,
          (seriesDate ?? date).month,
          (seriesDate ?? date).day,
        ),
        subtasks = List.unmodifiable(
          subtasks,
        );

  bool get isRecurring =>
      task.recurrence.isRecurring;

  bool get hasOverride =>
      effectiveTask != null ||
      seriesDate != date;

  String get occurrenceKey =>
      '${task.id}@'
      '${seriesDate.year.toString().padLeft(4, '0')}-'
      '${seriesDate.month.toString().padLeft(2, '0')}-'
      '${seriesDate.day.toString().padLeft(2, '0')}';

  int get subtaskCount =>
      subtasks.length;

  int get completedSubtaskCount =>
      subtasks
          .where(
            (subtask) =>
                subtask.isCompleted,
          )
          .length;

  LifeTask get displayTask {
    final source =
        effectiveTask ?? task;

    return LifeTask(
      id: task.id,
      title: source.title,
      description: source.description,
      scheduledDate: date,
      startTimeMinutes:
          source.startTimeMinutes,
      durationMinutes:
          source.durationMinutes,
      categoryId: source.categoryId,
      allDay: source.allDay,
      priority: source.priority,
      recurrence: task.recurrence,
      subtasks: subtasks,
      isCompleted: isCompleted,
    );
  }

  TaskOccurrence copyWith({
    LifeTask? task,
    DateTime? date,
    DateTime? seriesDate,
    bool? isCompleted,
    List<TaskSubtask>? subtasks,
    LifeTask? effectiveTask,
    bool clearEffectiveTask = false,
  }) {
    return TaskOccurrence(
      task: task ?? this.task,
      date: date ?? this.date,
      seriesDate:
          seriesDate ?? this.seriesDate,
      isCompleted:
          isCompleted ?? this.isCompleted,
      subtasks:
          subtasks ?? this.subtasks,
      effectiveTask:
          clearEffectiveTask
              ? null
              : effectiveTask ??
                  this.effectiveTask,
    );
  }
}
