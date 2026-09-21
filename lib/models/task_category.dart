class TaskCategory {
  final String id;
  final String name;

  /// Colore ARGB salvato come intero.
  ///
  /// La UI potrà convertirlo con:
  /// Color(category.colorValue)
  final int colorValue;

  /// Chiave stabile dell'icona, ad esempio:
  /// person_outline, work_outline, menu_book_outlined.
  ///
  /// La conversione verso IconData resterà nella UI, così il modello
  /// non dipende da Flutter/Material.
  final String iconKey;

  /// Ordine di visualizzazione delle categorie.
  final int sortOrder;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.sortOrder,
  });

  TaskCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? iconKey,
    int? sortOrder,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
