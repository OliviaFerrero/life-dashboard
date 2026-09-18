import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';

class TasksPage extends StatelessWidget {
  final TaskRepository taskRepository;

  const TasksPage({
    super.key,
    required this.taskRepository,
  });

  Future<void> _addTask(
    BuildContext context,
  ) async {
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

    await taskRepository.addTask(
      result.task!,
    );
  }

  void _openTaskDetail(
    BuildContext context,
    LifeTask task,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailPage(
          task: task,
          taskRepository:
              taskRepository,
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

  String _formatTime(
    DateTime date,
  ) {
    return '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _timeLabel(
    LifeTask task,
  ) {
    if (task.startAt == null) {
      return '';
    }

    if (task.allDay) {
      return 'Tutto\nil giorno';
    }

    return _formatTime(
      task.startAt!,
    );
  }

  String _secondaryLabel(
    LifeTask task,
  ) {
    final parts = <String>[];

    if (!task.allDay &&
        task.endAt != null) {
      parts.add(
        'fino alle '
        '${_formatTime(task.endAt!)}',
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
    DateTime? date,
  ) {
    if (date == null) {
      return 'Senza data';
    }

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
        task.startAt;

    if (date == null) {
      return 'undated';
    }

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
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attività',
        ),
        actions: [
          IconButton(
            tooltip:
                'Nuova attività',
            onPressed: () {
              _addTask(context);
            },
            icon: const Icon(
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
        stream:
            taskRepository
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

          final tasks =
              snapshot.data!;

          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  32,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .check_circle_outline,
                      size: 54,
                      color:
                          colorScheme.primary,
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      'Nessuna attività',
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
                      'Quando aggiungerai '
                      'qualcosa da fare, '
                      'comparirà qui.',
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
                      onPressed: () {
                        _addTask(
                          context,
                        );
                      },
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
              ),
            );
          }

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
              for (final entry
                  in groups.entries) ...[
                _TaskGroup(
                  title:
                      _groupLabel(
                    entry.value
                        .first
                        .startAt,
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
                    await taskRepository
                        .setCompleted(
                      task.id,
                      completed,
                    );
                  },

                  onTaskTap:
                      (task) {
                    _openTaskDetail(
                      context,
                      task,
                    );
                  },
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ],
          );
        },
      ),
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