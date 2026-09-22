class TaskSubtask {
  final String id;
  final String title;
  final int sortOrder;
  final bool isCompleted;

  const TaskSubtask({
    required this.id,
    required this.title,
    required this.sortOrder,
    this.isCompleted = false,
  });

  TaskSubtask copyWith({
    String? id,
    String? title,
    int? sortOrder,
    bool? isCompleted,
  }) {
    return TaskSubtask(
      id: id ?? this.id,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      isCompleted:
          isCompleted ?? this.isCompleted,
    );
  }
}
