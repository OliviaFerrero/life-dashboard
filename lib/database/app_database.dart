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

  DateTimeColumn get startAt =>
      dateTime().nullable()();

  DateTimeColumn get endAt =>
      dateTime().nullable()();

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
  int get schemaVersion => 1;
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