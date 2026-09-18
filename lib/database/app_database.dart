import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

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
    TaskItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
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
      );
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
