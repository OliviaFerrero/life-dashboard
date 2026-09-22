import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/life_task.dart';
import '../models/task_occurrence.dart';
import '../models/task_recurrence.dart';
import '../models/task_subtask.dart';

class TaskRepository {
  final AppDatabase _database;

  TaskRepository(this._database);

  Stream<List<LifeTask>> watchAllTasks() {
    return _watchTaskData().map(
      (snapshot) => snapshot.tasks,
    );
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
    await _database.transaction(() async {
      await _database
          .into(_database.taskItems)
          .insert(
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

      await _syncSubtasks(
        task,
      );
    });
  }

  Future<void> updateTask(
    LifeTask task,
  ) async {
    await _database.transaction(() async {
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

      await _syncSubtasks(
        task,
      );
    });
  }

  Future<void> _syncSubtasks(
    LifeTask task,
  ) async {
    final existing =
        await (_database.select(
      _database.taskSubtasks,
    )..where(
              (row) =>
                  row.taskId.equals(task.id),
            ))
            .get();

    final incomingIds =
        task.subtasks
            .map(
              (subtask) =>
                  subtask.id,
            )
            .toSet();

    for (final row in existing) {
      if (!incomingIds.contains(
        row.id,
      )) {
        await (_database.delete(
          _database.taskSubtasks,
        )..where(
              (item) =>
                  item.id.equals(row.id),
            ))
            .go();
      }
    }

    for (var index = 0;
        index < task.subtasks.length;
        index++) {
      final subtask =
          task.subtasks[index];

      await _database
          .into(
            _database.taskSubtasks,
          )
          .insertOnConflictUpdate(
        TaskSubtasksCompanion.insert(
          id: subtask.id,
          taskId: task.id,
          title: subtask.title,
          sortOrder:
              Value(index),
          isCompleted: Value(
            task.recurrence.isRecurring
                ? false
                : subtask.isCompleted,
          ),
        ),
      );
    }
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

  /// Completion della task NON ricorrente.
  ///
  /// Quando si completa il parent vengono completate anche tutte le
  /// sottoattività ancora aperte. Quando si riapre il parent, invece,
  /// gli stati delle sottoattività restano invariati.
  Future<void> setCompleted(
    String id,
    bool completed,
  ) async {
    await _database.transaction(() async {
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

      if (completed) {
        await (_database.update(
          _database.taskSubtasks,
        )..where(
              (row) =>
                  row.taskId.equals(id),
            ))
            .write(
          const TaskSubtasksCompanion(
            isCompleted:
                Value(true),
          ),
        );
      }
    });
  }

  /// Salva una modifica che vale solo per una singola occorrenza.
  ///
  /// [occurrence.seriesDate] resta l'identità stabile della serie,
  /// mentre [editedTask.scheduledDate] diventa la data effettiva mostrata.
  Future<void> saveOccurrenceOverride({
    required TaskOccurrence occurrence,
    required LifeTask editedTask,
  }) async {
    if (!occurrence.isRecurring) {
      throw ArgumentError(
        'Gli override sono disponibili solo per task ricorrenti.',
      );
    }

    final effectiveDate =
        editedTask.scheduledDate;

    if (effectiveDate == null) {
      throw ArgumentError(
        'Una singola occorrenza deve avere una data.',
      );
    }

    await _database
        .into(
          _database.taskOccurrenceOverrides,
        )
        .insertOnConflictUpdate(
      TaskOccurrenceOverridesCompanion.insert(
        taskId:
            occurrence.task.id,
        occurrenceDate:
            _dateOnly(occurrence.seriesDate),
        effectiveDate:
            _dateOnly(effectiveDate),
        title:
            editedTask.title,
        description:
            Value(editedTask.description),
        startTimeMinutes:
            Value(
          editedTask.allDay
              ? null
              : editedTask.startTimeMinutes,
        ),
        durationMinutes:
            Value(editedTask.durationMinutes),
        categoryId:
            Value(editedTask.categoryId),
        allDay:
            Value(editedTask.allDay),
        priority:
            Value(editedTask.priority.index),
        isDeleted:
            const Value(false),
      ),
    );
  }

  /// Esclude una sola occorrenza dalla serie senza toccare le altre.
  ///
  /// Gli stati completato/subtasks restano collegati alla data originaria,
  /// così un eventuale futuro ripristino dell'eccezione non li ricollega
  /// a un'altra occorrenza.
  Future<void> deleteOccurrence(
    TaskOccurrence occurrence,
  ) async {
    if (!occurrence.isRecurring) {
      await deleteTask(
        occurrence.task.id,
      );
      return;
    }

    final effective =
        occurrence.displayTask;

    await _database
        .into(
          _database.taskOccurrenceOverrides,
        )
        .insertOnConflictUpdate(
      TaskOccurrenceOverridesCompanion.insert(
        taskId:
            occurrence.task.id,
        occurrenceDate:
            _dateOnly(occurrence.seriesDate),
        effectiveDate:
            _dateOnly(occurrence.date),
        title:
            effective.title,
        description:
            Value(effective.description),
        startTimeMinutes:
            Value(
          effective.allDay
              ? null
              : effective.startTimeMinutes,
        ),
        durationMinutes:
            Value(effective.durationMinutes),
        categoryId:
            Value(effective.categoryId),
        allDay:
            Value(effective.allDay),
        priority:
            Value(effective.priority.index),
        isDeleted:
            const Value(true),
      ),
    );
  }

  /// Completion della singola occorrenza di una task ricorrente.
  ///
  /// Completando il parent vengono completate anche tutte le
  /// sottoattività di QUELLA occorrenza.
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
        _dateOnly(occurrence.seriesDate);

    await _database.transaction(() async {
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

        final subtasks =
            await (_database.select(
          _database.taskSubtasks,
        )..where(
                  (row) =>
                      row.taskId.equals(
                        occurrence.task.id,
                      ),
                ))
                .get();

        for (final subtask in subtasks) {
          await _database
              .into(
                _database
                    .taskSubtaskOccurrenceStates,
              )
              .insertOnConflictUpdate(
            TaskSubtaskOccurrenceStatesCompanion
                .insert(
              subtaskId:
                  subtask.id,
              occurrenceDate:
                  date,
              isCompleted:
                  const Value(true),
            ),
          );
        }

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
    });
  }

  /// Cambia lo stato di una singola sottoattività.
  ///
  /// Per le task ricorrenti lo stato è legato alla data
  /// dell'occorrenza. Per le task singole viene salvato direttamente
  /// sulla definizione della sottoattività.
  Future<void> setSubtaskCompleted({
    required LifeTask task,
    required TaskSubtask subtask,
    required bool completed,
    DateTime? occurrenceDate,
  }) async {
    if (!task.recurrence.isRecurring) {
      await (_database.update(
        _database.taskSubtasks,
      )..where(
            (row) =>
                row.id.equals(subtask.id) &
                row.taskId.equals(task.id),
          ))
          .write(
        TaskSubtasksCompanion(
          isCompleted:
              Value(completed),
        ),
      );

      return;
    }

    if (occurrenceDate == null) {
      throw ArgumentError(
        'Una sottoattività ricorrente richiede occurrenceDate.',
      );
    }

    final date =
        _dateOnly(occurrenceDate);

    if (completed) {
      await _database
          .into(
            _database
                .taskSubtaskOccurrenceStates,
          )
          .insertOnConflictUpdate(
        TaskSubtaskOccurrenceStatesCompanion
            .insert(
          subtaskId:
              subtask.id,
          occurrenceDate:
              date,
          isCompleted:
              const Value(true),
        ),
      );

      return;
    }

    await (_database.delete(
      _database
          .taskSubtaskOccurrenceStates,
    )..where(
          (row) =>
              row.subtaskId.equals(
                subtask.id,
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
      leftOuterJoin(
        _database.taskSubtasks,
        _database
            .taskSubtasks
            .taskId
            .equalsExp(
              _database.taskItems.id,
            ),
      ),
      leftOuterJoin(
        _database
            .taskSubtaskOccurrenceStates,
        _database
            .taskSubtaskOccurrenceStates
            .subtaskId
            .equalsExp(
              _database.taskSubtasks.id,
            ),
      ),
      leftOuterJoin(
        _database.taskOccurrenceOverrides,
        _database
            .taskOccurrenceOverrides
            .taskId
            .equalsExp(
              _database.taskItems.id,
            ),
      ),
    ]);

    return query.watch().map((rows) {
      final taskRowsById =
          <String, TaskItem>{};

      final subtasksByTaskId =
          <String, Map<String, TaskSubtask>>{};

      final completedOccurrenceKeys =
          <String>{};

      final completedSubtaskOccurrenceKeys =
          <String>{};

      final overridesByTaskId =
          <String,
              Map<String, TaskOccurrenceOverrideRow>>{};

      for (final result in rows) {
        final taskRow =
            result.readTable(
          _database.taskItems,
        );

        taskRowsById.putIfAbsent(
          taskRow.id,
          () => taskRow,
        );

        final occurrenceState =
            result.readTableOrNull(
          _database.taskOccurrenceStates,
        );

        if (occurrenceState != null &&
            occurrenceState.isCompleted) {
          completedOccurrenceKeys.add(
            _stateKey(
              occurrenceState.taskId,
              occurrenceState.occurrenceDate,
            ),
          );
        }

        final subtaskRow =
            result.readTableOrNull(
          _database.taskSubtasks,
        );

        if (subtaskRow != null) {
          subtasksByTaskId
              .putIfAbsent(
                taskRow.id,
                () =>
                    <String, TaskSubtask>{},
              )
              .putIfAbsent(
                subtaskRow.id,
                () => TaskSubtask(
                  id: subtaskRow.id,
                  title:
                      subtaskRow.title,
                  sortOrder:
                      subtaskRow.sortOrder,
                  isCompleted:
                      subtaskRow
                          .isCompleted,
                ),
              );
        }

        final subtaskState =
            result.readTableOrNull(
          _database
              .taskSubtaskOccurrenceStates,
        );

        if (subtaskState != null &&
            subtaskState.isCompleted) {
          completedSubtaskOccurrenceKeys.add(
            _subtaskStateKey(
              subtaskState.subtaskId,
              subtaskState.occurrenceDate,
            ),
          );
        }

        final override =
            result.readTableOrNull(
          _database.taskOccurrenceOverrides,
        );

        if (override != null) {
          overridesByTaskId
              .putIfAbsent(
                taskRow.id,
                () => <
                    String,
                    TaskOccurrenceOverrideRow>{},
              )[_stateKey(
                taskRow.id,
                override.occurrenceDate,
              )] =
              override;
        }
      }

      final tasks =
          <LifeTask>[];

      for (final entry
          in taskRowsById.entries) {
        final subtasks =
            subtasksByTaskId[entry.key]
                    ?.values
                    .toList() ??
                <TaskSubtask>[];

        subtasks.sort(
          (a, b) {
            final order =
                a.sortOrder.compareTo(
              b.sortOrder,
            );

            if (order != 0) {
              return order;
            }

            return a.title
                .toLowerCase()
                .compareTo(
                  b.title.toLowerCase(),
                );
          },
        );

        tasks.add(
          _taskFromRow(
            entry.value,
            subtasks:
                subtasks,
          ),
        );
      }

      tasks.sort(
        _compareTasks,
      );

      return _TaskDataSnapshot(
        tasks: tasks,
        completedOccurrenceKeys:
            completedOccurrenceKeys,
        completedSubtaskOccurrenceKeys:
            completedSubtaskOccurrenceKeys,
        overridesByTaskId:
            overridesByTaskId,
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
              seriesDate: date,
              isCompleted:
                  task.isCompleted,
              subtasks:
                  task.subtasks,
            ),
          );
        }

        continue;
      }

      final taskOverrides =
          snapshot.overridesByTaskId[
                task.id] ??
              const <
                  String,
                  TaskOccurrenceOverrideRow>{};

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
          final key =
              _stateKey(
            task.id,
            cursor,
          );

          // Le eccezioni vengono aggiunte separatamente usando la
          // loro data effettiva. Qui evitiamo il doppione base.
          if (!taskOverrides.containsKey(
            key,
          )) {
            result.add(
              _buildBaseOccurrence(
                task,
                cursor,
                snapshot,
              ),
            );
          }
        }

        cursor = cursor.add(
          const Duration(days: 1),
        );
      }

      for (final override
          in taskOverrides.values) {
        final seriesDate =
            _dateOnly(
          override.occurrenceDate,
        );

        // Se la definizione della serie è stata cambiata e la vecchia
        // data non appartiene più alla regola, l'eccezione resta
        // persistita ma non viene applicata.
        if (!task.recurrence.occursOn(
          seriesDate,
          startDate,
        )) {
          continue;
        }

        if (override.isDeleted) {
          continue;
        }

        final effectiveDate =
            _dateOnly(
          override.effectiveDate,
        );

        if (effectiveDate.isBefore(start) ||
            effectiveDate.isAfter(end)) {
          continue;
        }

        result.add(
          _buildOverrideOccurrence(
            task,
            override,
            snapshot,
          ),
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
            seriesDate: startDate,
            isCompleted:
                task.isCompleted,
            subtasks:
                task.subtasks,
          ),
        );

        continue;
      }

      final next =
          _nextRelevantOccurrence(
        task,
        snapshot,
        now,
      );

      if (next != null) {
        result.add(
          next,
        );
      }
    }

    result.sort(
      _compareOccurrences,
    );

    return result;
  }

  TaskOccurrence _buildBaseOccurrence(
    LifeTask task,
    DateTime seriesDate,
    _TaskDataSnapshot snapshot,
  ) {
    final normalized =
        _dateOnly(seriesDate);

    return TaskOccurrence(
      task: task,
      date: normalized,
      seriesDate: normalized,
      isCompleted:
          snapshot
              .completedOccurrenceKeys
              .contains(
        _stateKey(
          task.id,
          normalized,
        ),
      ),
      subtasks:
          _effectiveSubtasksForOccurrence(
        task,
        normalized,
        snapshot,
      ),
    );
  }

  TaskOccurrence _buildOverrideOccurrence(
    LifeTask task,
    TaskOccurrenceOverrideRow override,
    _TaskDataSnapshot snapshot,
  ) {
    final seriesDate =
        _dateOnly(
      override.occurrenceDate,
    );

    final effectiveDate =
        _dateOnly(
      override.effectiveDate,
    );

    final subtasks =
        _effectiveSubtasksForOccurrence(
      task,
      seriesDate,
      snapshot,
    );

    final effectiveTask =
        LifeTask(
      id:
          task.id,
      title:
          override.title,
      description:
          override.description,
      scheduledDate:
          effectiveDate,
      startTimeMinutes:
          override.allDay
              ? null
              : override.startTimeMinutes,
      durationMinutes:
          override.durationMinutes,
      categoryId:
          override.categoryId,
      allDay:
          override.allDay,
      priority:
          _priorityFromInt(
        override.priority,
      ),
      recurrence:
          task.recurrence,
      subtasks:
          subtasks,
      isCompleted:
          false,
    );

    return TaskOccurrence(
      task: task,
      date: effectiveDate,
      seriesDate: seriesDate,
      isCompleted:
          snapshot
              .completedOccurrenceKeys
              .contains(
        _stateKey(
          task.id,
          seriesDate,
        ),
      ),
      subtasks:
          subtasks,
      effectiveTask:
          effectiveTask,
    );
  }

  TaskOccurrence? _nextRelevantOccurrence(
    LifeTask task,
    _TaskDataSnapshot snapshot,
    DateTime now,
  ) {
    final startDate =
        task.scheduledDate;

    if (startDate == null ||
        !task.recurrence.isRecurring) {
      return null;
    }

    final candidates =
        <TaskOccurrence>[];

    final taskOverrides =
        snapshot.overridesByTaskId[
              task.id] ??
            const <
                String,
                TaskOccurrenceOverrideRow>{};

    // Le eccezioni possono provenire anche da una data originaria
    // precedente e essere state spostate nel futuro.
    for (final override
        in taskOverrides.values) {
      final seriesDate =
          _dateOnly(
        override.occurrenceDate,
      );

      if (override.isDeleted ||
          !task.recurrence.occursOn(
            seriesDate,
            startDate,
          )) {
        continue;
      }

      final occurrence =
          _buildOverrideOccurrence(
        task,
        override,
        snapshot,
      );

      if (!_isOccurrencePast(
        occurrence.displayTask,
        occurrence.date,
        now,
      )) {
        candidates.add(
          occurrence,
        );
      }
    }

    final today =
        _dateOnly(now);

    var cursor =
        _dateOnly(startDate);

    if (cursor.isBefore(today)) {
      cursor = today;
    }

    // Ogni eccezione può "occupare" una data base. Allunghiamo il
    // margine in base al numero di eccezioni per trovare comunque
    // una prossima occorrenza non esclusa.
    final maxSteps =
        370 +
        taskOverrides.length * 7;

    for (var i = 0;
        i < maxSteps;
        i++) {
      if (task.recurrence.occursOn(
        cursor,
        startDate,
      )) {
        final key =
            _stateKey(
          task.id,
          cursor,
        );

        if (!taskOverrides.containsKey(
          key,
        )) {
          final occurrence =
              _buildBaseOccurrence(
            task,
            cursor,
            snapshot,
          );

          if (!_isOccurrencePast(
            occurrence.displayTask,
            occurrence.date,
            now,
          )) {
            candidates.add(
              occurrence,
            );
            break;
          }
        }
      }

      cursor = cursor.add(
        const Duration(days: 1),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      _compareOccurrences,
    );

    return candidates.first;
  }

  List<TaskSubtask>
      _effectiveSubtasksForOccurrence(
    LifeTask task,
    DateTime date,
    _TaskDataSnapshot snapshot,
  ) {
    if (!task.recurrence.isRecurring) {
      return task.subtasks;
    }

    return [
      for (final subtask
          in task.subtasks)
        subtask.copyWith(
          isCompleted:
              snapshot
                  .completedSubtaskOccurrenceKeys
                  .contains(
            _subtaskStateKey(
              subtask.id,
              date,
            ),
          ),
        ),
    ];
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

    final aTask =
        a.displayTask;
    final bTask =
        b.displayTask;

    if (aTask.allDay !=
        bTask.allDay) {
      return aTask.allDay
          ? -1
          : 1;
    }

    final aTime =
        aTask.startTimeMinutes;
    final bTime =
        bTask.startTimeMinutes;

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

    return aTask.title
        .toLowerCase()
        .compareTo(
          bTask.title.toLowerCase(),
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
    TaskItem row, {
    List<TaskSubtask> subtasks =
        const [],
  }) {
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
      subtasks:
          subtasks,
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

  String _subtaskStateKey(
    String subtaskId,
    DateTime date,
  ) {
    final normalized =
        _dateOnly(date);

    return '$subtaskId@'
        '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}

class _TaskDataSnapshot {
  final List<LifeTask> tasks;
  final Set<String>
      completedOccurrenceKeys;
  final Set<String>
      completedSubtaskOccurrenceKeys;
  final Map<
      String,
      Map<String, TaskOccurrenceOverrideRow>>
      overridesByTaskId;

  const _TaskDataSnapshot({
    required this.tasks,
    required this.completedOccurrenceKeys,
    required this.completedSubtaskOccurrenceKeys,
    required this.overridesByTaskId,
  });
}
