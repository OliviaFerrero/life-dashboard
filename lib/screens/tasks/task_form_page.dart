import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/id/id_generator.dart';
import '../../core/time/app_clock.dart';
import '../../core/time/civil_date.dart';
import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_recurrence.dart';
import '../../repositories/category_repository.dart';
import '../../utils/task_category_icons.dart';
import '../../widgets/editorial_time_picker.dart';
import '../../widgets/task_prompts.dart';
import 'category_management_page.dart';
import 'task_editor_controller.dart';
import 'task_editor_mode.dart';
import 'task_form_subtask_widgets.dart';
import 'task_category_setting_row.dart';
import 'task_priority_selector.dart';

part 'task_form_shared_widgets.dart';
part 'task_form_date_time_widgets.dart';
part 'task_form_duration_recurrence_widgets.dart';
part 'task_form_metadata_widgets.dart';

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
        await showEditorialTimePicker(
      context: context,
      title: 'Ora inizio',
      initialTime: initialTime,
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
        await showEditorialTimePicker(
      context: context,
      title: 'Ora fine',
      initialTime: initialTime,
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
                      return const TaskCategorySettingRow(
                        statusLabel:
                            'Categorie non disponibili',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const TaskCategorySettingRow(
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

                    return TaskCategorySettingRow(
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
                TaskPrioritySelector(
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
                  TaskSubtaskEditor(
                    subtasks:
                        _editorController
                            .subtasks,
                    onAdd:
                        _editorController
                            .addSubtask,
                    onRename:
                        _editorController
                            .renameSubtask,
                    onDelete: (subtaskId) {
                      _dismissKeyboard();
                      _editorController
                          .removeSubtask(
                        subtaskId,
                      );
                    },
                    onReorder:
                        _editorController
                            .reorderSubtasks,
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

