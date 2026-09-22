import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../models/task_category.dart';
import '../models/task_occurrence.dart';
import '../repositories/category_repository.dart';
import '../repositories/task_repository.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/life_section_header.dart';
import '../widgets/task_timeline.dart';
import 'tasks/task_detail_page.dart';
import 'tasks/tasks_page.dart';

class TodayPage extends StatelessWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;

  const TodayPage({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
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

  String _clock(
    DateTime value,
  ) {
    return '${_twoDigits(value.hour)}:'
        '${_twoDigits(value.minute)}';
  }

  String _timeLabelForWindow(
    TaskOccurrence occurrence,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final task =
        occurrence.displayTask;

    if (task.allDay) {
      return 'Tutto il\ngiorno';
    }

    if (task.startTimeMinutes == null) {
      return '';
    }

    final visibleStart =
        occurrence.visibleStartInWindow(
      windowStart,
      windowEnd,
    );

    if (visibleStart == null) {
      return _formatClockMinutes(
        task.startTimeMinutes!,
      );
    }

    return _clock(
      visibleStart,
    );
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
      final visibleStart =
          occurrence.visibleStartInWindow(
        windowStart,
        windowEnd,
      );

      final visibleEnd =
          occurrence.visibleEndInWindow(
        windowStart,
        windowEnd,
      );

      if (visibleStart != null &&
          actualStart.isBefore(
            windowStart,
          )) {
        parts.add(
          'continua da prima',
        );
      }

      if (visibleEnd != null) {
        parts.add(
          'fino alle ${_clock(visibleEnd)}',
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

  TaskOccurrence? _findNextOccurrence(
    List<TaskOccurrence> occurrences,
    DateTime now,
  ) {
    final incomplete =
        occurrences
            .where(
              (occurrence) =>
                  !occurrence.isCompleted,
            )
            .toList();

    if (incomplete.isEmpty) {
      return null;
    }

    for (final occurrence
        in incomplete) {
      final start =
          occurrence.timedStart;
      final end =
          occurrence.timedEnd;

      if (start != null &&
          end != null &&
          !now.isBefore(start) &&
          now.isBefore(end)) {
        return occurrence;
      }
    }

    for (final occurrence
        in incomplete) {
      final start =
          occurrence.timedStart;

      if (start != null &&
          !start.isBefore(now)) {
        return occurrence;
      }
    }

    for (final occurrence
        in incomplete) {
      final task =
          occurrence.displayTask;

      if (task.allDay ||
          task.startTimeMinutes == null) {
        return occurrence;
      }
    }

    return incomplete.first;
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
              taskRepository,
          categoryRepository:
              categoryRepository,
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
              taskRepository,
          categoryRepository:
              categoryRepository,
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
        DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Oggi usa ancora la giornata civile 00:00 -> 24:00.
    // La timeline riceve però una finestra esplicita: in futuro
    // questi confini potranno diventare configurabili (es. 06:00
    // -> 03:00 del giorno successivo) senza cambiare la semantica
    // delle occorrenze che attraversano la mezzanotte.
    final dayWindowStart =
        today;
    final dayWindowEnd =
        today.add(
      const Duration(days: 1),
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
                taskRepository
                    .watchOccurrencesOverlappingWindow(
              dayWindowStart,
              dayWindowEnd,
              untimedAnchorDate:
                  today,
            ),
            initialData:
                const [],
            builder:
                (context, occurrenceSnapshot) {
              final occurrences =
                  occurrenceSnapshot.data ??
                      const <
                          TaskOccurrence>[];

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

              final incompleteCount =
                  occurrences.length -
                      completedCount;

              final nextOccurrence =
                  _findNextOccurrence(
                occurrences,
                now,
              );

              return StreamBuilder<int>(
                stream:
                    taskRepository
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
                        categoryRepository
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
                            height: 2,
                          ),

                          Text(
                            _dayLabel(
                              today,
                            ),
                            style:
                                Theme.of(
                              context,
                            )
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
                                vertical:
                                    26,
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
                              occurrences:
                                  occurrences,
                              windowStart:
                                  dayWindowStart,
                              windowEnd:
                                  dayWindowEnd,
                              nextOccurrenceKey:
                                  nextOccurrence
                                      ?.occurrenceKey,
                              timeLabelBuilder:
                                  _timeLabelForWindow,
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

                                await taskRepository
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

                          if (tasks.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 8,
                              ),
                              child: Text(
                                incompleteCount ==
                                        0
                                    ? 'Tutto completato per oggi'
                                    : incompleteCount ==
                                            1
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

                          DashboardCard(
                            icon:
                                Icons
                                    .task_alt,
                            title:
                                'Attività',
                            value:
                                totalIncompleteCount ==
                                        1
                                    ? '1 attività da completare'
                                    : '$totalIncompleteCount attività da completare',
                            onTap:
                                () {
                              _openTasks(
                                context,
                              );
                            },
                          ),

                          Divider(
                            color:
                                colorScheme
                                    .outlineVariant
                                    .withValues(
                              alpha:
                                  0.55,
                            ),
                          ),

                          const DashboardCard(
                            icon:
                                Icons.repeat,
                            title:
                                'Abitudini',
                            value:
                                '0 completate oggi',
                          ),

                          Divider(
                            color:
                                colorScheme
                                    .outlineVariant
                                    .withValues(
                              alpha:
                                  0.55,
                            ),
                          ),

                          const DashboardCard(
                            icon:
                                Icons
                                    .shopping_bag_outlined,
                            title:
                                'Lista della spesa',
                            value:
                                '0 prodotti',
                          ),

                          Divider(
                            color:
                                colorScheme
                                    .outlineVariant
                                    .withValues(
                              alpha:
                                  0.55,
                            ),
                          ),

                          const DashboardCard(
                            icon:
                                Icons
                                    .account_balance_wallet_outlined,
                            title:
                                'Spese del mese',
                            value:
                                '€ 0,00',
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
  }
}
