import 'task_recurrence.dart';
import 'task_subtask.dart';

enum TaskPriority {
  low(0),
  normal(1),
  high(2);

  final int storageValue;

  const TaskPriority(
    this.storageValue,
  );

  static TaskPriority fromStorage(
    int value,
  ) {
    switch (value) {
      case 0:
        return TaskPriority.low;

      case 2:
        return TaskPriority.high;

      default:
        return TaskPriority.normal;
    }
  }
}

class LifeTask {
  final String id;
  final String title;
  final String description;

  /// Giorno assegnato all'attività.
  ///
  /// Per un'attività ricorrente è la data di inizio della serie.
  final DateTime? scheduledDate;

  /// Minuti trascorsi da mezzanotte (0..1439).
  /// Può esistere anche senza [scheduledDate].
  final int? startTimeMinutes;

  /// Durata stimata in minuti.
  /// Può esistere anche senza data e senza orario.
  final int? durationMinutes;

  /// Identificativo della categoria associata.
  /// Null significa "Nessuna categoria".
  final String? categoryId;

  final bool allDay;
  final TaskPriority priority;

  /// Regola di ricorrenza della task.
  ///
  /// Una ricorrenza richiede [scheduledDate], che funge da inizio serie.
  final TaskRecurrence recurrence;

  /// Definizione ordinata delle sottoattività.
  ///
  /// Per task non ricorrenti [TaskSubtask.isCompleted] contiene lo stato
  /// persistito. Per task ricorrenti lo stato effettivo appartiene alla
  /// singola occorrenza.
  final List<TaskSubtask> subtasks;

  /// Stato della task singola.
  ///
  /// Per le task ricorrenti lo stato effettivo viene salvato per singola
  /// occorrenza e questo valore non viene usato come stato della serie.
  final bool isCompleted;

  LifeTask({
    required this.id,
    required this.title,
    this.description = '',
    DateTime? scheduledDate,
    this.startTimeMinutes,
    this.durationMinutes,
    this.categoryId,
    this.allDay = false,
    this.priority = TaskPriority.normal,
    this.recurrence = const TaskRecurrence.none(),
    List<TaskSubtask> subtasks = const [],
    this.isCompleted = false,
  })  : scheduledDate = scheduledDate == null
            ? null
            : DateTime(
                scheduledDate.year,
                scheduledDate.month,
                scheduledDate.day,
              ),
        subtasks = List.unmodifiable(
          subtasks,
        );

  LifeTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    int? startTimeMinutes,
    bool clearStartTimeMinutes = false,
    int? durationMinutes,
    bool clearDurationMinutes = false,
    String? categoryId,
    bool clearCategoryId = false,
    bool? allDay,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    List<TaskSubtask>? subtasks,
    bool? isCompleted,
  }) {
    assert(
      !clearScheduledDate ||
          scheduledDate == null,
    );
    assert(
      !clearStartTimeMinutes ||
          startTimeMinutes == null,
    );
    assert(
      !clearDurationMinutes ||
          durationMinutes == null,
    );
    assert(
      !clearCategoryId ||
          categoryId == null,
    );

    return LifeTask(
      id:
          id ??
          this.id,
      title:
          title ??
          this.title,
      description:
          description ??
          this.description,
      scheduledDate:
          clearScheduledDate
              ? null
              : scheduledDate ??
                  this.scheduledDate,
      startTimeMinutes:
          clearStartTimeMinutes
              ? null
              : startTimeMinutes ??
                  this.startTimeMinutes,
      durationMinutes:
          clearDurationMinutes
              ? null
              : durationMinutes ??
                  this.durationMinutes,
      categoryId:
          clearCategoryId
              ? null
              : categoryId ??
                  this.categoryId,
      allDay:
          allDay ??
          this.allDay,
      priority:
          priority ??
          this.priority,
      recurrence:
          recurrence ??
          this.recurrence,
      subtasks:
          subtasks ??
          this.subtasks,
      isCompleted:
          isCompleted ??
          this.isCompleted,
    );
  }

  int get subtaskCount =>
      subtasks.length;

  int get completedSubtaskCount =>
      subtasks
          .where(
            (subtask) =>
                subtask.isCompleted,
          )
          .length;

  DateTime? get startAt {
    final date = scheduledDate;

    if (date == null) {
      return null;
    }

    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (allDay || startTimeMinutes == null) {
      return normalizedDate;
    }

    return normalizedDate.add(
      Duration(minutes: startTimeMinutes!),
    );
  }

  DateTime? get endAt {
    if (scheduledDate == null ||
        allDay ||
        startTimeMinutes == null ||
        durationMinutes == null) {
      return null;
    }

    final date = DateTime(
      scheduledDate!.year,
      scheduledDate!.month,
      scheduledDate!.day,
    );

    return date.add(
      Duration(
        minutes:
            startTimeMinutes! + durationMinutes!,
      ),
    );
  }
}
