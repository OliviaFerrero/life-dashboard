import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_occurrence.dart';
import '../../models/task_recurrence.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../utils/task_category_icons.dart';
import 'task_form_page.dart';

class TaskDetailPage extends StatefulWidget {
  final LifeTask task;
  final TaskOccurrence? occurrence;
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.occurrence,
    required this.taskRepository,
    required this.categoryRepository,
  });

  @override
  State<TaskDetailPage> createState() =>
      _TaskDetailPageState();
}

class _TaskDetailPageState
    extends State<TaskDetailPage> {
  late LifeTask _task;
  late bool _isCompleted;
  DateTime? _occurrenceDate;

  @override
  void initState() {
    super.initState();

    _task = widget.task;
    _occurrenceDate =
        widget.occurrence?.date ??
            widget.task.scheduledDate;
    _isCompleted =
        widget.occurrence?.isCompleted ??
            widget.task.isCompleted;
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(2, '0');
  }

  String _formatClockMinutes(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
  }

  String _formatEndTime(
    LifeTask task,
  ) {
    final start =
        task.startTimeMinutes;
    final duration =
        task.durationMinutes;

    if (start == null ||
        duration == null) {
      return '';
    }

    final total =
        start + duration;
    final extraDays =
        total ~/ (24 * 60);

    final suffix =
        extraDays == 0
            ? ''
            : extraDays == 1
                ? ' (+1 giorno)'
                : ' (+$extraDays giorni)';

    return '${_formatClockMinutes(total)}'
        '$suffix';
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

    return '$hours h $remaining min';
  }

  String _dateLabel(
    DateTime date,
  ) {
    const weekdays = [
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica',
    ];

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

    return '${weekdays[date.weekday - 1]} '
        '${date.day} '
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
        return 'Non ricorrente';

      case TaskRecurrenceType.daily:
        return 'Ogni giorno';

      case TaskRecurrenceType.weekly:
        final days =
            recurrence.weekdays;

        if (days.isEmpty) {
          return 'Ogni settimana';
        }

        if (days.length == 1) {
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

          return 'Ogni '
              '${names[days.first]}';
        }

        const short = {
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

        return days
            .map(
              (day) =>
                  short[day]!,
            )
            .join(' · ');
    }
  }

  bool _isPastUnfinished() {
    if (_isCompleted ||
        _task.recurrence.isRecurring) {
      return false;
    }

    final dateValue =
        _occurrenceDate ??
            _task.scheduledDate;

    if (dateValue == null) {
      return false;
    }

    final now =
        DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final date =
        DateTime(
      dateValue.year,
      dateValue.month,
      dateValue.day,
    );

    if (date.isBefore(today)) {
      return true;
    }

    if (date.isAfter(today)) {
      return false;
    }

    if (_task.allDay ||
        _task.startTimeMinutes ==
            null) {
      return false;
    }

    final cutoffMinutes =
        _task.startTimeMinutes! +
        (_task.durationMinutes ?? 0);

    final cutoff =
        date.add(
      Duration(
        minutes:
            cutoffMinutes,
      ),
    );

    return now.isAfter(
      cutoff,
    );
  }

  Future<void> _setCompleted(
    bool completed,
  ) async {
    final date =
        _occurrenceDate ??
            _task.scheduledDate;

    if (_task.recurrence.isRecurring &&
        date != null) {
      await widget.taskRepository
          .setOccurrenceCompleted(
        TaskOccurrence(
          task:
              _task,
          date:
              date,
          isCompleted:
              _isCompleted,
        ),
        completed,
      );
    } else {
      await widget.taskRepository
          .setCompleted(
        _task.id,
        completed,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isCompleted =
          completed;

      if (!_task.recurrence
          .isRecurring) {
        _task.isCompleted =
            completed;
      }
    });
  }

  Future<void> _editTask() async {
    final wasRecurring =
        _task.recurrence.isRecurring;

    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          initialTask:
              _task,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.shouldDelete) {
      await widget.taskRepository
          .deleteTask(
        _task.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
      );
      return;
    }

    final updatedTask =
        result.task;

    if (updatedTask == null) {
      return;
    }

    await widget.taskRepository
        .updateTask(
      updatedTask,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _task =
          updatedTask;

      if (!_task.recurrence
          .isRecurring) {
        _occurrenceDate =
            _task.scheduledDate;
        _isCompleted =
            _task.isCompleted;
      } else {
        final currentDate =
            _occurrenceDate;

        if (!wasRecurring ||
            currentDate == null ||
            _task.scheduledDate ==
                null ||
            !_task.recurrence
                .occursOn(
              currentDate,
              _task
                  .scheduledDate!,
            )) {
          _occurrenceDate =
              _task.scheduledDate;
          _isCompleted =
              false;
        }
      }
    });
  }

  Future<void> _rescheduleTask() async {
    if (_task.recurrence.isRecurring) {
      return;
    }

    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          initialTask:
              _task,
          rescheduleOnly:
              true,
        ),
      ),
    );

    final updatedTask =
        result?.task;

    if (updatedTask == null) {
      return;
    }

    await widget.taskRepository
        .updateTask(
      updatedTask,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _task =
          updatedTask;
      _occurrenceDate =
          updatedTask.scheduledDate;
      _isCompleted =
          updatedTask.isCompleted;
    });
  }

  Future<void> _deleteTask() async {
    final recurring =
        _task.recurrence.isRecurring;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            recurring
                ? 'Eliminare serie?'
                : 'Eliminare attività?',
          ),
          content: Text(
            recurring
                ? 'Vuoi eliminare tutta la serie '
                    '"${_task.title}"?'
                : 'Vuoi eliminare '
                    '"${_task.title}"?',
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

    if (confirmed != true) {
      return;
    }

    await widget.taskRepository
        .deleteTask(
      _task.id,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
    );
  }

  Future<void> _showTaskActions() async {
    final recurring =
        _task.recurrence.isRecurring;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      isScrollControlled:
          false,
      builder: (sheetContext) {
        final colorScheme =
            Theme.of(sheetContext)
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
              10,
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
                  'AZIONI',
                  style:
                      Theme.of(
                    sheetContext,
                  )
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
                _ActionSheetRow(
                  icon:
                      Icons
                          .edit_outlined,
                  label:
                      recurring
                          ? 'Modifica serie'
                          : 'Modifica',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _editTask();
                  },
                ),
                Divider(
                  height: 1,
                  indent: 44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _ActionSheetRow(
                  icon:
                      Icons
                          .delete_outline,
                  label:
                      recurring
                          ? 'Elimina serie'
                          : 'Elimina',
                  isDestructive:
                      true,
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _deleteTask();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final priorityColor =
        _priorityColor(
      context,
      _task.priority,
    );

    final isPast =
        _isPastUnfinished();

    final effectiveDate =
        _occurrenceDate ??
            _task.scheduledDate;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Dettaglio',
        ),
        actions: [
          IconButton(
            tooltip:
                'Azioni attività',
            onPressed:
                _showTaskActions,
            icon:
                const Icon(
              Icons.more_horiz,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: StreamBuilder<
          Map<String, TaskCategory>>(
        stream:
            widget.categoryRepository
                .watchCategoryMap(),
        initialData:
            const {},
        builder:
            (context,
                categorySnapshot) {
          final categoryMap =
              categorySnapshot.data ??
                  const <
                      String,
                      TaskCategory>{};

          final category =
              _task.categoryId ==
                      null
                  ? null
                  : categoryMap[
                      _task
                          .categoryId];

          final categoryColor =
              category == null
                  ? colorScheme
                      .onSurfaceVariant
                      .withValues(
                        alpha:
                            0.72,
                      )
                  : Color(
                      category
                          .colorValue,
                    );

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              24,
              10,
              24,
              120,
            ),
            children: [
              Text(
                _task.title,
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
                          height:
                              1.12,
                          decoration:
                              _isCompleted
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                        ),
              ),

              const SizedBox(
                height: 18,
              ),

              _CompletionAction(
                completed:
                    _isCompleted,
                accentColor:
                    categoryColor,
                onTap:
                    () {
                  _setCompleted(
                    !_isCompleted,
                  );
                },
              ),

              if (isPast) ...[
                const SizedBox(
                  height: 26,
                ),
                _OverdueNotice(
                  onReschedule:
                      _rescheduleTask,
                ),
              ],

              const SizedBox(
                height: 38,
              ),

              const _SectionLabel(
                text:
                    'PIANIFICAZIONE',
              ),

              const SizedBox(
                height: 14,
              ),

              if (effectiveDate ==
                  null)
                const _InfoLine(
                  icon:
                      Icons
                          .inbox_outlined,
                  title:
                      'Inbox',
                  value:
                      'Nessuna data assegnata',
                )
              else
                Text(
                  _dateLabel(
                    effectiveDate,
                  ),
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w700,
                            letterSpacing:
                                -0.25,
                          ),
                ),

              if (_task.recurrence
                  .isRecurring) ...[
                const SizedBox(
                  height: 16,
                ),
                _InfoLine(
                  icon:
                      Icons.repeat,
                  title:
                      'Ripetizione',
                  value:
                      _recurrenceLabel(
                    _task.recurrence,
                  ),
                ),
              ],

              if (_task.allDay) ...[
                const SizedBox(
                  height: 16,
                ),
                const _InfoLine(
                  icon:
                      Icons
                          .today_outlined,
                  title:
                      'Orario',
                  value:
                      'Tutto il giorno',
                ),
              ] else if (_task
                      .startTimeMinutes !=
                  null) ...[
                const SizedBox(
                  height: 18,
                ),
                if (_task
                        .durationMinutes !=
                    null)
                  _TimeRange(
                    start:
                        _formatClockMinutes(
                      _task
                          .startTimeMinutes!,
                    ),
                    end:
                        _formatEndTime(
                      _task,
                    ),
                  )
                else
                  _InfoLine(
                    icon:
                        Icons
                            .schedule_outlined,
                    title:
                        effectiveDate ==
                                null
                            ? 'Orario preferito'
                            : 'Ora inizio',
                    value:
                        _formatClockMinutes(
                      _task
                          .startTimeMinutes!,
                    ),
                  ),
              ] else if (effectiveDate !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),
                const _InfoLine(
                  icon:
                      Icons
                          .schedule_outlined,
                  title:
                      'Orario',
                  value:
                      'Non impostato',
                ),
              ],

              if (_task.durationMinutes !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),
                _InfoLine(
                  icon:
                      Icons
                          .timer_outlined,
                  title:
                      'Durata',
                  value:
                      _durationLabel(
                    _task
                        .durationMinutes!,
                  ),
                ),
              ],

              const SizedBox(
                height: 34,
              ),
              const _SoftDivider(),
              const SizedBox(
                height: 28,
              ),

              const _SectionLabel(
                text:
                    'CATEGORIA',
              ),
              const SizedBox(
                height: 13,
              ),

              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(
                      color:
                          categoryColor
                              .withValues(
                        alpha:
                            0.11,
                      ),
                      shape:
                          BoxShape
                              .circle,
                    ),
                    child: Icon(
                      category == null
                          ? Icons
                              .remove_circle_outline
                          : taskCategoryIcon(
                              category
                                  .iconKey,
                            ),
                      size: 17,
                      color:
                          categoryColor,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    category?.name ??
                        'Nessuna categoria',
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color:
                                  categoryColor,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                  ),
                ],
              ),

              const SizedBox(
                height: 34,
              ),
              const _SoftDivider(),
              const SizedBox(
                height: 28,
              ),

              const _SectionLabel(
                text:
                    'PRIORITÀ',
              ),
              const SizedBox(
                height: 13,
              ),

              Row(
                children: [
                  Icon(
                    Icons
                        .flag_outlined,
                    size: 19,
                    color:
                        priorityColor,
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  Text(
                    _priorityLabel(
                      _task
                          .priority,
                    ),
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color:
                                  priorityColor,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                  ),
                ],
              ),

              const SizedBox(
                height: 34,
              ),
              const _SoftDivider(),
              const SizedBox(
                height: 28,
              ),

              const _SectionLabel(
                text:
                    'NOTE',
              ),
              const SizedBox(
                height: 13,
              ),

              Text(
                _task.description
                        .trim()
                        .isEmpty
                    ? 'Nessuna nota.'
                    : _task.description,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          height:
                              1.55,
                          color:
                              _task.description
                                      .trim()
                                      .isEmpty
                                  ? colorScheme
                                      .onSurfaceVariant
                                  : null,
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionSheetRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionSheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final color =
        isDestructive
            ? colorScheme.error
            : colorScheme.onSurface;

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
            vertical: 15,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  icon,
                  size: 20,
                  color:
                      color,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                color,
                            fontWeight:
                                FontWeight
                                    .w600,
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

class _CompletionAction
    extends StatelessWidget {
  final bool completed;
  final Color accentColor;
  final VoidCallback onTap;

  const _CompletionAction({
    required this.completed,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 7,
              horizontal: 2,
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration:
                      BoxDecoration(
                    color:
                        completed
                            ? accentColor
                            : Colors
                                .transparent,
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          completed
                              ? accentColor
                              : colorScheme
                                  .onSurfaceVariant,
                      width: 2,
                    ),
                  ),
                  child:
                      completed
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color:
                                  colorScheme
                                      .onPrimary,
                            )
                          : null,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  completed
                      ? 'Completata'
                      : 'Segna come completata',
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                completed
                                    ? accentColor
                                    : colorScheme
                                        .onSurface,
                            fontWeight:
                                FontWeight
                                    .w600,
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

class _OverdueNotice
    extends StatelessWidget {
  final VoidCallback onReschedule;

  const _OverdueNotice({
    required this.onReschedule,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      padding:
          const EdgeInsets
              .fromLTRB(
        16,
        14,
        12,
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            colorScheme
                .errorContainer
                .withValues(
          alpha: 0.35,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons
                .event_repeat_outlined,
            color:
                colorScheme
                    .error,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'DA RIPROGRAMMARE',
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color:
                                colorScheme
                                    .error,
                            fontWeight:
                                FontWeight
                                    .w800,
                            letterSpacing:
                                0.7,
                          ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Questa attività è passata '
                  'e non risulta completata.',
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed:
                onReschedule,
            child:
                const Text(
              'Sposta a…',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel
    extends StatelessWidget {
  final String text;

  const _SectionLabel({
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
                    Theme.of(
                  context,
                )
                        .colorScheme
                        .onSurfaceVariant,
                fontWeight:
                    FontWeight
                        .w800,
                letterSpacing:
                    1,
              ),
    );
  }
}

class _InfoLine
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets
                  .only(
            top: 2,
          ),
          child: Icon(
            icon,
            size: 19,
            color:
                colorScheme
                    .onSurfaceVariant,
          ),
        ),
        const SizedBox(
          width: 11,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style:
                    Theme.of(
                  context,
                )
                        .textTheme
                        .bodySmall
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
                height: 2,
              ),
              Text(
                value,
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
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftDivider
    extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Divider(
      height: 1,
      color:
          Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(
                alpha: 0.55,
              ),
    );
  }
}

class _TimeRange
    extends StatelessWidget {
  final String start;
  final String end;

  const _TimeRange({
    required this.start,
    required this.end,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Row(
      children: [
        Text(
          start,
          style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w700,
                    letterSpacing:
                        -0.4,
                  ),
        ),
        const SizedBox(
          width: 14,
        ),
        Expanded(
          child: Container(
            height: 1,
            color:
                colorScheme
                    .outlineVariant,
          ),
        ),
        const SizedBox(
          width: 14,
        ),
        Flexible(
          child: Text(
            end,
            textAlign:
                TextAlign.right,
            style:
                Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight
                              .w700,
                      letterSpacing:
                          -0.4,
                    ),
          ),
        ),
      ],
    );
  }
}
