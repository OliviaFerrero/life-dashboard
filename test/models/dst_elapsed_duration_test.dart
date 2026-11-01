import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';

bool _isItalianDstZone() {
  return DateTime(2026, 3, 29, 1).timeZoneOffset == const Duration(hours: 1) &&
      DateTime(2026, 3, 29, 4).timeZoneOffset == const Duration(hours: 2) &&
      DateTime(2026, 10, 25, 1).timeZoneOffset == const Duration(hours: 2) &&
      DateTime(2026, 10, 25, 4).timeZoneOffset == const Duration(hours: 1);
}

void main() {
  final skipOutsideItaly = !_isItalianDstZone();

  test('spring: 90 elapsed minutes from 01:30 end at 04:00', () {
    final task = LifeTask(
      id: 'spring-elapsed',
      title: 'Passaggio ora legale',
      scheduledDate: DateTime(2026, 3, 29),
      startTimeMinutes: 90,
      durationMinutes: 90,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 3, 29),
      isCompleted: false,
    );

    expect(task.startAt, DateTime(2026, 3, 29, 1, 30));
    expect(task.endAt, DateTime(2026, 3, 29, 4));
    expect(occurrence.timedEnd, task.endAt);
    expect(task.endAt!.difference(task.startAt!), const Duration(minutes: 90));
  }, skip: skipOutsideItaly);

  test('autumn: 150 elapsed minutes from 01:30 end at 03:00', () {
    final task = LifeTask(
      id: 'autumn-elapsed',
      title: 'Passaggio ora solare',
      scheduledDate: DateTime(2026, 10, 25),
      startTimeMinutes: 90,
      durationMinutes: 150,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 10, 25),
      isCompleted: false,
    );

    expect(task.startAt, DateTime(2026, 10, 25, 1, 30));
    expect(task.endAt, DateTime(2026, 10, 25, 3));
    expect(occurrence.timedEnd, task.endAt);
    expect(task.endAt!.difference(task.startAt!), const Duration(minutes: 150));
  }, skip: skipOutsideItaly);
}
