enum TaskPriority {
  low,
  normal,
  high,
}

class LifeTask {
  final String id;
  final String title;
  final String description;

  final DateTime? startAt;
  final DateTime? endAt;

  final bool allDay;
  final TaskPriority priority;

  bool isCompleted;

  LifeTask({
    required this.id,
    required this.title,
    this.description = '',
    this.startAt,
    this.endAt,
    this.allDay = false,
    this.priority = TaskPriority.normal,
    this.isCompleted = false,
  });
}