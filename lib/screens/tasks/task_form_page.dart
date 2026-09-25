import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/id/id_generator.dart';
import '../../core/time/app_clock.dart';
import '../../core/time/civil_date.dart';
import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_recurrence.dart';
import '../../models/task_subtask.dart';
import '../../repositories/category_repository.dart';
import '../../utils/task_category_icons.dart';
import '../../widgets/task_prompts.dart';
import 'category_management_page.dart';
import 'task_editor_controller.dart';
import 'task_editor_mode.dart';

class TaskFormResult {
  final LifeTask? task;
  final bool shouldDelete;

  const TaskFormResult.save(
    this.task,
  ) : shouldDelete = false;

  const TaskFormResult.delete()
      : task = null,
        shouldDelete = true;
}

class TaskFormPage extends StatefulWidget {
  final CategoryRepository categoryRepository;
  final LifeTask? initialTask;
  final DateTime? initialDate;
  final int? initialStartTimeMinutes;

  /// Punto temporale scelto con long press nella Week. Quando presente,
  /// il form prova a mantenere il BLOCCO centrato attorno a questo minuto
  /// finché l'utente non modifica manualmente l'ora di inizio/fine.
  final int? initialCenterTimeMinutes;

  /// Modalità unica dell'editor.
  ///
  /// Sostituisce le precedenti combinazioni di flag booleani, così il form
  /// può trovarsi in un solo stato valido alla volta.
  final TaskEditorMode mode;

  const TaskFormPage({
    super.key,
    required this.categoryRepository,
    required this.mode,
    this.initialTask,
    this.initialDate,
    this.initialStartTimeMinutes,
    this.initialCenterTimeMinutes,
  }) : assert(
          mode == TaskEditorMode.create
              ? initialTask == null
              : initialTask != null,
          'TaskEditorMode.create non accetta initialTask; '
          'le altre modalità richiedono initialTask.',
        );

  @override
  State<TaskFormPage> createState() =>
      _TaskFormPageState();
}

class _TaskFormPageState
    extends State<TaskFormPage> {
  final _formKey =
      GlobalKey<FormState>();

  late IdGenerator _idGenerator;
  late TaskEditorController _editorController;
  bool _didInitializeEditorController = false;

  TextEditingController get _titleController =>
      _editorController.titleController;

  TextEditingController get _descriptionController =>
      _editorController.descriptionController;

  DateTime? get _selectedDate =>
      _editorController.selectedDate;

  TimeOfDay? get _startTime =>
      _editorController.startTime;

  int? get _durationMinutes =>
      _editorController.durationMinutes;

  String? get _selectedCategoryId =>
      _editorController.selectedCategoryId;

  TaskRecurrence get _recurrence =>
      _editorController.recurrence;

  List<TaskSubtask> get _subtasks =>
      _editorController.subtasks;

  bool get _allDay =>
      _editorController.allDay;

  TaskPriority get _priority =>
      _editorController.priority;


  bool get _isOccurrenceMode =>
      widget.mode ==
      TaskEditorMode.editOccurrence;

  bool get _isRescheduleMode =>
      widget.mode ==
      TaskEditorMode.reschedule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitializeEditorController) {
      return;
    }

    _idGenerator =
        IdGeneratorScope.read(
      context,
    );

    _editorController =
        TaskEditorController(
      mode:
          widget.mode,
      idGenerator:
          _idGenerator,
      initialTask:
          widget.initialTask,
      initialDate:
          widget.initialDate,
      initialStartTimeMinutes:
          widget.initialStartTimeMinutes,
      initialCenterTimeMinutes:
          widget.initialCenterTimeMinutes,
    );

    _didInitializeEditorController =
        true;
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager
        .instance
        .primaryFocus
        ?.unfocus();
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(
          2,
          '0',
        );
  }

  int _minutesFromTimeOfDay(
    TimeOfDay time,
  ) {
    return time.hour * 60 +
        time.minute;
  }

  TimeOfDay _timeOfDayFromMinutes(
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

  String _durationLabel(
    int? minutes,
  ) {
    if (minutes == null ||
        minutes <= 0) {
      return 'Nessuna';
    }

    final hours =
        minutes ~/ 60;

    final remaining =
        minutes % 60;

    if (hours == 0) {
      return '$remaining min';
    }

    if (remaining == 0) {
      return hours == 1
          ? '1 ora'
          : '$hours ore';
    }

    return '$hours h '
        '$remaining min';
  }

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _endTimeLabel(
    BuildContext context,
  ) {
    if (_startTime == null ||
        _durationMinutes == null) {
      return 'Nessuna';
    }

    final start =
        _minutesFromTimeOfDay(
      _startTime!,
    );

    final total =
        start + _durationMinutes!;

    final end =
        _timeOfDayFromMinutes(
      total,
    );

    final extraDays =
        total ~/ (24 * 60);

    final daySuffix =
        extraDays > 0
            ? extraDays == 1
                ? ' (+1 giorno)'
                : ' (+$extraDays giorni)'
            : '';

    return '${_twoDigits(end.hour)}:'
        '${_twoDigits(end.minute)}'
        '$daySuffix';
  }

  Future<void> _selectDate() async {
    _dismissKeyboard();

    final today =
        CivilDate.dateOnly(
      AppClockScope.read(
        context,
      ).now,
    );

    final result =
        await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.24,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _DatePickerSheet(
          initialDate:
              _selectedDate ??
                  today,
          today:
              today,
        );
      },
    );

    if (!mounted ||
        result == null) {
      return;
    }

    _editorController.setDate(
      result,
    );
  }

  void _clearDate() {
    _dismissKeyboard();

    _editorController.clearDate();
  }

  Future<void> _selectStartTime() async {
    _dismissKeyboard();

    final initialTime =
        _startTime ??
            TimeOfDay.now();

    final result =
        await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.24,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _TimePickerSheet(
          title:
              'Ora inizio',
          initialTime:
              initialTime,
        );
      },
    );

    if (!mounted ||
        result == null) {
      return;
    }

    _editorController.setStartTime(
      result,
    );
  }

  void _clearStartTime() {
    _dismissKeyboard();

    _editorController
        .clearStartTime();
  }

  Future<void> _selectEndTime() async {
    _dismissKeyboard();

    if (_startTime == null) {
      return;
    }

    final initialTime =
        _durationMinutes == null
            ? _timeOfDayFromMinutes(
                _minutesFromTimeOfDay(
                      _startTime!,
                    ) +
                    60,
              )
            : _timeOfDayFromMinutes(
                _minutesFromTimeOfDay(
                      _startTime!,
                    ) +
                    _durationMinutes!,
              );

    final result =
        await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.24,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _TimePickerSheet(
          title:
              'Ora fine',
          initialTime:
              initialTime,
        );
      },
    );

    if (!mounted ||
        result == null) {
      return;
    }

    final start =
        _minutesFromTimeOfDay(
      _startTime!,
    );

    var end =
        _minutesFromTimeOfDay(
      result,
    );

    if (end == start) {
      ScaffoldMessenger
          .of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'L’ora di fine non può '
            'coincidere con l’ora di inizio.',
          ),
        ),
      );

      return;
    }

    if (end < start) {
      end += 24 * 60;
    }

    _editorController
        .setDurationFromManualEnd(
      end - start,
    );
  }

  void _setDurationValue(
    int? minutes,
  ) {
    _editorController.setDuration(
      minutes,
    );
  }

  Future<void> _selectDuration() async {
    _dismissKeyboard();

    final result =
        await showModalBottomSheet<int>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.24,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _DurationPickerSheet(
          initialMinutes:
              _durationMinutes,
        );
      },
    );

    if (!mounted ||
        result == null) {
      return;
    }

    _setDurationValue(
      result < 0
          ? null
          : result,
    );
  }

  String _priorityLabel(
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return 'Bassa';

      case TaskPriority.normal:
        return 'Normale';

      case TaskPriority.high:
        return 'Alta';
    }
  }

  Color _priorityColor(
    BuildContext context,
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(
          0xFF5F8F73,
        );

      case TaskPriority.normal:
        return Theme.of(context)
            .colorScheme
            .primary;

      case TaskPriority.high:
        return const Color(
          0xFFC65B61,
        );
    }
  }

  String _recurrenceLabel(
    TaskRecurrence recurrence,
  ) {
    switch (recurrence.type) {
      case TaskRecurrenceType.none:
        return 'Non ripetere';

      case TaskRecurrenceType.daily:
        return 'Ogni giorno';

      case TaskRecurrenceType.weekly:
        final days =
            recurrence.weekdays;

        if (days.isEmpty) {
          return 'Ogni settimana';
        }

        if (days.length == 1) {
          return 'Ogni ${_weekdayName(days.first)}';
        }

        return days
            .map(_weekdayShortLabel)
            .join(' · ');
    }
  }

  String _weekdayName(
    int weekday,
  ) {
    const names = {
      DateTime.monday:
          'lunedì',
      DateTime.tuesday:
          'martedì',
      DateTime.wednesday:
          'mercoledì',
      DateTime.thursday:
          'giovedì',
      DateTime.friday:
          'venerdì',
      DateTime.saturday:
          'sabato',
      DateTime.sunday:
          'domenica',
    };

    return names[weekday] ??
        'settimana';
  }

  String _weekdayShortLabel(
    int weekday,
  ) {
    const labels = {
      DateTime.monday:
          'Lun',
      DateTime.tuesday:
          'Mar',
      DateTime.wednesday:
          'Mer',
      DateTime.thursday:
          'Gio',
      DateTime.friday:
          'Ven',
      DateTime.saturday:
          'Sab',
      DateTime.sunday:
          'Dom',
    };

    return labels[weekday] ?? '';
  }

  Future<void> _selectRecurrence() async {
    _dismissKeyboard();

    final selectedDate =
        _selectedDate;

    if (selectedDate == null) {
      return;
    }

    final result =
        await showModalBottomSheet<
            TaskRecurrence>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _RecurrencePickerSheet(
          initialRecurrence:
              _recurrence,
          anchorWeekday:
              selectedDate.weekday,
        );
      },
    );

    if (!mounted ||
        result == null) {
      return;
    }

    _editorController.setRecurrence(
      result,
    );
  }

  Future<String?> _editSubtaskTitle({
    String initialTitle = '',
    required String title,
    required String actionLabel,
  }) async {
    _dismissKeyboard();

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _SubtaskTitleSheet(
          title:
              title,
          actionLabel:
              actionLabel,
          initialTitle:
              initialTitle,
        );
      },
    );
  }

  Future<void> _addSubtask() async {
    final title =
        await _editSubtaskTitle(
      title:
          'Nuova sottoattività',
      actionLabel:
          'Aggiungi',
    );

    if (!mounted ||
        title == null) {
      return;
    }

    final trimmed =
        title.trim();

    if (trimmed.isEmpty) {
      return;
    }

    _editorController.addSubtask(
      trimmed,
    );
  }

  Future<void> _renameSubtask(
    TaskSubtask subtask,
  ) async {
    final title =
        await _editSubtaskTitle(
      initialTitle:
          subtask.title,
      title:
          'Modifica sottoattività',
      actionLabel:
          'Salva',
    );

    if (!mounted ||
        title == null) {
      return;
    }

    final trimmed =
        title.trim();

    if (trimmed.isEmpty) {
      return;
    }

    _editorController.renameSubtask(
      subtask.id,
      trimmed,
    );
  }

  void _removeSubtask(
    TaskSubtask subtask,
  ) {
    _dismissKeyboard();

    _editorController.removeSubtask(
      subtask.id,
    );
  }

  void _reorderSubtasks(
    int oldIndex,
    int newIndex,
  ) {
    _editorController.reorderSubtasks(
      oldIndex,
      newIndex,
    );
  }

  TaskCategory? _findCategory(
    List<TaskCategory> categories,
    String? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  Future<void> _selectCategory() async {
    _dismissKeyboard();

    final result =
        await showModalBottomSheet<
            _CategorySelectionResult>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (context) {
        return _CategoryPickerSheet(
          categoryRepository:
              widget.categoryRepository,
          selectedCategoryId:
              _selectedCategoryId,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result != null) {
      _editorController
          .setSelectedCategoryId(
        result.categoryId,
      );

      return;
    }

    final selectedId =
        _selectedCategoryId;

    if (selectedId == null) {
      return;
    }

    final stillExists =
        await widget
            .categoryRepository
            .getCategoryById(
          selectedId,
        );

    if (!mounted) {
      return;
    }

    if (stillExists == null) {
      _editorController
          .setSelectedCategoryId(
        null,
      );
    }
  }

  Future<void> _saveTask() async {
    _dismissKeyboard();

    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    final categoryId =
        _editorController
            .categoryIdForValidation;

    String? validatedCategoryId =
        categoryId;

    if (categoryId != null) {
      final category =
          await widget
              .categoryRepository
              .getCategoryById(
            categoryId,
          );

      if (category == null) {
        validatedCategoryId =
            null;
      }
    }

    if (!mounted) {
      return;
    }

    final task =
        _editorController.buildTask(
      validatedCategoryId:
          validatedCategoryId,
    );

    Navigator.pop(
      context,
      TaskFormResult.save(
        task,
      ),
    );
  }

  Future<void> _deleteTask() async {
    _dismissKeyboard();

    final confirmed =
        await TaskPrompts
            .confirmDeleteTask(
      context,
      task:
          widget.initialTask!,
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    Navigator.pop(
      context,
      const TaskFormResult.delete(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation:
          _editorController,
      builder:
          (context, _) =>
              _buildEditor(
        context,
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final screenTitle =
        switch (widget.mode) {
      TaskEditorMode.create =>
        'Nuova attività',
      TaskEditorMode.edit =>
        'Modifica attività',
      TaskEditorMode.editOccurrence =>
        'Modifica occorrenza',
      TaskEditorMode.duplicate =>
        'Duplica attività',
      TaskEditorMode.reschedule =>
        'Sposta attività',
    };

    return Scaffold(
      appBar: AppBar(
        title:
            const SizedBox
                .shrink(),
        actions: [
          if (widget.mode ==
              TaskEditorMode.edit)
            IconButton(
              tooltip:
                  'Elimina attività',
              icon:
                  const Icon(
                Icons.delete_outline,
              ),
              color:
                  colorScheme.error,
              onPressed:
                  _deleteTask,
            ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: GestureDetector(
        behavior:
            HitTestBehavior
                .translucent,
        onTap:
            _dismissKeyboard,
        child: Form(
          key:
              _formKey,
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            padding:
                const EdgeInsets
                    .fromLTRB(
              24,
              6,
              24,
              110,
            ),
            children: [
              Text(
                screenTitle,
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing:
                              -0.7,
                        ),
              ),

              if (_isOccurrenceMode) ...[
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Le modifiche valgono solo per questa occorrenza. '
                  'Ripetizione e sottoattività restano quelle della serie.',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            height:
                                1.35,
                          ),
                ),
              ],

              if (_isRescheduleMode) ...[
                const SizedBox(
                  height: 8,
                ),
                Text(
                  widget
                      .initialTask!
                      .title,
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                          ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Scegli una nuova data, un nuovo orario '
                  'oppure modifica la durata.',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            height:
                                1.35,
                          ),
                ),
                const SizedBox(
                  height: 30,
                ),
              ] else ...[
                const SizedBox(
                  height: 26,
                ),
                TextFormField(
                  controller:
                      _titleController,
                  textCapitalization:
                      TextCapitalization.sentences,
                  onTapOutside:
                      (_) {
                    _dismissKeyboard();
                  },
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                            letterSpacing:
                                -0.35,
                          ),
                  decoration:
                      InputDecoration(
                    hintText:
                        'Senza titolo',
                    hintStyle:
                        TextStyle(
                      color:
                          colorScheme
                              .onSurfaceVariant
                              .withValues(
                                alpha: 0.68,
                              ),
                    ),
                    border:
                        InputBorder.none,
                    enabledBorder:
                        InputBorder.none,
                    focusedBorder:
                        InputBorder.none,
                    contentPadding:
                        EdgeInsets.zero,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Divider(
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                            alpha: 0.58,
                          ),
                ),
                const SizedBox(
                  height: 24,
                ),
              ],

              const _FormSectionLabel(
                text:
                    'PIANIFICAZIONE',
              ),
              const SizedBox(
                height: 8,
              ),

              _SettingRow(
                icon:
                    Icons
                        .calendar_today_outlined,
                title:
                    _isOccurrenceMode
                        ? 'Data'
                        : _recurrence
                                .isRecurring
                            ? 'Inizio serie'
                            : 'Data',
                value:
                    _selectedDate ==
                            null
                        ? 'Inbox'
                        : _formatDate(
                            _selectedDate!,
                          ),
                onTap:
                    _selectDate,
                onClear:
                    _selectedDate ==
                                null ||
                            _isOccurrenceMode
                        ? null
                        : _clearDate,
              ),

              if (_selectedDate !=
                  null) ...[
                const _FormDivider(),
                _SwitchSettingRow(
                  icon:
                      Icons
                          .today_outlined,
                  title:
                      'Tutto il giorno',
                  value:
                      _allDay,
                  onChanged:
                      _editorController
                          .setAllDay,
                ),
              ],

              if (!_allDay) ...[
                const _FormDivider(),
                _SettingRow(
                  icon:
                      Icons
                          .schedule_outlined,
                  title:
                      _selectedDate ==
                              null
                          ? 'Orario preferito'
                          : 'Ora inizio',
                  value:
                      _startTime ==
                              null
                          ? 'Nessuna'
                          : '${_twoDigits(_startTime!.hour)}:'
                              '${_twoDigits(_startTime!.minute)}',
                  onTap:
                      _selectStartTime,
                  onClear:
                      _startTime ==
                              null
                          ? null
                          : _clearStartTime,
                ),

                const _FormDivider(),
                _SettingRow(
                  icon:
                      Icons
                          .more_time_outlined,
                  title:
                      'Ora fine',
                  value:
                      _endTimeLabel(
                    context,
                  ),
                  enabled:
                      _startTime !=
                          null,
                  onTap:
                      _startTime ==
                              null
                          ? null
                          : _selectEndTime,
                ),
              ],

              const _FormDivider(),
              _InlineDurationPicker(
                value:
                    _durationMinutes,
                labelBuilder:
                    _durationLabel,
                onChanged:
                    _setDurationValue,
                onCustom:
                    _selectDuration,
              ),

              if (_selectedDate !=
                      null &&
                  !_isRescheduleMode &&
                  !_isOccurrenceMode) ...[
                const _FormDivider(),
                _SettingRow(
                  icon:
                      Icons.repeat,
                  title:
                      'Ripetizione',
                  value:
                      _recurrenceLabel(
                    _recurrence,
                  ),
                  onTap:
                      _selectRecurrence,
                ),
              ],

              if (!_isRescheduleMode) ...[
                const SizedBox(
                  height: 30,
                ),
                const _FormSectionLabel(
                  text:
                      'IDENTITÀ',
                ),
                const SizedBox(
                  height: 8,
                ),

                StreamBuilder<
                    List<TaskCategory>>(
                  stream:
                      widget
                          .categoryRepository
                          .watchAllCategories(),
                  builder:
                      (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _CategorySettingRow(
                        statusLabel:
                            'Categorie non disponibili',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const _CategorySettingRow(
                        statusLabel:
                            'Caricamento…',
                      );
                    }

                    final categories =
                        snapshot.data!;

                    final selectedCategory =
                        _findCategory(
                      categories,
                      _selectedCategoryId,
                    );

                    return _CategorySettingRow(
                      category:
                          selectedCategory,
                      onTap:
                          _selectCategory,
                    );
                  },
                ),

                const SizedBox(
                  height: 18,
                ),
                Text(
                  'Priorità',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                FontWeight.w600,
                          ),
                ),
                const SizedBox(
                  height: 7,
                ),
                _PrioritySelector(
                  value:
                      _priority,
                  labelBuilder:
                      _priorityLabel,
                  colorBuilder:
                      (priority) =>
                          _priorityColor(
                    context,
                    priority,
                  ),
                  onChanged:
                      _editorController
                          .setPriority,
                ),

                if (!_isOccurrenceMode) ...[
                  const SizedBox(
                    height: 30,
                  ),
                  const _FormSectionLabel(
                    text:
                        'SOTTOATTIVITÀ',
                  ),
                  const SizedBox(
                    height: 8,
                  ),

                  if (_subtasks.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 8,
                      ),
                      child: Text(
                        'Nessuna sottoattività.',
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap:
                          true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles:
                          false,
                      itemCount:
                          _subtasks.length,
                      onReorderItem:
                          _reorderSubtasks,
                      itemBuilder:
                          (context, index) {
                        final subtask =
                            _subtasks[index];

                        return _SubtaskFormRow(
                          key:
                              ValueKey(
                            subtask.id,
                          ),
                          subtask:
                              subtask,
                          index:
                              index,
                          onTap: () {
                            _renameSubtask(
                              subtask,
                            );
                          },
                          onDelete: () {
                            _removeSubtask(
                              subtask,
                            );
                          },
                        );
                      },
                    ),

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child:
                        TextButton.icon(
                      onPressed:
                          _addSubtask,
                      icon:
                          const Icon(
                        Icons.add,
                        size: 18,
                      ),
                      label:
                          const Text(
                        'Aggiungi sottoattività',
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 28,
                ),
                const _FormSectionLabel(
                  text:
                      'NOTE',
                ),
                const SizedBox(
                  height: 7,
                ),
                TextFormField(
                  controller:
                      _descriptionController,
                  minLines:
                      3,
                  maxLines:
                      8,
                  textCapitalization:
                      TextCapitalization.sentences,
                  onTapOutside:
                      (_) {
                    _dismissKeyboard();
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Dettagli, promemoria, link…',
                    hintStyle:
                        TextStyle(
                      color:
                          colorScheme
                              .onSurfaceVariant
                              .withValues(
                                alpha: 0.78,
                              ),
                    ),
                    border:
                        InputBorder.none,
                    enabledBorder:
                        InputBorder.none,
                    focusedBorder:
                        InputBorder.none,
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 4,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Divider(
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                            alpha: 0.5,
                          ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          SafeArea(
        minimum:
            const EdgeInsets
                .fromLTRB(
          20,
          8,
          20,
          16,
        ),
        child:
            _FormPrimaryAction(
          onTap:
              _saveTask,
          icon:
              switch (widget.mode) {
            TaskEditorMode.create =>
              Icons.add,
            TaskEditorMode.edit =>
              Icons.check,
            TaskEditorMode.editOccurrence =>
              Icons.check,
            TaskEditorMode.duplicate =>
              Icons.library_add_outlined,
            TaskEditorMode.reschedule =>
              Icons.event_repeat_outlined,
          },
          label:
              switch (widget.mode) {
            TaskEditorMode.create =>
              'Crea attività',
            TaskEditorMode.edit =>
              'Salva',
            TaskEditorMode.editOccurrence =>
              'Salva occorrenza',
            TaskEditorMode.duplicate =>
              'Crea duplicato',
            TaskEditorMode.reschedule =>
              'Sposta attività',
          },
        ),
      ),
    );
  }
}

class _FormSectionLabel
    extends StatelessWidget {
  final String text;

  const _FormSectionLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(
                color:
                    Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    1.0,
              ),
    );
  }
}

class _FormDivider
    extends StatelessWidget {
  const _FormDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Divider(
      height: 1,
      indent: 44,
      color:
          Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(
                alpha: 0.5,
              ),
    );
  }
}

class _SettingRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    this.enabled = true,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Opacity(
      opacity:
          enabled
              ? 1
              : 0.42,
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              enabled
                  ? onTap
                  : null,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 12,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  child: Icon(
                    icon,
                    size: 19,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        value,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w600,
                                  height:
                                      1.15,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                if (onClear !=
                    null)
                  _TinyIconAction(
                    tooltip:
                        'Rimuovi',
                    icon:
                        Icons.close,
                    onTap:
                        onClear!,
                  )
                else
                  Icon(
                    Icons
                        .chevron_right,
                    size: 18,
                    color:
                        colorScheme
                            .onSurfaceVariant
                            .withValues(
                              alpha: 0.52,
                            ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchSettingRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>
      onChanged;

  const _SwitchSettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            () {
          onChanged(
            !value,
          );
        },
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  icon,
                  size: 19,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurfaceVariant,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      value
                          ? 'Attivo'
                          : 'Disattivo',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),
              _EditorialToggle(
                value:
                    value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TinyIconAction
    extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _TinyIconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Tooltip(
      message:
          tooltip,
      child: InkResponse(
        onTap:
            onTap,
        radius:
            20,
        child: Padding(
          padding:
              const EdgeInsets.all(
            6,
          ),
          child: Icon(
            icon,
            size: 17,
            color:
                colorScheme
                    .onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EditorialToggle
    extends StatelessWidget {
  final bool value;

  const _EditorialToggle({
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 160,
      ),
      curve:
          Curves.easeOutCubic,
      width: 42,
      height: 24,
      padding:
          const EdgeInsets.all(
        3,
      ),
      decoration:
          BoxDecoration(
        color:
            value
                ? colorScheme.primary
                    .withValues(
                      alpha: 0.14,
                    )
                : Colors
                    .transparent,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border:
            Border.all(
          color:
              value
                  ? colorScheme.primary
                  : colorScheme
                      .outlineVariant,
          width: 1.2,
        ),
      ),
      child: AnimatedAlign(
        duration:
            const Duration(
          milliseconds: 160,
        ),
        curve:
            Curves.easeOutCubic,
        alignment:
            value
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration:
              BoxDecoration(
            color:
                value
                    ? colorScheme.primary
                    : colorScheme
                        .onSurfaceVariant
                        .withValues(
                          alpha: 0.56,
                        ),
            shape:
                BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _FormPrimaryAction
    extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _FormPrimaryAction({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          colorScheme.primary,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    colorScheme
                        .onPrimary,
              ),
              const SizedBox(
                width: 9,
              ),
              Text(
                label,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onPrimary,
                          fontWeight:
                              FontWeight.w700,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryAction
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetPrimaryAction({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          colorScheme.primary,
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: SizedBox(
          width:
              double.infinity,
          height: 48,
          child: Center(
            child: Text(
              label,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color:
                            colorScheme
                                .onPrimary,
                        fontWeight:
                            FontWeight.w700,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTextAction
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetTextAction({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final effectiveColor =
        color ??
            Theme.of(context)
                .colorScheme
                .primary;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: SizedBox(
          width:
              double.infinity,
          height: 42,
          child: Center(
            child: Text(
              label,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color:
                            effectiveColor,
                        fontWeight:
                            FontWeight.w600,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberPickerField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helper;
  final ValueChanged<String>?
      onSubmitted;

  const _NumberPickerField({
    required this.controller,
    required this.label,
    this.helper,
    this.onSubmitted,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Text(
          helper == null
              ? label
              : '$label · $helper',
          style:
              Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                    color:
                        colorScheme
                            .onSurfaceVariant,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        0.2,
                  ),
        ),
        const SizedBox(
          height: 3,
        ),
        TextField(
          controller:
              controller,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],
          onSubmitted:
              onSubmitted,
          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
          decoration:
              InputDecoration(
            hintText:
                '0',
            hintStyle:
                TextStyle(
              color:
                  colorScheme
                      .onSurfaceVariant
                      .withValues(
                        alpha: 0.45,
                      ),
            ),
            border:
                InputBorder.none,
            enabledBorder:
                InputBorder.none,
            focusedBorder:
                InputBorder.none,
            isDense:
                true,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              vertical: 4,
            ),
          ),
        ),
        Container(
          height: 1,
          color:
              colorScheme
                  .outlineVariant
                  .withValues(
                    alpha: 0.78,
                  ),
        ),
      ],
    );
  }
}

class _DatePickerSheet
    extends StatefulWidget {
  final DateTime initialDate;
  final DateTime today;

  const _DatePickerSheet({
    required this.initialDate,
    required this.today,
  });

  @override
  State<_DatePickerSheet>
      createState() =>
          _DatePickerSheetState();
}

class _DatePickerSheetState
    extends State<_DatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();

    _selectedDate =
        DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    _visibleMonth =
        DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
  }

  String _monthLabel(
    DateTime month,
  ) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];

    return '${months[month.month - 1]} '
        '${month.year}';
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _changeMonth(
    int delta,
  ) {
    setState(() {
      _visibleMonth =
          DateTime(
        _visibleMonth.year,
        _visibleMonth.month +
            delta,
        1,
      );
    });
  }

  void _chooseQuick(
    DateTime date,
  ) {
    setState(() {
      _selectedDate =
          DateTime(
        date.year,
        date.month,
        date.day,
      );

      _visibleMonth =
          DateTime(
        date.year,
        date.month,
        1,
      );
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final today =
        widget.today;

    final tomorrow =
        CivilDate.nextDay(
      today,
    );

    final firstDay =
        DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final leading =
        firstDay.weekday -
            DateTime.monday;

    final dayCount =
        DateTime(
      _visibleMonth.year,
      _visibleMonth.month +
          1,
      0,
    ).day;

    final usedCells =
        leading +
            dayCount;

    final rowCount =
        (usedCells / 7)
            .ceil();

    final cellCount =
        rowCount * 7;

    return SafeArea(
      top: false,
      child: Container(
        margin:
            const EdgeInsets
                .fromLTRB(
          12,
          0,
          12,
          12,
        ),
        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          18,
          20,
          16,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme.surface,
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
                      alpha: 0.52,
                    ),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data',
                    style:
                        Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing:
                                  -0.4,
                            ),
                  ),
                ),
                _TinyIconAction(
                  tooltip:
                      'Mese precedente',
                  icon:
                      Icons
                          .chevron_left,
                  onTap:
                      () {
                    _changeMonth(
                      -1,
                    );
                  },
                ),
                const SizedBox(
                  width: 2,
                ),
                _TinyIconAction(
                  tooltip:
                      'Mese successivo',
                  icon:
                      Icons
                          .chevron_right,
                  onTap:
                      () {
                    _changeMonth(
                      1,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthLabel(
                      _visibleMonth,
                    ),
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                  ),
                ),
                _DateQuickAction(
                  label:
                      'Oggi',
                  selected:
                      _sameDay(
                    _selectedDate,
                    today,
                  ),
                  onTap:
                      () {
                    _chooseQuick(
                      today,
                    );
                  },
                ),
                const SizedBox(
                  width: 6,
                ),
                _DateQuickAction(
                  label:
                      'Domani',
                  selected:
                      _sameDay(
                    _selectedDate,
                    tomorrow,
                  ),
                  onTap:
                      () {
                    _chooseQuick(
                      tomorrow,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                for (final label
                    in const [
                  'L',
                  'M',
                  'M',
                  'G',
                  'V',
                  'S',
                  'D',
                ])
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style:
                            Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 6,
            ),
            GridView.builder(
              shrinkWrap:
                  true,
              physics:
                  const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 42,
              ),
              itemCount:
                  cellCount,
              itemBuilder:
                  (context, index) {
                final day =
                    index -
                        leading +
                        1;

                if (day < 1 ||
                    day > dayCount) {
                  return const SizedBox
                      .shrink();
                }

                final date =
                    DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  day,
                );

                final selected =
                    _sameDay(
                  date,
                  _selectedDate,
                );

                final isToday =
                    _sameDay(
                  date,
                  today,
                );

                return _CalendarDayChoice(
                  day:
                      day,
                  selected:
                      selected,
                  isToday:
                      isToday,
                  onTap:
                      () {
                    setState(() {
                      _selectedDate =
                          date;
                    });
                  },
                );
              },
            ),
            const SizedBox(
              height: 14,
            ),
            _SheetPrimaryAction(
              label:
                  'Conferma ${_selectedDate.day}/${_selectedDate.month}',
              onTap:
                  () {
                Navigator.pop(
                  context,
                  _selectedDate,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DateQuickAction
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateQuickAction({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          selected
              ? colorScheme.primary
                  .withValues(
                    alpha: 0.10,
                  )
              : Colors
                  .transparent,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          child: Text(
            label,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          selected
                              ? colorScheme.primary
                              : colorScheme
                                  .onSurfaceVariant,
                      fontWeight:
                          FontWeight.w700,
                    ),
          ),
        ),
      ),
    );
  }
}

class _CalendarDayChoice
    extends StatelessWidget {
  final int day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayChoice({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Center(
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              onTap,
          customBorder:
              const CircleBorder(),
          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 140,
            ),
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  selected
                      ? colorScheme.primary
                          .withValues(
                            alpha: 0.13,
                          )
                      : Colors
                          .transparent,
              shape:
                  BoxShape.circle,
              border:
                  selected ||
                          isToday
                      ? Border.all(
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme
                                      .outlineVariant,
                          width:
                              selected
                                  ? 1.5
                                  : 1,
                        )
                      : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme
                                      .onSurface,
                          fontWeight:
                              selected ||
                                      isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePickerSheet
    extends StatefulWidget {
  final String title;
  final TimeOfDay initialTime;

  const _TimePickerSheet({
    required this.title,
    required this.initialTime,
  });

  @override
  State<_TimePickerSheet>
      createState() =>
          _TimePickerSheetState();
}

class _TimePickerSheetState
    extends State<_TimePickerSheet> {
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController
      _hourController;

  late final FixedExtentScrollController
      _minuteController;

  @override
  void initState() {
    super.initState();

    _hour =
        widget.initialTime.hour;

    _minute =
        widget.initialTime.minute;

    _hourController =
        FixedExtentScrollController(
      initialItem:
          _hour,
    );

    _minuteController =
        FixedExtentScrollController(
      initialItem:
          _minute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _setMinute(
    int minute,
  ) {
    setState(() {
      _minute =
          minute;
    });

    _minuteController.animateToItem(
      minute,
      duration:
          const Duration(
        milliseconds: 180,
      ),
      curve:
          Curves.easeOutCubic,
    );
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(
          2,
          '0',
        );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        margin:
            const EdgeInsets
                .fromLTRB(
          12,
          0,
          12,
          12,
        ),
        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          18,
          20,
          16,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme.surface,
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
                      alpha: 0.52,
                    ),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing:
                            -0.4,
                      ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              '${_twoDigits(_hour)}:${_twoDigits(_minute)}',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight.w600,
                      ),
            ),
            const SizedBox(
              height: 14,
            ),
            SizedBox(
              height: 190,
              child: Stack(
                alignment:
                    Alignment.center,
                children: [
                  Container(
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color:
                          colorScheme
                              .surfaceContainerHighest
                              .withValues(
                                alpha: 0.34,
                              ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _TimeWheel(
                          controller:
                              _hourController,
                          itemCount:
                              24,
                          selectedValue:
                              _hour,
                          labelBuilder:
                              (value) =>
                                  _twoDigits(
                            value,
                          ),
                          onChanged:
                              (value) {
                            setState(() {
                              _hour =
                                  value;
                            });
                          },
                        ),
                      ),
                      Text(
                        ':',
                        style:
                            Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                      ),
                      Expanded(
                        child:
                            _TimeWheel(
                          controller:
                              _minuteController,
                          itemCount:
                              60,
                          selectedValue:
                              _minute,
                          labelBuilder:
                              (value) =>
                                  _twoDigits(
                            value,
                          ),
                          onChanged:
                              (value) {
                            setState(() {
                              _minute =
                                  value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                for (final minute
                    in const [
                  0,
                  15,
                  30,
                  45,
                ]) ...[
                  Expanded(
                    child:
                        _MinuteQuickChoice(
                      minute:
                          minute,
                      selected:
                          _minute ==
                              minute,
                      onTap:
                          () {
                        _setMinute(
                          minute,
                        );
                      },
                    ),
                  ),
                  if (minute !=
                      45)
                    const SizedBox(
                      width: 7,
                    ),
                ],
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            _SheetPrimaryAction(
              label:
                  'Conferma',
              onTap:
                  () {
                Navigator.pop(
                  context,
                  TimeOfDay(
                    hour:
                        _hour,
                    minute:
                        _minute,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeWheel
    extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedValue;
  final String Function(int value)
      labelBuilder;
  final ValueChanged<int>
      onChanged;

  const _TimeWheel({
    required this.controller,
    required this.itemCount,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return ListWheelScrollView.useDelegate(
      controller:
          controller,
      itemExtent:
          44,
      perspective:
          0.0025,
      diameterRatio:
          1.7,
      physics:
          const FixedExtentScrollPhysics(),
      onSelectedItemChanged:
          onChanged,
      childDelegate:
          ListWheelChildBuilderDelegate(
        childCount:
            itemCount,
        builder:
            (context, index) {
          if (index < 0 ||
              index >=
                  itemCount) {
            return null;
          }

          final selected =
              index ==
                  selectedValue;

          return Center(
            child: Text(
              labelBuilder(
                index,
              ),
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color:
                            selected
                                ? colorScheme
                                    .onSurface
                                : colorScheme
                                    .onSurfaceVariant
                                    .withValues(
                                      alpha: 0.48,
                                    ),
                        fontWeight:
                            selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                      ),
            ),
          );
        },
      ),
    );
  }
}

class _MinuteQuickChoice
    extends StatelessWidget {
  final int minute;
  final bool selected;
  final VoidCallback onTap;

  const _MinuteQuickChoice({
    required this.minute,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final label =
        ':${minute.toString().padLeft(2, '0')}';

    return Material(
      color:
          selected
              ? colorScheme.primary
                  .withValues(
                    alpha: 0.1,
                  )
              : Colors
                  .transparent,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Container(
          height: 36,
          alignment:
              Alignment.center,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? colorScheme.primary
                      : colorScheme
                          .outlineVariant
                          .withValues(
                            alpha: 0.72,
                          ),
            ),
          ),
          child: Text(
            label,
            style:
                Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color:
                          selected
                              ? colorScheme.primary
                              : colorScheme
                                  .onSurfaceVariant,
                      fontWeight:
                          FontWeight.w700,
                    ),
          ),
        ),
      ),
    );
  }
}


class _InlineDurationPicker
    extends StatelessWidget {
  final int? value;
  final String Function(
    int? minutes,
  ) labelBuilder;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCustom;

  const _InlineDurationPicker({
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    required this.onCustom,
  });

  static const _presets = <int>[
    15,
    30,
    45,
    60,
    90,
    120,
    180,
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final isCustom =
        value != null &&
            !_presets.contains(
              value,
            );

    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 12,
      ),
      child: Container(
        padding:
            const EdgeInsets
                .fromLTRB(
          14,
          13,
          14,
          12,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme
                  .surfaceContainerHighest
                  .withValues(
                    alpha: 0.30,
                  ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
                      alpha: 0.42,
                    ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  Icons
                      .timer_outlined,
                  size: 20,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durata',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      labelBuilder(
                        value,
                      ),
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurfaceVariant,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding:
                const EdgeInsets.only(
              left: 36,
            ),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _InlineDurationChoice(
                  label:
                      'Nessuna',
                  selected:
                      value == null,
                  onTap: () {
                    onChanged(
                      null,
                    );
                  },
                ),
                for (final minutes
                    in _presets)
                  _InlineDurationChoice(
                    label:
                        labelBuilder(
                      minutes,
                    ),
                    selected:
                        value ==
                            minutes,
                    onTap: () {
                      onChanged(
                        minutes,
                      );
                    },
                  ),
                _InlineDurationChoice(
                  label:
                      isCustom
                          ? 'Altro · ${labelBuilder(value)}'
                          : 'Altro',
                  selected:
                      isCustom,
                  onTap:
                      onCustom,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _InlineDurationChoice
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InlineDurationChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          6,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            7,
            5,
            7,
            4,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                label,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                          fontWeight:
                              selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                        ),
              ),
              const SizedBox(
                height: 4,
              ),
              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 140,
                ),
                height: 2,
                width:
                    selected
                        ? 22
                        : 0,
                decoration:
                    BoxDecoration(
                  color:
                      colorScheme.primary,
                  borderRadius:
                      BorderRadius.circular(
                    999,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurrencePickerSheet
    extends StatefulWidget {
  final TaskRecurrence initialRecurrence;
  final int anchorWeekday;

  const _RecurrencePickerSheet({
    required this.initialRecurrence,
    required this.anchorWeekday,
  });

  @override
  State<_RecurrencePickerSheet>
      createState() =>
          _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState
    extends State<_RecurrencePickerSheet> {
  late TaskRecurrenceType _type;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();

    _type =
        widget.initialRecurrence.type;

    _weekdays =
        widget.initialRecurrence.weekdays
            .toSet();

    if (_type ==
            TaskRecurrenceType.weekly &&
        _weekdays.isEmpty) {
      _weekdays.add(
        widget.anchorWeekday,
      );
    }
  }

  void _selectType(
    TaskRecurrenceType type,
  ) {
    setState(() {
      _type = type;

      if (_type ==
              TaskRecurrenceType.weekly &&
          _weekdays.isEmpty) {
        _weekdays.add(
          widget.anchorWeekday,
        );
      }
    });
  }

  void _toggleWeekday(
    int weekday,
  ) {
    setState(() {
      if (_weekdays.contains(
        weekday,
      )) {
        if (_weekdays.length > 1) {
          _weekdays.remove(
            weekday,
          );
        }
      } else {
        _weekdays.add(
          weekday,
        );
      }
    });
  }

  void _confirm() {
    switch (_type) {
      case TaskRecurrenceType.none:
        Navigator.pop(
          context,
          const TaskRecurrence.none(),
        );
        return;

      case TaskRecurrenceType.daily:
        Navigator.pop(
          context,
          const TaskRecurrence.daily(),
        );
        return;

      case TaskRecurrenceType.weekly:
        Navigator.pop(
          context,
          TaskRecurrence.weekly(
            _weekdays,
          ),
        );
        return;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        margin:
            const EdgeInsets
                .fromLTRB(
          12,
          0,
          12,
          12,
        ),
        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          18,
          20,
          18,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme.surface,
          borderRadius:
              BorderRadius.circular(
            24,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
              alpha: 0.55,
            ),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              'RIPETIZIONE',
              style:
                  Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w800,
                        letterSpacing:
                            1,
                      ),
            ),

            const SizedBox(
              height: 8,
            ),

            _RecurrenceChoiceRow(
              label:
                  'Non ripetere',
              selected:
                  _type ==
                      TaskRecurrenceType
                          .none,
              onTap: () {
                _selectType(
                  TaskRecurrenceType
                      .none,
                );
              },
            ),

            const _FormDivider(),

            _RecurrenceChoiceRow(
              label:
                  'Ogni giorno',
              selected:
                  _type ==
                      TaskRecurrenceType
                          .daily,
              onTap: () {
                _selectType(
                  TaskRecurrenceType
                      .daily,
                );
              },
            ),

            const _FormDivider(),

            _RecurrenceChoiceRow(
              label:
                  'Ogni settimana',
              selected:
                  _type ==
                      TaskRecurrenceType
                          .weekly,
              onTap: () {
                _selectType(
                  TaskRecurrenceType
                      .weekly,
                );
              },
            ),

            if (_type ==
                TaskRecurrenceType
                    .weekly) ...[
              const SizedBox(
                height: 16,
              ),

              Text(
                'Giorni',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  for (final weekday
                      in const [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ])
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              2,
                        ),
                        child:
                            _WeekdayChoice(
                          label:
                              const {
                            DateTime.monday:
                                'L',
                            DateTime.tuesday:
                                'M',
                            DateTime.wednesday:
                                'M',
                            DateTime.thursday:
                                'G',
                            DateTime.friday:
                                'V',
                            DateTime.saturday:
                                'S',
                            DateTime.sunday:
                                'D',
                          }[weekday]!,
                          selected:
                              _weekdays
                                  .contains(
                            weekday,
                          ),
                          onTap: () {
                            _toggleWeekday(
                              weekday,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(
              height: 22,
            ),

            _SheetPrimaryAction(
              label:
                  'Conferma',
              onTap:
                  _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrenceChoiceRow
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RecurrenceChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 13,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                selected
                                    ? colorScheme.primary
                                    : colorScheme
                                        .onSurface,
                            fontWeight:
                                selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                          ),
                ),
              ),
              AnimatedOpacity(
                duration:
                    const Duration(
                  milliseconds: 140,
                ),
                opacity:
                    selected
                        ? 1
                        : 0,
                child: Icon(
                  Icons.check_rounded,
                  size: 19,
                  color:
                      colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayChoice
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WeekdayChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 140,
          ),
          height: 36,
          decoration:
              BoxDecoration(
            color:
                selected
                    ? colorScheme.primary
                        .withValues(
                          alpha: 0.11,
                        )
                    : Colors
                        .transparent,
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? colorScheme.primary
                      : colorScheme
                          .outlineVariant
                          .withValues(
                            alpha: 0.72,
                          ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color:
                            selected
                                ? colorScheme.primary
                                : colorScheme
                                    .onSurfaceVariant,
                        fontWeight:
                            FontWeight.w700,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtaskFormRow
    extends StatelessWidget {
  final TaskSubtask subtask;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubtaskFormRow({
    super.key,
    required this.subtask,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 8,
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index:
                    index,
                child: Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    2,
                    10,
                    12,
                    10,
                  ),
                  child: Icon(
                    Icons
                        .drag_indicator,
                    size: 20,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  subtask.title,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                ),
              ),

              IconButton(
                tooltip:
                    'Rimuovi sottoattività',
                visualDensity:
                    VisualDensity
                        .compact,
                onPressed:
                    onDelete,
                icon:
                    Icon(
                  Icons.close,
                  size: 18,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtaskTitleSheet
    extends StatefulWidget {
  final String title;
  final String actionLabel;
  final String initialTitle;

  const _SubtaskTitleSheet({
    required this.title,
    required this.actionLabel,
    required this.initialTitle,
  });

  @override
  State<_SubtaskTitleSheet>
      createState() =>
          _SubtaskTitleSheetState();
}

class _SubtaskTitleSheetState
    extends State<_SubtaskTitleSheet> {
  late final TextEditingController
      _controller;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text:
          widget.initialTitle,
    );

    _controller.selection =
        TextSelection.collapsed(
      offset:
          _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value =
        _controller.text.trim();

    if (value.isEmpty) {
      setState(() {
        _errorText =
            'Inserisci un titolo.';
      });
      return;
    }

    FocusManager
        .instance
        .primaryFocus
        ?.unfocus();

    Navigator.pop(
      context,
      value,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(
          context,
        ).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin:
              const EdgeInsets
                  .fromLTRB(
            12,
            0,
            12,
            12,
          ),
          padding:
              const EdgeInsets
                  .fromLTRB(
            20,
            18,
            20,
            18,
          ),
          decoration:
              BoxDecoration(
            color:
                colorScheme.surface,
            borderRadius:
                BorderRadius.circular(
              24,
            ),
            border:
                Border.all(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.55,
              ),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                widget.title,
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
              ),

              const SizedBox(
                height: 18,
              ),

              TextField(
                controller:
                    _controller,
                autofocus:
                    true,
                textInputAction:
                    TextInputAction.done,
                onSubmitted:
                    (_) {
                  _confirm();
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Titolo sottoattività',
                  errorText:
                      _errorText,
                  border:
                      const UnderlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton(
                  onPressed:
                      _confirm,
                  child:
                      Text(
                    widget.actionLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelectionResult {
  final String? categoryId;

  const _CategorySelectionResult(
    this.categoryId,
  );
}

class _CategorySettingRow
    extends StatelessWidget {
  final TaskCategory? category;
  final String? statusLabel;
  final VoidCallback? onTap;

  const _CategorySettingRow({
    this.category,
    this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final categoryColor =
        category == null
            ? colorScheme
                .onSurfaceVariant
            : Color(
                category!.colorValue,
              );

    final label =
        statusLabel ??
            category?.name ??
            'Nessuna categoria';

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 12,
          ),

          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration:
                    BoxDecoration(
                  color:
                      categoryColor
                          .withValues(
                    alpha: 0.11,
                  ),
                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  category == null
                      ? Icons
                          .remove_circle_outline
                      : taskCategoryIcon(
                          category!
                              .iconKey,
                        ),
                  size: 18,
                  color:
                      categoryColor,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                statusLabel !=
                                        null
                                    ? colorScheme
                                        .onSurfaceVariant
                                    : null,
                          ),
                ),
              ),

              if (onTap != null)
                Icon(
                  Icons
                      .chevron_right,
                  size: 19,
                  color:
                      colorScheme
                          .onSurfaceVariant
                          .withValues(
                    alpha: 0.65,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet
    extends StatelessWidget {
  final CategoryRepository categoryRepository;
  final String? selectedCategoryId;

  const _CategoryPickerSheet({
    required this.categoryRepository,
    required this.selectedCategoryId,
  });

  Future<void> _openManagement(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CategoryManagementPage(
          categoryRepository:
              categoryRepository,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return SafeArea(
      top: false,

      child: Container(
        constraints:
            BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(
                    context,
                  ).height *
                  0.78,
        ),

        margin:
            const EdgeInsets
                .fromLTRB(
          12,
          0,
          12,
          12,
        ),

        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          18,
          20,
          12,
        ),

        decoration:
            BoxDecoration(
          color:
              colorScheme.surface,
          borderRadius:
              BorderRadius.circular(
            24,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
              alpha: 0.55,
            ),
          ),
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            Text(
              'CATEGORIA',
              style:
                  Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w800,
                        letterSpacing:
                            1.0,
                      ),
            ),

            const SizedBox(
              height: 8,
            ),

            _CategoryPickerRow(
              label:
                  'Nessuna categoria',
              icon:
                  Icons
                      .remove_circle_outline,
              color:
                  colorScheme
                      .onSurfaceVariant,
              selected:
                  selectedCategoryId ==
                      null,
              onTap: () {
                Navigator.pop(
                  context,
                  const _CategorySelectionResult(
                    null,
                  ),
                );
              },
            ),

            Divider(
              height: 1,
              indent: 46,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha: 0.45,
              ),
            ),

            Flexible(
              child: StreamBuilder<
                  List<TaskCategory>>(
                stream:
                    categoryRepository
                        .watchAllCategories(),

                builder:
                    (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 18,
                      ),
                      child: Text(
                        'Impossibile caricare '
                        'le categorie.',
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .error,
                                ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding:
                          EdgeInsets
                              .symmetric(
                        vertical: 24,
                      ),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    );
                  }

                  final categories =
                      snapshot.data!;

                  if (categories.isEmpty) {
                    return Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 18,
                      ),
                      child: Text(
                        'Non hai ancora '
                        'categorie personalizzate.',
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap:
                        true,
                    padding:
                        EdgeInsets.zero,
                    itemCount:
                        categories.length,
                    separatorBuilder:
                        (_, _) {
                      return Divider(
                        height: 1,
                        indent: 46,
                        color:
                            colorScheme
                                .outlineVariant
                                .withValues(
                          alpha:
                              0.45,
                        ),
                      );
                    },
                    itemBuilder:
                        (context, index) {
                      final category =
                          categories[index];

                      return _CategoryPickerRow(
                        label:
                            category.name,
                        icon:
                            taskCategoryIcon(
                          category.iconKey,
                        ),
                        color:
                            Color(
                          category.colorValue,
                        ),
                        selected:
                            selectedCategoryId ==
                                category.id,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _CategorySelectionResult(
                              category.id,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            Divider(
              height: 1,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha: 0.55,
              ),
            ),

            Material(
              color:
                  Colors.transparent,

              child: InkWell(
                onTap: () {
                  _openManagement(
                    context,
                  );
                },
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),

                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Icon(
                          Icons
                              .tune_outlined,
                          size: 20,
                          color:
                              colorScheme
                                  .primary,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Text(
                          'Gestisci categorie',
                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        colorScheme
                                            .primary,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                        ),
                      ),

                      Icon(
                        Icons
                            .chevron_right,
                        size: 19,
                        color:
                            colorScheme
                                .primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerRow
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPickerRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),

        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 13,
          ),

          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Align(
                  alignment:
                      Alignment
                          .centerLeft,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(
                      color:
                          color.withValues(
                        alpha: 0.11,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color:
                          color,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                selected
                                    ? FontWeight
                                        .w700
                                    : FontWeight
                                        .w500,
                          ),
                ),
              ),

              if (selected)
                Icon(
                  Icons.check,
                  size: 19,
                  color:
                      colorScheme
                          .primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySelector
    extends StatelessWidget {
  final TaskPriority value;

  final String Function(
    TaskPriority priority,
  ) labelBuilder;

  final Color Function(
    TaskPriority priority,
  ) colorBuilder;

  final ValueChanged<TaskPriority>
      onChanged;

  const _PrioritySelector({
    required this.value,
    required this.labelBuilder,
    required this.colorBuilder,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        for (int i = 0;
            i <
                TaskPriority
                    .values.length;
            i++) ...[
          Expanded(
            child: _PriorityChoice(
              priority:
                  TaskPriority
                      .values[i],
              label:
                  labelBuilder(
                TaskPriority
                    .values[i],
              ),
              color:
                  colorBuilder(
                TaskPriority
                    .values[i],
              ),
              selected:
                  value ==
                      TaskPriority
                          .values[i],
              onTap: () {
                onChanged(
                  TaskPriority
                      .values[i],
                );
              },
            ),
          ),

          if (i !=
              TaskPriority
                      .values.length -
                  1)
            const SizedBox(
              width: 12,
            ),
        ],
      ],
    );
  }
}

class _PriorityChoice
    extends StatelessWidget {
  final TaskPriority priority;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChoice({
    required this.priority,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          10,
        ),

        child: Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            4,
            10,
            4,
            7,
          ),

          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  Icon(
                    Icons
                        .flag_outlined,
                    size: 16,
                    color:
                        selected
                            ? color
                            : colorScheme
                                .onSurfaceVariant,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Flexible(
                    child: Text(
                      label,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    selected
                                        ? color
                                        : colorScheme
                                            .onSurfaceVariant,
                                fontWeight:
                                    selected
                                        ? FontWeight
                                            .w700
                                        : FontWeight
                                            .w500,
                              ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 9,
              ),

              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 150,
                ),
                height: 2,
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? color
                          : Colors
                              .transparent,
                  borderRadius:
                      BorderRadius
                          .circular(
                    2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationPickerSheet
    extends StatefulWidget {
  final int? initialMinutes;

  const _DurationPickerSheet({
    required this.initialMinutes,
  });

  @override
  State<_DurationPickerSheet>
      createState() =>
          _DurationPickerSheetState();
}

class _DurationPickerSheetState
    extends State<_DurationPickerSheet> {
  late final TextEditingController
      _hoursController;
  late final TextEditingController
      _minutesController;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    final current =
        widget.initialMinutes ?? 0;

    _hoursController =
        TextEditingController(
      text:
          current >= 60
              ? (current ~/ 60)
                  .toString()
              : '',
    );

    _minutesController =
        TextEditingController(
      text:
          current % 60 == 0
              ? ''
              : (current % 60)
                  .toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();

    super.dispose();
  }

  void _confirmCustomDuration() {
    final hours =
        int.tryParse(
              _hoursController.text,
            ) ??
            0;

    final minutes =
        int.tryParse(
              _minutesController.text,
            ) ??
            0;

    if (minutes >= 60) {
      setState(() {
        _errorText =
            'I minuti devono essere compresi tra 0 e 59.';
      });
      return;
    }

    final total =
        hours * 60 + minutes;

    if (total <= 0) {
      setState(() {
        _errorText =
            'Inserisci una durata maggiore di zero.';
      });
      return;
    }

    FocusScope.of(context)
        .unfocus();

    Navigator.pop(
      context,
      total,
    );
  }

  void _removeDuration() {
    FocusScope.of(context)
        .unfocus();

    Navigator.pop(
      context,
      -1,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            MediaQuery
                .viewInsetsOf(
          context,
        ).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin:
              const EdgeInsets
                  .fromLTRB(
            12,
            0,
            12,
            12,
          ),
          padding:
              const EdgeInsets
                  .fromLTRB(
            20,
            18,
            20,
            16,
          ),
          decoration:
              BoxDecoration(
            color:
                colorScheme.surface,
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border:
                Border.all(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                        alpha: 0.52,
                      ),
            ),
          ),
          child:
              SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Durata esatta',
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing:
                                -0.4,
                          ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Usa ore e minuti quando i valori rapidi non bastano.',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            height:
                                1.35,
                          ),
                ),
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 112,
                      child:
                          _NumberPickerField(
                        controller:
                            _hoursController,
                        label:
                            'Ore',
                        onSubmitted:
                            (_) {
                          _confirmCustomDuration();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                    ),
                    SizedBox(
                      width: 128,
                      child:
                          _NumberPickerField(
                        controller:
                            _minutesController,
                        label:
                            'Minuti',
                        helper:
                            '0–59',
                        onSubmitted:
                            (_) {
                          _confirmCustomDuration();
                        },
                      ),
                    ),
                  ],
                ),
                if (_errorText !=
                    null) ...[
                  const SizedBox(
                    height: 9,
                  ),
                  Text(
                    _errorText!,
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  colorScheme.error,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                  ),
                ],
                const SizedBox(
                  height: 18,
                ),
                _SheetPrimaryAction(
                  label:
                      'Conferma',
                  onTap:
                      _confirmCustomDuration,
                ),
                const SizedBox(
                  height: 4,
                ),
                _SheetTextAction(
                  label:
                      'Rimuovi durata',
                  onTap:
                      _removeDuration,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

