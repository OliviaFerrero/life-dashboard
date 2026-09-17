import 'package:flutter/material.dart';

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

  const TaskFormPage({
    super.key,
    this.initialTask,
    this.initialDate,
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
  TimeOfDay? _endTime;

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

      _allDay = task.allDay;

      _priority = task.priority;

      if (task.startAt != null) {
        _selectedDate = DateTime(
          task.startAt!.year,
          task.startAt!.month,
          task.startAt!.day,
        );

        if (!task.allDay) {
          _startTime =
              TimeOfDay.fromDateTime(
            task.startAt!,
          );
        }
      }

      if (task.endAt != null &&
          !task.allDay) {
        _endTime =
            TimeOfDay.fromDateTime(
          task.endAt!,
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

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? now,
      firstDate:
          DateTime(now.year - 1),
      lastDate:
          DateTime(now.year + 10),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  Future<void> _selectStartTime() async {
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

        if (_endTime != null) {
          final startMinutes =
              _startTime!.hour * 60 +
                  _startTime!.minute;

          final endMinutes =
              _endTime!.hour * 60 +
                  _endTime!.minute;

          if (endMinutes <=
              startMinutes) {
            _endTime = null;
          }
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final result =
        await showTimePicker(
      context: context,
      initialTime:
          _endTime ??
              TimeOfDay(
                hour:
                    (_startTime!.hour +
                            1) %
                        24,
                minute:
                    _startTime!.minute,
              ),
    );

    if (result != null) {
      final startMinutes =
          _startTime!.hour * 60 +
              _startTime!.minute;

      final endMinutes =
          result.hour * 60 +
              result.minute;

      if (endMinutes <=
          startMinutes) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'L’ora di fine deve essere '
              'successiva all’ora di inizio.',
            ),
          ),
        );

        return;
      }

      setState(() {
        _endTime = result;
      });
    }
  }

  DateTime? _combineDateAndTime(
    DateTime? date,
    TimeOfDay? time,
  ) {
    if (date == null) {
      return null;
    }

    if (time == null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _saveTask() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final oldTask =
        widget.initialTask;

    final task = LifeTask(
      id: oldTask?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),

      title:
          _titleController.text.trim(),

      description:
          _descriptionController.text
              .trim(),

      startAt:
          _combineDateAndTime(
        _selectedDate,
        _allDay
            ? null
            : _startTime,
      ),

      endAt: _allDay
          ? null
          : _combineDateAndTime(
              _selectedDate,
              _endTime,
            ),

      allDay: _allDay,

      priority: _priority,

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
    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
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
                  const Text('Annulla'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Elimina'),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Modifica attività'
              : 'Nuova attività',
        ),

        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Elimina attività',
              icon: const Icon(
                Icons.delete_outline,
              ),
              color:
                  colorScheme.error,
              onPressed: _deleteTask,
            ),
        ],
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            TextFormField(
              controller:
                  _titleController,

              autofocus: !_isEditing,

              decoration:
                  const InputDecoration(
                labelText: 'Titolo',
                hintText:
                    'Es. Dentista',
                border:
                    OutlineInputBorder(),
              ),

              validator: (value) {
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

              decoration:
                  const InputDecoration(
                labelText:
                    'Descrizione',
                hintText: 'Opzionale',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              'Quando',

              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),

            const SizedBox(
              height: 8,
            ),

            Card(
              margin: EdgeInsets.zero,

              child: Column(
                children: [
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
                          ? 'Nessuna data'
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
                                icon:
                                    const Icon(
                                  Icons
                                      .close,
                                ),
                                onPressed:
                                    () {
                                  setState(
                                    () {
                                      _selectedDate =
                                          null;

                                      _startTime =
                                          null;

                                      _endTime =
                                          null;
                                    },
                                  );
                                },
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

                          if (_allDay) {
                            _startTime =
                                null;

                            _endTime =
                                null;
                          }
                        });
                      },
                    ),
                  ],

                  if (_selectedDate !=
                          null &&
                      !_allDay) ...[
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
                          const Icon(
                        Icons
                            .chevron_right,
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
                            .schedule_outlined,
                      ),

                      title:
                          const Text(
                        'Ora fine',
                      ),

                      subtitle: Text(
                        _endTime ==
                                null
                            ? 'Nessuna'
                            : _endTime!
                                .format(
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

            const SizedBox(
              height: 24,
            ),

            Text(
              'Priorità',

              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
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
                      value: priority,

                      child: Text(
                        _priorityLabel(
                          priority,
                        ),
                      ),
                    ),
                  )
                  .toList(),

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _priority =
                        value;
                  });
                }
              },
            ),

            const SizedBox(
              height: 100,
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          SafeArea(
        minimum:
            const EdgeInsets.all(16),

        child: FilledButton.icon(
          onPressed: _saveTask,

          icon: Icon(
            _isEditing
                ? Icons.save_outlined
                : Icons.add_task,
          ),

          label: Text(
            _isEditing
                ? 'Salva modifiche'
                : 'Crea attività',
          ),

          style:
              FilledButton.styleFrom(
            minimumSize:
                const Size.fromHeight(
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