import 'package:flutter/material.dart';

import '../../models/life_task.dart';

class TaskPrioritySelector
    extends StatelessWidget {
  final TaskPriority value;

  final String Function(
    TaskPriority priority,
  ) labelBuilder;

  final Color Function(
    TaskPriority priority,
  ) colorBuilder;

  final ValueChanged<TaskPriority>
      onChanged;

  const TaskPrioritySelector({
    super.key,
    required this.value,
    required this.labelBuilder,
    required this.colorBuilder,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        for (int i = 0;
            i <
                TaskPriority
                    .values.length;
            i++) ...[
          Expanded(
            child: _PriorityChoice(
              priority:
                  TaskPriority
                      .values[i],
              label:
                  labelBuilder(
                TaskPriority
                    .values[i],
              ),
              color:
                  colorBuilder(
                TaskPriority
                    .values[i],
              ),
              selected:
                  value ==
                      TaskPriority
                          .values[i],
              onTap: () {
                onChanged(
                  TaskPriority
                      .values[i],
                );
              },
            ),
          ),

          if (i !=
              TaskPriority
                      .values.length -
                  1)
            const SizedBox(
              width: 12,
            ),
        ],
      ],
    );
  }
}

class _PriorityChoice
    extends StatelessWidget {
  final TaskPriority priority;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChoice({
    required this.priority,
    required this.label,
    required this.color,
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

        borderRadius:
            BorderRadius.circular(
          10,
        ),

        child: Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            4,
            10,
            4,
            7,
          ),

          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  Icon(
                    Icons
                        .flag_outlined,
                    size: 16,
                    color:
                        selected
                            ? color
                            : colorScheme
                                .onSurfaceVariant,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Flexible(
                    child: Text(
                      label,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    selected
                                        ? color
                                        : colorScheme
                                            .onSurfaceVariant,
                                fontWeight:
                                    selected
                                        ? FontWeight
                                            .w700
                                        : FontWeight
                                            .w500,
                              ),
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
                  milliseconds: 150,
                ),
                height: 2,
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? color
                          : Colors
                              .transparent,
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

