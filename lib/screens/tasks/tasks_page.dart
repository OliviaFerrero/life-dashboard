import 'package:flutter/material.dart';

import '../../core/time/civil_date.dart';
import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_occurrence.dart';
import '../../models/task_recurrence.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../utils/task_category_icons.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';

enum _TaskListMode {
  scheduled,
  inbox,
}

class TasksPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;
  final bool openInbox;

  const TasksPage({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
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
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
        ),
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
    LifeTask task, {
    TaskOccurrence? occurrence,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailPage(
          task:
              task,
          occurrence:
              occurrence,
          taskRepository:
              widget.taskRepository,
          categoryRepository:
              widget.categoryRepository,
        ),
      ),
    );
  }

  DateTime _dateOnly(
    DateTime date,
  ) {
    return CivilDate.dateOnly(
      date,
    );
  }

  bool _sameDay(
    DateTime first,
    DateTime second,
  ) {
    return CivilDate.sameDay(
      first,
      second,
    );
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

    final date =
        _dateOnly(
      scheduledDate,
    );

    if (!task.allDay &&
        task.startTimeMinutes !=
            null) {
      final startMoment =
          date.add(
        Duration(
          minutes:
              task.startTimeMinutes!,
        ),
      );

      final duration =
          task.durationMinutes;

      final cutoff =
          duration != null &&
                  duration > 0
              ? startMoment.add(
                  Duration(
                    minutes:
                        duration,
                  ),
                )
              : startMoment;

      return now.isAfter(
        cutoff,
      );
    }

    final today =
        _dateOnly(now);

    return date.isBefore(
      today,
    );
  }

  int _comparePastNewestFirst(
    TaskOccurrence a,
    TaskOccurrence b,
  ) {
    final dateComparison =
        b.date.compareTo(a.date);

    if (dateComparison != 0) {
      return dateComparison;
    }

    final aTime =
        a.displayTask.startTimeMinutes ??
            -1;
    final bTime =
        b.displayTask.startTimeMinutes ??
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

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
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
          _formatClockMinutes(end);

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
        _durationLabel(duration),
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
        CivilDate.nextDay(
      today,
    );

    final yesterday =
        CivilDate.previousDay(
      today,
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
    TaskOccurrence occurrence,
  ) {
    final date =
        occurrence.date;

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

  String? _recurrenceLabel(
    TaskRecurrence recurrence,
  ) {
    switch (recurrence.type) {
      case TaskRecurrenceType.none:
        return null;

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

  Map<String, List<TaskOccurrence>>
      _groupScheduledOccurrences(
    List<TaskOccurrence> occurrences,
  ) {
    final groups =
        <String,
            List<TaskOccurrence>>{};

    for (final occurrence
        in occurrences) {
      final key =
          _groupKey(
        occurrence,
      );

      groups
          .putIfAbsent(
            key,
            () => [],
          )
          .add(
            occurrence,
          );
    }

    return groups;
  }

  Future<bool> _confirmCompleteAll(
    int remainingSubtasks,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Completare attività?',
          ),
          content:
              Text(
            remainingSubtasks == 1
                ? 'C’è ancora 1 sottoattività da completare. Vuoi completare tutto?'
                : 'Ci sono ancora $remainingSubtasks sottoattività da completare. Vuoi completare tutto?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
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
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'Completa tutto',
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
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
            (context, taskSnapshot) {
          if (taskSnapshot.hasError) {
            return Center(
              child: Text(
                'Errore nel caricamento '
                'delle attività:\n'
                '${taskSnapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          if (!taskSnapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final allTasks =
              taskSnapshot.data!;

          final inboxTasks =
              allTasks
                  .where(
                    (task) =>
                        task.scheduledDate ==
                        null,
                  )
                  .toList();

          return StreamBuilder<
              List<TaskOccurrence>>(
            stream:
                widget.taskRepository
                    .watchScheduleOverview(
              now,
            ),
            builder:
                (context,
                    occurrenceSnapshot) {
              if (occurrenceSnapshot
                  .hasError) {
                return Center(
                  child: Text(
                    'Errore nel caricamento '
                    'delle attività:\n'
                    '${occurrenceSnapshot.error}',
                    textAlign:
                        TextAlign.center,
                  ),
                );
              }

              if (!occurrenceSnapshot
                  .hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final scheduledOccurrences =
                  occurrenceSnapshot.data!;

              final currentOccurrences =
                  scheduledOccurrences
                      .where(
                        (occurrence) =>
                            !_isPastTask(
                          occurrence
                              .displayTask,
                          now,
                        ),
                      )
                      .toList();

              final pastOccurrences =
                  scheduledOccurrences
                      .where(
                        (occurrence) =>
                            _isPastTask(
                          occurrence
                              .displayTask,
                          now,
                        ),
                      )
                      .toList()
                    ..sort(
                      _comparePastNewestFirst,
                    );

              return StreamBuilder<
                  Map<String,
                      TaskCategory>>(
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
                            scheduledOccurrences
                                .length,
                        inboxCount:
                            inboxTasks
                                .length,
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
                          _TaskListMode
                              .inbox)
                        if (inboxTasks
                            .isEmpty)
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
                            categoryBuilder:
                                (task) =>
                                    task.categoryId ==
                                            null
                                        ? null
                                        : categoryMap[
                                            task.categoryId],
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
                              if (completed) {
                                final remaining =
                                    task.subtasks
                                        .where(
                                          (subtask) =>
                                              !subtask
                                                  .isCompleted,
                                        )
                                        .length;

                                if (remaining > 0) {
                                  final confirmed =
                                      await _confirmCompleteAll(
                                    remaining,
                                  );

                                  if (!confirmed) {
                                    return;
                                  }
                                }
                              }

                              await widget
                                  .taskRepository
                                  .setCompleted(
                                task.id,
                                completed,
                              );
                            },
                            onTaskTap:
                                (task) {
                              _openTaskDetail(
                                task,
                              );
                            },
                          )
                      else ...[
                        if (currentOccurrences
                            .isEmpty)
                          _EmptyCurrentTasks(
                            hasPast:
                                pastOccurrences
                                    .isNotEmpty,
                            onAdd:
                                _addTask,
                          )
                        else
                          for (final entry
                              in _groupScheduledOccurrences(
                            currentOccurrences,
                          ).entries) ...[
                            _OccurrenceGroup(
                              title:
                                  _groupLabel(
                                entry.value
                                    .first
                                    .date,
                              ),
                              occurrences:
                                  entry.value,
                              timeLabelBuilder:
                                  _timeLabel,
                              secondaryLabelBuilder:
                                  _secondaryLabel,
                              categoryBuilder:
                                  (task) =>
                                      task.categoryId ==
                                              null
                                          ? null
                                          : categoryMap[
                                              task.categoryId],
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
                              recurrenceLabelBuilder:
                                  (task) =>
                                      _recurrenceLabel(
                                task.recurrence,
                              ),
                              onCompletedChanged:
                                  (
                                occurrence,
                                completed,
                              ) async {
                                if (completed) {
                                  final remaining =
                                      occurrence
                                          .subtasks
                                          .where(
                                            (subtask) =>
                                                !subtask
                                                    .isCompleted,
                                          )
                                          .length;

                                  if (remaining > 0) {
                                    final confirmed =
                                        await _confirmCompleteAll(
                                      remaining,
                                    );

                                    if (!confirmed) {
                                      return;
                                    }
                                  }
                                }

                                await widget
                                    .taskRepository
                                    .setOccurrenceCompleted(
                                  occurrence,
                                  completed,
                                );
                              },
                              onTaskTap:
                                  (occurrence) {
                                _openTaskDetail(
                                  occurrence
                                      .task,
                                  occurrence:
                                      occurrence,
                                );
                              },
                            ),

                            const SizedBox(
                              height: 30,
                            ),
                          ],

                        if (pastOccurrences
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 2,
                          ),

                          _PastSection(
                            occurrences:
                                pastOccurrences,
                            expanded:
                                _pastExpanded,
                            onToggle:
                                () {
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
                            categoryBuilder:
                                (task) =>
                                    task.categoryId ==
                                            null
                                        ? null
                                        : categoryMap[
                                            task.categoryId],
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
                            recurrenceLabelBuilder:
                                (task) =>
                                    _recurrenceLabel(
                              task.recurrence,
                            ),
                            onCompletedChanged:
                                (
                              occurrence,
                              completed,
                            ) async {
                              if (completed) {
                                final remaining =
                                    occurrence
                                        .subtasks
                                        .where(
                                          (subtask) =>
                                              !subtask
                                                  .isCompleted,
                                        )
                                        .length;

                                if (remaining > 0) {
                                  final confirmed =
                                      await _confirmCompleteAll(
                                    remaining,
                                  );

                                  if (!confirmed) {
                                    return;
                                  }
                                }
                              }

                              await widget
                                  .taskRepository
                                  .setOccurrenceCompleted(
                                occurrence,
                                completed,
                              );
                            },
                            onTaskTap:
                                (occurrence) {
                              _openTaskDetail(
                                occurrence
                                    .task,
                                occurrence:
                                    occurrence,
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  );
                },
              );
            },
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
                  milliseconds:
                      160,
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
            CrossAxisAlignment
                .start,
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
            CrossAxisAlignment
                .start,
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
  final TaskCategory? Function(
    LifeTask task,
  ) categoryBuilder;
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
    required this.categoryBuilder,
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
            category:
                categoryBuilder(
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
            recurrenceLabel:
                null,
            onCompletedChanged:
                (completed) {
              return onCompletedChanged(
                tasks[i],
                completed,
              );
            },
            onTap:
                () {
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
                alpha:
                    0.45,
              ),
            ),
        ],
      ],
    );
  }
}

class _OccurrenceGroup
    extends StatelessWidget {
  final String title;
  final List<TaskOccurrence>
      occurrences;
  final String Function(
    LifeTask task,
  ) timeLabelBuilder;
  final String Function(
    LifeTask task,
  ) secondaryLabelBuilder;
  final TaskCategory? Function(
    LifeTask task,
  ) categoryBuilder;
  final Color Function(
    LifeTask task,
  ) priorityColorBuilder;
  final String Function(
    LifeTask task,
  ) priorityLabelBuilder;
  final String? Function(
    LifeTask task,
  ) recurrenceLabelBuilder;
  final Future<void> Function(
    TaskOccurrence occurrence,
    bool completed,
  ) onCompletedChanged;
  final void Function(
    TaskOccurrence occurrence,
  ) onTaskTap;

  const _OccurrenceGroup({
    required this.title,
    required this.occurrences,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.categoryBuilder,
    required this.priorityColorBuilder,
    required this.priorityLabelBuilder,
    required this.recurrenceLabelBuilder,
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
            i < occurrences.length;
            i++) ...[
          Builder(
            builder:
                (context) {
              final occurrence =
                  occurrences[i];
              final task =
                  occurrence
                      .displayTask;

              return _TaskRow(
                task:
                    task,
                timeLabel:
                    timeLabelBuilder(
                  task,
                ),
                secondaryLabel:
                    secondaryLabelBuilder(
                  task,
                ),
                category:
                    categoryBuilder(
                  task,
                ),
                priorityColor:
                    priorityColorBuilder(
                  task,
                ),
                priorityLabel:
                    priorityLabelBuilder(
                  task,
                ),
                recurrenceLabel:
                    recurrenceLabelBuilder(
                  occurrence.task,
                ),
                onCompletedChanged:
                    (completed) {
                  return onCompletedChanged(
                    occurrence,
                    completed,
                  );
                },
                onTap:
                    () {
                  onTaskTap(
                    occurrence,
                  );
                },
              );
            },
          ),
          if (i !=
              occurrences.length - 1)
            Divider(
              indent: 96,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.45,
              ),
            ),
        ],
      ],
    );
  }
}

class _PastSection
    extends StatelessWidget {
  final List<TaskOccurrence>
      occurrences;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(
    DateTime date,
  ) groupLabelBuilder;
  final String Function(
    TaskOccurrence occurrence,
  ) groupKeyBuilder;
  final String Function(
    LifeTask task,
  ) timeLabelBuilder;
  final String Function(
    LifeTask task,
  ) secondaryLabelBuilder;
  final TaskCategory? Function(
    LifeTask task,
  ) categoryBuilder;
  final Color Function(
    LifeTask task,
  ) priorityColorBuilder;
  final String Function(
    LifeTask task,
  ) priorityLabelBuilder;
  final String? Function(
    LifeTask task,
  ) recurrenceLabelBuilder;
  final Future<void> Function(
    TaskOccurrence occurrence,
    bool completed,
  ) onCompletedChanged;
  final void Function(
    TaskOccurrence occurrence,
  ) onTaskTap;

  const _PastSection({
    required this.occurrences,
    required this.expanded,
    required this.onToggle,
    required this.groupLabelBuilder,
    required this.groupKeyBuilder,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.categoryBuilder,
    required this.priorityColorBuilder,
    required this.priorityLabelBuilder,
    required this.recurrenceLabelBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
  });

  Map<String, List<TaskOccurrence>>
      _groups() {
    final groups =
        <String,
            List<TaskOccurrence>>{};

    for (final occurrence
        in occurrences) {
      final key =
          groupKeyBuilder(
        occurrence,
      );

      groups
          .putIfAbsent(
            key,
            () => [],
          )
          .add(
            occurrence,
          );
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
                    '${occurrences.length}',
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
                      milliseconds:
                          160,
                    ),
                    turns:
                        expanded
                            ? 0.5
                            : 0,
                    child: Icon(
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
                      .date,
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
              Builder(
                builder:
                    (context) {
                  final occurrence =
                      entry.value[i];
                  final task =
                      occurrence
                          .displayTask;

                  return _TaskRow(
                    task:
                        task,
                    timeLabel:
                        timeLabelBuilder(
                      task,
                    ),
                    secondaryLabel:
                        secondaryLabelBuilder(
                      task,
                    ),
                    category:
                        categoryBuilder(
                      task,
                    ),
                    priorityColor:
                        priorityColorBuilder(
                      task,
                    ),
                    priorityLabel:
                        priorityLabelBuilder(
                      task,
                    ),
                    recurrenceLabel:
                        recurrenceLabelBuilder(
                      occurrence
                          .task,
                    ),
                    isPast:
                        true,
                    onCompletedChanged:
                        (completed) {
                      return onCompletedChanged(
                        occurrence,
                        completed,
                      );
                    },
                    onTap:
                        () {
                      onTaskTap(
                        occurrence,
                      );
                    },
                  );
                },
              ),
              if (i !=
                  entry.value
                          .length -
                      1)
                Divider(
                  indent: 96,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.4,
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

class _TaskRow
    extends StatelessWidget {
  final LifeTask task;
  final String timeLabel;
  final String secondaryLabel;
  final TaskCategory? category;
  final Color priorityColor;
  final String priorityLabel;
  final String? recurrenceLabel;
  final bool isPast;
  final Future<void> Function(
    bool completed,
  ) onCompletedChanged;
  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.timeLabel,
    required this.secondaryLabel,
    required this.category,
    required this.priorityColor,
    required this.priorityLabel,
    required this.recurrenceLabel,
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

    final categoryColor =
        category == null
            ? colorScheme
                .onSurfaceVariant
                .withValues(
                  alpha: 0.72,
                )
            : Color(
                category!.colorValue,
              );

    return Opacity(
      opacity:
          isPast
              ? 0.82
              : 1,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
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
                          ? categoryColor
                          : Colors
                              .transparent,
                  shape:
                      BoxShape.circle,
                  border:
                      Border.all(
                    color:
                        categoryColor,
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
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    task.title,
                                    maxLines:
                                        1,
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
                                  width: 6,
                                ),
                                Tooltip(
                                  message:
                                      'Priorità $priorityLabel',
                                  child: Icon(
                                    Icons
                                        .flag_outlined,
                                    size: 15,
                                    color:
                                        priorityColor,
                                  ),
                                ),
                              ],
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
                              alpha:
                                  0.55,
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

                      if (category != null ||
                          recurrenceLabel !=
                              null ||
                          task.subtasks
                              .isNotEmpty ||
                          (isPast &&
                              !task
                                  .isCompleted &&
                              !task
                                  .recurrence
                                  .isRecurring)) ...[
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
                            if (category !=
                                null)
                              Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Icon(
                                    taskCategoryIcon(
                                      category!
                                          .iconKey,
                                    ),
                                    size: 14,
                                    color:
                                        categoryColor,
                                  ),
                                  const SizedBox(
                                    width:
                                        4,
                                  ),
                                  Text(
                                    category!
                                        .name,
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  categoryColor,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                  ),
                                ],
                              ),

                            if (task.subtasks
                                .isNotEmpty)
                              Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Icon(
                                    Icons
                                        .checklist_rounded,
                                    size: 14,
                                    color:
                                        categoryColor,
                                  ),
                                  const SizedBox(
                                    width:
                                        4,
                                  ),
                                  Text(
                                    '${task.subtasks.where((subtask) => subtask.isCompleted).length}/${task.subtasks.length}',
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .bodySmall
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

                            if (recurrenceLabel !=
                                null)
                              Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 14,
                                    color:
                                        colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  const SizedBox(
                                    width:
                                        4,
                                  ),
                                  Text(
                                    recurrenceLabel!,
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
                                ],
                              ),

                            if (isPast &&
                                !task
                                    .isCompleted &&
                                !task
                                    .recurrence
                                    .isRecurring)
                              Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
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
                                    width:
                                        4,
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
