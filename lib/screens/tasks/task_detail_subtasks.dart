import 'package:flutter/material.dart';

import '../../models/task_subtask.dart';

class TaskDetailSubtasksSection extends StatefulWidget {
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
  State<TaskDetailSubtasksSection> createState() =>
      _TaskDetailSubtasksSectionState();
}

class _TaskDetailSubtasksSectionState extends State<TaskDetailSubtasksSection> {
  bool _expanded = false;

  int get _completedCount => widget.subtasks
      .where(
        (subtask) => subtask.isCompleted,
      )
      .length;

  int get _remainingCount => widget.subtasks.length - _completedCount;

  bool get _canCollapse => widget.subtasks.length > widget.collapsedItemCount;

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final completedCount = _completedCount;
    final total = widget.subtasks.length;
    final progress = total == 0 ? 0.0 : completedCount / total;
    final remaining = _remainingCount;
    final visible = _visibleSubtasks;
    final hiddenCount = total - visible.length;

    final cardColor = Color.alphaBlend(
      widget.accentColor.withValues(
        alpha: brightness == Brightness.dark ? 0.10 : 0.045,
      ),
      colorScheme.surface,
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    widget.accentColor.withValues(
                      alpha: brightness == Brightness.dark ? 0.18 : 0.13,
                    ),
                    colorScheme.surface,
                  ),
                ),
                child: Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 24,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sottoattività',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining == 0
                          ? 'Tutto completato'
                          : remaining == 1
                              ? '1 da completare'
                              : '$remaining da completare',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: remaining == 0
                                ? widget.accentColor
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$completedCount/$total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            color: widget.accentColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.25,
                          ),
                    ),
                    const SizedBox(height: 7),
                    _SubtaskProgressBar(
                      progress: progress,
                      accentColor: widget.accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _SubtaskDetailRow(
                    subtask: visible[index],
                    accentColor: widget.accentColor,
                    onTap: () {
                      widget.onToggle(visible[index]);
                    },
                  ),
                  if (index != visible.length - 1) const SizedBox(height: 7),
                ],
              ],
            ),
          ),
          if (_canCollapse) ...[
            const SizedBox(height: 8),
            _ExpandCollapseAction(
              expanded: _expanded,
              hiddenCount: hiddenCount,
              accentColor: widget.accentColor,
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SubtaskProgressBar extends StatelessWidget {
  final double progress;
  final Color accentColor;

  const _SubtaskProgressBar({
    required this.progress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: ColoredBox(
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtaskDetailRow extends StatelessWidget {
  final TaskSubtask subtask;
  final Color accentColor;
  final VoidCallback onTap;

  const _SubtaskDetailRow({
    required this.subtask,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final completed = subtask.isCompleted;

    final rowColor = Color.alphaBlend(
      accentColor.withValues(
        alpha: completed
            ? (brightness == Brightness.dark ? 0.11 : 0.075)
            : (brightness == Brightness.dark ? 0.035 : 0.018),
      ),
      colorScheme.surfaceContainerLow,
    );

    return Material(
      color: rowColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 14,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  color: completed ? accentColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed
                        ? accentColor
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                    width: 1.8,
                  ),
                ),
                child: completed
                    ? Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: _foregroundFor(accentColor),
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                completed ? FontWeight.w400 : FontWeight.w600,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: completed
                                ? colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.76,
                                  )
                                : colorScheme.onSurface,
                          ) ??
                      const TextStyle(),
                  child: Text(subtask.title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandCollapseAction extends StatelessWidget {
  final bool expanded;
  final int hiddenCount;
  final Color accentColor;
  final VoidCallback onTap;

  const _ExpandCollapseAction({
    required this.expanded,
    required this.hiddenCount,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = expanded
        ? 'Mostra meno'
        : hiddenCount == 1
            ? 'Mostra 1 altra'
            : 'Mostra altre $hiddenCount';

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _foregroundFor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xFF17171C);
}
