import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/database/app_database.dart';

/// Verifica l'upgrade verso lo schema Drift v6 a partire da database già
/// popolati, senza usare né modificare il database reale dell'app.
///
/// Le strutture SQL v1-v5 sono fixture ricostruite dalle dichiarazioni
/// storiche di app_database.dart presenti nei commit GitHub:
/// v1 b85784361348, v2 2cc738f56e34, v3 93c0be4f303e,
/// v4 edb794e1c837, v5 62bede1ceb13.
///
/// Non sostituiscono gli snapshot di schema generati da drift_dev: per un
/// confronto strutturale formale saranno necessari i relativi export.
void main() {
  group('Data preservation: historical database upgrades to v6', () {
    for (var originalVersion = 1; originalVersion <= 5; originalVersion++) {
      test('v$originalVersion -> v6 preserves existing user data', () async {
        // Il setup SQLite viene eseguito PRIMA che AppDatabase apra il DB.
        // PRAGMA user_version forza il normale percorso onUpgrade.
        final executor = NativeDatabase.memory(
          setup: (sqlite) {
            void execute(String sql) => sqlite.execute(sql);

            _createHistoricalSchema(originalVersion, execute);
            _insertHistoricalData(originalVersion, execute);
            execute('PRAGMA user_version = $originalVersion');
          },
        );

        final db = AppDatabase(executor);
        addTearDown(db.close);

        // Questa è la prima operazione Drift: deve eseguire onUpgrade.
        final currentVersion = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(currentVersion.read<int>('user_version'), 6);
        expect(db.schemaVersion, 6);

        final tasks = await db.select(db.taskItems).get();
        expect(tasks.length, originalVersion >= 4 ? 3 : 2);

        final legacy = tasks.singleWhere((task) => task.id == 'legacy-event');
        expect(legacy.title, 'Attività storica');
        expect(legacy.description, 'Note da conservare');
        expect(legacy.priority, 2);
        expect(legacy.isCompleted, false);
        expect(legacy.allDay, false);
        expect(legacy.scheduledDate, isNotNull);
        expect(legacy.scheduledDate!.year, 2025);
        expect(legacy.scheduledDate!.month, 8);
        expect(legacy.scheduledDate!.day, 18);
        expect(legacy.startTimeMinutes, 9 * 60 + 10);
        expect(legacy.durationMinutes, 90);

        // V1 usava le vecchie colonne startAt/endAt: l'orario 00:00
        // senza endAt non rappresentava un orario esplicitamente scelto.
        final midnight = tasks.singleWhere((task) => task.id == 'midnight');
        expect(midnight.description, 'Nessun orario esplicito');
        expect(midnight.scheduledDate, isNotNull);
        expect(midnight.scheduledDate!.day, 19);
        expect(midnight.startTimeMinutes, isNull);
        expect(midnight.durationMinutes, isNull);

        final categories = await db.select(db.taskCategories).get();
        if (originalVersion < 3) {
          // La migrazione crea e popola le categorie di default.
          expect(categories.length, 5);
          expect(
            categories.map((category) => category.id),
            containsAll(['personal', 'work', 'health', 'study', 'errands']),
          );
          expect(legacy.categoryId, isNull);
        } else {
          final custom = categories.singleWhere(
            (category) => category.id == 'custom-category',
          );
          expect(custom.name, 'Categoria personale');
          expect(custom.colorValue, 0xFF123456);
          expect(legacy.categoryId, 'custom-category');
        }

        if (originalVersion >= 4) {
          final recurring = tasks.singleWhere(
            (task) => task.id == 'recurring-series',
          );
          expect(recurring.recurrenceType, 'weekly');
          expect(recurring.recurrenceWeekdays, 1);
          expect(recurring.scheduledDate, isNotNull);

          final states = await db.select(db.taskOccurrenceStates).get();
          expect(states.length, 1);
          expect(states.single.taskId, 'recurring-series');
          expect(states.single.isCompleted, true);
          expect(states.single.occurrenceDate.day, 18);
        }

        if (originalVersion >= 5) {
          final subtasks = await db.select(db.taskSubtasks).get();
          expect(subtasks.length, 3);
          final completed = subtasks.singleWhere(
            (subtask) => subtask.id == 'step-completed',
          );
          final open = subtasks.singleWhere(
            (subtask) => subtask.id == 'step-open',
          );
          expect(completed.taskId, 'legacy-event');
          expect(completed.title, 'Passaggio concluso');
          expect(completed.isCompleted, true);
          expect(open.taskId, 'legacy-event');
          expect(open.isCompleted, false);
          expect(open.sortOrder, 1);

          final recurringStates = await db
              .select(db.taskSubtaskOccurrenceStates)
              .get();
          expect(recurringStates.length, 1);
          expect(recurringStates.single.subtaskId, 'step-recurring');
          expect(recurringStates.single.isCompleted, true);
          expect(recurringStates.single.occurrenceDate.day, 18);
        }

        // La sesta tabella, introdotta dalla v6, deve esistere e restare
        // vuota. La migrazione non deve inventare override di ricorrenza.
        expect(await db.select(db.taskOccurrenceOverrides).get(), isEmpty);

        final tables = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name NOT LIKE 'sqlite_%'",
            )
            .get();
        expect(
          tables.map((row) => row.read<String>('name')),
          containsAll([
            'task_items',
            'task_categories',
            'task_occurrence_states',
            'task_subtasks',
            'task_subtask_occurrence_states',
            'task_occurrence_overrides',
          ]),
        );

        final taskColumns = await db
            .customSelect('PRAGMA table_info(task_items)')
            .get();
        expect(
          taskColumns.map((row) => row.read<String>('name')),
          containsAll([
            'scheduled_date',
            'start_time_minutes',
            'duration_minutes',
            'category_id',
            'recurrence_type',
            'recurrence_weekdays',
          ]),
        );

        final foreignKeys = await db
            .customSelect('PRAGMA foreign_keys')
            .getSingle();
        expect(foreignKeys.read<int>('foreign_keys'), 1);

        final violations = await db
            .customSelect('PRAGMA foreign_key_check')
            .get();
        expect(violations, isEmpty);

        final integrity = await db
            .customSelect('PRAGMA integrity_check')
            .getSingle();
        expect(integrity.read<String>('integrity_check'), 'ok');
      });
    }
  });
}

void _createHistoricalSchema(int version, void Function(String) execute) {
  assert(version >= 1 && version <= 5);

  // Stesse tabelle/colonne/default/PK/FK delle dichiarazioni Drift
  // conservate nei commit storici indicati sopra.
  if (version >= 3) {
    execute('''
      CREATE TABLE task_categories (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_key TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      )
    ''');
  }

  final columns = <String>[
    'id TEXT NOT NULL',
    'title TEXT NOT NULL',
    "description TEXT NOT NULL DEFAULT ''",
    'start_at INTEGER',
    'end_at INTEGER',
    if (version >= 2) ...[
      'scheduled_date INTEGER',
      'start_time_minutes INTEGER',
      'duration_minutes INTEGER',
    ],
    if (version >= 3)
      'category_id TEXT REFERENCES task_categories (id) ON DELETE SET NULL',
    'all_day INTEGER NOT NULL DEFAULT 0',
    'priority INTEGER NOT NULL DEFAULT 1',
    'is_completed INTEGER NOT NULL DEFAULT 0',
    if (version >= 4) ...[
      "recurrence_type TEXT NOT NULL DEFAULT 'none'",
      'recurrence_weekdays INTEGER NOT NULL DEFAULT 0',
    ],
    "created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))",
    'PRIMARY KEY (id)',
  ];
  execute('CREATE TABLE task_items (${columns.join(', ')})');

  if (version >= 4) {
    execute('''
      CREATE TABLE task_occurrence_states (
        task_id TEXT NOT NULL REFERENCES task_items (id) ON DELETE CASCADE,
        occurrence_date INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (task_id, occurrence_date)
      )
    ''');
  }

  if (version >= 5) {
    execute('''
      CREATE TABLE task_subtasks (
        id TEXT NOT NULL,
        task_id TEXT NOT NULL REFERENCES task_items (id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      )
    ''');
    execute('''
      CREATE TABLE task_subtask_occurrence_states (
        subtask_id TEXT NOT NULL REFERENCES task_subtasks (id) ON DELETE CASCADE,
        occurrence_date INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (subtask_id, occurrence_date)
      )
    ''');
  }
}

void _insertHistoricalData(int version, void Function(String) execute) {
  final start = _asSqlDateTime(DateTime(2025, 8, 18, 9, 10));
  final end = _asSqlDateTime(DateTime(2025, 8, 18, 10, 40));
  final firstDay = _asSqlDateTime(DateTime(2025, 8, 18));
  final nextDay = _asSqlDateTime(DateTime(2025, 8, 19));

  execute('''
    INSERT INTO task_items (
      id, title, description, start_at, end_at, all_day, priority, is_completed
    ) VALUES (
      'legacy-event', 'Attività storica', 'Note da conservare',
      $start, $end, 0, 2, 0
    )
  ''');
  execute('''
    INSERT INTO task_items (
      id, title, description, start_at, all_day, priority, is_completed
    ) VALUES (
      'midnight', 'Senza orario', 'Nessun orario esplicito',
      $nextDay, 0, 1, 0
    )
  ''');

  if (version >= 2) {
    execute('''
      UPDATE task_items SET
        scheduled_date = $firstDay,
        start_time_minutes = 550,
        duration_minutes = 90
      WHERE id = 'legacy-event'
    ''');
    execute('''
      UPDATE task_items SET scheduled_date = $nextDay
      WHERE id = 'midnight'
    ''');
  }

  if (version >= 3) {
    for (final category in ['personal', 'work', 'health', 'study', 'errands']) {
      execute('''
        INSERT INTO task_categories (
          id, name, color_value, icon_key, sort_order
        ) VALUES (
          '$category', '$category', 4284900966, 'label_outline', 0
        )
      ''');
    }
    execute('''
      INSERT INTO task_categories (
        id, name, color_value, icon_key, sort_order
      ) VALUES (
        'custom-category', 'Categoria personale', 4279383126,
        'star_outline', 7
      )
    ''');
    execute('''
      UPDATE task_items SET category_id = 'custom-category'
      WHERE id = 'legacy-event'
    ''');
  }

  if (version >= 4) {
    execute('''
      INSERT INTO task_items (id, title, description, all_day, priority,
          is_completed, scheduled_date, start_time_minutes, duration_minutes,
          recurrence_type, recurrence_weekdays)
      VALUES ('recurring-series', 'Attività ricorrente', 'Ripetizione',
          0, 1, 0, $firstDay, 600, 30, 'weekly', 1)
    ''');
    execute('''
      INSERT INTO task_occurrence_states (
        task_id, occurrence_date, is_completed
      ) VALUES ('recurring-series', $firstDay, 1)
    ''');
  }

  if (version >= 5) {
    execute('''
      INSERT INTO task_subtasks (id, task_id, title, sort_order, is_completed)
      VALUES ('step-completed', 'legacy-event', 'Passaggio concluso', 0, 1)
    ''');
    execute('''
      INSERT INTO task_subtasks (id, task_id, title, sort_order, is_completed)
      VALUES ('step-open', 'legacy-event', 'Passaggio aperto', 1, 0)
    ''');
    execute('''
      INSERT INTO task_subtasks (id, task_id, title, sort_order, is_completed)
      VALUES ('step-recurring', 'recurring-series', 'Passaggio ricorrente', 0, 0)
    ''');
    execute('''
      INSERT INTO task_subtask_occurrence_states (
        subtask_id, occurrence_date, is_completed
      ) VALUES ('step-recurring', $firstDay, 1)
    ''');
  }
}

int _asSqlDateTime(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
