import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/repositories/task_repository.dart';

bool _isItalianDstZone() {
  return DateTime(2026, 3, 29, 1).timeZoneOffset == const Duration(hours: 1) &&
      DateTime(2026, 3, 29, 4).timeZoneOffset == const Duration(hours: 2) &&
      DateTime(2026, 10, 25, 1).timeZoneOffset == const Duration(hours: 2) &&
      DateTime(2026, 10, 25, 4).timeZoneOffset == const Duration(hours: 1);
}

void main() {
  final skipOutsideItaly = !_isItalianDstZone();

  test(
    'recurring overview does not keep a finished spring-DST task as current',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = TaskRepository(database);

      await repository.addTask(
        LifeTask(
          id: 'daily-dst',
          title: 'Dopo cambio ora',
          scheduledDate: DateTime(2026, 3, 28),
          startTimeMinutes: 3 * 60 + 30,
          durationMinutes: 15,
          recurrence: const TaskRecurrence.daily(),
        ),
      );

      final overview = await repository
          .watchScheduleOverview(DateTime(2026, 3, 29, 4))
          .first;

      expect(overview, hasLength(1));
      expect(overview.single.date, DateTime(2026, 3, 30));
      expect(overview.single.occurrenceKey, 'daily-dst@2026-03-30');
    },
    skip: skipOutsideItaly,
  );

  test(
    'long spring-DST task remains visible on the following civil date',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = TaskRepository(database);

      await repository.addTask(
        LifeTask(
          id: 'short-day',
          title: 'Oltre il giorno da 23 ore',
          scheduledDate: DateTime(2026, 3, 29),
          startTimeMinutes: 0,
          durationMinutes: 23 * 60 + 30,
          recurrence: const TaskRecurrence.daily(),
        ),
      );

      final occurrences = await repository
          .watchOccurrencesOverlappingWindow(
            DateTime(2026, 3, 30),
            DateTime(2026, 3, 30, 1),
          )
          .first;

      final march29 = occurrences.where(
        (occurrence) => occurrence.occurrenceKey == 'short-day@2026-03-29',
      );
      expect(march29, hasLength(1));
      expect(march29.single.timedEnd, DateTime(2026, 3, 30, 0, 30));
    },
    skip: skipOutsideItaly,
  );
}
