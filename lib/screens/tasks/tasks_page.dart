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

  bool _pastExpanded = false;

  @override
  void initState() {
    super.initState();

    _mode = widget.openInbox
        ? _TaskListMode.inbox
        : _TaskListMode.scheduled;
  }

  Future<void> _addTask() async {
    final result =
        await Navigator.push<TaskFormResult>(
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

    await widget.taskRepository.addTask(
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

  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
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

  bool _isPastTask(
    LifeTask task,
    DateTime now,
  ) {
    final scheduledDate =
        task.scheduledDate;

    if (scheduledDate == null) {
      return false;
    }

    final today =
        _dateOnly(now);

    final date =
        _dateOnly(
      scheduledDate,
    );

    if (date.isBefore(today)) {
      return true;
    }

    if (date.isAfter(today)) {
      return false;
    }

    if (task.allDay ||
        task.startTimeMinutes == null) {
      return false;
    }

    final endMinutes =
        task.startTimeMinutes! +
        (task.durationMinutes ?? 0);

    final endMoment =
        date.add(
      Duration(
        minutes: endMinutes,
      ),
    );

    return now.isAfter(
      endMoment,
    );
  }

  int _comparePastNewestFirst(
    LifeTask a,
    LifeTask b,
  ) {
    final aDate =
        a.scheduledDate!;
    final bDate =
        b.scheduledDate!;

    final dateComparison =
        bDate.compareTo(aDate);

    if (dateComparison != 0) {
      return dateComparison;
    }

    final aTime =
        a.startTimeMinutes ??
            -1;
    final bTime =
        b.startTimeMinutes ??
            -1;

    return bTime.compareTo(
      aTime,
    );
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
    final now =
        DateTime.now();

    final today =
        _dateOnly(now);

    final tomorrow =
        today.add(
      const Duration(days: 1),
    );

    final yesterday =
        today.subtract(
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

    if (_sameDay(
      date,
      yesterday,
    )) {
      return 'Ieri';
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final now =
        DateTime.now();

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

          final currentTasks =
              scheduledTasks
                  .where(
                    (task) =>
                        !_isPastTask(
                      task,
                      now,
                    ),
                  )
                  .toList();

          final pastTasks =
              scheduledTasks
                  .where(
                    (task) =>
                        _isPastTask(
                      task,
                      now,
                    ),
                  )
                  .toList()
                ..sort(
                  _comparePastNewestFirst,
                );

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              4,
              20,
              44,
            ),

            children: [
              _TaskModeSwitch(
                selected:
                    _mode,
                scheduledCount:
                    scheduledTasks.length,
                inboxCount:
                    inboxTasks.length,
                onChanged:
                    (mode) {
                  setState(() {
                    _mode =
                        mode;
                  });
                },
              ),

              const SizedBox(
                height: 30,
              ),

              if (_mode ==
                  _TaskListMode.inbox)
                if (inboxTasks.isEmpty)
                  _EmptyTaskList(
                    isInbox:
                        true,
                    onAdd:
                        _addTask,
                  )
                else
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
                if (currentTasks.isEmpty)
                  _EmptyCurrentTasks(
                    hasPast:
                        pastTasks
                            .isNotEmpty,
                    onAdd:
                        _addTask,
                  )
                else
                  for (final entry
                      in _groupScheduledTasks(
                    currentTasks,
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

                if (pastTasks.isNotEmpty) ...[
                  const SizedBox(
                    height: 2,
                  ),

                  _PastSection(
                    tasks:
                        pastTasks,
                    expanded:
                        _pastExpanded,
                    onToggle: () {
                      setState(() {
                        _pastExpanded =
                            !_pastExpanded;
                      });
                    },
                    groupLabelBuilder:
                        _groupLabel,
                    groupKeyBuilder:
                        _groupKey,
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
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TaskModeSwitch
    extends StatelessWidget {
  final _TaskListMode selected;
  final int scheduledCount;
  final int inboxCount;
  final ValueChanged<_TaskListMode>
      onChanged;

  const _TaskModeSwitch({
    required this.selected,
    required this.scheduledCount,
    required this.inboxCount,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _ModeTab(
            label:
                'Programmate',
            count:
                scheduledCount,
            selected:
                selected ==
                    _TaskListMode
                        .scheduled,
            onTap: () {
              onChanged(
                _TaskListMode
                    .scheduled,
              );
            },
          ),
        ),

        const SizedBox(
          width: 22,
        ),

        Expanded(
          child: _ModeTab(
            label:
                'Inbox',
            count:
                inboxCount,
            selected:
                selected ==
                    _TaskListMode
                        .inbox,
            onTap: () {
              onChanged(
                _TaskListMode
                    .inbox,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeTab
    extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.count,
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

        child: Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            0,
            12,
            0,
            10,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Row(
                children: [
                  Text(
                    label,
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  selected
                                      ? FontWeight
                                          .w700
                                      : FontWeight
                                          .w500,
                              color:
                                  selected
                                      ? colorScheme
                                          .onSurface
                                      : colorScheme
                                          .onSurfaceVariant,
                            ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    '$count',
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  selected
                                      ? colorScheme
                                          .primary
                                      : colorScheme
                                          .onSurfaceVariant,
                              fontWeight:
                                  FontWeight
                                      .w700,
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
                  milliseconds: 160,
                ),
                height: 2,
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? colorScheme
                              .primary
                          : colorScheme
                              .outlineVariant
                              .withValues(
                            alpha:
                                0.45,
                          ),
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

class _EmptyCurrentTasks
    extends StatelessWidget {
  final bool hasPast;
  final VoidCallback onAdd;

  const _EmptyCurrentTasks({
    required this.hasPast,
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
          const EdgeInsets.only(
        bottom: 30,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            hasPast
                ? 'Niente in programma'
                : 'Nessuna attività',
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
            height: 7,
          ),

          Text(
            hasPast
                ? 'Le attività passate sono '
                    'raccolte più sotto.'
                : 'Aggiungi qualcosa da fare '
                    'quando vuoi.',
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
            height: 16,
          ),

          TextButton.icon(
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
          const EdgeInsets
              .fromLTRB(
        0,
        30,
        0,
        20,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            isInbox
                ? 'Inbox vuota'
                : 'Nessuna attività',
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
            height: 7,
          ),

          Text(
            isInbox
                ? 'Qui raccogliamo le cose '
                    'che vuoi fare ma che non '
                    'hai ancora programmato.'
                : 'Aggiungi qualcosa da fare '
                    'quando vuoi.',
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
            height: 16,
          ),

          TextButton.icon(
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
                        FontWeight
                            .w700,
                    letterSpacing:
                        -0.3,
                  ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          'Durata e orario possono '
          'esserci anche senza una data.',
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
          height: 14,
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
                alpha: 0.45,
              ),
            ),
        ],
      ],
    );
  }
}

class _PastSection
    extends StatelessWidget {
  final List<LifeTask> tasks;
  final bool expanded;
  final VoidCallback onToggle;

  final String Function(
    DateTime date,
  ) groupLabelBuilder;

  final String Function(
    LifeTask task,
  ) groupKeyBuilder;

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

  const _PastSection({
    required this.tasks,
    required this.expanded,
    required this.onToggle,
    required this.groupLabelBuilder,
    required this.groupKeyBuilder,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.priorityColorBuilder,
    required this.priorityLabelBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
  });

  Map<String, List<LifeTask>>
      _groups() {
    final groups =
        <String, List<LifeTask>>{};

    for (final task in tasks) {
      final key =
          groupKeyBuilder(task);

      groups
          .putIfAbsent(
            key,
            () => [],
          )
          .add(task);
    }

    return groups;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final groups =
        _groups();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Divider(
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
            onTap:
                onToggle,

            child: Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 17,
              ),

              child: Row(
                children: [
                  Icon(
                    Icons
                        .history_outlined,
                    size: 20,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      'Passate',
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                    ),
                  ),

                  Text(
                    '${tasks.length}',
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
                                      .w600,
                            ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  AnimatedRotation(
                    duration:
                        const Duration(
                      milliseconds: 160,
                    ),
                    turns:
                        expanded
                            ? 0.5
                            : 0,
                    child:
                        Icon(
                      Icons
                          .keyboard_arrow_down,
                      color:
                          colorScheme
                              .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (expanded) ...[
          const SizedBox(
            height: 4,
          ),

          for (final entry
              in groups.entries) ...[
            Padding(
              padding:
                  const EdgeInsets
                      .only(
                top: 8,
                bottom: 4,
              ),
              child: Text(
                groupLabelBuilder(
                  entry.value
                      .first
                      .scheduledDate!,
                ),
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
                                  .w700,
                        ),
              ),
            ),

            for (int i = 0;
                i <
                    entry.value
                        .length;
                i++) ...[
              _TaskRow(
                task:
                    entry.value[i],
                timeLabel:
                    timeLabelBuilder(
                  entry.value[i],
                ),
                secondaryLabel:
                    secondaryLabelBuilder(
                  entry.value[i],
                ),
                priorityColor:
                    priorityColorBuilder(
                  entry.value[i],
                ),
                priorityLabel:
                    priorityLabelBuilder(
                  entry.value[i],
                ),
                isPast:
                    true,
                onCompletedChanged:
                    (completed) {
                  return onCompletedChanged(
                    entry.value[i],
                    completed,
                  );
                },
                onTap: () {
                  onTaskTap(
                    entry.value[i],
                  );
                },
              ),

              if (i !=
                  entry.value.length -
                      1)
                Divider(
                  indent: 96,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha: 0.4,
                  ),
                ),
            ],

            const SizedBox(
              height: 14,
            ),
          ],
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
                        FontWeight
                            .w700,
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
                alpha: 0.45,
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

  final bool isPast;

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
    this.isPast = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final muted =
        isPast;

    return Opacity(
      opacity:
          muted
              ? 0.82
              : 1,

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 58,

            child: Padding(
              padding:
                  const EdgeInsets
                      .only(
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
                onTap:
                    onTap,

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
                            size: 18,
                            color:
                                colorScheme
                                    .onSurfaceVariant
                                    .withValues(
                              alpha: 0.55,
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

                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment:
                            WrapCrossAlignment
                                .center,

                        children: [
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

                          if (isPast &&
                              !task
                                  .isCompleted)
                            Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                Icon(
                                  Icons
                                      .event_repeat_outlined,
                                  size: 14,
                                  color:
                                      colorScheme
                                          .error,
                                ),

                                const SizedBox(
                                  width: 4,
                                ),

                                Text(
                                  'Da riprogrammare',
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                colorScheme
                                                    .error,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                ),
                              ],
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
      ),
    );
  }
}
