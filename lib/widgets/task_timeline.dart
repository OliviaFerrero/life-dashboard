import 'package:flutter/material.dart';

import '../models/life_task.dart';

class TaskTimeline
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
  ) accentColorBuilder;

  final String? nextTaskId;

  final Future<void> Function(
    LifeTask task,
    bool completed,
  ) onCompletedChanged;

  final void Function(
    LifeTask task,
  ) onTaskTap;

  const TaskTimeline({
    super.key,
    required this.tasks,
    required this.timeLabelBuilder,
    required this.secondaryLabelBuilder,
    required this.accentColorBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
    this.nextTaskId,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        for (int i = 0;
            i < tasks.length;
            i++)
          _TaskTimelineItem(
            task: tasks[i],

            timeLabel:
                timeLabelBuilder(
              tasks[i],
            ),

            secondaryLabel:
                secondaryLabelBuilder(
              tasks[i],
            ),

            accentColor:
                accentColorBuilder(
              tasks[i],
            ),

            isFirst: i == 0,

            isLast:
                i == tasks.length - 1,

            isNext:
                tasks[i].id ==
                    nextTaskId,

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
      ],
    );
  }
}

class _TaskTimelineItem
    extends StatelessWidget {
  final LifeTask task;
  final String timeLabel;
  final String secondaryLabel;
  final Color accentColor;

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
    required this.accentColor,
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
                      Text(
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