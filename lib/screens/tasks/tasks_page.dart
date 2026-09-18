import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';

enum _TaskListMode {
  scheduled,
  inbox,
}

class TasksPage extends StatefulWidget {
  final TaskRepository taskRepository;

  /// Se true, la pagina si apre direttamente sulla Inbox.
  final bool openInbox;

  const TasksPage({
    super.key,
    required this.taskRepository,
    this.openInbox = false,
  });

  @override
  State<TasksPage> createState() =>
      _TasksPageState();
}

class _TasksPageState
    extends State<TasksPage> {
  late _TaskListMode _mode;

  @override
  void initState() {
    super.initState();

    _mode = widget.openInbox
        ? _TaskListMode.inbox
        : _TaskListMode.scheduled;
  }

  Future<void> _addTask() async {
    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const TaskFormPage(),
      ),
    );

    if (result == null ||
        result.shouldDelete ||
        result.task == null) {
      return;
    }

    await widget.taskRepository
        .addTask(
      result.task!,
    );
  }

  void _openTaskDetail(
    LifeTask task,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailPage(
          task: task,
          taskRepository:
              widget.taskRepository,
        ),
      ),
    );
  }

  bool _sameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
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

    final hour =
        normalized ~/ 60;

    final minute =
        normalized % 60;

    return '${_twoDigits(hour)}:'
        '${_twoDigits(minute)}';
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

  String _timeLabel(
    LifeTask task,
  ) {
    if (task.allDay) {
      return 'Tutto\nil giorno';
    }

    final start =
        task.startTimeMinutes;

    if (start == null) {
      return '';
    }

    return _formatClockMinutes(
      start,
    );
  }

  String _secondaryLabel(
    LifeTask task,
  ) {
    final parts = <String>[];

    final start =
        task.startTimeMinutes;

    final duration =
        task.durationMinutes;

    if (!task.allDay &&
        start != null &&
        duration != null) {
      final end =
          start + duration;

      var endLabel =
          _formatClockMinutes(
        end,
      );

      final extraDays =
          end ~/ (24 * 60);

      if (extraDays > 0) {
        endLabel +=
            extraDays == 1
                ? ' (+1 g)'
                : ' (+$extraDays g)';
      }

      parts.add(
        'fino alle $endLabel',
      );
    }

    if (duration != null) {
      parts.add(
        _durationLabel(
          duration,
        ),
      );
    }

    if (task.description
        .trim()
        .isNotEmpty) {
      parts.add(
        task.description.trim(),
      );
    }

    return parts.join(' · ');
  }

  String _groupLabel(
    DateTime date,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrow =
        today.add(
      const Duration(days: 1),
    );

    if (_sameDay(
      date,
      today,
    )) {
      return 'Oggi';
    }

    if (_sameDay(
      date,
      tomorrow,
    )) {
      return 'Domani';
    }

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
        '${months[date.month - 1]}';
  }

  String _groupKey(
    LifeTask task,
  ) {
    final date =
        task.scheduledDate!;

    return '${date.year}-'
        '${_twoDigits(date.month)}-'
        '${_twoDigits(date.day)}';
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Attività',
        ),

        actions: [
          IconButton(
            tooltip:
                'Nuova attività',
            onPressed:
                _addTask,
            icon:
                const Icon(
              Icons.add,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: StreamBuilder<
          List<LifeTask>>(
        stream: widget
            .taskRepository
            .watchAllTasks(),

        builder:
            (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Errore nel caricamento '
                'delle attività:\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final allTasks =
              snapshot.data!;

          final scheduledTasks =
              allTasks
                  .where(
                    (task) =>
                        task.scheduledDate !=
                        null,
                  )
                  .toList();

          final inboxTasks =
              allTasks
                  .where(
                    (task) =>
                        task.scheduledDate ==
                        null,
                  )
                  .toList();

          final visibleTasks =
              _mode ==
                      _TaskListMode
                          .scheduled
                  ? scheduledTasks
                  : inboxTasks;

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              8,
              20,
              40,
            ),

            children: [
              SegmentedButton<
                  _TaskListMode>(
                showSelectedIcon:
                    false,

                segments: [
                  ButtonSegment(
                    value:
                        _TaskListMode
                            .scheduled,
                    icon:
                        const Icon(
                      Icons
                          .calendar_today_outlined,
                    ),
                    label: Text(
                      'Programmate '
                      '(${scheduledTasks.length})',
                    ),
                  ),

                  ButtonSegment(
                    value:
                        _TaskListMode
                            .inbox,
                    icon:
                        const Icon(
                      Icons
                          .inbox_outlined,
                    ),
                    label: Text(
                      'Inbox '
                      '(${inboxTasks.length})',
                    ),
                  ),
                ],

                selected: {
                  _mode,
                },

                onSelectionChanged:
                    (selection) {
                  setState(() {
                    _mode =
                        selection.first;
                  });
                },
              ),

              const SizedBox(
                height: 28,
              ),

              if (visibleTasks.isEmpty)
                _EmptyTaskList(
                  isInbox:
                      _mode ==
                          _TaskListMode
                              .inbox,
                  onAdd:
                      _addTask,
                )
              else if (_mode ==
                  _TaskListMode.inbox)
                _InboxSection(
                  tasks:
                      inboxTasks,
                  timeLabelBuilder:
                      _timeLabel,
                  secondaryLabelBuilder:
                      _secondaryLabel,
                  priorityColorBuilder:
                      (task) =>
                          _priorityColor(
                    context,
                    task.priority,
                  ),
                  priorityLabelBuilder:
                      (task) =>
                          _priorityLabel(
                    task.priority,
                  ),
                  onCompletedChanged:
                      (
                    task,
                    completed,
                  ) async {
                    await widget
                        .taskRepository
                        .setCompleted(
                      task.id,
                      completed,
                    );
                  },
                  onTaskTap:
                      _openTaskDetail,
                )
              else ...[
                for (final entry
                    in _groupScheduledTasks(
                  scheduledTasks,
                ).entries) ...[
                  _TaskGroup(
                    title:
                        _groupLabel(
                      entry.value
                          .first
                          .scheduledDate!,
                    ),
                    tasks:
                        entry.value,
                    timeLabelBuilder:
                        _timeLabel,
                    secondaryLabelBuilder:
                        _secondaryLabel,
                    priorityColorBuilder:
                        (task) =>
                            _priorityColor(
                      context,
                      task.priority,
                    ),
                    priorityLabelBuilder:
                        (task) =>
                            _priorityLabel(
                      task.priority,
                    ),
                    onCompletedChanged:
                        (
                      task,
                      completed,
                    ) async {
                      await widget
                          .taskRepository
                          .setCompleted(
                        task.id,
                        completed,
                      );
                    },
                    onTaskTap:
                        _openTaskDetail,
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Map<String, List<LifeTask>>
      _groupScheduledTasks(
    List<LifeTask> tasks,
  ) {
    final groups =
        <String, List<LifeTask>>{};

    for (final task in tasks) {
      final key =
          _groupKey(task);

      groups
          .putIfAbsent(
            key,
            () => [],
          )
          .add(task);
    }

    return groups;
  }
}

class _EmptyTaskList
    extends StatelessWidget {
  final bool isInbox;
  final VoidCallback onAdd;

  const _EmptyTaskList({
    required this.isInbox,
    required this.onAdd,
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
          const EdgeInsets.symmetric(
        vertical: 54,
        horizontal: 20,
      ),

      child: Column(
        children: [
          Icon(
            isInbox
                ? Icons
                    .inbox_outlined
                : Icons
                    .event_available_outlined,
            size: 54,
            color:
                colorScheme.primary,
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            isInbox
                ? 'Inbox vuota'
                : 'Nessuna attività programmata',
            textAlign:
                TextAlign.center,
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
            height: 8,
          ),

          Text(
            isInbox
                ? 'Qui compariranno le attività '
                    'a cui non hai ancora assegnato '
                    'una data.'
                : 'Le attività con una data '
                    'compariranno qui.',
            textAlign:
                TextAlign.center,
            style:
                Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color:
                          colorScheme
                              .onSurfaceVariant,
                    ),
          ),

          const SizedBox(
            height: 22,
          ),

          FilledButton.icon(
            onPressed:
                onAdd,
            icon:
                const Icon(
              Icons.add,
            ),
            label:
                const Text(
              'Nuova attività',
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxSection
    extends StatelessWidget {
  final List<LifeTask> tasks;

  final String Function(
    LifeTask task,
  ) timeLabelBuilder;

  final String Function(
    LifeTask task,
  ) secondaryLabelBuilder;

  final Color Function(
    LifeTask task,
  ) priorityColorBuilder;

  final String Function(
    LifeTask task,
  ) priorityLabelBuilder;

  final Future<void> Function(
    LifeTask task,
    bool completed,
  ) onCompletedChanged;

  final void Function(
    LifeTask task,
  ) onTaskTap;

  const _InboxSection({
    required this.tasks,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.priorityColorBuilder,
    required this.priorityLabelBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
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
      children: [
        Text(
          'Da programmare',
          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        -0.3,
                  ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          'Puoi già indicare durata e '
          'orario preferito, anche senza '
          'scegliere un giorno.',
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
          height: 12,
        ),

        for (int i = 0;
            i < tasks.length;
            i++) ...[
          _TaskRow(
            task:
                tasks[i],
            timeLabel:
                timeLabelBuilder(
              tasks[i],
            ),
            secondaryLabel:
                secondaryLabelBuilder(
              tasks[i],
            ),
            priorityColor:
                priorityColorBuilder(
              tasks[i],
            ),
            priorityLabel:
                priorityLabelBuilder(
              tasks[i],
            ),
            onCompletedChanged:
                (completed) {
              return onCompletedChanged(
                tasks[i],
                completed,
              );
            },
            onTap: () {
              onTaskTap(
                tasks[i],
              );
            },
          ),

          if (i !=
              tasks.length - 1)
            Divider(
              indent: 96,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha: 0.55,
              ),
            ),
        ],
      ],
    );
  }
}

class _TaskGroup
    extends StatelessWidget {
  final String title;

  final List<LifeTask> tasks;

  final String Function(
    LifeTask task,
  ) timeLabelBuilder;

  final String Function(
    LifeTask task,
  ) secondaryLabelBuilder;

  final Color Function(
    LifeTask task,
  ) priorityColorBuilder;

  final String Function(
    LifeTask task,
  ) priorityLabelBuilder;

  final Future<void> Function(
    LifeTask task,
    bool completed,
  ) onCompletedChanged;

  final void Function(
    LifeTask task,
  ) onTaskTap;

  const _TaskGroup({
    required this.title,
    required this.tasks,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.priorityColorBuilder,
    required this.priorityLabelBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
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
      children: [
        Text(
          title,
          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        -0.3,
                  ),
        ),

        const SizedBox(
          height: 10,
        ),

        for (int i = 0;
            i < tasks.length;
            i++) ...[
          _TaskRow(
            task:
                tasks[i],
            timeLabel:
                timeLabelBuilder(
              tasks[i],
            ),
            secondaryLabel:
                secondaryLabelBuilder(
              tasks[i],
            ),
            priorityColor:
                priorityColorBuilder(
              tasks[i],
            ),
            priorityLabel:
                priorityLabelBuilder(
              tasks[i],
            ),
            onCompletedChanged:
                (completed) {
              return onCompletedChanged(
                tasks[i],
                completed,
              );
            },
            onTap: () {
              onTaskTap(
                tasks[i],
              );
            },
          ),

          if (i !=
              tasks.length - 1)
            Divider(
              indent: 96,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha: 0.55,
              ),
            ),
        ],
      ],
    );
  }
}

class _TaskRow
    extends StatelessWidget {
  final LifeTask task;

  final String timeLabel;
  final String secondaryLabel;

  final Color priorityColor;
  final String priorityLabel;

  final Future<void> Function(
    bool completed,
  ) onCompletedChanged;

  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.timeLabel,
    required this.secondaryLabel,
    required this.priorityColor,
    required this.priorityLabel,
    required this.onCompletedChanged,
    required this.onTap,
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
        SizedBox(
          width: 58,

          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 18,
              right: 8,
            ),

            child: Text(
              timeLabel,
              textAlign:
                  TextAlign.right,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall
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
        ),

        InkResponse(
          radius: 24,

          onTap: () {
            onCompletedChanged(
              !task.isCompleted,
            );
          },

          child: Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              8,
              16,
              10,
              16,
            ),

            child: Container(
              width: 18,
              height: 18,

              decoration:
                  BoxDecoration(
                color:
                    task.isCompleted
                        ? priorityColor
                        : Colors
                            .transparent,
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      priorityColor,
                  width: 2,
                ),
              ),

              child:
                  task.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color:
                              Colors.white,
                        )
                      : null,
            ),
          ),
        ),

        Expanded(
          child: Material(
            color:
                Colors.transparent,

            child: InkWell(
              onTap: onTap,

              child: Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  4,
                  13,
                  4,
                  14,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                Theme.of(
                              context,
                            )
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      decoration:
                                          task.isCompleted
                                              ? TextDecoration
                                                  .lineThrough
                                              : null,
                                    ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Icon(
                          Icons
                              .chevron_right,
                          size: 19,
                          color:
                              colorScheme
                                  .onSurfaceVariant
                                  .withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ],
                    ),

                    if (secondaryLabel
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        secondaryLabel,
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
                                ),
                      ),
                    ],

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Icon(
                          Icons
                              .flag_outlined,
                          size: 14,
                          color:
                              priorityColor,
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          priorityLabel,
                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        priorityColor,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
