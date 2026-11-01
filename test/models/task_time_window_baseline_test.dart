import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_recurrence.dart';

void main() {
  test(
    'cross-midnight task keeps elapsed duration and occurrence identity',
    () {
      final task = LifeTask(
        id: 'night-task',
        title: 'Turno notturno',
        scheduledDate: DateTime(2026, 10, 31),
        startTimeMinutes: 23 * 60 + 30,
        durationMinutes: 90,
        recurrence: const TaskRecurrence.daily(),
      );
      final occurrence = TaskOccurrence(
        task: task,
        date: DateTime(2026, 10, 31),
        seriesDate: DateTime(2026, 10, 31),
        isCompleted: false,
      );

      expect(occurrence.timedStart, DateTime(2026, 10, 31, 23, 30));
      expect(occurrence.timedEnd, DateTime(2026, 11, 1, 1));
      expect(
        occurrence.timedEnd!.difference(occurrence.timedStart!),
        const Duration(minutes: 90),
      );
      expect(occurrence.occurrenceKey, 'night-task@2026-10-31');

      expect(
        occurrence.overlapsWindow(
          DateTime(2026, 10, 31),
          DateTime(2026, 11, 1),
        ),
        isTrue,
      );
      expect(
        occurrence.overlapsWindow(DateTime(2026, 11, 1), DateTime(2026, 11, 2)),
        isTrue,
      );
      expect(occurrence.occurrenceKey, 'night-task@2026-10-31');
    },
  );

  test('half-open time windows exclude an event ending at their start', () {
    final task = LifeTask(
      id: 'ends-at-midnight',
      title: 'Fino a mezzanotte',
      scheduledDate: DateTime(2026, 11, 1),
      startTimeMinutes: 23 * 60 + 30,
      durationMinutes: 30,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 11, 1),
      isCompleted: false,
    );

    expect(occurrence.timedEnd, DateTime(2026, 11, 2));
    expect(
      occurrence.overlapsWindow(DateTime(2026, 11, 2), DateTime(2026, 11, 3)),
      isFalse,
    );
  });

  test('visible part of an overnight task is clipped to the window', () {
    final task = LifeTask(
      id: 'clip-test',
      title: 'Notte',
      scheduledDate: DateTime(2026, 11, 1),
      startTimeMinutes: 23 * 60 + 30,
      durationMinutes: 90,
    );
    final occurrence = TaskOccurrence(
      task: task,
      date: DateTime(2026, 11, 1),
      isCompleted: false,
    );

    final start = DateTime(2026, 11, 2);
    final end = DateTime(2026, 11, 2, 0, 45);
    expect(occurrence.visibleStartInWindow(start, end), start);
    expect(occurrence.visibleEndInWindow(start, end), end);
  });

  test('moving an occurrence does not change its stable series date', () {
    final task = LifeTask(
      id: 'daily',
      title: 'Serie',
      scheduledDate: DateTime(2026, 10, 31),
      startTimeMinutes: 22 * 60,
      durationMinutes: 180,
      recurrence: const TaskRecurrence.daily(),
    );
    final moved = TaskOccurrence(
      task: task,
      date: DateTime(2026, 11, 2),
      seriesDate: DateTime(2026, 10, 31),
      isCompleted: false,
    );

    expect(moved.hasOverride, isTrue);
    expect(moved.occurrenceKey, 'daily@2026-10-31');
    expect(moved.timedStart, DateTime(2026, 11, 2, 22));
    expect(moved.timedEnd, DateTime(2026, 11, 3, 1));
  });
}
