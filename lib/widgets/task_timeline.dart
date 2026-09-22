import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../models/task_occurrence.dart';

/// Timeline della giornata basata su una finestra temporale esplicita.
///
/// Oggi usa ancora 00:00 -> 24:00, ma i confini NON sono codificati qui:
/// in futuro potranno diventare, ad esempio, 06:00 -> 03:00 del giorno
/// successivo. Un eventuale marker "Fine giornata" potrà quindi estendere
/// windowEnd oltre l'orario configurato quando esistono task più tarde.
class TaskTimeline
    extends StatelessWidget {
  final List<TaskOccurrence> occurrences;

  final DateTime windowStart;
  final DateTime windowEnd;

  final String Function(
    TaskOccurrence occurrence,
    DateTime windowStart,
    DateTime windowEnd,
  ) timeLabelBuilder;

  final String Function(
    TaskOccurrence occurrence,
    DateTime windowStart,
    DateTime windowEnd,
  ) secondaryLabelBuilder;

  final String? Function(
    LifeTask task,
  ) subtaskProgressBuilder;

  final Color Function(
    LifeTask task,
  ) accentColorBuilder;

  final Color Function(
    LifeTask task,
  ) priorityColorBuilder;

  final String? nextOccurrenceKey;

  final Future<void> Function(
    TaskOccurrence occurrence,
    bool completed,
  ) onCompletedChanged;

  final void Function(
    TaskOccurrence occurrence,
  ) onTaskTap;

  const TaskTimeline({
    super.key,
    required this.occurrences,
    required this.windowStart,
    required this.windowEnd,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.subtaskProgressBuilder,
    required this.accentColorBuilder,
    required this.priorityColorBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
    this.nextOccurrenceKey,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        for (int i = 0;
            i < occurrences.length;
            i++)
          Builder(
            builder: (context) {
              final occurrence =
                  occurrences[i];
              final task =
                  occurrence.displayTask;

              return _TaskTimelineItem(
                task:
                    task,

                timeLabel:
                    timeLabelBuilder(
                  occurrence,
                  windowStart,
                  windowEnd,
                ),

                secondaryLabel:
                    secondaryLabelBuilder(
                  occurrence,
                  windowStart,
                  windowEnd,
                ),

                subtaskProgress:
                    subtaskProgressBuilder(
                  task,
                ),

                accentColor:
                    accentColorBuilder(
                  task,
                ),

                priorityColor:
                    priorityColorBuilder(
                  task,
                ),

                isFirst:
                    i == 0,

                isLast:
                    i ==
                        occurrences.length -
                            1,

                isNext:
                    occurrence
                            .occurrenceKey ==
                        nextOccurrenceKey,

                onCompletedChanged:
                    (completed) {
                  return onCompletedChanged(
                    occurrence,
                    completed,
                  );
                },

                onTap: () {
                  onTaskTap(
                    occurrence,
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _TaskTimelineItem
    extends StatelessWidget {
  final LifeTask task;
  final String timeLabel;
  final String secondaryLabel;
  final String? subtaskProgress;
  final Color accentColor;
  final Color priorityColor;

  final bool isFirst;
  final bool isLast;
  final bool isNext;

  final Future<void> Function(
    bool completed,
  ) onCompletedChanged;

  final VoidCallback onTap;

  const _TaskTimelineItem({
    required this.task,
    required this.timeLabel,
    required this.secondaryLabel,
    required this.subtaskProgress,
    required this.accentColor,
    required this.priorityColor,
    required this.isFirst,
    required this.isLast,
    required this.isNext,
    required this.onCompletedChanged,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final lineColor =
        colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 18,
                right: 8,
              ),

              child: Align(
                alignment:
                    Alignment.topRight,
                child: Text(
                  timeLabel,
                  textAlign:
                      TextAlign.right,
                  maxLines: 2,

                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: isNext
                                ? accentColor
                                : colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                isNext
                                    ? FontWeight
                                        .w700
                                    : FontWeight
                                        .w500,
                          ),
                ),
              ),
            ),
          ),

          GestureDetector(
            behavior:
                HitTestBehavior.opaque,

            onTap: () {
              onCompletedChanged(
                !task.isCompleted,
              );
            },

            child: SizedBox(
              width: 36,

              child: Stack(
                children: [
                  if (!isFirst)
                    Positioned(
                      top: 0,
                      left: 17,
                      width: 1,
                      height: 27,
                      child: ColoredBox(
                        color:
                            lineColor,
                      ),
                    ),

                  if (!isLast)
                    Positioned(
                      top: 27,
                      bottom: 0,
                      left: 17,
                      width: 1,
                      child: ColoredBox(
                        color:
                            lineColor,
                      ),
                    ),

                  Positioned(
                    top: 19,
                    left: 9,

                    child: Container(
                      width: 17,
                      height: 17,

                      decoration:
                          BoxDecoration(
                        color:
                            task.isCompleted
                                ? accentColor
                                : Theme.of(
                                  context,
                                )
                                    .scaffoldBackgroundColor,

                        shape:
                            BoxShape.circle,

                        border:
                            Border.all(
                          color:
                              accentColor,
                          width: isNext
                              ? 3
                              : 2,
                        ),
                      ),

                      child:
                          task.isCompleted
                              ? const Icon(
                                  Icons
                                      .check,
                                  size: 11,
                                  color:
                                      Colors
                                          .white,
                                )
                              : null,
                    ),
                  ),
                ],
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
                    10,
                    12,
                    4,
                    18,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Row(
                        children: [
                          Flexible(
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
                                            isNext
                                                ? FontWeight
                                                    .w700
                                                : FontWeight
                                                    .w600,

                                        color:
                                            isNext &&
                                                    !task
                                                        .isCompleted
                                                ? accentColor
                                                : null,

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

                          Icon(
                            Icons.flag_outlined,
                            size: 15,
                            color:
                                priorityColor,
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

                      if (subtaskProgress !=
                          null) ...[
                        const SizedBox(
                          height: 6,
                        ),

                        Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            Icon(
                              Icons
                                  .checklist_outlined,
                              size: 14,
                              color:
                                  colorScheme
                                      .onSurfaceVariant,
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              subtaskProgress!,
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
                                                .w700,
                                      ),
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

          Padding(
            padding:
                const EdgeInsets.only(
              top: 17,
            ),
            child: Icon(
              Icons.chevron_right,
              size: 19,
              color: colorScheme
                  .onSurfaceVariant
                  .withValues(
                alpha: 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
