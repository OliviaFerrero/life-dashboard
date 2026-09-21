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

  IntColumn get priority =>
      integer().withDefault(const Constant(1))();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    TaskCategories,
    TaskItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          // Prima portiamo fisicamente la tabella TaskItems allo schema
          // corrente. Questo è importante anche per un eventuale salto
          // diretto v1 -> v3, perché le query Drift usano lo schema
          // generato più recente.
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

          // Migrazione dati legacy v1 -> nuovo modello scheduling.
          //
          // Viene eseguita solo dopo aver aggiunto anche le eventuali
          // colonne v3, così select(taskItems) può leggere in sicurezza
          // lo schema corrente generato da Drift.
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
                    final difference = oldEnd.difference(oldStart);

                    if (difference.inMinutes > 0) {
                      migratedDurationMinutes =
                          difference.inMinutes;
                    }
                  }
                }
              }

              await (update(taskItems)
                    ..where(
                      (item) => item.id.equals(row.id),
                    ))
                  .write(
                TaskItemsCompanion(
                  scheduledDate: Value(migratedDate),
                  startTimeMinutes: Value(migratedStartMinutes),
                  durationMinutes: Value(migratedDurationMinutes),
                ),
              );
            }
          }
        },
        beforeOpen: (details) async {
          // SQLite non abilita le foreign key di default.
          // Servono, tra le altre cose, per ON DELETE SET NULL
          // su TaskItems.categoryId.
          await customStatement('PRAGMA foreign_keys = ON');
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

    return NativeDatabase.createInBackground(file);
  });
}
