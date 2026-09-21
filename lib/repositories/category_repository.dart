import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/task_category.dart';

class CategoryRepository {
  final AppDatabase _database;

  CategoryRepository(this._database);

  Stream<List<TaskCategory>> watchAllCategories() {
    final query = _database.select(_database.taskCategories)
      ..orderBy([
        (row) => OrderingTerm.asc(row.sortOrder),
        (row) => OrderingTerm.asc(row.name),
      ]);

    return query.watch().map(
          (rows) => rows.map(_categoryFromRow).toList(),
        );
  }

  Stream<Map<String, TaskCategory>> watchCategoryMap() {
    return watchAllCategories().map(
      (categories) => {
        for (final category in categories)
          category.id: category,
      },
    );
  }

  Future<List<TaskCategory>> getAllCategories() async {
    final query = _database.select(_database.taskCategories)
      ..orderBy([
        (row) => OrderingTerm.asc(row.sortOrder),
        (row) => OrderingTerm.asc(row.name),
      ]);

    final rows = await query.get();

    return rows.map(_categoryFromRow).toList();
  }

  Future<TaskCategory?> getCategoryById(String id) async {
    final query = _database.select(_database.taskCategories)
      ..where(
        (row) => row.id.equals(id),
      );

    final row = await query.getSingleOrNull();

    return row == null ? null : _categoryFromRow(row);
  }

  Future<void> addCategory(TaskCategory category) async {
    await _database.into(_database.taskCategories).insert(
          TaskCategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            colorValue: category.colorValue,
            iconKey: category.iconKey,
            sortOrder: Value(category.sortOrder),
          ),
        );
  }

  Future<void> updateCategory(TaskCategory category) async {
    await (_database.update(_database.taskCategories)
          ..where(
            (row) => row.id.equals(category.id),
          ))
        .write(
      TaskCategoriesCompanion(
        name: Value(category.name),
        colorValue: Value(category.colorValue),
        iconKey: Value(category.iconKey),
        sortOrder: Value(category.sortOrder),
      ),
    );
  }

  Future<void> deleteCategory(String id) async {
    await _database.transaction(() async {
      // Lo facciamo esplicitamente oltre a ON DELETE SET NULL:
      // in questo modo la semantica resta chiara e sicura anche
      // se il database venisse aperto in futuro da un contesto
      // dove le foreign key non fossero abilitate.
      await (_database.update(_database.taskItems)
            ..where(
              (row) => row.categoryId.equals(id),
            ))
          .write(
        const TaskItemsCompanion(
          categoryId: Value(null),
        ),
      );

      await (_database.delete(_database.taskCategories)
            ..where(
              (row) => row.id.equals(id),
            ))
          .go();
    });
  }

  TaskCategory _categoryFromRow(TaskCategoryRow row) {
    return TaskCategory(
      id: row.id,
      name: row.name,
      colorValue: row.colorValue,
      iconKey: row.iconKey,
      sortOrder: row.sortOrder,
    );
  }
}
