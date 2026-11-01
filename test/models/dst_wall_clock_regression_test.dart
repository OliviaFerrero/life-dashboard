import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';

// These are intentionally RED on the current implementation when Dart is
// running in an Europe/Rome-like timezone. The next phase will fix the
// midnight + Duration calculation used for a stored wall-clock start time.
// Other host timezones skip these checks rather than produce false results.
bool _isItalianDstZone() {
  return DateTime(2026, 3, 29, 1).timeZoneOffset == const Duration(hours: 1) &&
      DateTime(2026, 3, 29, 4).timeZoneOffset == const Duration(hours: 2) &&
      DateTime(2026, 10, 25, 1).timeZoneOffset == const Duration(hours: 2) &&
      DateTime(2026, 10, 25, 4).timeZoneOffset == const Duration(hours: 1);
}

void main() {
  final skipOutsideItaly = !_isItalianDstZone();

  test('spring: LifeTask.startAt remains 03:30 local after clock advances', () {
    final task = LifeTask(
      id: 'spring-task',
      title: 'Ore 03:30',
      scheduledDate: DateTime(2026, 3, 29),
      startTimeMinutes: 3 * 60 + 30,
      durationMinutes: 60,
    );

    expect(task.startAt, DateTime(2026, 3, 29, 3, 30));
  }, skip: skipOutsideItaly);

  test(
    'spring: LifeTask.endAt is 60 elapsed minutes after the local start',
    () {
      final task = LifeTask(
        id: 'spring-end',
        title: 'Una ora',
        scheduledDate: DateTime(2026, 3, 29),
        startTimeMinutes: 3 * 60 + 30,
        durationMinutes: 60,
      );

      final expectedStart = DateTime(2026, 3, 29, 3, 30);
      expect(task.endAt, expectedStart.add(const Duration(minutes: 60)));
    },
    skip: skipOutsideItaly,
  );

  test('autumn: occurrence at 03:30 is not displaced to repeated 02:30', () {
    final task = LifeTask(
      id: 'autumn-task',
      title: 'Ore 03:30',
      scheduledDate: DateTime(2026, 10, 25),
      startTimeMinutes: 3 * 60 + 30,
      durationMinutes: 45,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 10, 25),
      isCompleted: false,
    );

    expect(occurrence.timedStart, DateTime(2026, 10, 25, 3, 30));
  }, skip: skipOutsideItaly);

  test('spring: a 03:30 occurrence intersects the real 03:30-04:00 window', () {
    final task = LifeTask(
      id: 'spring-visible',
      title: 'Visibile nella finestra giusta',
      scheduledDate: DateTime(2026, 3, 29),
      startTimeMinutes: 3 * 60 + 30,
      durationMinutes: 60,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 3, 29),
      isCompleted: false,
    );

    expect(
      occurrence.overlapsWindow(
        DateTime(2026, 3, 29, 3, 30),
        DateTime(2026, 3, 29, 4),
      ),
      isTrue,
    );
  }, skip: skipOutsideItaly);
}
