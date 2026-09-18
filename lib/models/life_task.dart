enum TaskPriority {
  low,
  normal,
  high,
}

class LifeTask {
  final String id;
  final String title;
  final String description;

  /// Giorno assegnato all'attività, senza significato di orario.
  final DateTime? scheduledDate;

  /// Minuti trascorsi da mezzanotte (0..1439).
  /// Può esistere anche senza [scheduledDate].
  final int? startTimeMinutes;

  /// Durata stimata in minuti.
  /// Può esistere anche senza data e senza orario.
  final int? durationMinutes;

  final bool allDay;
  final TaskPriority priority;

  bool isCompleted;

  LifeTask({
    required this.id,
    required this.title,
    this.description = '',
    DateTime? scheduledDate,
    this.startTimeMinutes,
    this.durationMinutes,
    this.allDay = false,
    this.priority = TaskPriority.normal,
    this.isCompleted = false,
  }) : scheduledDate = scheduledDate == null
            ? null
            : DateTime(
                scheduledDate.year,
                scheduledDate.month,
                scheduledDate.day,
              );

  bool get hasDate => scheduledDate != null;

  bool get hasTime =>
      !allDay && startTimeMinutes != null;

  bool get hasDuration =>
      durationMinutes != null && durationMinutes! > 0;

  bool get isInInbox => scheduledDate == null;

  /// Getter di compatibilità utile per le viste calendario.
  /// Se c'è solo la data, restituisce la mezzanotte di quel giorno.
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

  /// Calcolato da data + ora inizio + durata.
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
        minutes: startTimeMinutes! + durationMinutes!,
      ),
    );
  }
}
