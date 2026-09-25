import 'package:flutter/material.dart';

import '../../core/id/id_generator.dart';
import '../../models/life_task.dart';
import '../../models/task_recurrence.dart';
import '../../models/task_subtask.dart';
import 'task_editor_mode.dart';

class TaskEditorController extends ChangeNotifier {
  final TaskEditorMode mode;
  final LifeTask? initialTask;
  final int? initialCenterTimeMinutes;
  final int? initialStartTimeMinutes;
  final IdGenerator _idGenerator;

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  int? _durationMinutes;
  String? _selectedCategoryId;
  TaskRecurrence _recurrence;
  List<TaskSubtask> _subtasks;
  bool _allDay;
  TaskPriority _priority;
  bool _centerPlacementActive;

  TaskEditorController({
    required this.mode,
    required IdGenerator idGenerator,
    this.initialTask,
    DateTime? initialDate,
    this.initialStartTimeMinutes,
    this.initialCenterTimeMinutes,
  })  : assert(
          mode == TaskEditorMode.create
              ? initialTask == null
              : initialTask != null,
          'TaskEditorMode.create non accetta initialTask; '
          'le altre modalità richiedono initialTask.',
        ),
        _idGenerator = idGenerator,
        titleController = TextEditingController(
          text: initialTask?.title ?? '',
        ),
        descriptionController = TextEditingController(
          text: initialTask?.description ?? '',
        ),
        _selectedDate = initialTask?.scheduledDate ??
            (initialDate == null
                ? null
                : DateTime(
                    initialDate.year,
                    initialDate.month,
                    initialDate.day,
                  )),
        _durationMinutes = initialTask?.durationMinutes,
        _selectedCategoryId = initialTask?.categoryId,
        _recurrence = mode == TaskEditorMode.duplicate
            ? const TaskRecurrence.none()
            : initialTask?.recurrence ??
                const TaskRecurrence.none(),
        _subtasks = _initialSubtasks(
          initialTask,
          mode,
          idGenerator,
        ),
        _allDay = initialTask?.allDay ?? false,
        _priority = initialTask?.priority ??
            TaskPriority.normal,
        _centerPlacementActive =
            initialTask == null &&
                initialCenterTimeMinutes != null {
    final sourceStartMinutes =
        initialTask?.startTimeMinutes;

    if (sourceStartMinutes != null) {
      _startTime =
          _timeOfDayFromMinutes(
        sourceStartMinutes,
      );
    } else if (_centerPlacementActive) {
      _startTime =
          _timeOfDayFromMinutes(
        _centeredWeekStartMinutes(
          _durationMinutes,
        ),
      );
    } else if (initialStartTimeMinutes != null) {
      _startTime =
          _timeOfDayFromMinutes(
        initialStartTimeMinutes!,
      );
    }
  }

  static List<TaskSubtask> _initialSubtasks(
    LifeTask? task,
    TaskEditorMode mode,
    IdGenerator idGenerator,
  ) {
    if (task == null) {
      return <TaskSubtask>[];
    }

    final sourceSubtasks =
        task.subtasks.toList()
          ..sort(
            (a, b) =>
                a.sortOrder.compareTo(
              b.sortOrder,
            ),
          );

    if (mode != TaskEditorMode.duplicate) {
      return sourceSubtasks;
    }

    final duplicateSeed =
        idGenerator.next();

    return [
      for (var index = 0;
          index < sourceSubtasks.length;
          index++)
        TaskSubtask(
          id:
              'subtask_${duplicateSeed}_$index',
          title:
              sourceSubtasks[index].title,
          sortOrder:
              index,
          isCompleted:
              false,
        ),
    ];
  }

  DateTime? get selectedDate =>
      _selectedDate;

  TimeOfDay? get startTime =>
      _startTime;

  int? get durationMinutes =>
      _durationMinutes;

  String? get selectedCategoryId =>
      _selectedCategoryId;

  TaskRecurrence get recurrence =>
      _recurrence;

  List<TaskSubtask> get subtasks =>
      List.unmodifiable(
        _subtasks,
      );

  bool get allDay =>
      _allDay;

  TaskPriority get priority =>
      _priority;

  List<TaskSubtask> get normalizedSubtasks {
    return [
      for (var index = 0;
          index < _subtasks.length;
          index++)
        _subtasks[index].copyWith(
          sortOrder:
              index,
        ),
    ];
  }

  void setDate(
    DateTime date,
  ) {
    final normalized =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (_selectedDate == normalized) {
      return;
    }

    _selectedDate =
        normalized;
    notifyListeners();
  }

  void clearDate() {
    if (_selectedDate == null &&
        !_allDay &&
        !_recurrence.isRecurring) {
      return;
    }

    _selectedDate = null;
    _allDay = false;
    _recurrence =
        const TaskRecurrence.none();
    notifyListeners();
  }

  void setStartTime(
    TimeOfDay time,
  ) {
    if (_sameTime(
          _startTime,
          time,
        ) &&
        !_centerPlacementActive) {
      return;
    }

    _startTime =
        time;
    _centerPlacementActive =
        false;
    notifyListeners();
  }

  void clearStartTime() {
    if (_startTime == null &&
        !_centerPlacementActive) {
      return;
    }

    _startTime = null;
    _centerPlacementActive =
        false;
    notifyListeners();
  }

  void setDuration(
    int? minutes,
  ) {
    final changed =
        _durationMinutes !=
            minutes;

    _durationMinutes =
        minutes;

    if (_centerPlacementActive &&
        initialCenterTimeMinutes !=
            null) {
      final centered =
          _timeOfDayFromMinutes(
        _centeredWeekStartMinutes(
          _durationMinutes,
        ),
      );

      final startChanged =
          !_sameTime(
        _startTime,
        centered,
      );

      _startTime =
          centered;

      if (changed ||
          startChanged) {
        notifyListeners();
      }

      return;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void setDurationFromManualEnd(
    int minutes,
  ) {
    final changed =
        _durationMinutes !=
                minutes ||
            _centerPlacementActive;

    _durationMinutes =
        minutes;
    _centerPlacementActive =
        false;

    if (changed) {
      notifyListeners();
    }
  }

  void setAllDay(
    bool value,
  ) {
    if (_allDay == value) {
      return;
    }

    _allDay =
        value;
    notifyListeners();
  }

  void setPriority(
    TaskPriority value,
  ) {
    if (_priority == value) {
      return;
    }

    _priority =
        value;
    notifyListeners();
  }

  void setRecurrence(
    TaskRecurrence value,
  ) {
    if (_sameRecurrence(
      _recurrence,
      value,
    )) {
      return;
    }

    _recurrence =
        value;
    notifyListeners();
  }

  void setSelectedCategoryId(
    String? value,
  ) {
    if (_selectedCategoryId ==
        value) {
      return;
    }

    _selectedCategoryId =
        value;
    notifyListeners();
  }

  void addSubtask(
    String title,
  ) {
    final trimmed =
        title.trim();

    if (trimmed.isEmpty) {
      return;
    }

    _subtasks.add(
      TaskSubtask(
        id:
            'subtask_${_idGenerator.next()}',
        title:
            trimmed,
        sortOrder:
            _subtasks.length,
      ),
    );

    notifyListeners();
  }

  void renameSubtask(
    String subtaskId,
    String title,
  ) {
    final trimmed =
        title.trim();

    if (trimmed.isEmpty) {
      return;
    }

    final index =
        _subtasks.indexWhere(
      (item) =>
          item.id == subtaskId,
    );

    if (index < 0 ||
        _subtasks[index].title ==
            trimmed) {
      return;
    }

    _subtasks[index] =
        _subtasks[index].copyWith(
      title:
          trimmed,
    );

    notifyListeners();
  }

  void removeSubtask(
    String subtaskId,
  ) {
    final previousLength =
        _subtasks.length;

    _subtasks.removeWhere(
      (item) =>
          item.id == subtaskId,
    );

    if (_subtasks.length ==
        previousLength) {
      return;
    }

    _subtasks =
        normalizedSubtasks;
    notifyListeners();
  }

  void reorderSubtasks(
    int oldIndex,
    int newIndex,
  ) {
    final item =
        _subtasks.removeAt(
      oldIndex,
    );

    _subtasks.insert(
      newIndex,
      item,
    );

    _subtasks =
        normalizedSubtasks;
    notifyListeners();
  }

  /// Categoria che la UI deve verificare nel repository prima del salvataggio.
  ///
  /// In modalità reschedule la categoria non è modificabile e quindi deriva
  /// sempre dalla task sorgente; nelle altre modalità deriva dal draft.
  String? get categoryIdForValidation {
    if (mode ==
        TaskEditorMode.reschedule) {
      return initialTask!.categoryId;
    }

    return _selectedCategoryId;
  }

  /// Costruisce il LifeTask finale applicando tutte le semantiche della
  /// modalità editor corrente.
  ///
  /// [validatedCategoryId] deve essere il risultato della verifica effettuata
  /// dal livello UI/applicativo tramite CategoryRepository. Null rappresenta
  /// "Nessuna categoria" o una categoria non più esistente.
  LifeTask buildTask({
    required String? validatedCategoryId,
  }) {
    final sourceTask =
        initialTask;

    final oldTask =
        mode.createsNewTask
            ? null
            : sourceTask;

    final enteredTitle =
        titleController.text
            .trim();

    final isReschedule =
        mode ==
        TaskEditorMode.reschedule;

    final isOccurrence =
        mode ==
        TaskEditorMode.editOccurrence;

    final isDuplicate =
        mode ==
        TaskEditorMode.duplicate;

    final title =
        isReschedule
            ? sourceTask!.title
            : enteredTitle.isEmpty
                ? 'Senza titolo'
                : enteredTitle;

    final description =
        isReschedule
            ? sourceTask!.description
            : descriptionController.text
                .trim();

    final priority =
        isReschedule
            ? sourceTask!.priority
            : _priority;

    final recurrence =
        isOccurrence
            ? sourceTask!.recurrence
            : isReschedule
                ? _selectedDate == null
                    ? const TaskRecurrence.none()
                    : sourceTask!.recurrence
                : _selectedDate == null
                    ? const TaskRecurrence.none()
                    : _recurrence;

    final effectiveAllDay =
        _selectedDate != null &&
        _allDay;

    return LifeTask(
      id:
          oldTask?.id ??
              _idGenerator.next(),
      title:
          title,
      description:
          description,
      scheduledDate:
          _selectedDate,
      startTimeMinutes:
          effectiveAllDay ||
                  _startTime == null
              ? null
              : _minutesFromTimeOfDay(
                  _startTime!,
                ),
      durationMinutes:
          _durationMinutes,
      categoryId:
          validatedCategoryId,
      allDay:
          effectiveAllDay,
      priority:
          priority,
      recurrence:
          recurrence,
      subtasks:
          isReschedule ||
                  isOccurrence
              ? sourceTask!.subtasks
              : normalizedSubtasks,
      isCompleted:
          isDuplicate
              ? false
              : oldTask?.isCompleted ??
                  false,
    );
  }

  static int _minutesFromTimeOfDay(
    TimeOfDay time,
  ) {
    return time.hour * 60 +
        time.minute;
  }

  static bool _sameTime(
    TimeOfDay? a,
    TimeOfDay? b,
  ) {
    if (a == null ||
        b == null) {
      return a == null &&
          b == null;
    }

    return a.hour == b.hour &&
        a.minute == b.minute;
  }

  static bool _sameRecurrence(
    TaskRecurrence a,
    TaskRecurrence b,
  ) {
    return a.type == b.type &&
        a.weekdaysMask ==
            b.weekdaysMask;
  }

  static TimeOfDay _timeOfDayFromMinutes(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    return TimeOfDay(
      hour:
          normalized ~/ 60,
      minute:
          normalized % 60,
    );
  }

  int _preferredWeekStartMinutes(
    double rawMinutes,
  ) {
    final nearestQuarter =
        (rawMinutes / 15).round() * 15;

    final nearestHalfHour =
        (rawMinutes / 30).round() * 30;

    final preferred =
        (rawMinutes - nearestHalfHour).abs() <= 8
            ? nearestHalfHour
            : nearestQuarter;

    return preferred
        .clamp(
          0,
          24 * 60 - 15,
        )
        .toInt();
  }

  int _centeredWeekStartMinutes(
    int? durationMinutes,
  ) {
    final center =
        initialCenterTimeMinutes;

    if (center == null) {
      return initialStartTimeMinutes ??
          0;
    }

    final effectiveDuration =
        durationMinutes != null &&
                durationMinutes > 0
            ? durationMinutes
            : 30;

    return _preferredWeekStartMinutes(
      center -
          effectiveDuration / 2,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
