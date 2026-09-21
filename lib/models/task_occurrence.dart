import 'life_task.dart';

class TaskOccurrence {
  final LifeTask task;
  final DateTime date;
  final bool isCompleted;

  TaskOccurrence({
    required this.task,
    required DateTime date,
    required this.isCompleted,
  }) : date = DateTime(
          date.year,
          date.month,
          date.day,
        );

  bool get isRecurring =>
      task.recurrence.isRecurring;

  String get occurrenceKey =>
      '${task.id}@'
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  LifeTask get displayTask => LifeTask(
        id: task.id,
        title: task.title,
        description: task.description,
        scheduledDate: date,
        startTimeMinutes:
            task.startTimeMinutes,
        durationMinutes:
            task.durationMinutes,
        categoryId: task.categoryId,
        allDay: task.allDay,
        priority: task.priority,
        recurrence: task.recurrence,
        isCompleted: isCompleted,
      );

  TaskOccurrence copyWith({
    LifeTask? task,
    DateTime? date,
    bool? isCompleted,
  }) {
    return TaskOccurrence(
      task: task ?? this.task,
      date: date ?? this.date,
      isCompleted:
          isCompleted ?? this.isCompleted,
    );
  }
}
