import 'package:flutter/material.dart';

import '../core/time/app_clock.dart';

import '../models/life_task.dart';
import '../models/task_category.dart';
import '../models/task_occurrence.dart';
import '../repositories/category_repository.dart';
import '../repositories/task_repository.dart';
import '../services/day_settings_controller.dart';
import '../utils/task_category_icons.dart';
import '../widgets/task_timeline.dart';
import 'tasks/task_detail_page.dart';
import 'tasks/tasks_page.dart';

class TodayPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;
  final DaySettingsController daySettingsController;

  const TodayPage({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
    required this.daySettingsController,
  });

  @override
  State<TodayPage> createState() =>
      _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
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

  String _secondaryLabelForWindow(
    TaskOccurrence occurrence,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final task =
        occurrence.displayTask;
    final parts =
        <String>[];

    final actualStart =
        occurrence.timedStart;
    final actualEnd =
        occurrence.timedEnd;

    if (!task.allDay &&
        actualStart != null &&
        actualEnd != null) {
      if (actualStart.isBefore(
        windowStart,
      )) {
        parts.add(
          'continua da prima',
        );
      }

      if (actualEnd.isAfter(
        windowEnd,
      )) {
        parts.add(
          'continua dopo',
        );
      }
    }

    final duration =
        task.durationMinutes;

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

  Color _categoryColor(
    BuildContext context,
    LifeTask task,
    Map<String, TaskCategory> categoryMap,
  ) {
    final category =
        task.categoryId == null
            ? null
            : categoryMap[task.categoryId];

    if (category == null) {
      return Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(
            alpha: 0.72,
          );
    }

    return Color(
      category.colorValue,
    );
  }

  IconData _categoryIcon(
    LifeTask task,
    Map<String, TaskCategory> categoryMap,
  ) {
    final category =
        task.categoryId == null
            ? null
            : categoryMap[task.categoryId];

    if (category == null) {
      return Icons.label_outline;
    }

    return taskCategoryIcon(
      category.iconKey,
    );
  }

  DateTime _effectiveDayEnd({
    required DateTime dayStart,
    required DateTime configuredEnd,
    required DateTime nextDayStart,
    required List<TaskOccurrence> occurrences,
  }) {
    var result = configuredEnd;

    for (final occurrence in occurrences) {
      final task =
          occurrence.displayTask;

      if (task.allDay ||
          task.startTimeMinutes == null) {
        continue;
      }

      final start =
          occurrence.timedStart;

      if (start == null ||
          !start.isBefore(nextDayStart)) {
        continue;
      }

      var end =
          occurrence.timedEnd;

      end ??= start.add(
        Duration(
          minutes:
              task.durationMinutes ?? 30,
        ),
      );

      if (!end.isAfter(dayStart)) {
        continue;
      }

      if (end.isAfter(result)) {
        result = end;
      }
    }

    return result;
  }

  void _openTasks(
    BuildContext context, {
    bool inbox = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TasksPage(
          taskRepository:
              widget.taskRepository,
          categoryRepository:
              widget.categoryRepository,
          openInbox:
              inbox,
        ),
      ),
    );
  }

  void _openTaskDetail(
    BuildContext context,
    TaskOccurrence occurrence,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailPage(
          task:
              occurrence.task,
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

  Future<bool> _confirmCompleteAll(
    BuildContext context,
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
        AppClockScope.watch(
      context,
    ).now;

    return AnimatedBuilder(
      animation:
          widget.daySettingsController,
      builder:
          (context, _) {
        final dayWindowStart =
            widget.daySettingsController
                .personalDayStartFor(
          now,
        );

        final configuredDayEnd =
            widget.daySettingsController
                .configuredEndForStart(
          dayWindowStart,
        );

        final nextDayStart =
            widget.daySettingsController
                .nextPersonalDayStart(
          dayWindowStart,
        );

        final anchorDate =
            DateTime(
          dayWindowStart.year,
          dayWindowStart.month,
          dayWindowStart.day,
        );

        final colorScheme =
            Theme.of(context)
                .colorScheme;

        return SafeArea(
          bottom: false,
          child: StreamBuilder<
              List<LifeTask>>(
            stream:
                widget.taskRepository
                    .watchAllTasks(),
            initialData:
                const [],
            builder:
                (context, allTaskSnapshot) {
              final allTasks =
                  allTaskSnapshot.data ??
                      const <LifeTask>[];

              final inboxCount =
                  allTasks.where(
                (task) =>
                    task.scheduledDate ==
                        null &&
                    !task.isCompleted,
              ).length;

              return StreamBuilder<
                  List<TaskOccurrence>>(
                stream:
                    widget.taskRepository
                        .watchOccurrencesOverlappingWindow(
                  dayWindowStart,
                  nextDayStart,
                  untimedAnchorDate:
                      anchorDate,
                ),
                initialData:
                    const [],
                builder:
                    (context, occurrenceSnapshot) {
                  final occurrences =
                      occurrenceSnapshot.data ??
                          const <
                              TaskOccurrence>[];

                  final effectiveDayEnd =
                      _effectiveDayEnd(
                    dayStart:
                        dayWindowStart,
                    configuredEnd:
                        configuredDayEnd,
                    nextDayStart:
                        nextDayStart,
                    occurrences:
                        occurrences,
                  );

                  final tasks =
                      occurrences
                          .map(
                            (occurrence) =>
                                occurrence
                                    .displayTask,
                          )
                          .toList();

                  final completedCount =
                      occurrences.where(
                    (occurrence) =>
                        occurrence.isCompleted,
                  ).length;

                  return StreamBuilder<int>(
                    stream:
                        widget.taskRepository
                            .watchIncompleteOverviewCount(
                      now,
                    ),
                    initialData:
                        0,
                    builder:
                        (context, totalSnapshot) {
                      final totalIncompleteCount =
                          totalSnapshot.data ??
                              0;

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
                              categorySnapshot
                                      .data ??
                                  const <
                                      String,
                                      TaskCategory>{};

                          return Column(
                            children: [
                              Container(
                                width:
                                    double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  14,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Theme.of(context)
                                          .scaffoldBackgroundColor,
                                  border:
                                      Border(
                                    bottom:
                                        BorderSide(
                                      color:
                                          colorScheme
                                              .outlineVariant
                                              .withValues(
                                        alpha:
                                            0.38,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                                    .headlineLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing:
                                                          -0.8,
                                                    ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip:
                                              'Tutte le attività',
                                          onPressed:
                                              () {
                                            _openTasks(
                                              context,
                                            );
                                          },
                                          icon:
                                              Badge(
                                            isLabelVisible:
                                                totalIncompleteCount >
                                                    0,
                                            label: Text(
                                              '$totalIncompleteCount',
                                            ),
                                            child:
                                                const Icon(
                                              Icons
                                                  .checklist_rounded,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip:
                                              'Inbox',
                                          onPressed:
                                              () {
                                            _openTasks(
                                              context,
                                              inbox:
                                                  true,
                                            );
                                          },
                                          icon:
                                              Badge(
                                            isLabelVisible:
                                                inboxCount >
                                                    0,
                                            label: Text(
                                              '$inboxCount',
                                            ),
                                            child:
                                                const Icon(
                                              Icons
                                                  .inbox_outlined,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _dayLabel(
                                              anchorDate,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                          ),
                                        ),
                                        if (tasks.isNotEmpty) ...[
                                          const SizedBox(
                                            width: 16,
                                          ),
                                          Icon(
                                            Icons.check_rounded,
                                            size: 15,
                                            color:
                                                colorScheme.primary,
                                          ),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          Text(
                                            '$completedCount/${tasks.length}',
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
                                                          FontWeight.w700,
                                                    ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    20,
                                    32,
                                  ),
                                  children: [
                                    if (tasks.isEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              26,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons
                                                  .wb_sunny_outlined,
                                              color:
                                                  colorScheme.primary,
                                            ),
                                            const SizedBox(
                                              width: 14,
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Nessuna attività '
                                                'programmata per questa giornata.',
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
                                        occurrences:
                                            occurrences,
                                        windowStart:
                                            dayWindowStart,
                                        windowEnd:
                                            effectiveDayEnd,
                                        secondaryLabelBuilder:
                                            _secondaryLabelForWindow,
                                        subtaskProgressBuilder:
                                            (task) {
                                          if (task.subtasks
                                              .isEmpty) {
                                            return null;
                                          }

                                          final completed =
                                              task.subtasks
                                                  .where(
                                                    (subtask) =>
                                                        subtask
                                                            .isCompleted,
                                                  )
                                                  .length;

                                          return '$completed/'
                                              '${task.subtasks.length}';
                                        },
                                        accentColorBuilder:
                                            (task) {
                                          return _categoryColor(
                                            context,
                                            task,
                                            categoryMap,
                                          );
                                        },
                                        categoryIconBuilder:
                                            (task) {
                                          return _categoryIcon(
                                            task,
                                            categoryMap,
                                          );
                                        },
                                        priorityColorBuilder:
                                            (task) {
                                          return _priorityColor(
                                            context,
                                            task.priority,
                                          );
                                        },
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
                                                context,
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
                                            context,
                                            occurrence,
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
