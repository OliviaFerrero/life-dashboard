import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../repositories/task_repository.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/life_section_header.dart';
import '../widgets/task_timeline.dart';
import 'calendar/calendar_page.dart';
import 'tasks/task_detail_page.dart';
import 'tasks/tasks_page.dart';

class TodayPage
    extends StatelessWidget {
  final TaskRepository taskRepository;

  const TodayPage({
    super.key,
    required this.taskRepository,
  });

  String _dayLabel(
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
        '${months[date.month - 1]}';
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
    if (task.allDay) {
      return 'Tutto il\ngiorno';
    }

    if (task.startAt == null) {
      return '';
    }

    return _formatTime(
      task.startAt!,
    );
  }

  String _secondaryLabel(
    LifeTask task,
  ) {
    final parts =
        <String>[];

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

  LifeTask? _findNextTask(
    List<LifeTask> tasks,
    DateTime now,
  ) {
    final incomplete =
        tasks.where(
      (task) =>
          !task.isCompleted,
    );

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

    return null;
  }

  void _openTasks(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TasksPage(
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

    final today =
        DateTime(
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
        stream:
            taskRepository
                .watchTasksForDay(
          today,
        ),

        initialData:
            const [],

        builder:
            (context, snapshot) {
          final tasks =
              snapshot.data ??
                  const <
                      LifeTask>[];

          final completedCount =
              tasks.where(
            (task) =>
                task.isCompleted,
          ).length;

          final incompleteCount =
              tasks.length -
                  completedCount;

          final nextTask =
              _findNextTask(
            tasks,
            now,
          );

          final visibleTasks =
              tasks
                  .take(5)
                  .toList();

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              24,
              20,
              40,
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
                                    -1.2,
                              ),
                    ),
                  ),

                  IconButton(
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
                height: 2,
              ),

              Text(
                _dayLabel(
                  today,
                ),

                style:
                    Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,

                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
              ),

              const SizedBox(
                height: 32,
              ),

              LifeSectionHeader(
                title:
                    'La tua giornata',

                value:
                    tasks.isEmpty
                        ? null
                        : '$completedCount/'
                            '${tasks.length}',

                actionLabel:
                    tasks.isEmpty
                        ? null
                        : 'Vedi tutte',

                onAction:
                    tasks.isEmpty
                        ? null
                        : () {
                            _openTasks(
                              context,
                            );
                          },
              ),

              const SizedBox(
                height: 8,
              ),

              if (tasks.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 26,
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Icon(
                        Icons
                            .wb_sunny_outlined,
                        color:
                            colorScheme
                                .primary,
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Text(
                          'Nessuna attività '
                          'programmata per oggi.',

                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        colorScheme
                                            .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                TaskTimeline(
                  tasks:
                      visibleTasks,

                  nextTaskId:
                      nextTask?.id,

                  timeLabelBuilder:
                      _timeLabel,

                  secondaryLabelBuilder:
                      _secondaryLabel,

                  accentColorBuilder:
                      (task) {
                    return _priorityColor(
                      context,
                      task.priority,
                    );
                  },

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

              if (tasks.length > 5)
                Align(
                  alignment:
                      Alignment.centerLeft,

                  child: TextButton(
                    onPressed: () {
                      _openTasks(
                        context,
                      );
                    },

                    child: Text(
                      'Altre '
                      '${tasks.length - 5} '
                      'attività',
                    ),
                  ),
                ),

              if (tasks.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    top: 8,
                  ),

                  child: Text(
                    incompleteCount == 0
                        ? 'Tutto completato per oggi'
                        : incompleteCount == 1
                            ? '1 attività ancora da completare'
                            : '$incompleteCount attività ancora da completare',

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
                ),

              const SizedBox(
                height: 34,
              ),

              const LifeSectionHeader(
                title:
                    'Panoramica',
              ),

              const SizedBox(
                height: 4,
              ),

              const DashboardCard(
                icon: Icons.repeat,
                title: 'Abitudini',
                value: '0 completate oggi',
              ),

              Divider(
                color: colorScheme.outlineVariant
                    .withValues(alpha: 0.55),
              ),

              const DashboardCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Lista della spesa',
                value: '0 prodotti',
              ),

              Divider(
                color: colorScheme.outlineVariant
                    .withValues(alpha: 0.55),
              ),

              const DashboardCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Spese del mese',
                value: '€ 0,00',
              ),
            ],
          );
        },
      ),
    );
  }
}