import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/life_task.dart';

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
  final LifeTask? initialTask;
  final DateTime? initialDate;
  final bool rescheduleOnly;

  const TaskFormPage({
    super.key,
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
  final _formKey = GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;

  int? _durationMinutes;

  bool _allDay = false;

  TaskPriority _priority =
      TaskPriority.normal;

  bool get _isEditing =>
      widget.initialTask != null;

  @override
  void initState() {
    super.initState();

    final task = widget.initialTask;

    if (task != null) {
      _titleController.text =
          task.title;

      _descriptionController.text =
          task.description;

      _selectedDate =
          task.scheduledDate;

      _durationMinutes =
          task.durationMinutes;

      _allDay =
          task.allDay;

      _priority =
          task.priority;

      if (task.startTimeMinutes != null) {
        _startTime =
            _timeOfDayFromMinutes(
          task.startTimeMinutes!,
        );
      }
    } else if (widget.initialDate != null) {
      _selectedDate = DateTime(
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
    FocusManager.instance.primaryFocus?.unfocus();
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
      hour: normalized ~/ 60,
      minute: normalized % 60,
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

    return '${hours} h '
        '${remaining} min';
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

    final now = DateTime.now();

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
        _startTime = result;
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
      initialTime: initialTime,
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

      ScaffoldMessenger.of(context)
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,

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

  void _saveTask() {
    _dismissKeyboard();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final oldTask =
        widget.initialTask;

    final title =
        widget.rescheduleOnly
            ? oldTask!.title
            : _titleController.text.trim();

    final description =
        widget.rescheduleOnly
            ? oldTask!.description
            : _descriptionController.text.trim();

    final priority =
        widget.rescheduleOnly
            ? oldTask!.priority
            : _priority;

    final effectiveAllDay =
        _selectedDate != null &&
        _allDay;

    final task = LifeTask(
      id: oldTask?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),

      title: title,

      description: description,

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

      allDay:
          effectiveAllDay,

      priority:
          priority,

      isCompleted:
          oldTask?.isCompleted ??
              false,
    );

    Navigator.pop(
      context,
      TaskFormResult.save(task),
    );
  }

  Future<void> _deleteTask() async {
    _dismissKeyboard();

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Eliminare attività?',
          ),

          content: Text(
            'Vuoi eliminare '
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
        title: Text(
          widget.rescheduleOnly
              ? 'Sposta attività'
              : _isEditing
                  ? 'Modifica attività'
                  : 'Nuova attività',
        ),

        actions: [
          if (_isEditing &&
              !widget.rescheduleOnly)
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
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,

        child: Form(
          key: _formKey,

          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,

            padding:
                const EdgeInsets.all(
              20,
            ),

          children: [
            if (widget.rescheduleOnly) ...[
              Text(
                widget
                    .initialTask!
                    .title,
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
                height: 6,
              ),

              Text(
                'Scegli una nuova '
                'pianificazione. La durata '
                'rimane modificabile.',
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
                height: 28,
              ),
            ] else ...[
              TextFormField(
                controller:
                    _titleController,

                autofocus:
                    !_isEditing,

                onTapOutside: (_) {
                  _dismissKeyboard();
                },

                decoration:
                    const InputDecoration(
                  labelText:
                      'Titolo',
                  hintText:
                      'Es. Dentista',
                  border:
                      OutlineInputBorder(),
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
                height: 16,
              ),

              TextFormField(
                controller:
                    _descriptionController,

                maxLines: 3,

                onTapOutside: (_) {
                  _dismissKeyboard();
                },

                decoration:
                    const InputDecoration(
                  labelText:
                      'Descrizione',
                  hintText:
                      'Opzionale',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 24,
              ),
            ],

            Text(
              'Pianificazione',
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
              height: 8,
            ),

            Card(
              margin:
                  EdgeInsets.zero,

              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .timer_outlined,
                    ),

                    title:
                        const Text(
                      'Durata',
                    ),

                    subtitle: Text(
                      _durationLabel(
                        _durationMinutes,
                      ),
                    ),

                    trailing:
                        const Icon(
                      Icons
                          .chevron_right,
                    ),

                    onTap:
                        _selectDuration,
                  ),

                  const Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .calendar_today_outlined,
                    ),

                    title:
                        const Text(
                      'Data',
                    ),

                    subtitle: Text(
                      _selectedDate ==
                              null
                          ? 'Nessuna data · Inbox'
                          : _formatDate(
                              _selectedDate!,
                            ),
                    ),

                    trailing:
                        _selectedDate ==
                                null
                            ? const Icon(
                                Icons
                                    .chevron_right,
                              )
                            : IconButton(
                                tooltip:
                                    'Rimuovi data',
                                icon:
                                    const Icon(
                                  Icons
                                      .close,
                                ),
                                onPressed:
                                    _clearDate,
                              ),

                    onTap:
                        _selectDate,
                  ),

                  if (_selectedDate !=
                      null) ...[
                    const Divider(
                      height: 1,
                    ),

                    SwitchListTile(
                      secondary:
                          const Icon(
                        Icons
                            .today_outlined,
                      ),

                      title:
                          const Text(
                        'Tutto il giorno',
                      ),

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
                    const Divider(
                      height: 1,
                    ),

                    ListTile(
                      leading:
                          const Icon(
                        Icons.schedule,
                      ),

                      title:
                          const Text(
                        'Ora inizio',
                      ),

                      subtitle: Text(
                        _startTime ==
                                null
                            ? 'Nessuna'
                            : _startTime!
                                .format(
                                  context,
                                ),
                      ),

                      trailing:
                          _startTime ==
                                  null
                              ? const Icon(
                                  Icons
                                      .chevron_right,
                                )
                              : IconButton(
                                  tooltip:
                                      'Rimuovi orario',
                                  icon:
                                      const Icon(
                                    Icons
                                        .close,
                                  ),
                                  onPressed:
                                      _clearStartTime,
                                ),

                      onTap:
                          _selectStartTime,
                    ),

                    const Divider(
                      height: 1,
                    ),

                    ListTile(
                      enabled:
                          _startTime !=
                              null,

                      leading:
                          const Icon(
                        Icons
                            .more_time_outlined,
                      ),

                      title:
                          const Text(
                        'Ora fine',
                      ),

                      subtitle: Text(
                        _endTimeLabel(
                          context,
                        ),
                      ),

                      trailing:
                          const Icon(
                        Icons
                            .chevron_right,
                      ),

                      onTap:
                          _startTime ==
                                  null
                              ? null
                              : _selectEndTime,
                    ),
                  ],
                ],
              ),
            ),

            if (!widget
                .rescheduleOnly) ...[
              const SizedBox(
                height: 24,
              ),

              Text(
                'Priorità',
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
                height: 8,
              ),

              DropdownButtonFormField<
                  TaskPriority>(
                initialValue:
                    _priority,

                decoration:
                    const InputDecoration(
                  border:
                      OutlineInputBorder(),
                ),

                items: TaskPriority
                    .values
                    .map(
                      (priority) =>
                          DropdownMenuItem(
                        value:
                            priority,
                        child: Text(
                          _priorityLabel(
                            priority,
                          ),
                        ),
                      ),
                    )
                    .toList(),

                onChanged:
                    (value) {
                  if (value != null) {
                    setState(() {
                      _priority =
                          value;
                    });
                  }
                },
              ),
            ],

            const SizedBox(
              height: 100,
            ),
            ],
          ),
        ),
      ),

      bottomNavigationBar:
          SafeArea(
        minimum:
            const EdgeInsets.all(
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
                        .save_outlined
                    : Icons
                        .add_task,
          ),

          label: Text(
            widget.rescheduleOnly
                ? 'Sposta attività'
                : _isEditing
                    ? 'Salva modifiche'
                    : 'Crea attività',
          ),

          style:
              FilledButton.styleFrom(
            minimumSize:
                const Size
                    .fromHeight(
              54,
            ),
            backgroundColor:
                colorScheme.primary,
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
      text: current >= 60
          ? (current ~/ 60)
              .toString()
          : '',
    );

    _minutesController =
        TextEditingController(
      text: current % 60 == 0
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

    return '${hours} h '
        '${remaining} min';
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
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(
          context,
        ).bottom,
      ),

      child: SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,

        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          4,
          20,
          24,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

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
              height: 6,
            ),

            Text(
              'Scegli una durata rapida '
              'oppure inserisci ore e minuti '
              'con precisione al minuto.',

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

            Text(
              'Scelte rapide',

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
              height: 10,
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
                  ActionChip(
                    label: Text(
                      _durationLabel(
                        minutes,
                      ),
                    ),

                    onPressed: () {
                      _applyQuickDuration(
                        minutes,
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(
              height: 26,
            ),

            Text(
              'Durata personalizzata',

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
              height: 10,
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _hoursController,

                    onTapOutside: (_) {
                      FocusManager.instance
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
                          OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: TextField(
                    controller:
                        _minutesController,

                    onTapOutside: (_) {
                      FocusManager.instance
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
                          OutlineInputBorder(),
                    ),

                    onSubmitted: (_) {
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
                  'Conferma durata',
                ),
              ),
            ),

            const SizedBox(
              height: 8,
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

