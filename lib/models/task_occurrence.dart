import 'life_task.dart';
import 'task_subtask.dart';

class TaskOccurrence {
  /// Definizione della serie/task da cui nasce l'occorrenza.
  final LifeTask task;

  /// Data effettiva di inizio mostrata all'utente.
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

  /// Inizio reale della parte temporizzata dell'occorrenza.
  ///
  /// Rimane indipendente dai confini della giornata mostrata:
  /// questo rende la timeline compatibile anche con una futura
  /// "giornata personale" 06:00 -> 03:00 del giorno successivo.
  DateTime? get timedStart {
    final task =
        displayTask;

    if (task.allDay ||
        task.startTimeMinutes == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(
      Duration(
        minutes:
            task.startTimeMinutes!,
      ),
    );
  }

  /// Fine reale della task temporizzata.
  ///
  /// Può cadere uno o più giorni dopo [date].
  DateTime? get timedEnd {
    final start =
        timedStart;
    final duration =
        displayTask.durationMinutes;

    if (start == null ||
        duration == null ||
        duration <= 0) {
      return null;
    }

    return start.add(
      Duration(
        minutes:
            duration,
      ),
    );
  }

  /// True se questa occorrenza deve essere considerata visibile
  /// dentro una finestra temporale [windowStart, windowEnd).
  ///
  /// Le task con durata vengono considerate per INTERSEZIONE,
  /// quindi una task 23:30 -> 00:30 compare su entrambi i giorni
  /// quando le viste usano finestre civili separate.
  bool overlapsWindow(
    DateTime windowStart,
    DateTime windowEnd, {
    DateTime? untimedAnchorDate,
  }) {
    if (!windowEnd.isAfter(
      windowStart,
    )) {
      return false;
    }

    final effective =
        displayTask;

    if (effective.allDay ||
        effective.startTimeMinutes == null) {
      final dayStart =
          DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (untimedAnchorDate != null) {
        return dayStart.year ==
                untimedAnchorDate.year &&
            dayStart.month ==
                untimedAnchorDate.month &&
            dayStart.day ==
                untimedAnchorDate.day;
      }

      final dayEnd =
          dayStart.add(
        const Duration(days: 1),
      );

      return dayStart.isBefore(
            windowEnd,
          ) &&
          dayEnd.isAfter(
            windowStart,
          );
    }

    final start =
        timedStart!;

    final end =
        timedEnd;

    if (end == null) {
      return !start.isBefore(
            windowStart,
          ) &&
          start.isBefore(
            windowEnd,
          );
    }

    return start.isBefore(
          windowEnd,
        ) &&
        end.isAfter(
          windowStart,
        );
  }

  DateTime? visibleStartInWindow(
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    if (!overlapsWindow(
      windowStart,
      windowEnd,
    )) {
      return null;
    }

    final start =
        timedStart;

    if (start == null) {
      return null;
    }

    return start.isBefore(
      windowStart,
    )
        ? windowStart
        : start;
  }

  DateTime? visibleEndInWindow(
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    if (!overlapsWindow(
      windowStart,
      windowEnd,
    )) {
      return null;
    }

    final end =
        timedEnd;

    if (end == null) {
      return null;
    }

    return end.isAfter(
      windowEnd,
    )
        ? windowEnd
        : end;
  }

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
