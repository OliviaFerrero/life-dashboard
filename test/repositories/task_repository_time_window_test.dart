import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/database/app_database.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_recurrence.dart';
import 'package:life_hub/repositories/task_repository.dart';

void main() {
  test(
    'a recurring overnight event is still found using its original day',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = TaskRepository(database);

      await repository.addTask(
        LifeTask(
          id: 'nightly',
          title: 'Turno',
          scheduledDate: DateTime(2026, 10, 31),
          startTimeMinutes: 23 * 60 + 30,
          durationMinutes: 90,
          recurrence: const TaskRecurrence.daily(),
        ),
      );

      final saturday = await repository
          .watchOccurrencesOverlappingWindow(
            DateTime(2026, 10, 31, 22),
            DateTime(2026, 11, 1),
          )
          .first;
      final sundayMorning = await repository
          .watchOccurrencesOverlappingWindow(
            DateTime(2026, 11, 1),
            DateTime(2026, 11, 1, 2),
          )
          .first;

      expect(saturday, hasLength(1));
      expect(sundayMorning, hasLength(1));
      expect(saturday.single.occurrenceKey, 'nightly@2026-10-31');
      expect(sundayMorning.single.occurrenceKey, 'nightly@2026-10-31');
      expect(sundayMorning.single.timedEnd, DateTime(2026, 11, 1, 1));
    },
  );

  test(
    'end-exclusive interval does not duplicate a midnight boundary',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = TaskRepository(database);

      await repository.addTask(
        LifeTask(
          id: 'midnight',
          title: 'Termina alle 00:00',
          scheduledDate: DateTime(2026, 11, 1),
          startTimeMinutes: 23 * 60 + 30,
          durationMinutes: 30,
        ),
      );

      final nextDay = await repository
          .watchOccurrencesOverlappingWindow(
            DateTime(2026, 11, 2),
            DateTime(2026, 11, 3),
          )
          .first;
      expect(nextDay, isEmpty);
    },
  );
}
