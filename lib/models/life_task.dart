import 'task_recurrence.dart';

enum TaskPriority {
  low,
  normal,
  high,
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

  /// Stato della task singola.
  ///
  /// Per le task ricorrenti lo stato effettivo viene salvato per singola
  /// occorrenza e questo valore non viene usato come stato della serie.
  bool isCompleted;

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
    this.isCompleted = false,
  }) : scheduledDate = scheduledDate == null
            ? null
            : DateTime(
                scheduledDate.year,
                scheduledDate.month,
                scheduledDate.day,
              );

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
