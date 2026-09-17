import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/life_task.dart';

class TaskRepository {
  final AppDatabase _database;

  TaskRepository(this._database);

  Stream<List<LifeTask>> watchAllTasks() {
    return _database
        .select(_database.taskItems)
        .watch()
        .map((rows) {
      final tasks = rows.map(_taskFromRow).toList();

      tasks.sort(_compareTasks);

      return tasks;
    });
  }

  Stream<List<LifeTask>> watchTasksForDay(DateTime day) {
    return watchAllTasks().map((tasks) {
      return tasks.where((task) {
        final date = task.startAt;

        if (date == null) {
          return false;
        }

        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).toList()
        ..sort(_compareTasks);
    });
  }

  Stream<int> watchIncompleteCount() {
    return watchAllTasks().map(
      (tasks) => tasks
          .where(
            (task) => !task.isCompleted,
          )
          .length,
    );
  }

  Future<void> addTask(
    LifeTask task,
  ) async {
    await _database
        .into(_database.taskItems)
        .insert(
          TaskItemsCompanion.insert(
            id: task.id,
            title: task.title,
            description: Value(task.description),
            startAt: Value(task.startAt),
            endAt: Value(task.endAt),
            allDay: Value(task.allDay),
            priority: Value(task.priority.index),
            isCompleted: Value(task.isCompleted),
          ),
        );
  }

  Future<void> updateTask(
    LifeTask task,
  ) async {
    await (_database.update(
      _database.taskItems,
    )..where(
            (row) => row.id.equals(task.id),
          ))
        .write(
      TaskItemsCompanion(
        title: Value(task.title),
        description: Value(task.description),
        startAt: Value(task.startAt),
        endAt: Value(task.endAt),
        allDay: Value(task.allDay),
        priority: Value(task.priority.index),
        isCompleted: Value(task.isCompleted),
      ),
    );
  }

  Future<void> deleteTask(
    String id,
  ) async {
    await (_database.delete(
      _database.taskItems,
    )..where(
            (row) => row.id.equals(id),
          ))
        .go();
  }

  Future<void> setCompleted(
    String id,
    bool completed,
  ) async {
    await (_database.update(
      _database.taskItems,
    )..where(
            (row) => row.id.equals(id),
          ))
        .write(
      TaskItemsCompanion(
        isCompleted: Value(completed),
      ),
    );
  }

  int _compareTasks(
    LifeTask a,
    LifeTask b,
  ) {
    if (a.startAt == null && b.startAt == null) {
      return 0;
    }

    if (a.startAt == null) {
      return 1;
    }

    if (b.startAt == null) {
      return -1;
    }

    return a.startAt!.compareTo(b.startAt!);
  }

  LifeTask _taskFromRow(
    TaskItem row,
  ) {
    return LifeTask(
      id: row.id,
      title: row.title,
      description: row.description,
      startAt: row.startAt,
      endAt: row.endAt,
      allDay: row.allDay,
      priority: _priorityFromInt(row.priority),
      isCompleted: row.isCompleted,
    );
  }

  TaskPriority _priorityFromInt(
    int value,
  ) {
    switch (value) {
      case 0:
        return TaskPriority.low;

      case 2:
        return TaskPriority.high;

      default:
        return TaskPriority.normal;
    }
  }
}