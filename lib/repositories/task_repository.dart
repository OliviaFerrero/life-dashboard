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

  Future<void> addTask(LifeTask task) async {
    await _database.into(_database.taskItems).insert(
          TaskItemsCompanion.insert(
            id: task.id,
            title: task.title,
            description: Value(task.description),

            // Legacy mantenuto sincronizzato.
            startAt: Value(task.startAt),
            endAt: Value(task.endAt),

            scheduledDate: Value(task.scheduledDate),
            startTimeMinutes: Value(
              task.allDay ? null : task.startTimeMinutes,
            ),
            durationMinutes: Value(task.durationMinutes),

            categoryId: Value(task.categoryId),

            allDay: Value(task.allDay),
            priority: Value(task.priority.index),
            isCompleted: Value(task.isCompleted),
          ),
        );
  }

  Future<void> updateTask(LifeTask task) async {
    await (_database.update(_database.taskItems)
          ..where(
            (row) => row.id.equals(task.id),
          ))
        .write(
      TaskItemsCompanion(
        title: Value(task.title),
        description: Value(task.description),

        // Legacy mantenuto sincronizzato.
        startAt: Value(task.startAt),
        endAt: Value(task.endAt),

        scheduledDate: Value(task.scheduledDate),
        startTimeMinutes: Value(
          task.allDay ? null : task.startTimeMinutes,
        ),
        durationMinutes: Value(task.durationMinutes),

        categoryId: Value(task.categoryId),

        allDay: Value(task.allDay),
        priority: Value(task.priority.index),
        isCompleted: Value(task.isCompleted),
      ),
    );
  }

  Future<void> deleteTask(String id) async {
    await (_database.delete(_database.taskItems)
          ..where(
            (row) => row.id.equals(id),
          ))
        .go();
  }

  Future<void> setCompleted(
    String id,
    bool completed,
  ) async {
    await (_database.update(_database.taskItems)
          ..where(
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
    final aDate = a.scheduledDate;
    final bDate = b.scheduledDate;

    if (aDate == null && bDate != null) {
      return 1;
    }

    if (aDate != null && bDate == null) {
      return -1;
    }

    if (aDate != null && bDate != null) {
      final dateComparison = aDate.compareTo(bDate);

      if (dateComparison != 0) {
        return dateComparison;
      }
    }

    if (a.allDay != b.allDay) {
      return a.allDay ? -1 : 1;
    }

    final aTime = a.startTimeMinutes;
    final bTime = b.startTimeMinutes;

    if (aTime == null && bTime != null) {
      return -1;
    }

    if (aTime != null && bTime == null) {
      return 1;
    }

    if (aTime != null && bTime != null) {
      final timeComparison = aTime.compareTo(bTime);

      if (timeComparison != 0) {
        return timeComparison;
      }
    }

    return a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        );
  }

  LifeTask _taskFromRow(TaskItem row) {
    final fallbackDate = row.startAt == null
        ? null
        : DateTime(
            row.startAt!.year,
            row.startAt!.month,
            row.startAt!.day,
          );

    final scheduledDate = row.scheduledDate ?? fallbackDate;

    int? startTimeMinutes = row.startTimeMinutes;

    if (startTimeMinutes == null &&
        !row.allDay &&
        row.startAt != null) {
      final oldStart = row.startAt!;

      final hasExplicitTime =
          oldStart.hour != 0 ||
          oldStart.minute != 0 ||
          oldStart.second != 0 ||
          row.endAt != null;

      if (hasExplicitTime) {
        startTimeMinutes =
            oldStart.hour * 60 + oldStart.minute;
      }
    }

    int? durationMinutes = row.durationMinutes;

    if (durationMinutes == null &&
        row.startAt != null &&
        row.endAt != null) {
      final difference = row.endAt!.difference(row.startAt!);

      if (difference.inMinutes > 0) {
        durationMinutes = difference.inMinutes;
      }
    }

    return LifeTask(
      id: row.id,
      title: row.title,
      description: row.description,
      scheduledDate: scheduledDate,
      startTimeMinutes: startTimeMinutes,
      durationMinutes: durationMinutes,
      categoryId: row.categoryId,
      allDay: row.allDay,
      priority: _priorityFromInt(row.priority),
      isCompleted: row.isCompleted,
    );
  }

  TaskPriority _priorityFromInt(int value) {
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
