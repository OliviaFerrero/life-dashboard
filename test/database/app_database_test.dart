import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'opens an in-memory database at schema v6',
    () async {
      expect(
        database.schemaVersion,
        6,
      );

      // Force Drift to open/create the database.
      await database
          .customSelect(
            'SELECT 1',
          )
          .getSingle();

      final versionRow =
          await database
              .customSelect(
                'PRAGMA user_version',
              )
              .getSingle();

      expect(
        versionRow.data.values.single,
        6,
      );
    },
  );

  test(
    'seeds the five default task categories',
    () async {
      final categories =
          await database
              .select(
                database.taskCategories,
              )
              .get();

      expect(
        categories.map(
          (category) =>
              category.id,
        ),
        containsAll(
          const [
            'personal',
            'work',
            'health',
            'study',
            'errands',
          ],
        ),
      );

      expect(
        categories.length,
        5,
      );
    },
  );

  test(
    'enables SQLite foreign keys',
    () async {
      final row =
          await database
              .customSelect(
                'PRAGMA foreign_keys',
              )
              .getSingle();

      expect(
        row.data.values.single,
        1,
      );
    },
  );
}
