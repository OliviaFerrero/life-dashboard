enum TaskRecurrenceType {
  none,
  daily,
  weekly,
}

class TaskRecurrence {
  final TaskRecurrenceType type;

  /// Bit 0 = lunedì, bit 1 = martedì, ... bit 6 = domenica.
  final int weekdaysMask;

  const TaskRecurrence.none()
      : type = TaskRecurrenceType.none,
        weekdaysMask = 0;

  const TaskRecurrence.daily()
      : type = TaskRecurrenceType.daily,
        weekdaysMask = 0;

  const TaskRecurrence.weeklyMask(
    this.weekdaysMask,
  ) : type = TaskRecurrenceType.weekly;

  factory TaskRecurrence.weekly(
    Iterable<int> weekdays,
  ) {
    var mask = 0;

    for (final weekday in weekdays) {
      if (weekday < DateTime.monday ||
          weekday > DateTime.sunday) {
        continue;
      }

      mask |= 1 << (weekday - 1);
    }

    return TaskRecurrence.weeklyMask(mask);
  }

  bool get isRecurring =>
      type != TaskRecurrenceType.none;

  List<int> get weekdays {
    if (type != TaskRecurrenceType.weekly) {
      return const [];
    }

    return [
      for (var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++)
        if (includesWeekday(weekday))
          weekday,
    ];
  }

  bool includesWeekday(
    int weekday,
  ) {
    if (weekday < DateTime.monday ||
        weekday > DateTime.sunday) {
      return false;
    }

    return (weekdaysMask &
            (1 << (weekday - 1))) !=
        0;
  }

  bool occursOn(
    DateTime date,
    DateTime startDate,
  ) {
    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (normalizedDate.isBefore(
      normalizedStart,
    )) {
      return false;
    }

    switch (type) {
      case TaskRecurrenceType.none:
        return normalizedDate ==
            normalizedStart;

      case TaskRecurrenceType.daily:
        return true;

      case TaskRecurrenceType.weekly:
        final effectiveMask =
            weekdaysMask == 0
                ? 1 <<
                    (normalizedStart.weekday - 1)
                : weekdaysMask;

        return (effectiveMask &
                (1 <<
                    (normalizedDate.weekday - 1))) !=
            0;
    }
  }

  String get storageValue {
    switch (type) {
      case TaskRecurrenceType.none:
        return 'none';
      case TaskRecurrenceType.daily:
        return 'daily';
      case TaskRecurrenceType.weekly:
        return 'weekly';
    }
  }

  static TaskRecurrence fromStorage(
    String value,
    int weekdaysMask,
  ) {
    switch (value) {
      case 'daily':
        return const TaskRecurrence.daily();

      case 'weekly':
        return TaskRecurrence.weeklyMask(
          weekdaysMask,
        );

      default:
        return const TaskRecurrence.none();
    }
  }
}
