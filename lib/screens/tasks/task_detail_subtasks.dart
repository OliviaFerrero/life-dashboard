import 'package:flutter/material.dart';

import '../../models/task_subtask.dart';

class TaskDetailSubtasksSection
    extends StatefulWidget {
  final List<TaskSubtask> subtasks;
  final Color accentColor;
  final ValueChanged<TaskSubtask> onToggle;
  final int collapsedItemCount;

  const TaskDetailSubtasksSection({
    super.key,
    required this.subtasks,
    required this.accentColor,
    required this.onToggle,
    this.collapsedItemCount = 6,
  });

  @override
  State<TaskDetailSubtasksSection>
      createState() =>
          _TaskDetailSubtasksSectionState();
}

class _TaskDetailSubtasksSectionState
    extends State<TaskDetailSubtasksSection> {
  bool _expanded = false;

  int get _completedCount =>
      widget.subtasks
          .where(
            (subtask) =>
                subtask.isCompleted,
          )
          .length;

  int get _remainingCount =>
      widget.subtasks.length -
      _completedCount;

  bool get _canCollapse =>
      widget.subtasks.length >
      widget.collapsedItemCount;

  List<TaskSubtask> get _visibleSubtasks {
    if (_expanded || !_canCollapse) {
      return widget.subtasks;
    }

    return widget.subtasks
        .take(
          widget.collapsedItemCount,
        )
        .toList(
          growable: false,
        );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final completedCount =
        _completedCount;

    final total =
        widget.subtasks.length;

    final progress =
        total == 0
            ? 0.0
            : completedCount / total;

    final remaining =
        _remainingCount;

    final visible =
        _visibleSubtasks;

    final hiddenCount =
        total - visible.length;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SOTTOATTIVITÀ',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing:
                          1.0,
                    ),
              ),
            ),
            Text(
              '$completedCount/$total',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant,
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        _SubtaskProgressBar(
          progress:
              progress,
          accentColor:
              widget.accentColor,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          remaining == 0
              ? 'Tutto completato'
              : remaining == 1
                  ? '1 da completare'
                  : '$remaining da completare',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: remaining == 0
                    ? widget.accentColor
                    : colorScheme
                        .onSurfaceVariant,
                fontWeight:
                    FontWeight.w600,
              ),
        ),
        const SizedBox(
          height: 10,
        ),
        AnimatedSize(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          curve:
              Curves.easeOutCubic,
          child: Column(
            children: [
              for (var index = 0;
                  index <
                      visible.length;
                  index++) ...[
                _SubtaskDetailRow(
                  subtask:
                      visible[index],
                  accentColor:
                      widget.accentColor,
                  onTap: () {
                    widget.onToggle(
                      visible[index],
                    );
                  },
                ),
                if (index !=
                    visible.length -
                        1)
                  Divider(
                    height:
                        1,
                    indent:
                        34,
                    color: colorScheme
                        .outlineVariant
                        .withValues(
                      alpha:
                          0.42,
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (_canCollapse) ...[
          const SizedBox(
            height: 6,
          ),
          _ExpandCollapseAction(
            expanded:
                _expanded,
            hiddenCount:
                hiddenCount,
            onTap: () {
              setState(() {
                _expanded =
                    !_expanded;
              });
            },
          ),
        ],
      ],
    );
  }
}

class _SubtaskProgressBar
    extends StatelessWidget {
  final double progress;
  final Color accentColor;

  const _SubtaskProgressBar({
    required this.progress,
    required this.accentColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        999,
      ),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit:
              StackFit.expand,
          children: [
            ColoredBox(
              color: colorScheme
                  .surfaceContainerHighest
                  .withValues(
                alpha:
                    0.6,
              ),
            ),
            FractionallySizedBox(
              alignment:
                  Alignment.centerLeft,
              widthFactor:
                  progress.clamp(
                0.0,
                1.0,
              ),
              child: ColoredBox(
                color:
                    accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtaskDetailRow
    extends StatelessWidget {
  final TaskSubtask subtask;
  final Color accentColor;
  final VoidCallback onTap;

  const _SubtaskDetailRow({
    required this.subtask,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final completed =
        subtask.isCompleted;

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
              const EdgeInsets.symmetric(
            vertical:
                11,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds:
                      150,
                ),
                width:
                    20,
                height:
                    20,
                decoration:
                    BoxDecoration(
                  color: completed
                      ? accentColor
                      : Colors
                          .transparent,
                  shape:
                      BoxShape.circle,
                  border:
                      Border.all(
                    color: completed
                        ? accentColor
                        : colorScheme
                            .onSurfaceVariant
                            .withValues(
                              alpha:
                                  0.72,
                            ),
                    width:
                        1.8,
                  ),
                ),
                child: completed
                    ? const Icon(
                        Icons.check,
                        size:
                            12,
                        color:
                            Colors.white,
                      )
                    : null,
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration:
                      const Duration(
                    milliseconds:
                        150,
                  ),
                  style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                completed
                                    ? FontWeight
                                        .w400
                                    : FontWeight
                                        .w500,
                            decoration:
                                completed
                                    ? TextDecoration
                                        .lineThrough
                                    : null,
                            color:
                                completed
                                    ? colorScheme
                                        .onSurfaceVariant
                                        .withValues(
                                          alpha:
                                              0.7,
                                        )
                                    : colorScheme
                                        .onSurface,
                          ) ??
                      const TextStyle(),
                  child: Text(
                    subtask.title,
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

class _ExpandCollapseAction
    extends StatelessWidget {
  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  const _ExpandCollapseAction({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final label =
        expanded
            ? 'Mostra meno'
            : hiddenCount == 1
                ? 'Mostra 1 altra'
                : 'Mostra altre $hiddenCount';

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            8,
          ),
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  2,
              vertical:
                  7,
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color:
                            colorScheme.primary,
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(
                  width:
                      4,
                ),
                Icon(
                  expanded
                      ? Icons
                          .expand_less
                      : Icons
                          .expand_more,
                  size:
                      18,
                  color:
                      colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
