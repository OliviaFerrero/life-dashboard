import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../repositories/task_repository.dart';
import '../widgets/dashboard_card.dart';
import 'calendar/calendar_page.dart';
import 'tasks/task_detail_page.dart';
import 'tasks/tasks_page.dart';

class TodayPage extends StatelessWidget {
  final TaskRepository taskRepository;

  const TodayPage({
    super.key,
    required this.taskRepository,
  });

  String _dayLabel(DateTime date) {
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

  String _twoDigits(int value) {
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

  String _taskTimeLabel(
    LifeTask task,
  ) {
    if (task.startAt == null) {
      return '';
    }

    if (task.allDay) {
      return 'Tutto il giorno';
    }

    final start =
        _formatTime(
      task.startAt!,
    );

    if (task.endAt == null) {
      return start;
    }

    return '$start – '
        '${_formatTime(task.endAt!)}';
  }

  Color _priorityColor(
    BuildContext context,
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;

      case TaskPriority.normal:
        return Theme.of(context)
            .colorScheme
            .primary;

      case TaskPriority.high:
        return Colors.red;
    }
  }

  LifeTask? _findNextTask(
    List<LifeTask> tasks,
    DateTime now,
  ) {
    final incomplete = tasks
        .where(
          (task) =>
              !task.isCompleted,
        )
        .toList();

    if (incomplete.isEmpty) {
      return null;
    }

    for (final task
        in incomplete) {
      if (!task.allDay &&
          task.startAt != null &&
          !task.startAt!
              .isBefore(now)) {
        return task;
      }
    }

    for (final task
        in incomplete) {
      if (task.allDay) {
        return task;
      }
    }

    return incomplete.first;
  }

  void _openTasks(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TasksPage(
          taskRepository:
              taskRepository,
        ),
      ),
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final now =
        DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return SafeArea(
      bottom: false,
      child: StreamBuilder<
          List<LifeTask>>(
        stream: taskRepository
            .watchTasksForDay(
          today,
        ),
        initialData: const [],
        builder:
            (context, snapshot) {
          final tasks =
              snapshot.data ??
                  const <LifeTask>[];

          final completedCount =
              tasks
                  .where(
                    (task) =>
                        task.isCompleted,
                  )
                  .length;

          final incompleteCount =
              tasks.length -
                  completedCount;

          final nextTask =
              _findNextTask(
            tasks,
            now,
          );

          final visibleTasks =
              tasks.take(3).toList();

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              24,
              20,
              32,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Oggi',
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w700,
                                letterSpacing:
                                    -1,
                              ),
                    ),
                  ),
                  IconButton
                      .filledTonal(
                    tooltip:
                        'Calendario',
                    icon: const Icon(
                      Icons
                          .calendar_month_outlined,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  CalendarPage(
                            taskRepository:
                                taskRepository,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                _dayLabel(today),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(
                height: 28,
              ),

              Text(
                'Prossima attività',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),

              const SizedBox(
                height: 10,
              ),

              if (nextTask == null)
                Card(
                  margin:
                      EdgeInsets.zero,
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .check_circle_outline,
                          color:
                              colorScheme
                                  .primary,
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        const Expanded(
                          child: Text(
                            'Nessuna attività '
                            'da completare oggi.',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  margin:
                      EdgeInsets.zero,
                  clipBehavior:
                      Clip.antiAlias,
                  child: Row(
                    children: [
                      Checkbox(
                        value:
                            nextTask
                                .isCompleted,
                        onChanged:
                            (value) async {
                          await taskRepository
                              .setCompleted(
                            nextTask.id,
                            value ??
                                false,
                          );
                        },
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _openTaskDetail(
                              context,
                              nextTask,
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              4,
                              16,
                              14,
                              16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 48,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _priorityColor(
                                      context,
                                      nextTask
                                          .priority,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        nextTask
                                            .title,
                                        style:
                                            Theme.of(
                                          context,
                                        )
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                      ),
                                      const SizedBox(
                                        height:
                                            4,
                                      ),
                                      Text(
                                        _taskTimeLabel(
                                          nextTask,
                                        ),
                                        style:
                                            Theme.of(
                                          context,
                                        )
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      colorScheme.onSurfaceVariant,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons
                                      .chevron_right,
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 28,
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Attività di oggi',
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
                  if (tasks.isNotEmpty)
                    Text(
                      '$completedCount/'
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
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              if (tasks.isEmpty)
                Card(
                  margin:
                      EdgeInsets.zero,
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .event_available_outlined,
                          color:
                              colorScheme
                                  .primary,
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        const Expanded(
                          child: Text(
                            'Giornata libera: '
                            'non hai attività '
                            'programmate.',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  margin:
                      EdgeInsets.zero,
                  clipBehavior:
                      Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0;
                          i <
                              visibleTasks
                                  .length;
                          i++) ...[
                        _TodayTaskTile(
                          task:
                              visibleTasks[
                                  i],
                          timeLabel:
                              _taskTimeLabel(
                            visibleTasks[
                                i],
                          ),
                          priorityColor:
                              _priorityColor(
                            context,
                            visibleTasks[
                                    i]
                                .priority,
                          ),
                          onChanged:
                              (completed) async {
                            await taskRepository
                                .setCompleted(
                              visibleTasks[
                                      i]
                                  .id,
                              completed,
                            );
                          },
                          onTap: () {
                            _openTaskDetail(
                              context,
                              visibleTasks[
                                  i],
                            );
                          },
                        ),
                        if (i !=
                            visibleTasks
                                    .length -
                                1)
                          const Divider(
                            height: 1,
                          ),
                      ],
                      if (tasks.length >
                          3) ...[
                        const Divider(
                          height: 1,
                        ),
                        TextButton(
                          onPressed: () {
                            _openTasks(
                              context,
                            );
                          },
                          child: Text(
                            'Vedi tutte '
                            '(${tasks.length})',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(
                height: 14,
              ),

              DashboardCard(
                icon:
                    Icons.task_alt,
                title: 'Attività',
                value:
                    incompleteCount ==
                            1
                        ? '1 da completare oggi'
                        : '$incompleteCount '
                            'da completare oggi',
                onTap: () {
                  _openTasks(
                    context,
                  );
                },
              ),

              const SizedBox(
                height: 14,
              ),

              const DashboardCard(
                icon: Icons.repeat,
                title: 'Abitudini',
                value:
                    '0 completate oggi',
              ),

              const SizedBox(
                height: 14,
              ),

              const DashboardCard(
                icon: Icons
                    .shopping_cart_outlined,
                title:
                    'Lista della spesa',
                value: '0 prodotti',
              ),

              const SizedBox(
                height: 14,
              ),

              const DashboardCard(
                icon: Icons
                    .account_balance_wallet_outlined,
                title:
                    'Spese del mese',
                value: '€ 0,00',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayTaskTile
    extends StatelessWidget {
  final LifeTask task;
  final String timeLabel;
  final Color priorityColor;
  final ValueChanged<bool>
      onChanged;
  final VoidCallback onTap;

  const _TodayTaskTile({
    required this.task,
    required this.timeLabel,
    required this.priorityColor,
    required this.onChanged,
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
      children: [
        Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            onChanged(
              value ?? false,
            );
          },
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                4,
                12,
                8,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 34,
                    decoration:
                        BoxDecoration(
                      color:
                          priorityColor,
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
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
                  Text(
                    timeLabel,
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
                            ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Icon(
                    Icons
                        .chevron_right,
                    size: 20,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}