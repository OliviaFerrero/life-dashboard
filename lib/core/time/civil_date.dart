abstract final class CivilDate {
  static DateTime dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  static bool sameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static DateTime addDays(
    DateTime date,
    int days,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day + days,
    );
  }

  static DateTime nextDay(
    DateTime date,
  ) {
    return addDays(
      date,
      1,
    );
  }

  static DateTime previousDay(
    DateTime date,
  ) {
    return addDays(
      date,
      -1,
    );
  }

  /// Numero di giorni CIVILI da [from] a [to].
  ///
  /// Non misura ore trascorse: usa solo anno/mese/giorno, quindi
  /// resta corretto anche quando due mezzanotti locali consecutive
  /// sono separate da 23 o 25 ore per il cambio dell'ora.
  static int differenceInDays(
    DateTime from,
    DateTime to,
  ) {
    final fromUtc =
        DateTime.utc(
      from.year,
      from.month,
      from.day,
    );

    final toUtc =
        DateTime.utc(
      to.year,
      to.month,
      to.day,
    );

    return toUtc
        .difference(
          fromUtc,
        )
        .inDays;
  }

  static DateTime startOfWeek(
    DateTime date, {
    int firstWeekday =
        DateTime.monday,
  }) {
    assert(
      firstWeekday >=
              DateTime.monday &&
          firstWeekday <=
              DateTime.sunday,
    );

    final normalized =
        dateOnly(
      date,
    );

    final offset =
        (normalized.weekday -
                firstWeekday) %
            7;

    return addDays(
      normalized,
      -offset,
    );
  }
}
