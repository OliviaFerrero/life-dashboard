// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TaskCategoriesTable extends TaskCategories
    with TableInfo<$TaskCategoriesTable, TaskCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorValue,
    iconKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TaskCategoriesTable createAlias(String alias) {
    return $TaskCategoriesTable(attachedDatabase, alias);
  }
}

class TaskCategoryRow extends DataClass implements Insertable<TaskCategoryRow> {
  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final int sortOrder;
  const TaskCategoryRow({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TaskCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TaskCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory TaskCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TaskCategoryRow copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? iconKey,
    int? sortOrder,
  }) => TaskCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TaskCategoryRow copyWithCompanion(TaskCategoriesCompanion data) {
    return TaskCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, iconKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder);
}

class TaskCategoriesCompanion extends UpdateCompanion<TaskCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TaskCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskCategoriesCompanion.insert({
    required String id,
    required String name,
    required int colorValue,
    required String iconKey,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorValue = Value(colorValue),
       iconKey = Value(iconKey);
  static Insertable<TaskCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? colorValue,
    Value<String>? iconKey,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TaskCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskItemsTable extends TaskItems
    with TableInfo<$TaskItemsTable, TaskItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _startTimeMinutesMeta = const VerificationMeta(
    'startTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> startTimeMinutes = GeneratedColumn<int>(
    'start_time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurrenceTypeMeta = const VerificationMeta(
    'recurrenceType',
  );
  @override
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
    'recurrence_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _recurrenceWeekdaysMeta =
      const VerificationMeta('recurrenceWeekdays');
  @override
  late final GeneratedColumn<int> recurrenceWeekdays = GeneratedColumn<int>(
    'recurrence_weekdays',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    startAt,
    endAt,
    scheduledDate,
    startTimeMinutes,
    durationMinutes,
    categoryId,
    allDay,
    priority,
    isCompleted,
    recurrenceType,
    recurrenceWeekdays,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('start_time_minutes')) {
      context.handle(
        _startTimeMinutesMeta,
        startTimeMinutes.isAcceptableOrUnknown(
          data['start_time_minutes']!,
          _startTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_type')) {
      context.handle(
        _recurrenceTypeMeta,
        recurrenceType.isAcceptableOrUnknown(
          data['recurrence_type']!,
          _recurrenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_weekdays')) {
      context.handle(
        _recurrenceWeekdaysMeta,
        recurrenceWeekdays.isAcceptableOrUnknown(
          data['recurrence_weekdays']!,
          _recurrenceWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      ),
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      startTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time_minutes'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      recurrenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_type'],
      )!,
      recurrenceWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_weekdays'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TaskItemsTable createAlias(String alias) {
    return $TaskItemsTable(attachedDatabase, alias);
  }
}

class TaskItem extends DataClass implements Insertable<TaskItem> {
  final String id;
  final String title;
  final String description;

  /// Colonne legacy mantenute per una migrazione sicura e per
  /// retrocompatibilità interna. Il nuovo modello usa i tre campi
  /// scheduledDate / startTimeMinutes / durationMinutes.
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? scheduledDate;
  final int? startTimeMinutes;
  final int? durationMinutes;

  /// Null significa "Nessuna categoria".
  ///
  /// Se una categoria viene eliminata, il task resta esistente e
  /// categoryId torna automaticamente a null.
  final String? categoryId;
  final bool allDay;
  final int priority;

  /// Stato usato dalle task NON ricorrenti.
  ///
  /// Per le task ricorrenti lo stato viene salvato in
  /// TaskOccurrenceStates, una riga per singola occorrenza completata.
  final bool isCompleted;

  /// Valori stabili: none / daily / weekly.
  final String recurrenceType;

  /// Bit mask: bit 0 = lunedì ... bit 6 = domenica.
  final int recurrenceWeekdays;
  final DateTime createdAt;
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    this.startAt,
    this.endAt,
    this.scheduledDate,
    this.startTimeMinutes,
    this.durationMinutes,
    this.categoryId,
    required this.allDay,
    required this.priority,
    required this.isCompleted,
    required this.recurrenceType,
    required this.recurrenceWeekdays,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<DateTime>(startAt);
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    if (!nullToAbsent || startTimeMinutes != null) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['all_day'] = Variable<bool>(allDay);
    map['priority'] = Variable<int>(priority);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['recurrence_type'] = Variable<String>(recurrenceType);
    map['recurrence_weekdays'] = Variable<int>(recurrenceWeekdays);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TaskItemsCompanion toCompanion(bool nullToAbsent) {
    return TaskItemsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      startTimeMinutes: startTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(startTimeMinutes),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      allDay: Value(allDay),
      priority: Value(priority),
      isCompleted: Value(isCompleted),
      recurrenceType: Value(recurrenceType),
      recurrenceWeekdays: Value(recurrenceWeekdays),
      createdAt: Value(createdAt),
    );
  }

  factory TaskItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskItem(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      startAt: serializer.fromJson<DateTime?>(json['startAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      startTimeMinutes: serializer.fromJson<int?>(json['startTimeMinutes']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      priority: serializer.fromJson<int>(json['priority']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      recurrenceType: serializer.fromJson<String>(json['recurrenceType']),
      recurrenceWeekdays: serializer.fromJson<int>(json['recurrenceWeekdays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'startAt': serializer.toJson<DateTime?>(startAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'startTimeMinutes': serializer.toJson<int?>(startTimeMinutes),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'categoryId': serializer.toJson<String?>(categoryId),
      'allDay': serializer.toJson<bool>(allDay),
      'priority': serializer.toJson<int>(priority),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'recurrenceType': serializer.toJson<String>(recurrenceType),
      'recurrenceWeekdays': serializer.toJson<int>(recurrenceWeekdays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    Value<DateTime?> startAt = const Value.absent(),
    Value<DateTime?> endAt = const Value.absent(),
    Value<DateTime?> scheduledDate = const Value.absent(),
    Value<int?> startTimeMinutes = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    bool? allDay,
    int? priority,
    bool? isCompleted,
    String? recurrenceType,
    int? recurrenceWeekdays,
    DateTime? createdAt,
  }) => TaskItem(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    startTimeMinutes: startTimeMinutes.present
        ? startTimeMinutes.value
        : this.startTimeMinutes,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    allDay: allDay ?? this.allDay,
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    recurrenceType: recurrenceType ?? this.recurrenceType,
    recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
    createdAt: createdAt ?? this.createdAt,
  );
  TaskItem copyWithCompanion(TaskItemsCompanion data) {
    return TaskItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      startTimeMinutes: data.startTimeMinutes.present
          ? data.startTimeMinutes.value
          : this.startTimeMinutes,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      priority: data.priority.present ? data.priority.value : this.priority,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      recurrenceWeekdays: data.recurrenceWeekdays.present
          ? data.recurrenceWeekdays.value
          : this.recurrenceWeekdays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('allDay: $allDay, ')
          ..write('priority: $priority, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceWeekdays: $recurrenceWeekdays, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    startAt,
    endAt,
    scheduledDate,
    startTimeMinutes,
    durationMinutes,
    categoryId,
    allDay,
    priority,
    isCompleted,
    recurrenceType,
    recurrenceWeekdays,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.scheduledDate == this.scheduledDate &&
          other.startTimeMinutes == this.startTimeMinutes &&
          other.durationMinutes == this.durationMinutes &&
          other.categoryId == this.categoryId &&
          other.allDay == this.allDay &&
          other.priority == this.priority &&
          other.isCompleted == this.isCompleted &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceWeekdays == this.recurrenceWeekdays &&
          other.createdAt == this.createdAt);
}

class TaskItemsCompanion extends UpdateCompanion<TaskItem> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime?> startAt;
  final Value<DateTime?> endAt;
  final Value<DateTime?> scheduledDate;
  final Value<int?> startTimeMinutes;
  final Value<int?> durationMinutes;
  final Value<String?> categoryId;
  final Value<bool> allDay;
  final Value<int> priority;
  final Value<bool> isCompleted;
  final Value<String> recurrenceType;
  final Value<int> recurrenceWeekdays;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TaskItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.allDay = const Value.absent(),
    this.priority = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceWeekdays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskItemsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.allDay = const Value.absent(),
    this.priority = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceWeekdays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<TaskItem> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<DateTime>? scheduledDate,
    Expression<int>? startTimeMinutes,
    Expression<int>? durationMinutes,
    Expression<String>? categoryId,
    Expression<bool>? allDay,
    Expression<int>? priority,
    Expression<bool>? isCompleted,
    Expression<String>? recurrenceType,
    Expression<int>? recurrenceWeekdays,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (startTimeMinutes != null) 'start_time_minutes': startTimeMinutes,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (categoryId != null) 'category_id': categoryId,
      if (allDay != null) 'all_day': allDay,
      if (priority != null) 'priority': priority,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceWeekdays != null) 'recurrence_weekdays': recurrenceWeekdays,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<DateTime?>? startAt,
    Value<DateTime?>? endAt,
    Value<DateTime?>? scheduledDate,
    Value<int?>? startTimeMinutes,
    Value<int?>? durationMinutes,
    Value<String?>? categoryId,
    Value<bool>? allDay,
    Value<int>? priority,
    Value<bool>? isCompleted,
    Value<String>? recurrenceType,
    Value<int>? recurrenceWeekdays,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TaskItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      categoryId: categoryId ?? this.categoryId,
      allDay: allDay ?? this.allDay,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (startTimeMinutes.present) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (recurrenceWeekdays.present) {
      map['recurrence_weekdays'] = Variable<int>(recurrenceWeekdays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('allDay: $allDay, ')
          ..write('priority: $priority, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceWeekdays: $recurrenceWeekdays, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskOccurrenceStatesTable extends TaskOccurrenceStates
    with TableInfo<$TaskOccurrenceStatesTable, TaskOccurrenceStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskOccurrenceStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<DateTime> occurrenceDate =
      GeneratedColumn<DateTime>(
        'occurrence_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, occurrenceDate, isCompleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_occurrence_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskOccurrenceStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, occurrenceDate};
  @override
  TaskOccurrenceStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskOccurrenceStateRow(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurrence_date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $TaskOccurrenceStatesTable createAlias(String alias) {
    return $TaskOccurrenceStatesTable(attachedDatabase, alias);
  }
}

class TaskOccurrenceStateRow extends DataClass
    implements Insertable<TaskOccurrenceStateRow> {
  final String taskId;

  /// Giorno specifico dell'occorrenza, normalizzato a mezzanotte locale.
  final DateTime occurrenceDate;
  final bool isCompleted;
  const TaskOccurrenceStateRow({
    required this.taskId,
    required this.occurrenceDate,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['occurrence_date'] = Variable<DateTime>(occurrenceDate);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  TaskOccurrenceStatesCompanion toCompanion(bool nullToAbsent) {
    return TaskOccurrenceStatesCompanion(
      taskId: Value(taskId),
      occurrenceDate: Value(occurrenceDate),
      isCompleted: Value(isCompleted),
    );
  }

  factory TaskOccurrenceStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskOccurrenceStateRow(
      taskId: serializer.fromJson<String>(json['taskId']),
      occurrenceDate: serializer.fromJson<DateTime>(json['occurrenceDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'occurrenceDate': serializer.toJson<DateTime>(occurrenceDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  TaskOccurrenceStateRow copyWith({
    String? taskId,
    DateTime? occurrenceDate,
    bool? isCompleted,
  }) => TaskOccurrenceStateRow(
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  TaskOccurrenceStateRow copyWithCompanion(TaskOccurrenceStatesCompanion data) {
    return TaskOccurrenceStateRow(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrenceStateRow(')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, occurrenceDate, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOccurrenceStateRow &&
          other.taskId == this.taskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.isCompleted == this.isCompleted);
}

class TaskOccurrenceStatesCompanion
    extends UpdateCompanion<TaskOccurrenceStateRow> {
  final Value<String> taskId;
  final Value<DateTime> occurrenceDate;
  final Value<bool> isCompleted;
  final Value<int> rowid;
  const TaskOccurrenceStatesCompanion({
    this.taskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskOccurrenceStatesCompanion.insert({
    required String taskId,
    required DateTime occurrenceDate,
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       occurrenceDate = Value(occurrenceDate);
  static Insertable<TaskOccurrenceStateRow> custom({
    Expression<String>? taskId,
    Expression<DateTime>? occurrenceDate,
    Expression<bool>? isCompleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskOccurrenceStatesCompanion copyWith({
    Value<String>? taskId,
    Value<DateTime>? occurrenceDate,
    Value<bool>? isCompleted,
    Value<int>? rowid,
  }) {
    return TaskOccurrenceStatesCompanion(
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      isCompleted: isCompleted ?? this.isCompleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<DateTime>(occurrenceDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrenceStatesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskSubtasksTable extends TaskSubtasks
    with TableInfo<$TaskSubtasksTable, TaskSubtaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskSubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    title,
    sortOrder,
    isCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskSubtaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskSubtaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskSubtaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $TaskSubtasksTable createAlias(String alias) {
    return $TaskSubtasksTable(attachedDatabase, alias);
  }
}

class TaskSubtaskRow extends DataClass implements Insertable<TaskSubtaskRow> {
  final String id;
  final String taskId;
  final String title;
  final int sortOrder;

  /// Stato usato dalle task NON ricorrenti.
  ///
  /// Per le task ricorrenti lo stato effettivo viene salvato in
  /// TaskSubtaskOccurrenceStates.
  final bool isCompleted;
  const TaskSubtaskRow({
    required this.id,
    required this.taskId,
    required this.title,
    required this.sortOrder,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  TaskSubtasksCompanion toCompanion(bool nullToAbsent) {
    return TaskSubtasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      sortOrder: Value(sortOrder),
      isCompleted: Value(isCompleted),
    );
  }

  factory TaskSubtaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskSubtaskRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  TaskSubtaskRow copyWith({
    String? id,
    String? taskId,
    String? title,
    int? sortOrder,
    bool? isCompleted,
  }) => TaskSubtaskRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    sortOrder: sortOrder ?? this.sortOrder,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  TaskSubtaskRow copyWithCompanion(TaskSubtasksCompanion data) {
    return TaskSubtaskRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskSubtaskRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, title, sortOrder, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskSubtaskRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.sortOrder == this.sortOrder &&
          other.isCompleted == this.isCompleted);
}

class TaskSubtasksCompanion extends UpdateCompanion<TaskSubtaskRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> title;
  final Value<int> sortOrder;
  final Value<bool> isCompleted;
  final Value<int> rowid;
  const TaskSubtasksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskSubtasksCompanion.insert({
    required String id,
    required String taskId,
    required String title,
    this.sortOrder = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       title = Value(title);
  static Insertable<TaskSubtaskRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<int>? sortOrder,
    Expression<bool>? isCompleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskSubtasksCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? title,
    Value<int>? sortOrder,
    Value<bool>? isCompleted,
    Value<int>? rowid,
  }) {
    return TaskSubtasksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskSubtasksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskSubtaskOccurrenceStatesTable extends TaskSubtaskOccurrenceStates
    with
        TableInfo<
          $TaskSubtaskOccurrenceStatesTable,
          TaskSubtaskOccurrenceStateRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskSubtaskOccurrenceStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subtaskIdMeta = const VerificationMeta(
    'subtaskId',
  );
  @override
  late final GeneratedColumn<String> subtaskId = GeneratedColumn<String>(
    'subtask_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_subtasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<DateTime> occurrenceDate =
      GeneratedColumn<DateTime>(
        'occurrence_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    subtaskId,
    occurrenceDate,
    isCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_subtask_occurrence_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskSubtaskOccurrenceStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subtask_id')) {
      context.handle(
        _subtaskIdMeta,
        subtaskId.isAcceptableOrUnknown(data['subtask_id']!, _subtaskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subtaskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subtaskId, occurrenceDate};
  @override
  TaskSubtaskOccurrenceStateRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskSubtaskOccurrenceStateRow(
      subtaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtask_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurrence_date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $TaskSubtaskOccurrenceStatesTable createAlias(String alias) {
    return $TaskSubtaskOccurrenceStatesTable(attachedDatabase, alias);
  }
}

class TaskSubtaskOccurrenceStateRow extends DataClass
    implements Insertable<TaskSubtaskOccurrenceStateRow> {
  final String subtaskId;

  /// Giorno specifico dell'occorrenza, normalizzato a mezzanotte locale.
  final DateTime occurrenceDate;
  final bool isCompleted;
  const TaskSubtaskOccurrenceStateRow({
    required this.subtaskId,
    required this.occurrenceDate,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subtask_id'] = Variable<String>(subtaskId);
    map['occurrence_date'] = Variable<DateTime>(occurrenceDate);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  TaskSubtaskOccurrenceStatesCompanion toCompanion(bool nullToAbsent) {
    return TaskSubtaskOccurrenceStatesCompanion(
      subtaskId: Value(subtaskId),
      occurrenceDate: Value(occurrenceDate),
      isCompleted: Value(isCompleted),
    );
  }

  factory TaskSubtaskOccurrenceStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskSubtaskOccurrenceStateRow(
      subtaskId: serializer.fromJson<String>(json['subtaskId']),
      occurrenceDate: serializer.fromJson<DateTime>(json['occurrenceDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subtaskId': serializer.toJson<String>(subtaskId),
      'occurrenceDate': serializer.toJson<DateTime>(occurrenceDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  TaskSubtaskOccurrenceStateRow copyWith({
    String? subtaskId,
    DateTime? occurrenceDate,
    bool? isCompleted,
  }) => TaskSubtaskOccurrenceStateRow(
    subtaskId: subtaskId ?? this.subtaskId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  TaskSubtaskOccurrenceStateRow copyWithCompanion(
    TaskSubtaskOccurrenceStatesCompanion data,
  ) {
    return TaskSubtaskOccurrenceStateRow(
      subtaskId: data.subtaskId.present ? data.subtaskId.value : this.subtaskId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskSubtaskOccurrenceStateRow(')
          ..write('subtaskId: $subtaskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subtaskId, occurrenceDate, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskSubtaskOccurrenceStateRow &&
          other.subtaskId == this.subtaskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.isCompleted == this.isCompleted);
}

class TaskSubtaskOccurrenceStatesCompanion
    extends UpdateCompanion<TaskSubtaskOccurrenceStateRow> {
  final Value<String> subtaskId;
  final Value<DateTime> occurrenceDate;
  final Value<bool> isCompleted;
  final Value<int> rowid;
  const TaskSubtaskOccurrenceStatesCompanion({
    this.subtaskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskSubtaskOccurrenceStatesCompanion.insert({
    required String subtaskId,
    required DateTime occurrenceDate,
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subtaskId = Value(subtaskId),
       occurrenceDate = Value(occurrenceDate);
  static Insertable<TaskSubtaskOccurrenceStateRow> custom({
    Expression<String>? subtaskId,
    Expression<DateTime>? occurrenceDate,
    Expression<bool>? isCompleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subtaskId != null) 'subtask_id': subtaskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskSubtaskOccurrenceStatesCompanion copyWith({
    Value<String>? subtaskId,
    Value<DateTime>? occurrenceDate,
    Value<bool>? isCompleted,
    Value<int>? rowid,
  }) {
    return TaskSubtaskOccurrenceStatesCompanion(
      subtaskId: subtaskId ?? this.subtaskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      isCompleted: isCompleted ?? this.isCompleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subtaskId.present) {
      map['subtask_id'] = Variable<String>(subtaskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<DateTime>(occurrenceDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskSubtaskOccurrenceStatesCompanion(')
          ..write('subtaskId: $subtaskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskOccurrenceOverridesTable extends TaskOccurrenceOverrides
    with TableInfo<$TaskOccurrenceOverridesTable, TaskOccurrenceOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskOccurrenceOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<DateTime> occurrenceDate =
      GeneratedColumn<DateTime>(
        'occurrence_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _effectiveDateMeta = const VerificationMeta(
    'effectiveDate',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveDate =
      GeneratedColumn<DateTime>(
        'effective_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startTimeMinutesMeta = const VerificationMeta(
    'startTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> startTimeMinutes = GeneratedColumn<int>(
    'start_time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    occurrenceDate,
    effectiveDate,
    title,
    description,
    startTimeMinutes,
    durationMinutes,
    categoryId,
    allDay,
    priority,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_occurrence_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskOccurrenceOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('effective_date')) {
      context.handle(
        _effectiveDateMeta,
        effectiveDate.isAcceptableOrUnknown(
          data['effective_date']!,
          _effectiveDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveDateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_time_minutes')) {
      context.handle(
        _startTimeMinutesMeta,
        startTimeMinutes.isAcceptableOrUnknown(
          data['start_time_minutes']!,
          _startTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, occurrenceDate};
  @override
  TaskOccurrenceOverrideRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskOccurrenceOverrideRow(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurrence_date'],
      )!,
      effectiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      startTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time_minutes'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $TaskOccurrenceOverridesTable createAlias(String alias) {
    return $TaskOccurrenceOverridesTable(attachedDatabase, alias);
  }
}

class TaskOccurrenceOverrideRow extends DataClass
    implements Insertable<TaskOccurrenceOverrideRow> {
  final String taskId;

  /// Data originaria generata dalla regola della serie.
  ///
  /// Rimane stabile anche quando l'occorrenza viene spostata a un
  /// altro giorno ed è quindi l'identità dell'eccezione.
  final DateTime occurrenceDate;

  /// Data effettiva mostrata all'utente per questa sola occorrenza.
  final DateTime effectiveDate;
  final String title;
  final String description;
  final int? startTimeMinutes;
  final int? durationMinutes;
  final String? categoryId;
  final bool allDay;
  final int priority;

  /// true = questa singola occorrenza è esclusa dalla serie.
  final bool isDeleted;
  const TaskOccurrenceOverrideRow({
    required this.taskId,
    required this.occurrenceDate,
    required this.effectiveDate,
    required this.title,
    required this.description,
    this.startTimeMinutes,
    this.durationMinutes,
    this.categoryId,
    required this.allDay,
    required this.priority,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['occurrence_date'] = Variable<DateTime>(occurrenceDate);
    map['effective_date'] = Variable<DateTime>(effectiveDate);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || startTimeMinutes != null) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['all_day'] = Variable<bool>(allDay);
    map['priority'] = Variable<int>(priority);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  TaskOccurrenceOverridesCompanion toCompanion(bool nullToAbsent) {
    return TaskOccurrenceOverridesCompanion(
      taskId: Value(taskId),
      occurrenceDate: Value(occurrenceDate),
      effectiveDate: Value(effectiveDate),
      title: Value(title),
      description: Value(description),
      startTimeMinutes: startTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(startTimeMinutes),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      allDay: Value(allDay),
      priority: Value(priority),
      isDeleted: Value(isDeleted),
    );
  }

  factory TaskOccurrenceOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskOccurrenceOverrideRow(
      taskId: serializer.fromJson<String>(json['taskId']),
      occurrenceDate: serializer.fromJson<DateTime>(json['occurrenceDate']),
      effectiveDate: serializer.fromJson<DateTime>(json['effectiveDate']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      startTimeMinutes: serializer.fromJson<int?>(json['startTimeMinutes']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      priority: serializer.fromJson<int>(json['priority']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'occurrenceDate': serializer.toJson<DateTime>(occurrenceDate),
      'effectiveDate': serializer.toJson<DateTime>(effectiveDate),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'startTimeMinutes': serializer.toJson<int?>(startTimeMinutes),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'categoryId': serializer.toJson<String?>(categoryId),
      'allDay': serializer.toJson<bool>(allDay),
      'priority': serializer.toJson<int>(priority),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  TaskOccurrenceOverrideRow copyWith({
    String? taskId,
    DateTime? occurrenceDate,
    DateTime? effectiveDate,
    String? title,
    String? description,
    Value<int?> startTimeMinutes = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    bool? allDay,
    int? priority,
    bool? isDeleted,
  }) => TaskOccurrenceOverrideRow(
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    effectiveDate: effectiveDate ?? this.effectiveDate,
    title: title ?? this.title,
    description: description ?? this.description,
    startTimeMinutes: startTimeMinutes.present
        ? startTimeMinutes.value
        : this.startTimeMinutes,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    allDay: allDay ?? this.allDay,
    priority: priority ?? this.priority,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  TaskOccurrenceOverrideRow copyWithCompanion(
    TaskOccurrenceOverridesCompanion data,
  ) {
    return TaskOccurrenceOverrideRow(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      effectiveDate: data.effectiveDate.present
          ? data.effectiveDate.value
          : this.effectiveDate,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startTimeMinutes: data.startTimeMinutes.present
          ? data.startTimeMinutes.value
          : this.startTimeMinutes,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrenceOverrideRow(')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('allDay: $allDay, ')
          ..write('priority: $priority, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    occurrenceDate,
    effectiveDate,
    title,
    description,
    startTimeMinutes,
    durationMinutes,
    categoryId,
    allDay,
    priority,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOccurrenceOverrideRow &&
          other.taskId == this.taskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.effectiveDate == this.effectiveDate &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTimeMinutes == this.startTimeMinutes &&
          other.durationMinutes == this.durationMinutes &&
          other.categoryId == this.categoryId &&
          other.allDay == this.allDay &&
          other.priority == this.priority &&
          other.isDeleted == this.isDeleted);
}

class TaskOccurrenceOverridesCompanion
    extends UpdateCompanion<TaskOccurrenceOverrideRow> {
  final Value<String> taskId;
  final Value<DateTime> occurrenceDate;
  final Value<DateTime> effectiveDate;
  final Value<String> title;
  final Value<String> description;
  final Value<int?> startTimeMinutes;
  final Value<int?> durationMinutes;
  final Value<String?> categoryId;
  final Value<bool> allDay;
  final Value<int> priority;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const TaskOccurrenceOverridesCompanion({
    this.taskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.effectiveDate = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.allDay = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskOccurrenceOverridesCompanion.insert({
    required String taskId,
    required DateTime occurrenceDate,
    required DateTime effectiveDate,
    required String title,
    this.description = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.allDay = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       occurrenceDate = Value(occurrenceDate),
       effectiveDate = Value(effectiveDate),
       title = Value(title);
  static Insertable<TaskOccurrenceOverrideRow> custom({
    Expression<String>? taskId,
    Expression<DateTime>? occurrenceDate,
    Expression<DateTime>? effectiveDate,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? startTimeMinutes,
    Expression<int>? durationMinutes,
    Expression<String>? categoryId,
    Expression<bool>? allDay,
    Expression<int>? priority,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (effectiveDate != null) 'effective_date': effectiveDate,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTimeMinutes != null) 'start_time_minutes': startTimeMinutes,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (categoryId != null) 'category_id': categoryId,
      if (allDay != null) 'all_day': allDay,
      if (priority != null) 'priority': priority,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskOccurrenceOverridesCompanion copyWith({
    Value<String>? taskId,
    Value<DateTime>? occurrenceDate,
    Value<DateTime>? effectiveDate,
    Value<String>? title,
    Value<String>? description,
    Value<int?>? startTimeMinutes,
    Value<int?>? durationMinutes,
    Value<String?>? categoryId,
    Value<bool>? allDay,
    Value<int>? priority,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return TaskOccurrenceOverridesCompanion(
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      title: title ?? this.title,
      description: description ?? this.description,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      categoryId: categoryId ?? this.categoryId,
      allDay: allDay ?? this.allDay,
      priority: priority ?? this.priority,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<DateTime>(occurrenceDate.value);
    }
    if (effectiveDate.present) {
      map['effective_date'] = Variable<DateTime>(effectiveDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTimeMinutes.present) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrenceOverridesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('allDay: $allDay, ')
          ..write('priority: $priority, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskCategoriesTable taskCategories = $TaskCategoriesTable(this);
  late final $TaskItemsTable taskItems = $TaskItemsTable(this);
  late final $TaskOccurrenceStatesTable taskOccurrenceStates =
      $TaskOccurrenceStatesTable(this);
  late final $TaskSubtasksTable taskSubtasks = $TaskSubtasksTable(this);
  late final $TaskSubtaskOccurrenceStatesTable taskSubtaskOccurrenceStates =
      $TaskSubtaskOccurrenceStatesTable(this);
  late final $TaskOccurrenceOverridesTable taskOccurrenceOverrides =
      $TaskOccurrenceOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskCategories,
    taskItems,
    taskOccurrenceStates,
    taskSubtasks,
    taskSubtaskOccurrenceStates,
    taskOccurrenceOverrides,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_items', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_occurrence_states', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_subtasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_subtasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('task_subtask_occurrence_states', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('task_occurrence_overrides', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('task_occurrence_overrides', kind: UpdateKind.update),
      ],
    ),
  ]);
}

typedef $$TaskCategoriesTableCreateCompanionBuilder =
    TaskCategoriesCompanion Function({
      required String id,
      required String name,
      required int colorValue,
      required String iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$TaskCategoriesTableUpdateCompanionBuilder =
    TaskCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> colorValue,
      Value<String> iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$TaskCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskCategoriesTable, TaskCategoryRow> {
  $$TaskCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TaskItemsTable, List<TaskItem>>
  _taskItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskItems,
    aliasName: 'task_categories__id__task_items__category_id',
  );

  $$TaskItemsTableProcessedTableManager get taskItemsRefs {
    final manager = $$TaskItemsTableTableManager(
      $_db,
      $_db.taskItems,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TaskOccurrenceOverridesTable,
    List<TaskOccurrenceOverrideRow>
  >
  _taskOccurrenceOverridesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskOccurrenceOverrides,
        aliasName:
            'task_categories__id__task_occurrence_overrides__category_id',
      );

  $$TaskOccurrenceOverridesTableProcessedTableManager
  get taskOccurrenceOverridesRefs {
    final manager = $$TaskOccurrenceOverridesTableTableManager(
      $_db,
      $_db.taskOccurrenceOverrides,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskOccurrenceOverridesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCategoriesTable> {
  $$TaskCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskItemsRefs(
    Expression<bool> Function($$TaskItemsTableFilterComposer f) f,
  ) {
    final $$TaskItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableFilterComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskOccurrenceOverridesRefs(
    Expression<bool> Function($$TaskOccurrenceOverridesTableFilterComposer f) f,
  ) {
    final $$TaskOccurrenceOverridesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceOverrides,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceOverridesTableFilterComposer(
                $db: $db,
                $table: $db.taskOccurrenceOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCategoriesTable> {
  $$TaskCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCategoriesTable> {
  $$TaskCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> taskItemsRefs<T extends Object>(
    Expression<T> Function($$TaskItemsTableAnnotationComposer a) f,
  ) {
    final $$TaskItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskOccurrenceOverridesRefs<T extends Object>(
    Expression<T> Function($$TaskOccurrenceOverridesTableAnnotationComposer a)
    f,
  ) {
    final $$TaskOccurrenceOverridesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceOverrides,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceOverridesTableAnnotationComposer(
                $db: $db,
                $table: $db.taskOccurrenceOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskCategoriesTable,
          TaskCategoryRow,
          $$TaskCategoriesTableFilterComposer,
          $$TaskCategoriesTableOrderingComposer,
          $$TaskCategoriesTableAnnotationComposer,
          $$TaskCategoriesTableCreateCompanionBuilder,
          $$TaskCategoriesTableUpdateCompanionBuilder,
          (TaskCategoryRow, $$TaskCategoriesTableReferences),
          TaskCategoryRow,
          PrefetchHooks Function({
            bool taskItemsRefs,
            bool taskOccurrenceOverridesRefs,
          })
        > {
  $$TaskCategoriesTableTableManager(
    _$AppDatabase db,
    $TaskCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskCategoriesCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int colorValue,
                required String iconKey,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskCategoriesCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskCategoriesTable, TaskCategoryRow>(table),
                  $$TaskCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskItemsRefs = false, taskOccurrenceOverridesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskItemsRefs) db.taskItems,
                    if (taskOccurrenceOverridesRefs) db.taskOccurrenceOverrides,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskItemsRefs)
                        await $_getPrefetchedData<
                          TaskCategoryRow,
                          $TaskCategoriesTable,
                          TaskItem
                        >(
                          currentTable: table,
                          referencedTable: $$TaskCategoriesTableReferences
                              ._taskItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskOccurrenceOverridesRefs)
                        await $_getPrefetchedData<
                          TaskCategoryRow,
                          $TaskCategoriesTable,
                          TaskOccurrenceOverrideRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskCategoriesTableReferences
                              ._taskOccurrenceOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskOccurrenceOverridesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TaskCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskCategoriesTable,
      TaskCategoryRow,
      $$TaskCategoriesTableFilterComposer,
      $$TaskCategoriesTableOrderingComposer,
      $$TaskCategoriesTableAnnotationComposer,
      $$TaskCategoriesTableCreateCompanionBuilder,
      $$TaskCategoriesTableUpdateCompanionBuilder,
      (TaskCategoryRow, $$TaskCategoriesTableReferences),
      TaskCategoryRow,
      PrefetchHooks Function({
        bool taskItemsRefs,
        bool taskOccurrenceOverridesRefs,
      })
    >;
typedef $$TaskItemsTableCreateCompanionBuilder = TaskItemsCompanion Function({
  required String id,
  required String title,
  Value<String> description,
  Value<DateTime?> startAt,
  Value<DateTime?> endAt,
  Value<DateTime?> scheduledDate,
  Value<int?> startTimeMinutes,
  Value<int?> durationMinutes,
  Value<String?> categoryId,
  Value<bool> allDay,
  Value<int> priority,
  Value<bool> isCompleted,
  Value<String> recurrenceType,
  Value<int> recurrenceWeekdays,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TaskItemsTableUpdateCompanionBuilder = TaskItemsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<DateTime?> startAt,
  Value<DateTime?> endAt,
  Value<DateTime?> scheduledDate,
  Value<int?> startTimeMinutes,
  Value<int?> durationMinutes,
  Value<String?> categoryId,
  Value<bool> allDay,
  Value<int> priority,
  Value<bool> isCompleted,
  Value<String> recurrenceType,
  Value<int> recurrenceWeekdays,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TaskItemsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskItemsTable, TaskItem> {
  $$TaskItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TaskCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .taskCategories
      .createAlias('task_items__category_id__task_categories__id');

  $$TaskCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$TaskCategoriesTableTableManager(
      $_db,
      $_db.taskCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TaskOccurrenceStatesTable,
    List<TaskOccurrenceStateRow>
  >
  _taskOccurrenceStatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskOccurrenceStates,
        aliasName: 'task_items__id__task_occurrence_states__task_id',
      );

  $$TaskOccurrenceStatesTableProcessedTableManager
  get taskOccurrenceStatesRefs {
    final manager = $$TaskOccurrenceStatesTableTableManager(
      $_db,
      $_db.taskOccurrenceStates,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskOccurrenceStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskSubtasksTable, List<TaskSubtaskRow>>
  _taskSubtasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskSubtasks,
    aliasName: 'task_items__id__task_subtasks__task_id',
  );

  $$TaskSubtasksTableProcessedTableManager get taskSubtasksRefs {
    final manager = $$TaskSubtasksTableTableManager(
      $_db,
      $_db.taskSubtasks,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskSubtasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TaskOccurrenceOverridesTable,
    List<TaskOccurrenceOverrideRow>
  >
  _taskOccurrenceOverridesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskOccurrenceOverrides,
        aliasName: 'task_items__id__task_occurrence_overrides__task_id',
      );

  $$TaskOccurrenceOverridesTableProcessedTableManager
  get taskOccurrenceOverridesRefs {
    final manager = $$TaskOccurrenceOverridesTableTableManager(
      $_db,
      $_db.taskOccurrenceOverrides,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskOccurrenceOverridesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskItemsTable> {
  $$TaskItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTimeMinutes => $composableBuilder(
    column: $table.startTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceWeekdays => $composableBuilder(
    column: $table.recurrenceWeekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskCategoriesTableFilterComposer get categoryId {
    final $$TaskCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.taskCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.taskCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskOccurrenceStatesRefs(
    Expression<bool> Function($$TaskOccurrenceStatesTableFilterComposer f) f,
  ) {
    final $$TaskOccurrenceStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskOccurrenceStates,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrenceStatesTableFilterComposer(
            $db: $db,
            $table: $db.taskOccurrenceStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskSubtasksRefs(
    Expression<bool> Function($$TaskSubtasksTableFilterComposer f) f,
  ) {
    final $$TaskSubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskSubtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskSubtasksTableFilterComposer(
            $db: $db,
            $table: $db.taskSubtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskOccurrenceOverridesRefs(
    Expression<bool> Function($$TaskOccurrenceOverridesTableFilterComposer f) f,
  ) {
    final $$TaskOccurrenceOverridesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceOverrides,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceOverridesTableFilterComposer(
                $db: $db,
                $table: $db.taskOccurrenceOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskItemsTable> {
  $$TaskItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTimeMinutes => $composableBuilder(
    column: $table.startTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceWeekdays => $composableBuilder(
    column: $table.recurrenceWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskCategoriesTableOrderingComposer get categoryId {
    final $$TaskCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.taskCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.taskCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskItemsTable> {
  $$TaskItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startTimeMinutes => $composableBuilder(
    column: $table.startTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceWeekdays => $composableBuilder(
    column: $table.recurrenceWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TaskCategoriesTableAnnotationComposer get categoryId {
    final $$TaskCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.taskCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskOccurrenceStatesRefs<T extends Object>(
    Expression<T> Function($$TaskOccurrenceStatesTableAnnotationComposer a) f,
  ) {
    final $$TaskOccurrenceStatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceStates,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceStatesTableAnnotationComposer(
                $db: $db,
                $table: $db.taskOccurrenceStates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> taskSubtasksRefs<T extends Object>(
    Expression<T> Function($$TaskSubtasksTableAnnotationComposer a) f,
  ) {
    final $$TaskSubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskSubtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskSubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.taskSubtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskOccurrenceOverridesRefs<T extends Object>(
    Expression<T> Function($$TaskOccurrenceOverridesTableAnnotationComposer a)
    f,
  ) {
    final $$TaskOccurrenceOverridesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceOverrides,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceOverridesTableAnnotationComposer(
                $db: $db,
                $table: $db.taskOccurrenceOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskItemsTable,
          TaskItem,
          $$TaskItemsTableFilterComposer,
          $$TaskItemsTableOrderingComposer,
          $$TaskItemsTableAnnotationComposer,
          $$TaskItemsTableCreateCompanionBuilder,
          $$TaskItemsTableUpdateCompanionBuilder,
          (TaskItem, $$TaskItemsTableReferences),
          TaskItem,
          PrefetchHooks Function({
            bool categoryId,
            bool taskOccurrenceStatesRefs,
            bool taskSubtasksRefs,
            bool taskOccurrenceOverridesRefs,
          })
        > {
  $$TaskItemsTableTableManager(_$AppDatabase db, $TaskItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int?> startTimeMinutes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String> recurrenceType = const Value.absent(),
                Value<int> recurrenceWeekdays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskItemsCompanion(
                id: id,
                title: title,
                description: description,
                startAt: startAt,
                endAt: endAt,
                scheduledDate: scheduledDate,
                startTimeMinutes: startTimeMinutes,
                durationMinutes: durationMinutes,
                categoryId: categoryId,
                allDay: allDay,
                priority: priority,
                isCompleted: isCompleted,
                recurrenceType: recurrenceType,
                recurrenceWeekdays: recurrenceWeekdays,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> description = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int?> startTimeMinutes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String> recurrenceType = const Value.absent(),
                Value<int> recurrenceWeekdays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskItemsCompanion.insert(
                id: id,
                title: title,
                description: description,
                startAt: startAt,
                endAt: endAt,
                scheduledDate: scheduledDate,
                startTimeMinutes: startTimeMinutes,
                durationMinutes: durationMinutes,
                categoryId: categoryId,
                allDay: allDay,
                priority: priority,
                isCompleted: isCompleted,
                recurrenceType: recurrenceType,
                recurrenceWeekdays: recurrenceWeekdays,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskItemsTable, TaskItem>(table),
                  $$TaskItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                taskOccurrenceStatesRefs = false,
                taskSubtasksRefs = false,
                taskOccurrenceOverridesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskOccurrenceStatesRefs) db.taskOccurrenceStates,
                    if (taskSubtasksRefs) db.taskSubtasks,
                    if (taskOccurrenceOverridesRefs) db.taskOccurrenceOverrides,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TaskItemsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TaskItemsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskOccurrenceStatesRefs)
                        await $_getPrefetchedData<
                          TaskItem,
                          $TaskItemsTable,
                          TaskOccurrenceStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskItemsTableReferences
                              ._taskOccurrenceStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskOccurrenceStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskSubtasksRefs)
                        await $_getPrefetchedData<
                          TaskItem,
                          $TaskItemsTable,
                          TaskSubtaskRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskItemsTableReferences
                              ._taskSubtasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskSubtasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskOccurrenceOverridesRefs)
                        await $_getPrefetchedData<
                          TaskItem,
                          $TaskItemsTable,
                          TaskOccurrenceOverrideRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskItemsTableReferences
                              ._taskOccurrenceOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskOccurrenceOverridesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TaskItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskItemsTable,
      TaskItem,
      $$TaskItemsTableFilterComposer,
      $$TaskItemsTableOrderingComposer,
      $$TaskItemsTableAnnotationComposer,
      $$TaskItemsTableCreateCompanionBuilder,
      $$TaskItemsTableUpdateCompanionBuilder,
      (TaskItem, $$TaskItemsTableReferences),
      TaskItem,
      PrefetchHooks Function({
        bool categoryId,
        bool taskOccurrenceStatesRefs,
        bool taskSubtasksRefs,
        bool taskOccurrenceOverridesRefs,
      })
    >;
typedef $$TaskOccurrenceStatesTableCreateCompanionBuilder =
    TaskOccurrenceStatesCompanion Function({
      required String taskId,
      required DateTime occurrenceDate,
      Value<bool> isCompleted,
      Value<int> rowid,
    });
typedef $$TaskOccurrenceStatesTableUpdateCompanionBuilder =
    TaskOccurrenceStatesCompanion Function({
      Value<String> taskId,
      Value<DateTime> occurrenceDate,
      Value<bool> isCompleted,
      Value<int> rowid,
    });

final class $$TaskOccurrenceStatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskOccurrenceStatesTable,
          TaskOccurrenceStateRow
        > {
  $$TaskOccurrenceStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskItemsTable _taskIdTable(_$AppDatabase db) => db.taskItems
      .createAlias('task_occurrence_states__task_id__task_items__id');

  $$TaskItemsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskItemsTableTableManager(
      $_db,
      $_db.taskItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskOccurrenceStatesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceStatesTable> {
  $$TaskOccurrenceStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskItemsTableFilterComposer get taskId {
    final $$TaskItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableFilterComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceStatesTable> {
  $$TaskOccurrenceStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskItemsTableOrderingComposer get taskId {
    final $$TaskItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableOrderingComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceStatesTable> {
  $$TaskOccurrenceStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$TaskItemsTableAnnotationComposer get taskId {
    final $$TaskItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskOccurrenceStatesTable,
          TaskOccurrenceStateRow,
          $$TaskOccurrenceStatesTableFilterComposer,
          $$TaskOccurrenceStatesTableOrderingComposer,
          $$TaskOccurrenceStatesTableAnnotationComposer,
          $$TaskOccurrenceStatesTableCreateCompanionBuilder,
          $$TaskOccurrenceStatesTableUpdateCompanionBuilder,
          (TaskOccurrenceStateRow, $$TaskOccurrenceStatesTableReferences),
          TaskOccurrenceStateRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskOccurrenceStatesTableTableManager(
    _$AppDatabase db,
    $TaskOccurrenceStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskOccurrenceStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskOccurrenceStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskOccurrenceStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<DateTime> occurrenceDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrenceStatesCompanion(
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required DateTime occurrenceDate,
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrenceStatesCompanion.insert(
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TaskOccurrenceStatesTable,
                    TaskOccurrenceStateRow
                  >(table),
                  $$TaskOccurrenceStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskOccurrenceStatesTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$TaskOccurrenceStatesTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskOccurrenceStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskOccurrenceStatesTable,
      TaskOccurrenceStateRow,
      $$TaskOccurrenceStatesTableFilterComposer,
      $$TaskOccurrenceStatesTableOrderingComposer,
      $$TaskOccurrenceStatesTableAnnotationComposer,
      $$TaskOccurrenceStatesTableCreateCompanionBuilder,
      $$TaskOccurrenceStatesTableUpdateCompanionBuilder,
      (TaskOccurrenceStateRow, $$TaskOccurrenceStatesTableReferences),
      TaskOccurrenceStateRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskSubtasksTableCreateCompanionBuilder =
    TaskSubtasksCompanion Function({
      required String id,
      required String taskId,
      required String title,
      Value<int> sortOrder,
      Value<bool> isCompleted,
      Value<int> rowid,
    });
typedef $$TaskSubtasksTableUpdateCompanionBuilder =
    TaskSubtasksCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> title,
      Value<int> sortOrder,
      Value<bool> isCompleted,
      Value<int> rowid,
    });

final class $$TaskSubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $TaskSubtasksTable, TaskSubtaskRow> {
  $$TaskSubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TaskItemsTable _taskIdTable(_$AppDatabase db) =>
      db.taskItems.createAlias('task_subtasks__task_id__task_items__id');

  $$TaskItemsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskItemsTableTableManager(
      $_db,
      $_db.taskItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TaskSubtaskOccurrenceStatesTable,
    List<TaskSubtaskOccurrenceStateRow>
  >
  _taskSubtaskOccurrenceStatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskSubtaskOccurrenceStates,
        aliasName:
            'task_subtasks__id__task_subtask_occurrence_states__subtask_id',
      );

  $$TaskSubtaskOccurrenceStatesTableProcessedTableManager
  get taskSubtaskOccurrenceStatesRefs {
    final manager = $$TaskSubtaskOccurrenceStatesTableTableManager(
      $_db,
      $_db.taskSubtaskOccurrenceStates,
    ).filter((f) => f.subtaskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskSubtaskOccurrenceStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskSubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $TaskSubtasksTable> {
  $$TaskSubtasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskItemsTableFilterComposer get taskId {
    final $$TaskItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableFilterComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskSubtaskOccurrenceStatesRefs(
    Expression<bool> Function(
      $$TaskSubtaskOccurrenceStatesTableFilterComposer f,
    )
    f,
  ) {
    final $$TaskSubtaskOccurrenceStatesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskSubtaskOccurrenceStates,
          getReferencedColumn: (t) => t.subtaskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskSubtaskOccurrenceStatesTableFilterComposer(
                $db: $db,
                $table: $db.taskSubtaskOccurrenceStates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskSubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskSubtasksTable> {
  $$TaskSubtasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskItemsTableOrderingComposer get taskId {
    final $$TaskItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableOrderingComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskSubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskSubtasksTable> {
  $$TaskSubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$TaskItemsTableAnnotationComposer get taskId {
    final $$TaskItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskSubtaskOccurrenceStatesRefs<T extends Object>(
    Expression<T> Function(
      $$TaskSubtaskOccurrenceStatesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$TaskSubtaskOccurrenceStatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskSubtaskOccurrenceStates,
          getReferencedColumn: (t) => t.subtaskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskSubtaskOccurrenceStatesTableAnnotationComposer(
                $db: $db,
                $table: $db.taskSubtaskOccurrenceStates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskSubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskSubtasksTable,
          TaskSubtaskRow,
          $$TaskSubtasksTableFilterComposer,
          $$TaskSubtasksTableOrderingComposer,
          $$TaskSubtasksTableAnnotationComposer,
          $$TaskSubtasksTableCreateCompanionBuilder,
          $$TaskSubtasksTableUpdateCompanionBuilder,
          (TaskSubtaskRow, $$TaskSubtasksTableReferences),
          TaskSubtaskRow,
          PrefetchHooks Function({
            bool taskId,
            bool taskSubtaskOccurrenceStatesRefs,
          })
        > {
  $$TaskSubtasksTableTableManager(_$AppDatabase db, $TaskSubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskSubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskSubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskSubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskSubtasksCompanion(
                id: id,
                taskId: taskId,
                title: title,
                sortOrder: sortOrder,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String title,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskSubtasksCompanion.insert(
                id: id,
                taskId: taskId,
                title: title,
                sortOrder: sortOrder,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskSubtasksTable, TaskSubtaskRow>(table),
                  $$TaskSubtasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskId = false, taskSubtaskOccurrenceStatesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskSubtaskOccurrenceStatesRefs)
                      db.taskSubtaskOccurrenceStates,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (taskId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.taskId,
                            referencedTable: $$TaskSubtasksTableReferences
                                ._taskIdTable(db),
                            referencedColumn: $$TaskSubtasksTableReferences
                                ._taskIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskSubtaskOccurrenceStatesRefs)
                        await $_getPrefetchedData<
                          TaskSubtaskRow,
                          $TaskSubtasksTable,
                          TaskSubtaskOccurrenceStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskSubtasksTableReferences
                              ._taskSubtaskOccurrenceStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskSubtasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskSubtaskOccurrenceStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subtaskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TaskSubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskSubtasksTable,
      TaskSubtaskRow,
      $$TaskSubtasksTableFilterComposer,
      $$TaskSubtasksTableOrderingComposer,
      $$TaskSubtasksTableAnnotationComposer,
      $$TaskSubtasksTableCreateCompanionBuilder,
      $$TaskSubtasksTableUpdateCompanionBuilder,
      (TaskSubtaskRow, $$TaskSubtasksTableReferences),
      TaskSubtaskRow,
      PrefetchHooks Function({
        bool taskId,
        bool taskSubtaskOccurrenceStatesRefs,
      })
    >;
typedef $$TaskSubtaskOccurrenceStatesTableCreateCompanionBuilder =
    TaskSubtaskOccurrenceStatesCompanion Function({
      required String subtaskId,
      required DateTime occurrenceDate,
      Value<bool> isCompleted,
      Value<int> rowid,
    });
typedef $$TaskSubtaskOccurrenceStatesTableUpdateCompanionBuilder =
    TaskSubtaskOccurrenceStatesCompanion Function({
      Value<String> subtaskId,
      Value<DateTime> occurrenceDate,
      Value<bool> isCompleted,
      Value<int> rowid,
    });

final class $$TaskSubtaskOccurrenceStatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskSubtaskOccurrenceStatesTable,
          TaskSubtaskOccurrenceStateRow
        > {
  $$TaskSubtaskOccurrenceStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskSubtasksTable _subtaskIdTable(_$AppDatabase db) =>
      db.taskSubtasks.createAlias(
        'task_subtask_occurrence_states__subtask_id__task_subtasks__id',
      );

  $$TaskSubtasksTableProcessedTableManager get subtaskId {
    final $_column = $_itemColumn<String>('subtask_id')!;

    final manager = $$TaskSubtasksTableTableManager(
      $_db,
      $_db.taskSubtasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subtaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskSubtaskOccurrenceStatesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskSubtaskOccurrenceStatesTable> {
  $$TaskSubtaskOccurrenceStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskSubtasksTableFilterComposer get subtaskId {
    final $$TaskSubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subtaskId,
      referencedTable: $db.taskSubtasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskSubtasksTableFilterComposer(
            $db: $db,
            $table: $db.taskSubtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskSubtaskOccurrenceStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskSubtaskOccurrenceStatesTable> {
  $$TaskSubtaskOccurrenceStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskSubtasksTableOrderingComposer get subtaskId {
    final $$TaskSubtasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subtaskId,
      referencedTable: $db.taskSubtasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskSubtasksTableOrderingComposer(
            $db: $db,
            $table: $db.taskSubtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskSubtaskOccurrenceStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskSubtaskOccurrenceStatesTable> {
  $$TaskSubtaskOccurrenceStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$TaskSubtasksTableAnnotationComposer get subtaskId {
    final $$TaskSubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subtaskId,
      referencedTable: $db.taskSubtasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskSubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.taskSubtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskSubtaskOccurrenceStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskSubtaskOccurrenceStatesTable,
          TaskSubtaskOccurrenceStateRow,
          $$TaskSubtaskOccurrenceStatesTableFilterComposer,
          $$TaskSubtaskOccurrenceStatesTableOrderingComposer,
          $$TaskSubtaskOccurrenceStatesTableAnnotationComposer,
          $$TaskSubtaskOccurrenceStatesTableCreateCompanionBuilder,
          $$TaskSubtaskOccurrenceStatesTableUpdateCompanionBuilder,
          (
            TaskSubtaskOccurrenceStateRow,
            $$TaskSubtaskOccurrenceStatesTableReferences,
          ),
          TaskSubtaskOccurrenceStateRow,
          PrefetchHooks Function({bool subtaskId})
        > {
  $$TaskSubtaskOccurrenceStatesTableTableManager(
    _$AppDatabase db,
    $TaskSubtaskOccurrenceStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskSubtaskOccurrenceStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskSubtaskOccurrenceStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskSubtaskOccurrenceStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> subtaskId = const Value.absent(),
                Value<DateTime> occurrenceDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskSubtaskOccurrenceStatesCompanion(
                subtaskId: subtaskId,
                occurrenceDate: occurrenceDate,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subtaskId,
                required DateTime occurrenceDate,
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskSubtaskOccurrenceStatesCompanion.insert(
                subtaskId: subtaskId,
                occurrenceDate: occurrenceDate,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TaskSubtaskOccurrenceStatesTable,
                    TaskSubtaskOccurrenceStateRow
                  >(table),
                  $$TaskSubtaskOccurrenceStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subtaskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subtaskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.subtaskId,
                        referencedTable:
                            $$TaskSubtaskOccurrenceStatesTableReferences
                                ._subtaskIdTable(db),
                        referencedColumn:
                            $$TaskSubtaskOccurrenceStatesTableReferences
                                ._subtaskIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskSubtaskOccurrenceStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskSubtaskOccurrenceStatesTable,
      TaskSubtaskOccurrenceStateRow,
      $$TaskSubtaskOccurrenceStatesTableFilterComposer,
      $$TaskSubtaskOccurrenceStatesTableOrderingComposer,
      $$TaskSubtaskOccurrenceStatesTableAnnotationComposer,
      $$TaskSubtaskOccurrenceStatesTableCreateCompanionBuilder,
      $$TaskSubtaskOccurrenceStatesTableUpdateCompanionBuilder,
      (
        TaskSubtaskOccurrenceStateRow,
        $$TaskSubtaskOccurrenceStatesTableReferences,
      ),
      TaskSubtaskOccurrenceStateRow,
      PrefetchHooks Function({bool subtaskId})
    >;
typedef $$TaskOccurrenceOverridesTableCreateCompanionBuilder =
    TaskOccurrenceOverridesCompanion Function({
      required String taskId,
      required DateTime occurrenceDate,
      required DateTime effectiveDate,
      required String title,
      Value<String> description,
      Value<int?> startTimeMinutes,
      Value<int?> durationMinutes,
      Value<String?> categoryId,
      Value<bool> allDay,
      Value<int> priority,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$TaskOccurrenceOverridesTableUpdateCompanionBuilder =
    TaskOccurrenceOverridesCompanion Function({
      Value<String> taskId,
      Value<DateTime> occurrenceDate,
      Value<DateTime> effectiveDate,
      Value<String> title,
      Value<String> description,
      Value<int?> startTimeMinutes,
      Value<int?> durationMinutes,
      Value<String?> categoryId,
      Value<bool> allDay,
      Value<int> priority,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$TaskOccurrenceOverridesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskOccurrenceOverridesTable,
          TaskOccurrenceOverrideRow
        > {
  $$TaskOccurrenceOverridesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskItemsTable _taskIdTable(_$AppDatabase db) => db.taskItems
      .createAlias('task_occurrence_overrides__task_id__task_items__id');

  $$TaskItemsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskItemsTableTableManager(
      $_db,
      $_db.taskItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TaskCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.taskCategories.createAlias(
        'task_occurrence_overrides__category_id__task_categories__id',
      );

  $$TaskCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$TaskCategoriesTableTableManager(
      $_db,
      $_db.taskCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskOccurrenceOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceOverridesTable> {
  $$TaskOccurrenceOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTimeMinutes => $composableBuilder(
    column: $table.startTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskItemsTableFilterComposer get taskId {
    final $$TaskItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableFilterComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TaskCategoriesTableFilterComposer get categoryId {
    final $$TaskCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.taskCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.taskCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceOverridesTable> {
  $$TaskOccurrenceOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTimeMinutes => $composableBuilder(
    column: $table.startTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskItemsTableOrderingComposer get taskId {
    final $$TaskItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableOrderingComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TaskCategoriesTableOrderingComposer get categoryId {
    final $$TaskCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.taskCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.taskCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceOverridesTable> {
  $$TaskOccurrenceOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startTimeMinutes => $composableBuilder(
    column: $table.startTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$TaskItemsTableAnnotationComposer get taskId {
    final $$TaskItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TaskCategoriesTableAnnotationComposer get categoryId {
    final $$TaskCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.taskCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskOccurrenceOverridesTable,
          TaskOccurrenceOverrideRow,
          $$TaskOccurrenceOverridesTableFilterComposer,
          $$TaskOccurrenceOverridesTableOrderingComposer,
          $$TaskOccurrenceOverridesTableAnnotationComposer,
          $$TaskOccurrenceOverridesTableCreateCompanionBuilder,
          $$TaskOccurrenceOverridesTableUpdateCompanionBuilder,
          (TaskOccurrenceOverrideRow, $$TaskOccurrenceOverridesTableReferences),
          TaskOccurrenceOverrideRow,
          PrefetchHooks Function({bool taskId, bool categoryId})
        > {
  $$TaskOccurrenceOverridesTableTableManager(
    _$AppDatabase db,
    $TaskOccurrenceOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskOccurrenceOverridesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskOccurrenceOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskOccurrenceOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<DateTime> occurrenceDate = const Value.absent(),
                Value<DateTime> effectiveDate = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> startTimeMinutes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrenceOverridesCompanion(
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                effectiveDate: effectiveDate,
                title: title,
                description: description,
                startTimeMinutes: startTimeMinutes,
                durationMinutes: durationMinutes,
                categoryId: categoryId,
                allDay: allDay,
                priority: priority,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required DateTime occurrenceDate,
                required DateTime effectiveDate,
                required String title,
                Value<String> description = const Value.absent(),
                Value<int?> startTimeMinutes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrenceOverridesCompanion.insert(
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                effectiveDate: effectiveDate,
                title: title,
                description: description,
                startTimeMinutes: startTimeMinutes,
                durationMinutes: durationMinutes,
                categoryId: categoryId,
                allDay: allDay,
                priority: priority,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TaskOccurrenceOverridesTable,
                    TaskOccurrenceOverrideRow
                  >(table),
                  $$TaskOccurrenceOverridesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable:
                            $$TaskOccurrenceOverridesTableReferences
                                ._taskIdTable(db),
                        referencedColumn:
                            $$TaskOccurrenceOverridesTableReferences
                                ._taskIdTable(db)
                                .id,
                      ) as T;
                    }
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable:
                            $$TaskOccurrenceOverridesTableReferences
                                ._categoryIdTable(db),
                        referencedColumn:
                            $$TaskOccurrenceOverridesTableReferences
                                ._categoryIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskOccurrenceOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskOccurrenceOverridesTable,
      TaskOccurrenceOverrideRow,
      $$TaskOccurrenceOverridesTableFilterComposer,
      $$TaskOccurrenceOverridesTableOrderingComposer,
      $$TaskOccurrenceOverridesTableAnnotationComposer,
      $$TaskOccurrenceOverridesTableCreateCompanionBuilder,
      $$TaskOccurrenceOverridesTableUpdateCompanionBuilder,
      (TaskOccurrenceOverrideRow, $$TaskOccurrenceOverridesTableReferences),
      TaskOccurrenceOverrideRow,
      PrefetchHooks Function({bool taskId, bool categoryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskCategoriesTableTableManager get taskCategories =>
      $$TaskCategoriesTableTableManager(_db, _db.taskCategories);
  $$TaskItemsTableTableManager get taskItems =>
      $$TaskItemsTableTableManager(_db, _db.taskItems);
  $$TaskOccurrenceStatesTableTableManager get taskOccurrenceStates =>
      $$TaskOccurrenceStatesTableTableManager(_db, _db.taskOccurrenceStates);
  $$TaskSubtasksTableTableManager get taskSubtasks =>
      $$TaskSubtasksTableTableManager(_db, _db.taskSubtasks);
  $$TaskSubtaskOccurrenceStatesTableTableManager
  get taskSubtaskOccurrenceStates =>
      $$TaskSubtaskOccurrenceStatesTableTableManager(
        _db,
        _db.taskSubtaskOccurrenceStates,
      );
  $$TaskOccurrenceOverridesTableTableManager get taskOccurrenceOverrides =>
      $$TaskOccurrenceOverridesTableTableManager(
        _db,
        _db.taskOccurrenceOverrides,
      );
}
