import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_recurrence.dart';
import '../../repositories/category_repository.dart';
import '../../utils/task_category_icons.dart';
import 'category_management_page.dart';

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
  final bool rescheduleOnly;

  const TaskFormPage({
    super.key,
    required this.categoryRepository,
    this.initialTask,
    this.initialDate,
    this.rescheduleOnly = false,
  });

  @override
  State<TaskFormPage> createState() =>
      _TaskFormPageState();
}

class _TaskFormPageState
    extends State<TaskFormPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;

  int? _durationMinutes;

  String? _selectedCategoryId;

  TaskRecurrence _recurrence =
      const TaskRecurrence.none();

  bool _allDay = false;

  TaskPriority _priority =
      TaskPriority.normal;

  bool get _isEditing =>
      widget.initialTask != null;

  @override
  void initState() {
    super.initState();

    final task =
        widget.initialTask;

    if (task != null) {
      _titleController.text =
          task.title;

      _descriptionController.text =
          task.description;

      _selectedDate =
          task.scheduledDate;

      _durationMinutes =
          task.durationMinutes;

      _selectedCategoryId =
          task.categoryId;

      _recurrence =
          task.recurrence;

      _allDay =
          task.allDay;

      _priority =
          task.priority;

      if (task.startTimeMinutes !=
          null) {
        _startTime =
            _timeOfDayFromMinutes(
          task.startTimeMinutes!,
        );
      }
    } else if (widget.initialDate !=
        null) {
      _selectedDate =
          DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager
        .instance
        .primaryFocus
        ?.unfocus();
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

    return '${end.format(context)}'
        '$daySuffix';
  }

  Future<void> _selectDate() async {
    _dismissKeyboard();

    final now =
        DateTime.now();

    final result =
        await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? now,
      firstDate:
          DateTime(now.year - 5),
      lastDate:
          DateTime(now.year + 10),
    );

    if (result != null) {
      setState(() {
        _selectedDate =
            DateTime(
          result.year,
          result.month,
          result.day,
        );
      });
    }
  }

  void _clearDate() {
    _dismissKeyboard();

    setState(() {
      _selectedDate = null;
      _allDay = false;
      _recurrence =
          const TaskRecurrence.none();
    });
  }

  Future<void> _selectStartTime() async {
    _dismissKeyboard();

    final result =
        await showTimePicker(
      context: context,
      initialTime:
          _startTime ??
              TimeOfDay.now(),
    );

    if (result != null) {
      setState(() {
        _startTime =
            result;
      });
    }
  }

  void _clearStartTime() {
    _dismissKeyboard();

    setState(() {
      _startTime = null;
    });
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
        await showTimePicker(
      context: context,
      initialTime:
          initialTime,
    );

    if (result == null) {
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
      if (!mounted) {
        return;
      }

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

    setState(() {
      _durationMinutes =
          end - start;
    });
  }

  Future<void> _selectDuration() async {
    _dismissKeyboard();

    final result =
        await showModalBottomSheet<int>(
      context: context,
      isScrollControlled:
          true,
      useSafeArea:
          true,
      showDragHandle:
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

    setState(() {
      _durationMinutes =
          result < 0
              ? null
              : result;
    });
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

    setState(() {
      _recurrence =
          result;
    });
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
      setState(() {
        _selectedCategoryId =
            result.categoryId;
      });

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
      setState(() {
        _selectedCategoryId =
            null;
      });
    }
  }

  Future<void> _saveTask() async {
    _dismissKeyboard();

    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    final oldTask =
        widget.initialTask;

    final title =
        widget.rescheduleOnly
            ? oldTask!.title
            : _titleController.text
                .trim();

    final description =
        widget.rescheduleOnly
            ? oldTask!.description
            : _descriptionController
                .text
                .trim();

    final priority =
        widget.rescheduleOnly
            ? oldTask!.priority
            : _priority;

    String? categoryId =
        widget.rescheduleOnly
            ? oldTask!.categoryId
            : _selectedCategoryId;

    if (categoryId != null) {
      final category =
          await widget
              .categoryRepository
              .getCategoryById(
            categoryId,
          );

      if (category == null) {
        categoryId = null;
      }
    }

    if (!mounted) {
      return;
    }

    final recurrence =
        widget.rescheduleOnly
            ? _selectedDate == null
                ? const TaskRecurrence.none()
                : oldTask!.recurrence
            : _selectedDate == null
                ? const TaskRecurrence.none()
                : _recurrence;

    final effectiveAllDay =
        _selectedDate != null &&
        _allDay;

    final task =
        LifeTask(
      id:
          oldTask?.id ??
              DateTime.now()
                  .microsecondsSinceEpoch
                  .toString(),

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
          categoryId,

      allDay:
          effectiveAllDay,

      priority:
          priority,

      recurrence:
          recurrence,

      isCompleted:
          oldTask?.isCompleted ??
              false,
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
        await showDialog<bool>(
      context: context,

      builder: (context) {
        final recurring =
            widget.initialTask!
                .recurrence
                .isRecurring;

        return AlertDialog(
          title:
              Text(
            recurring
                ? 'Eliminare serie?'
                : 'Eliminare attività?',
          ),
          content: Text(
            recurring
                ? 'Vuoi eliminare tutta la serie '
                    '"${widget.initialTask!.title}"?'
                : 'Vuoi eliminare '
                    '"${widget.initialTask!.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Annulla',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Elimina',
              ),
            ),
          ],
        );
      },
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
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:
            const SizedBox
                .shrink(),

        actions: [
          if (_isEditing &&
              !widget.rescheduleOnly)
            IconButton(
              tooltip:
                  'Elimina attività',
              icon:
                  const Icon(
                Icons
                    .delete_outline,
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
              8,
              24,
              120,
            ),

            children: [
              Text(
                widget.rescheduleOnly
                    ? 'Sposta attività'
                    : _isEditing
                        ? 'Modifica attività'
                        : 'Nuova attività',

                style:
                    Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                          letterSpacing:
                              -0.7,
                        ),
              ),

              if (widget
                  .rescheduleOnly) ...[
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
                                FontWeight
                                    .w600,
                          ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Scegli una nuova data, '
                  'un nuovo orario oppure '
                  'modifica la durata.',
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

                const SizedBox(
                  height: 34,
                ),
              ] else ...[
                const SizedBox(
                  height: 28,
                ),

                TextFormField(
                  controller:
                      _titleController,

                  autofocus:
                      !_isEditing,

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
                                FontWeight
                                    .w600,
                          ),

                  decoration:
                      InputDecoration(
                    hintText:
                        'Titolo attività',
                    hintStyle:
                        TextStyle(
                      color:
                          colorScheme
                              .onSurfaceVariant
                              .withValues(
                        alpha:
                            0.75,
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

                  validator:
                      (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Inserisci un titolo.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                Divider(
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.65,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                TextFormField(
                  controller:
                      _descriptionController,

                  minLines: 2,
                  maxLines: 5,

                  onTapOutside:
                      (_) {
                    _dismissKeyboard();
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        'Aggiungi una descrizione…',
                    hintStyle:
                        TextStyle(
                      color:
                          colorScheme
                              .onSurfaceVariant,
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
                  height: 30,
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
                        .timer_outlined,
                title:
                    'Durata',
                value:
                    _durationLabel(
                  _durationMinutes,
                ),
                onTap:
                    _selectDuration,
              ),

              const _FormDivider(),

              _SettingRow(
                icon:
                    Icons
                        .calendar_today_outlined,
                title:
                    _recurrence
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
                            null
                        ? null
                        : _clearDate,
              ),

              if (_selectedDate !=
                      null &&
                  !widget
                      .rescheduleOnly) ...[
                const _FormDivider(),

                _SettingRow(
                  icon:
                      Icons.repeat,
                  title:
                      'Ripeti',
                  value:
                      _recurrenceLabel(
                    _recurrence,
                  ),
                  onTap:
                      _selectRecurrence,
                ),
              ],

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
                      (value) {
                    setState(() {
                      _allDay =
                          value;
                    });
                  },
                ),
              ],

              if (!_allDay) ...[
                const _FormDivider(),

                _SettingRow(
                  icon:
                      Icons.schedule,
                  title:
                      'Ora inizio',
                  value:
                      _startTime ==
                              null
                          ? 'Nessuna'
                          : _startTime!
                              .format(
                                context,
                              ),
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

              if (!widget
                  .rescheduleOnly) ...[
                const SizedBox(
                  height: 34,
                ),

                const _FormSectionLabel(
                  text:
                      'CATEGORIA',
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
                  height: 34,
                ),

                const _FormSectionLabel(
                  text:
                      'PRIORITÀ',
                ),

                const SizedBox(
                  height: 12,
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
                      (priority) {
                    setState(() {
                      _priority =
                          priority;
                    });
                  },
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
            FilledButton.icon(
          onPressed:
              _saveTask,

          icon: Icon(
            widget.rescheduleOnly
                ? Icons
                    .event_repeat_outlined
                : _isEditing
                    ? Icons
                        .check
                    : Icons
                        .add,
          ),

          label: Text(
            widget.rescheduleOnly
                ? 'Sposta attività'
                : _isEditing
                    ? 'Salva'
                    : 'Crea attività',
          ),

          style:
              FilledButton
                  .styleFrom(
            minimumSize:
                const Size
                    .fromHeight(
              54,
            ),
          ),
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

          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 16,
            ),

            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Icon(
                    icon,
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
                  child: Text(
                    title,
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Flexible(
                  child: Text(
                    value,
                    textAlign:
                        TextAlign.right,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
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
                              fontWeight:
                                  FontWeight
                                      .w500,
                            ),
                  ),
                ),

                if (onClear !=
                    null) ...[
                  const SizedBox(
                    width: 4,
                  ),

                  IconButton(
                    tooltip:
                        'Rimuovi',
                    visualDensity:
                        VisualDensity
                            .compact,
                    onPressed:
                        onClear,
                    icon:
                        const Icon(
                      Icons.close,
                      size: 18,
                    ),
                  ),
                ] else ...[
                  const SizedBox(
                    width: 8,
                  ),

                  Icon(
                    Icons
                        .chevron_right,
                    size: 18,
                    color:
                        colorScheme
                            .onSurfaceVariant
                            .withValues(
                      alpha: 0.6,
                    ),
                  ),
                ],
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

    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 8,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(
              icon,
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
            child: Text(
              title,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
            ),
          ),

          Switch.adaptive(
            value:
                value,
            onChanged:
                onChanged,
          ),
        ],
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

            SizedBox(
              width:
                  double.infinity,
              child:
                  FilledButton(
                onPressed:
                    _confirm,
                child:
                    const Text(
                  'Conferma',
                ),
              ),
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
                width: 32,
                child: Icon(
                  selected
                      ? Icons
                          .radio_button_checked
                      : Icons
                          .radio_button_unchecked,
                  size: 20,
                  color:
                      selected
                          ? colorScheme
                              .primary
                          : colorScheme
                              .onSurfaceVariant,
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
          selected
              ? colorScheme.primary
              : Colors.transparent,
      shape:
          const CircleBorder(),
      child: InkWell(
        onTap:
            onTap,
        customBorder:
            const CircleBorder(),
        child: AspectRatio(
          aspectRatio: 1,
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
                                ? colorScheme
                                    .onPrimary
                                : colorScheme
                                    .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
            ),
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

  String _durationLabel(
    int minutes,
  ) {
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

  void _applyQuickDuration(
    int minutes,
  ) {
    FocusScope.of(context)
        .unfocus();

    Navigator.pop(
      context,
      minutes,
    );
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
            'I minuti devono essere '
            'compresi tra 0 e 59.';
      });
      return;
    }

    final total =
        hours * 60 + minutes;

    if (total <= 0) {
      setState(() {
        _errorText =
            'Inserisci una durata '
            'maggiore di zero.';
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

      child:
          SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,

        padding:
            const EdgeInsets
                .fromLTRB(
          22,
          4,
          22,
          24,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            Text(
              'Durata',
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
              height: 5,
            ),

            Text(
              'Scelta rapida oppure '
              'precisione al minuto.',
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

            const SizedBox(
              height: 20,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,

              children: [
                for (final minutes
                    in const [
                  5,
                  10,
                  15,
                  20,
                  25,
                  30,
                  45,
                  60,
                  90,
                  120,
                ])
                  _QuickDuration(
                    label:
                        _durationLabel(
                      minutes,
                    ),
                    selected:
                        widget.initialMinutes ==
                            minutes,
                    onTap: () {
                      _applyQuickDuration(
                        minutes,
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            Text(
              'Personalizzata',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      TextField(
                    controller:
                        _hoursController,

                    onTapOutside:
                        (_) {
                      FocusManager
                          .instance
                          .primaryFocus
                          ?.unfocus();
                    },

                    keyboardType:
                        TextInputType
                            .number,

                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Ore',
                      hintText:
                          '0',
                      border:
                          UnderlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 22,
                ),

                Expanded(
                  child:
                      TextField(
                    controller:
                        _minutesController,

                    onTapOutside:
                        (_) {
                      FocusManager
                          .instance
                          .primaryFocus
                          ?.unfocus();
                    },

                    keyboardType:
                        TextInputType
                            .number,

                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Minuti',
                      hintText:
                          '0',
                      helperText:
                          '0–59',
                      border:
                          UnderlineInputBorder(),
                    ),

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
                height: 10,
              ),

              Text(
                _errorText!,
                style:
                    TextStyle(
                  color:
                      colorScheme
                          .error,
                ),
              ),
            ],

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  FilledButton(
                onPressed:
                    _confirmCustomDuration,
                child:
                    const Text(
                  'Conferma',
                ),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  TextButton(
                onPressed:
                    _removeDuration,
                child:
                    const Text(
                  'Rimuovi durata',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDuration
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickDuration({
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
                    alpha: 0.1,
                  )
              : Colors
                  .transparent,

      borderRadius:
          BorderRadius.circular(
        999,
      ),

      child: InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          999,
        ),

        child: Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 13,
            vertical: 8,
          ),

          decoration:
              BoxDecoration(
            border:
                Border.all(
              color:
                  selected
                      ? colorScheme
                          .primary
                      : colorScheme
                          .outlineVariant,
            ),
            borderRadius:
                BorderRadius
                    .circular(
              999,
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
                              ? colorScheme
                                  .primary
                              : colorScheme
                                  .onSurface,
                      fontWeight:
                          selected
                              ? FontWeight
                                  .w700
                              : FontWeight
                                  .w500,
                    ),
          ),
        ),
      ),
    );
  }
}
