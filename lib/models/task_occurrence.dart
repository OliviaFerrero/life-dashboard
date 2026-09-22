import 'life_task.dart';
import 'task_subtask.dart';

class TaskOccurrence {
  final LifeTask task;
  final DateTime date;
  final bool isCompleted;
  final List<TaskSubtask> subtasks;

  TaskOccurrence({
    required this.task,
    required DateTime date,
    required this.isCompleted,
    List<TaskSubtask> subtasks = const [],
  })  : date = DateTime(
          date.year,
          date.month,
          date.day,
        ),
        subtasks = List.unmodifiable(
          subtasks,
        );

  bool get isRecurring =>
      task.recurrence.isRecurring;

  String get occurrenceKey =>
      '${task.id}@'
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int get subtaskCount =>
      subtasks.length;

  int get completedSubtaskCount =>
      subtasks
          .where(
            (subtask) =>
                subtask.isCompleted,
          )
          .length;

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
        subtasks: subtasks,
        isCompleted: isCompleted,
      );

  TaskOccurrence copyWith({
    LifeTask? task,
    DateTime? date,
    bool? isCompleted,
    List<TaskSubtask>? subtasks,
  }) {
    return TaskOccurrence(
      task: task ?? this.task,
      date: date ?? this.date,
      isCompleted:
          isCompleted ?? this.isCompleted,
      subtasks:
          subtasks ?? this.subtasks,
    );
  }
}
