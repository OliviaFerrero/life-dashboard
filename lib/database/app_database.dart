import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('TaskCategoryRow')
class TaskCategories extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get colorValue => integer()();

  TextColumn get iconKey => text()();

  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskItems extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get description =>
      text().withDefault(const Constant(''))();

  /// Colonne legacy mantenute per una migrazione sicura e per
  /// retrocompatibilità interna. Il nuovo modello usa i tre campi
  /// scheduledDate / startTimeMinutes / durationMinutes.
  DateTimeColumn get startAt => dateTime().nullable()();

  DateTimeColumn get endAt => dateTime().nullable()();

  DateTimeColumn get scheduledDate => dateTime().nullable()();

  IntColumn get startTimeMinutes => integer().nullable()();

  IntColumn get durationMinutes => integer().nullable()();

  /// Null significa "Nessuna categoria".
  ///
  /// Se una categoria viene eliminata, il task resta esistente e
  /// categoryId torna automaticamente a null.
  TextColumn get categoryId => text()
      .nullable()
      .references(
        TaskCategories,
        #id,
        onDelete: KeyAction.setNull,
      )();

  BoolColumn get allDay =>
      boolean().withDefault(const Constant(false))();

  /// Valori persistiti stabili:
  /// 0 = low, 1 = normal, 2 = high.
  ///
  /// Non dipende dall'ordine dichiarativo dell'enum Dart.
  IntColumn get priority =>
      integer().withDefault(const Constant(1))();

  /// Stato usato dalle task NON ricorrenti.
  ///
  /// Per le task ricorrenti lo stato viene salvato in
  /// TaskOccurrenceStates, una riga per singola occorrenza completata.
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Valori stabili: none / daily / weekly.
  TextColumn get recurrenceType =>
      text().withDefault(const Constant('none'))();

  /// Bit mask: bit 0 = lunedì ... bit 6 = domenica.
  IntColumn get recurrenceWeekdays =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskSubtaskRow')
class TaskSubtasks extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(
        TaskItems,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get title => text()();

  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  /// Stato usato dalle task NON ricorrenti.
  ///
  /// Per le task ricorrenti lo stato effettivo viene salvato in
  /// TaskSubtaskOccurrenceStates.
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskSubtaskOccurrenceStateRow')
class TaskSubtaskOccurrenceStates extends Table {
  TextColumn get subtaskId => text().references(
        TaskSubtasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Giorno specifico dell'occorrenza, normalizzato a mezzanotte locale.
  DateTimeColumn get occurrenceDate => dateTime()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {
        subtaskId,
        occurrenceDate,
      };
}

@DataClassName('TaskOccurrenceStateRow')
class TaskOccurrenceStates extends Table {
  TextColumn get taskId => text().references(
        TaskItems,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Giorno specifico dell'occorrenza, normalizzato a mezzanotte locale.
  DateTimeColumn get occurrenceDate => dateTime()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {
        taskId,
        occurrenceDate,
      };
}


@DataClassName('TaskOccurrenceOverrideRow')
class TaskOccurrenceOverrides extends Table {
  TextColumn get taskId => text().references(
        TaskItems,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Data originaria generata dalla regola della serie.
  ///
  /// Rimane stabile anche quando l'occorrenza viene spostata a un
  /// altro giorno ed è quindi l'identità dell'eccezione.
  DateTimeColumn get occurrenceDate => dateTime()();

  /// Data effettiva mostrata all'utente per questa sola occorrenza.
  DateTimeColumn get effectiveDate => dateTime()();

  TextColumn get title => text()();

  TextColumn get description =>
      text().withDefault(const Constant(''))();

  IntColumn get startTimeMinutes => integer().nullable()();

  IntColumn get durationMinutes => integer().nullable()();

  TextColumn get categoryId => text()
      .nullable()
      .references(
        TaskCategories,
        #id,
        onDelete: KeyAction.setNull,
      )();

  BoolColumn get allDay =>
      boolean().withDefault(const Constant(false))();

  /// Valori persistiti stabili:
  /// 0 = low, 1 = normal, 2 = high.
  ///
  /// Non dipende dall'ordine dichiarativo dell'enum Dart.
  IntColumn get priority =>
      integer().withDefault(const Constant(1))();

  /// true = questa singola occorrenza è esclusa dalla serie.
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {
        taskId,
        occurrenceDate,
      };
}

@DriftDatabase(
  tables: [
    TaskCategories,
    TaskItems,
    TaskOccurrenceStates,
    TaskSubtasks,
    TaskSubtaskOccurrenceStates,
    TaskOccurrenceOverrides,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([
    QueryExecutor? executor,
  ]) : super(
          executor ??
              _openConnection(),
        );

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          // Portiamo sempre TaskItems allo schema corrente prima di
          // eseguire query con il codice Drift generato più recente.
          if (from < 2) {
            await m.addColumn(
              taskItems,
              taskItems.scheduledDate,
            );

            await m.addColumn(
              taskItems,
              taskItems.startTimeMinutes,
            );

            await m.addColumn(
              taskItems,
              taskItems.durationMinutes,
            );
          }

          if (from < 3) {
            await m.createTable(taskCategories);

            await m.addColumn(
              taskItems,
              taskItems.categoryId,
            );

            await _seedDefaultCategories();
          }

          if (from < 4) {
            await m.addColumn(
              taskItems,
              taskItems.recurrenceType,
            );

            await m.addColumn(
              taskItems,
              taskItems.recurrenceWeekdays,
            );

            await m.createTable(
              taskOccurrenceStates,
            );
          }

          if (from < 5) {
            await m.createTable(
              taskSubtasks,
            );

            await m.createTable(
              taskSubtaskOccurrenceStates,
            );
          }

          if (from < 6) {
            await m.createTable(
              taskOccurrenceOverrides,
            );
          }

          // Migrazione dati legacy v1 -> scheduling flessibile.
          if (from < 2) {
            final oldRows = await select(taskItems).get();

            for (final row in oldRows) {
              final oldStart = row.startAt;
              final oldEnd = row.endAt;

              DateTime? migratedDate;
              int? migratedStartMinutes;
              int? migratedDurationMinutes;

              if (oldStart != null) {
                migratedDate = DateTime(
                  oldStart.year,
                  oldStart.month,
                  oldStart.day,
                );

                if (!row.allDay) {
                  final hasExplicitTime =
                      oldStart.hour != 0 ||
                      oldStart.minute != 0 ||
                      oldStart.second != 0 ||
                      oldEnd != null;

                  if (hasExplicitTime) {
                    migratedStartMinutes =
                        oldStart.hour * 60 + oldStart.minute;
                  }

                  if (oldEnd != null) {
                    final difference =
                        oldEnd.difference(oldStart);

                    if (difference.inMinutes > 0) {
                      migratedDurationMinutes =
                          difference.inMinutes;
                    }
                  }
                }
              }

              await (update(taskItems)
                    ..where(
                      (item) =>
                          item.id.equals(row.id),
                    ))
                  .write(
                TaskItemsCompanion(
                  scheduledDate:
                      Value(migratedDate),
                  startTimeMinutes:
                      Value(migratedStartMinutes),
                  durationMinutes:
                      Value(migratedDurationMinutes),
                ),
              );
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement(
            'PRAGMA foreign_keys = ON',
          );
        },
      );

  Future<void> _seedDefaultCategories() async {
    await batch((batch) {
      batch.insertAll(
        taskCategories,
        const [
          TaskCategoriesCompanion(
            id: Value('personal'),
            name: Value('Personale'),
            colorValue: Value(0xFF6750A4),
            iconKey: Value('person_outline'),
            sortOrder: Value(0),
          ),
          TaskCategoriesCompanion(
            id: Value('work'),
            name: Value('Lavoro'),
            colorValue: Value(0xFF4F7396),
            iconKey: Value('work_outline'),
            sortOrder: Value(1),
          ),
          TaskCategoriesCompanion(
            id: Value('health'),
            name: Value('Salute'),
            colorValue: Value(0xFF5B8F72),
            iconKey: Value('medical_services_outlined'),
            sortOrder: Value(2),
          ),
          TaskCategoriesCompanion(
            id: Value('study'),
            name: Value('Studio'),
            colorValue: Value(0xFFA97948),
            iconKey: Value('menu_book_outlined'),
            sortOrder: Value(3),
          ),
          TaskCategoriesCompanion(
            id: Value('errands'),
            name: Value('Commissioni'),
            colorValue: Value(0xFFB66B73),
            iconKey: Value('shopping_cart_outlined'),
            sortOrder: Value(4),
          ),
        ],
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final file = File(
      p.join(
        directory.path,
        'life_dashboard.sqlite',
      ),
    );

    return NativeDatabase.createInBackground(
      file,
    );
  });
}
