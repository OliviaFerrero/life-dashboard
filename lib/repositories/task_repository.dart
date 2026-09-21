import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/life_task.dart';
import '../models/task_occurrence.dart';
import '../models/task_recurrence.dart';

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

  Stream<List<TaskOccurrence>>
      watchOccurrencesInRange(
    DateTime start,
    DateTime end,
  ) {
    final rangeStart = _dateOnly(start);
    final rangeEnd = _dateOnly(end);

    return _watchTaskData().map(
      (snapshot) => _buildOccurrencesInRange(
        snapshot,
        rangeStart,
        rangeEnd,
      ),
    );
  }

  /// Restituisce una sola voce pianificata per ogni task:
  /// - task singola -> la sua data reale
  /// - task ricorrente -> occorrenza di oggi se ancora rilevante,
  ///   altrimenti la prossima occorrenza utile.
  ///
  /// In questo modo la pagina Attività non genera una lista infinita.
  Stream<List<TaskOccurrence>>
      watchScheduleOverview(
    DateTime referenceTime,
  ) {
    return _watchTaskData().map(
      (snapshot) => _buildScheduleOverview(
        snapshot,
        referenceTime,
      ),
    );
  }

  /// Conteggio usato da Oggi -> Panoramica -> Attività.
  ///
  /// Le task ricorrenti contano come una singola occorrenza
  /// corrente/prossima, evitando un totale infinito.
  Stream<int> watchIncompleteOverviewCount(
    DateTime referenceTime,
  ) {
    return _watchTaskData().map((snapshot) {
      final inboxIncomplete =
          snapshot.tasks.where(
        (task) =>
            task.scheduledDate == null &&
            !task.isCompleted,
      ).length;

      final scheduledIncomplete =
          _buildScheduleOverview(
        snapshot,
        referenceTime,
      ).where(
        (occurrence) =>
            !occurrence.isCompleted,
      ).length;

      return inboxIncomplete +
          scheduledIncomplete;
    });
  }

  Future<void> addTask(
    LifeTask task,
  ) async {
    await _database.into(_database.taskItems).insert(
          TaskItemsCompanion.insert(
            id: task.id,
            title: task.title,
            description:
                Value(task.description),

            // Legacy mantenuto sincronizzato.
            startAt: Value(task.startAt),
            endAt: Value(task.endAt),

            scheduledDate:
                Value(task.scheduledDate),
            startTimeMinutes: Value(
              task.allDay
                  ? null
                  : task.startTimeMinutes,
            ),
            durationMinutes:
                Value(task.durationMinutes),

            categoryId:
                Value(task.categoryId),

            allDay:
                Value(task.allDay),
            priority:
                Value(task.priority.index),

            // Per una serie ricorrente lo stato vive
            // nelle singole occorrenze.
            isCompleted: Value(
              task.recurrence.isRecurring
                  ? false
                  : task.isCompleted,
            ),

            recurrenceType: Value(
              task.recurrence.storageValue,
            ),
            recurrenceWeekdays: Value(
              task.recurrence.weekdaysMask,
            ),
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
        description:
            Value(task.description),

        // Legacy mantenuto sincronizzato.
        startAt: Value(task.startAt),
        endAt: Value(task.endAt),

        scheduledDate:
            Value(task.scheduledDate),
        startTimeMinutes: Value(
          task.allDay
              ? null
              : task.startTimeMinutes,
        ),
        durationMinutes:
            Value(task.durationMinutes),

        categoryId:
            Value(task.categoryId),

        allDay:
            Value(task.allDay),
        priority:
            Value(task.priority.index),
        isCompleted: Value(
          task.recurrence.isRecurring
              ? false
              : task.isCompleted,
        ),

        recurrenceType: Value(
          task.recurrence.storageValue,
        ),
        recurrenceWeekdays: Value(
          task.recurrence.weekdaysMask,
        ),
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
        isCompleted:
            Value(completed),
      ),
    );
  }

  Future<void> setOccurrenceCompleted(
    TaskOccurrence occurrence,
    bool completed,
  ) async {
    if (!occurrence.isRecurring) {
      await setCompleted(
        occurrence.task.id,
        completed,
      );
      return;
    }

    final date =
        _dateOnly(occurrence.date);

    if (completed) {
      await _database
          .into(
            _database.taskOccurrenceStates,
          )
          .insertOnConflictUpdate(
        TaskOccurrenceStatesCompanion.insert(
          taskId:
              occurrence.task.id,
          occurrenceDate:
              date,
          isCompleted:
              const Value(true),
        ),
      );

      return;
    }

    await (_database.delete(
      _database.taskOccurrenceStates,
    )..where(
          (row) =>
              row.taskId.equals(
                occurrence.task.id,
              ) &
              row.occurrenceDate.equals(
                date,
              ),
        ))
        .go();
  }

  Stream<_TaskDataSnapshot>
      _watchTaskData() {
    final query =
        _database.select(
      _database.taskItems,
    ).join([
      leftOuterJoin(
        _database.taskOccurrenceStates,
        _database
            .taskOccurrenceStates
            .taskId
            .equalsExp(
              _database.taskItems.id,
            ),
      ),
    ]);

    return query.watch().map((rows) {
      final tasksById =
          <String, LifeTask>{};

      final completedOccurrenceKeys =
          <String>{};

      for (final result in rows) {
        final row = result.readTable(
          _database.taskItems,
        );

        tasksById.putIfAbsent(
          row.id,
          () => _taskFromRow(row),
        );

        final state =
            result.readTableOrNull(
          _database.taskOccurrenceStates,
        );

        if (state != null &&
            state.isCompleted) {
          completedOccurrenceKeys.add(
            _stateKey(
              state.taskId,
              state.occurrenceDate,
            ),
          );
        }
      }

      final tasks =
          tasksById.values.toList()
            ..sort(_compareTasks);

      return _TaskDataSnapshot(
        tasks: tasks,
        completedOccurrenceKeys:
            completedOccurrenceKeys,
      );
    });
  }

  List<TaskOccurrence>
      _buildOccurrencesInRange(
    _TaskDataSnapshot snapshot,
    DateTime start,
    DateTime end,
  ) {
    if (end.isBefore(start)) {
      return const [];
    }

    final result =
        <TaskOccurrence>[];

    for (final task in snapshot.tasks) {
      final startDate =
          task.scheduledDate;

      if (startDate == null) {
        continue;
      }

      if (!task.recurrence.isRecurring) {
        final date =
            _dateOnly(startDate);

        if (!date.isBefore(start) &&
            !date.isAfter(end)) {
          result.add(
            TaskOccurrence(
              task: task,
              date: date,
              isCompleted:
                  task.isCompleted,
            ),
          );
        }

        continue;
      }

      var cursor =
          _dateOnly(startDate);

      if (cursor.isBefore(start)) {
        cursor = start;
      }

      while (!cursor.isAfter(end)) {
        if (task.recurrence.occursOn(
          cursor,
          startDate,
        )) {
          result.add(
            TaskOccurrence(
              task: task,
              date: cursor,
              isCompleted:
                  snapshot
                      .completedOccurrenceKeys
                      .contains(
                _stateKey(
                  task.id,
                  cursor,
                ),
              ),
            ),
          );
        }

        cursor = cursor.add(
          const Duration(days: 1),
        );
      }
    }

    result.sort(
      _compareOccurrences,
    );

    return result;
  }

  List<TaskOccurrence>
      _buildScheduleOverview(
    _TaskDataSnapshot snapshot,
    DateTime now,
  ) {
    final result =
        <TaskOccurrence>[];

    for (final task in snapshot.tasks) {
      final startDate =
          task.scheduledDate;

      if (startDate == null) {
        continue;
      }

      if (!task.recurrence.isRecurring) {
        result.add(
          TaskOccurrence(
            task: task,
            date: startDate,
            isCompleted:
                task.isCompleted,
          ),
        );

        continue;
      }

      final nextDate =
          _nextRelevantOccurrenceDate(
        task,
        now,
      );

      if (nextDate == null) {
        continue;
      }

      result.add(
        TaskOccurrence(
          task: task,
          date: nextDate,
          isCompleted:
              snapshot
                  .completedOccurrenceKeys
                  .contains(
            _stateKey(
              task.id,
              nextDate,
            ),
          ),
        ),
      );
    }

    result.sort(
      _compareOccurrences,
    );

    return result;
  }

  DateTime? _nextRelevantOccurrenceDate(
    LifeTask task,
    DateTime now,
  ) {
    final startDate =
        task.scheduledDate;

    if (startDate == null ||
        !task.recurrence.isRecurring) {
      return startDate;
    }

    final today =
        _dateOnly(now);

    var cursor =
        _dateOnly(startDate);

    if (cursor.isBefore(today)) {
      cursor = today;
    }

    // Weekly ha sempre un match entro 7 giorni.
    // 370 lascia ampio margine anche per dati non validi/futuri.
    for (var i = 0;
        i < 370;
        i++) {
      if (task.recurrence.occursOn(
        cursor,
        startDate,
      )) {
        if (!_isOccurrencePast(
          task,
          cursor,
          now,
        )) {
          return cursor;
        }
      }

      cursor = cursor.add(
        const Duration(days: 1),
      );
    }

    return null;
  }

  bool _isOccurrencePast(
    LifeTask task,
    DateTime occurrenceDate,
    DateTime now,
  ) {
    final today =
        _dateOnly(now);
    final date =
        _dateOnly(occurrenceDate);

    if (date.isBefore(today)) {
      return true;
    }

    if (date.isAfter(today)) {
      return false;
    }

    if (task.allDay ||
        task.startTimeMinutes == null) {
      return false;
    }

    final endMinutes =
        task.startTimeMinutes! +
        (task.durationMinutes ?? 0);

    final endMoment = date.add(
      Duration(
        minutes: endMinutes,
      ),
    );

    return now.isAfter(
      endMoment,
    );
  }

  int _compareOccurrences(
    TaskOccurrence a,
    TaskOccurrence b,
  ) {
    final dateComparison =
        a.date.compareTo(b.date);

    if (dateComparison != 0) {
      return dateComparison;
    }

    if (a.task.allDay !=
        b.task.allDay) {
      return a.task.allDay
          ? -1
          : 1;
    }

    final aTime =
        a.task.startTimeMinutes;
    final bTime =
        b.task.startTimeMinutes;

    if (aTime == null &&
        bTime != null) {
      return -1;
    }

    if (aTime != null &&
        bTime == null) {
      return 1;
    }

    if (aTime != null &&
        bTime != null) {
      final timeComparison =
          aTime.compareTo(bTime);

      if (timeComparison != 0) {
        return timeComparison;
      }
    }

    return a.task.title
        .toLowerCase()
        .compareTo(
          b.task.title.toLowerCase(),
        );
  }

  int _compareTasks(
    LifeTask a,
    LifeTask b,
  ) {
    final aDate =
        a.scheduledDate;
    final bDate =
        b.scheduledDate;

    if (aDate == null &&
        bDate != null) {
      return 1;
    }

    if (aDate != null &&
        bDate == null) {
      return -1;
    }

    if (aDate != null &&
        bDate != null) {
      final dateComparison =
          aDate.compareTo(bDate);

      if (dateComparison != 0) {
        return dateComparison;
      }
    }

    if (a.allDay != b.allDay) {
      return a.allDay
          ? -1
          : 1;
    }

    final aTime =
        a.startTimeMinutes;
    final bTime =
        b.startTimeMinutes;

    if (aTime == null &&
        bTime != null) {
      return -1;
    }

    if (aTime != null &&
        bTime == null) {
      return 1;
    }

    if (aTime != null &&
        bTime != null) {
      final timeComparison =
          aTime.compareTo(bTime);

      if (timeComparison != 0) {
        return timeComparison;
      }
    }

    return a.title
        .toLowerCase()
        .compareTo(
          b.title.toLowerCase(),
        );
  }

  LifeTask _taskFromRow(
    TaskItem row,
  ) {
    final fallbackDate =
        row.startAt == null
            ? null
            : DateTime(
                row.startAt!.year,
                row.startAt!.month,
                row.startAt!.day,
              );

    final scheduledDate =
        row.scheduledDate ??
            fallbackDate;

    int? startTimeMinutes =
        row.startTimeMinutes;

    if (startTimeMinutes == null &&
        !row.allDay &&
        row.startAt != null) {
      final oldStart =
          row.startAt!;

      final hasExplicitTime =
          oldStart.hour != 0 ||
          oldStart.minute != 0 ||
          oldStart.second != 0 ||
          row.endAt != null;

      if (hasExplicitTime) {
        startTimeMinutes =
            oldStart.hour * 60 +
                oldStart.minute;
      }
    }

    int? durationMinutes =
        row.durationMinutes;

    if (durationMinutes == null &&
        row.startAt != null &&
        row.endAt != null) {
      final difference =
          row.endAt!.difference(
        row.startAt!,
      );

      if (difference.inMinutes > 0) {
        durationMinutes =
            difference.inMinutes;
      }
    }

    return LifeTask(
      id: row.id,
      title: row.title,
      description:
          row.description,
      scheduledDate:
          scheduledDate,
      startTimeMinutes:
          startTimeMinutes,
      durationMinutes:
          durationMinutes,
      categoryId:
          row.categoryId,
      allDay:
          row.allDay,
      priority:
          _priorityFromInt(
        row.priority,
      ),
      recurrence:
          TaskRecurrence.fromStorage(
        row.recurrenceType,
        row.recurrenceWeekdays,
      ),
      isCompleted:
          row.isCompleted,
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

  DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  String _stateKey(
    String taskId,
    DateTime date,
  ) {
    final normalized =
        _dateOnly(date);

    return '$taskId@'
        '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}

class _TaskDataSnapshot {
  final List<LifeTask> tasks;
  final Set<String>
      completedOccurrenceKeys;

  const _TaskDataSnapshot({
    required this.tasks,
    required this.completedOccurrenceKeys,
  });
}
