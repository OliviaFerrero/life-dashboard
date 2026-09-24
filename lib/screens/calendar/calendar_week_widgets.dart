part of 'calendar_page.dart';

// Widget visuali della vista Week: header, gutter, overlay, blocchi evento e resize.

class _WeekActionSheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _WeekActionSheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final color =
        isDestructive
            ? colorScheme.error
            : colorScheme.onSurface;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                15,
          ),
          child:
              Row(
            children: [
              SizedBox(
                width:
                    32,
                child:
                    Icon(
                  icon,
                  size:
                      20,
                  color:
                      color,
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Text(
                  label,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                color,
                            fontWeight:
                                FontWeight.w600,
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

class _MoveScopeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoveScopeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                14,
          ),
          child:
              Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width:
                    32,
                child:
                    Icon(
                  icon,
                  size:
                      20,
                  color:
                      colorScheme.primary,
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                    ),
                    const SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      subtitle,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekPinnedGutter extends StatelessWidget {
  final double width;
  final double hourHeight;
  final double gridTopPadding;
  final ScrollController verticalController;
  final bool untimedExpanded;
  final double untimedOverlayHeight;
  final VoidCallback onCloseUntimed;

  const _WeekPinnedGutter({
    required this.width,
    required this.hourHeight,
    required this.gridTopPadding,
    required this.verticalController,
    required this.untimedExpanded,
    required this.untimedOverlayHeight,
    required this.onCloseUntimed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final backgroundColor =
        Theme.of(context).scaffoldBackgroundColor;

    return ColoredBox(
      color:
          backgroundColor,
      child:
          Column(
        children: [
          SizedBox(
            height:
                76,
            width:
                width,
          ),
          Expanded(
            child:
                Stack(
              children: [
                Positioned.fill(
                  child:
                      IgnorePointer(
                    child:
                        ColoredBox(
                      color:
                          backgroundColor,
                    ),
                  ),
                ),
                Positioned.fill(
                  child:
                      IgnorePointer(
                    child:
                        ClipRect(
                      child:
                          AnimatedBuilder(
                        animation:
                            verticalController,
                        builder:
                            (context, child) {
                          final offset =
                              verticalController.hasClients
                                  ? verticalController.offset
                                  : 0.0;

                          return Stack(
                            clipBehavior:
                                Clip.hardEdge,
                            children: [
                              for (var hour = 0;
                                  hour < 24;
                                  hour++)
                                Positioned(
                                  left:
                                      0,
                                  right:
                                      7,
                                  top:
                                      gridTopPadding +
                                          hour *
                                              hourHeight -
                                          8 -
                                          offset,
                                  child:
                                      Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    textAlign:
                                        TextAlign.right,
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (untimedExpanded)
                  Positioned(
                    left:
                        0,
                    right:
                        0,
                    top:
                        0,
                    height:
                        untimedOverlayHeight,
                    child:
                        Material(
                      color:
                          colorScheme
                              .surfaceContainerHigh
                              .withValues(
                        alpha:
                            0.97,
                      ),
                      elevation:
                          5,
                      shadowColor:
                          colorScheme.shadow.withValues(
                        alpha:
                            0.14,
                      ),
                      child:
                          Center(
                        child:
                            IconButton(
                          tooltip:
                              'Chiudi attività senza orario',
                          visualDensity:
                              VisualDensity.compact,
                          onPressed:
                              onCloseUntimed,
                          icon:
                              const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size:
                                19,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _WeekDayHeader extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final double gutterWidth;
  final double dayWidth;
  final bool collapsed;
  final bool untimedExpanded;
  final Map<int, List<TaskOccurrence>> untimedByDay;
  final Map<String, TaskCategory> categoryMap;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final ValueChanged<DateTime> onUntimedToggle;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekDayHeader({
    required this.days,
    required this.selectedDay,
    required this.gutterWidth,
    required this.dayWidth,
    required this.collapsed,
    required this.untimedExpanded,
    required this.untimedByDay,
    required this.categoryMap,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onUntimedToggle,
    required this.onDaySelected,
  });

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Color _indicatorColor(
    BuildContext context,
    TaskOccurrence occurrence,
  ) {
    final task =
        occurrence.displayTask;

    final category =
        task.categoryId == null
            ? null
            : categoryMap[
                task.categoryId];

    if (category == null) {
      return Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(
            alpha:
                0.72,
          );
    }

    return Color(
      category.colorValue,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final now =
        AppClockScope.watch(
      context,
    ).now;

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    const shortWeekdays = [
      'LUN',
      'MAR',
      'MER',
      'GIO',
      'VEN',
      'SAB',
      'DOM',
    ];

    return GestureDetector(
      behavior:
          HitTestBehavior.translucent,
      onVerticalDragUpdate:
          onVerticalDragUpdate,
      onVerticalDragEnd:
          onVerticalDragEnd,
      child:
          SizedBox(
        height:
            76,
        child:
            Row(
          children: [
            SizedBox(
              width:
                  gutterWidth,
              child:
                  Center(
                child:
                    Icon(
                  collapsed
                      ? Icons
                          .keyboard_arrow_down_rounded
                      : Icons
                          .keyboard_arrow_up_rounded,
                  size:
                      18,
                  color:
                      colorScheme
                          .onSurfaceVariant
                          .withValues(
                    alpha:
                        0.65,
                  ),
                ),
              ),
            ),
            for (var i = 0;
                i < days.length;
                i++)
              SizedBox(
                width:
                    dayWidth,
                child:
                    Column(
                  children: [
                    Expanded(
                      child:
                          Material(
                        color:
                            Colors.transparent,
                        child:
                            InkWell(
                          onTap:
                              () {
                            onDaySelected(
                              days[i],
                            );
                          },
                          child:
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              top:
                                  7,
                            ),
                            child:
                                Column(
                              children: [
                                Text(
                                  shortWeekdays[i],
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color:
                                                colorScheme
                                                    .onSurfaceVariant,
                                            fontWeight:
                                                FontWeight.w700,
                                            letterSpacing:
                                                0.65,
                                          ),
                                ),
                                const SizedBox(
                                  height:
                                      4,
                                ),
                                Container(
                                  width:
                                      30,
                                  height:
                                      30,
                                  alignment:
                                      Alignment.center,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _sameDay(
                                      days[i],
                                      selectedDay,
                                    )
                                            ? colorScheme
                                                .primary
                                            : _sameDay(
                                                days[i],
                                                today,
                                              )
                                                ? colorScheme
                                                    .primaryContainer
                                                : Colors
                                                    .transparent,
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child:
                                      Text(
                                    '${days[i].day}',
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  _sameDay(
                                                days[i],
                                                selectedDay,
                                              )
                                                      ? colorScheme
                                                          .onPrimary
                                                      : _sameDay(
                                                          days[i],
                                                          today,
                                                        )
                                                          ? colorScheme
                                                              .onPrimaryContainer
                                                          : colorScheme
                                                              .onSurface,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          16,
                      child:
                          Builder(
                        builder:
                            (context) {
                          final items =
                              untimedByDay[i] ??
                                  const <
                                      TaskOccurrence>[];

                          if (items.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final visible =
                              items
                                  .take(
                                    3,
                                  )
                                  .toList();

                          return Tooltip(
                            message:
                                items.length ==
                                        1
                                    ? '1 attività senza orario'
                                    : '${items.length} attività senza orario',
                            child:
                                Material(
                              color:
                                  Colors.transparent,
                              child:
                                  InkWell(
                                onTap:
                                    () {
                                  onUntimedToggle(
                                    days[i],
                                  );
                                },
                                borderRadius:
                                    BorderRadius.circular(
                                  999,
                                ),
                                child:
                                    Center(
                                  child:
                                      AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds:
                                          160,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          5,
                                      vertical:
                                          3,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          untimedExpanded &&
                                                  _sameDay(
                                                    days[i],
                                                    selectedDay,
                                                  )
                                              ? colorScheme
                                                  .surfaceContainerHigh
                                              : Colors
                                                  .transparent,
                                      borderRadius:
                                          BorderRadius.circular(
                                        999,
                                      ),
                                    ),
                                    child:
                                        Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        for (var dotIndex =
                                                0;
                                            dotIndex <
                                                visible.length;
                                            dotIndex++) ...[
                                          Container(
                                            width:
                                                5,
                                            height:
                                                5,
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  _indicatorColor(
                                                context,
                                                visible[
                                                    dotIndex],
                                              ),
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                          ),
                                          if (dotIndex !=
                                              visible.length -
                                                  1)
                                            const SizedBox(
                                              width:
                                                  3,
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekUntimedOverlay extends StatelessWidget {
  final double gutterWidth;
  final double dayWidth;
  final double chipHeight;
  final double itemGap;
  final double verticalPadding;
  final Map<int, List<TaskOccurrence>> untimedByDay;
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;
  final VoidCallback onClose;
  final Color backgroundColor;

  const _WeekUntimedOverlay({
    required this.gutterWidth,
    required this.dayWidth,
    required this.chipHeight,
    required this.itemGap,
    required this.verticalPadding,
    required this.untimedByDay,
    required this.categoryMap,
    required this.onOpen,
    required this.onActions,
    required this.onClose,
    required this.backgroundColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color:
          backgroundColor,
      elevation:
          5,
      shadowColor:
          colorScheme.shadow.withValues(
        alpha:
            0.14,
      ),
      child:
          DecoratedBox(
        decoration:
            BoxDecoration(
          border:
              Border(
            top:
                BorderSide(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.45,
              ),
            ),
            bottom:
                BorderSide(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.75,
              ),
            ),
          ),
        ),
        child:
            Stack(
          children: [
            Positioned(
              left:
                  0,
              top:
                  0,
              bottom:
                  0,
              width:
                  gutterWidth,
              child:
                  Center(
                child:
                    IconButton(
                  tooltip:
                      'Chiudi attività senza orario',
                  visualDensity:
                      VisualDensity.compact,
                  onPressed:
                      onClose,
                  icon:
                      const Icon(
                    Icons
                        .keyboard_arrow_up_rounded,
                    size:
                        19,
                  ),
                ),
              ),
            ),
            for (var dayIndex =
                    0;
                dayIndex <
                    7;
                dayIndex++)
              Positioned(
                left:
                    gutterWidth +
                    dayIndex *
                        dayWidth,
                top:
                    0,
                bottom:
                    0,
                width:
                    dayWidth,
                child:
                    _UntimedDayLane(
                  occurrences:
                      untimedByDay[
                          dayIndex]!,
                  chipHeight:
                      chipHeight,
                  itemGap:
                      itemGap,
                  verticalPadding:
                      verticalPadding,
                  categoryMap:
                      categoryMap,
                  onOpen:
                      onOpen,
                  onActions:
                      onActions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UntimedDayLane extends StatelessWidget {
  final List<TaskOccurrence> occurrences;
  final double chipHeight;
  final double itemGap;
  final double verticalPadding;
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;

  const _UntimedDayLane({
    required this.occurrences,
    required this.chipHeight,
    required this.itemGap,
    required this.verticalPadding,
    required this.categoryMap,
    required this.onOpen,
    required this.onActions,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration:
          BoxDecoration(
        border:
            Border(
          left:
              BorderSide(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
              alpha:
                  0.45,
            ),
          ),
        ),
      ),
      child:
          ListView.separated(
        primary:
            false,
        padding:
            EdgeInsets.symmetric(
          horizontal:
              4,
          vertical:
              verticalPadding,
        ),
        itemCount:
            occurrences.length,
        separatorBuilder:
            (_, _) =>
                SizedBox(
          height:
              itemGap,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final occurrence =
              occurrences[
                  index];

          return SizedBox(
            height:
                chipHeight,
            child:
                _UntimedOccurrenceChip(
              occurrence:
                  occurrence,
              height:
                  chipHeight,
              categoryMap:
                  categoryMap,
              onTap:
                  () {
                onOpen(
                  occurrence,
                );
              },
              onLongPress:
                  () {
                onActions(
                  occurrence,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _UntimedOccurrenceChip extends StatelessWidget {
  final TaskOccurrence occurrence;
  final double height;
  final Map<String, TaskCategory> categoryMap;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _UntimedOccurrenceChip({
    required this.occurrence,
    required this.height,
    required this.categoryMap,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final task =
        occurrence.displayTask;

    final category =
        task.categoryId == null
            ? null
            : categoryMap[
                task.categoryId];

    final color =
        category == null
            ? colorScheme
                .onSurfaceVariant
            : Color(
                category.colorValue,
              );

    return Material(
      color:
          color.withValues(
        alpha:
            0.12,
      ),
      borderRadius:
          BorderRadius.circular(
        8,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        onLongPress:
            onLongPress,
        borderRadius:
            BorderRadius.circular(
          8,
        ),
        child:
            Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal:
                height < 25
                    ? 4
                    : 6,
          ),
          child:
              Row(
            children: [
              Icon(
                category == null
                    ? task.allDay
                        ? Icons
                            .wb_sunny_outlined
                        : Icons
                            .schedule_outlined
                    : taskCategoryIcon(
                        category.iconKey,
                      ),
                size:
                    height < 25
                        ? 10
                        : 12,
                color:
                    color,
              ),
              SizedBox(
                width:
                    height < 25
                        ? 3
                        : 4,
              ),
              Expanded(
                child:
                    Text(
                  task.title,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color:
                                color,
                            fontSize:
                                height < 25
                                    ? 9
                                    : null,
                            fontWeight:
                                FontWeight.w700,
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


class _WeekOccurrenceBlock extends StatelessWidget {
  final LifeTask task;
  final TaskCategory? category;
  final Color accentColor;
  final Color priorityColor;
  final String timeText;
  final String? subtaskText;
  final double height;
  final double hourHeight;
  final int startTimeMinutes;
  final int initialDurationMinutes;
  final ScrollController verticalScrollController;
  final _WeekAutoScrollUpdate onAutoScrollUpdate;
  final VoidCallback onAutoScrollEnd;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function(int durationMinutes)? onResizeEnd;

  const _WeekOccurrenceBlock({
    required this.task,
    required this.category,
    required this.accentColor,
    required this.priorityColor,
    required this.timeText,
    required this.subtaskText,
    required this.height,
    required this.hourHeight,
    required this.startTimeMinutes,
    required this.initialDurationMinutes,
    required this.verticalScrollController,
    required this.onAutoScrollUpdate,
    required this.onAutoScrollEnd,
    required this.onTap,
    required this.onLongPress,
    required this.onResizeEnd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final identityIcon =
        category == null
            ? Icons.circle_outlined
            : taskCategoryIcon(
                category!.iconKey,
              );

    return Material(
      color:
          accentColor.withValues(
        alpha:
            task.isCompleted
                ? 0.08
                : 0.15,
      ),
      borderRadius:
          BorderRadius.circular(
        9,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        onLongPress:
            onLongPress,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child:
            Container(
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color:
                  accentColor.withValues(
                alpha:
                    0.48,
              ),
            ),
          ),
          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final width =
                  constraints.maxWidth;

              final ultraNarrow =
                  width < 34;

              if (ultraNarrow) {
                return Center(
                  child:
                      Icon(
                    identityIcon,
                    size:
                        10,
                    color:
                        accentColor,
                  ),
                );
              }

              final compact =
                  width < 60;

              // I blocchi molto bassi (per esempio attività da 15/30 minuti)
              // hanno pochissimo spazio verticale. In quel caso passiamo a una
              // resa minimale: una sola riga di titolo, niente icona interna e
              // padding ridotto. Il resize handle resta sovrapposto in basso.
              final veryShort =
                  constraints.maxHeight < 40;

              final showTime =
                  !veryShort &&
                  width >= 68 &&
                  height >= 46;

              final showFooter =
                  width >= 78 &&
                  height >= 68 &&
                  (subtaskText !=
                          null ||
                      task.priority !=
                          TaskPriority
                              .normal);

              final titleStyle =
                  Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color:
                            accentColor,
                        fontSize:
                            veryShort ||
                                    compact
                                ? 8.5
                                : null,
                        fontWeight:
                            FontWeight.w800,
                        height:
                            1.05,
                        decoration:
                            task.isCompleted
                                ? TextDecoration
                                    .lineThrough
                                : null,
                      );

              final content =
                  Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  compact
                      ? 3
                      : 5,
                  veryShort
                      ? 2
                      : 4,
                  compact
                      ? 3
                      : 4,
                  veryShort
                      ? 2
                      : onResizeEnd == null
                          ? 4
                          : 12,
                ),
                child:
                    ClipRect(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (veryShort ||
                          compact)
                        Text(
                          task.title,
                          maxLines:
                              veryShort
                                  ? 1
                                  : height >= 46
                                      ? 2
                                      : 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              titleStyle,
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              identityIcon,
                              size:
                                  11,
                              color:
                                  accentColor,
                            ),
                            const SizedBox(
                              width:
                                  3,
                            ),
                            Expanded(
                              child:
                                  Text(
                                task.title,
                                maxLines:
                                    height >= 52
                                        ? 2
                                        : 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    titleStyle,
                              ),
                            ),
                          ],
                        ),
                      if (showTime) ...[
                        const SizedBox(
                          height:
                              3,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              FittedBox(
                            fit:
                                BoxFit.scaleDown,
                            alignment:
                                Alignment.centerLeft,
                            child:
                                Text(
                              timeText,
                              maxLines:
                                  1,
                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            colorScheme
                                                .onSurfaceVariant,
                                        fontSize:
                                            9,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                            ),
                          ),
                        ),
                      ],
                      if (showFooter) ...[
                        const Spacer(),
                        Row(
                          children: [
                            if (subtaskText !=
                                null) ...[
                              Icon(
                                Icons
                                    .checklist_rounded,
                                size:
                                    10,
                                color:
                                    accentColor,
                              ),
                              const SizedBox(
                                width:
                                    2,
                              ),
                              Flexible(
                                child:
                                    Text(
                                  subtaskText!,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color:
                                                accentColor,
                                            fontSize:
                                                9,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Icon(
                              Icons
                                  .flag_outlined,
                              size:
                                  10,
                              color:
                                  priorityColor,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );

              if (onResizeEnd == null) {
                return content;
              }

              return Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  Positioned.fill(
                    child:
                        content,
                  ),
                  Positioned(
                    left:
                        0,
                    right:
                        0,
                    bottom:
                        0,
                    height:
                        18,
                    child:
                        _WeekResizeHandle(
                      accentColor:
                          accentColor,
                      hourHeight:
                          hourHeight,
                      startTimeMinutes:
                          startTimeMinutes,
                      initialDurationMinutes:
                          initialDurationMinutes,
                      verticalScrollController:
                          verticalScrollController,
                      onAutoScrollUpdate:
                          onAutoScrollUpdate,
                      onAutoScrollEnd:
                          onAutoScrollEnd,
                      onResizeEnd:
                          onResizeEnd!,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


class _WeekResizeHandle extends StatefulWidget {
  final Color accentColor;
  final double hourHeight;
  final int startTimeMinutes;
  final int initialDurationMinutes;
  final ScrollController verticalScrollController;
  final _WeekAutoScrollUpdate onAutoScrollUpdate;
  final VoidCallback onAutoScrollEnd;
  final Future<void> Function(
    int durationMinutes,
  ) onResizeEnd;

  const _WeekResizeHandle({
    required this.accentColor,
    required this.hourHeight,
    required this.startTimeMinutes,
    required this.initialDurationMinutes,
    required this.verticalScrollController,
    required this.onAutoScrollUpdate,
    required this.onAutoScrollEnd,
    required this.onResizeEnd,
  });

  @override
  State<_WeekResizeHandle> createState() =>
      _WeekResizeHandleState();
}

class _WeekResizeHandleState
    extends State<_WeekResizeHandle> {
  double _dragDy = 0;
  double _initialVerticalScrollOffset = 0;
  bool _dragging = false;
  late int _previewDurationMinutes;

  @override
  void initState() {
    super.initState();
    _previewDurationMinutes =
        widget.initialDurationMinutes;
  }

  @override
  void didUpdateWidget(
    covariant _WeekResizeHandle oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!_dragging &&
        oldWidget.initialDurationMinutes !=
            widget.initialDurationMinutes) {
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    }
  }

  int _durationForDrag(
    double dragDy,
  ) {
    final rawDuration =
        widget.initialDurationMinutes +
        dragDy /
            widget.hourHeight *
            60;

    final snapped =
        (rawDuration / 15).round() *
        15;

    return math.max(
      15,
      snapped,
    ).toInt();
  }

  String _clockLabel(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    final hour =
        (normalized ~/ 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        (normalized % 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
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
          ? '1 h'
          : '$hours h';
    }

    return '$hours h $remaining min';
  }

  double _effectiveDragDy() {
    final currentScrollOffset =
        widget.verticalScrollController.hasClients
            ? widget.verticalScrollController.offset
            : _initialVerticalScrollOffset;

    return _dragDy +
        currentScrollOffset -
        _initialVerticalScrollOffset;
  }

  void _refreshPreviewDuration() {
    if (!_dragging ||
        !mounted) {
      return;
    }

    final nextDuration =
        _durationForDrag(
      _effectiveDragDy(),
    );

    if (nextDuration ==
        _previewDurationMinutes) {
      return;
    }

    setState(() {
      _previewDurationMinutes =
          nextDuration;
    });
  }

  void _startDrag(
    DragStartDetails details,
  ) {
    _initialVerticalScrollOffset =
        widget.verticalScrollController.hasClients
            ? widget.verticalScrollController.offset
            : 0;

    setState(() {
      _dragDy = 0;
      _dragging = true;
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    });

    widget.onAutoScrollUpdate(
      details.globalPosition,
      allowHorizontal:
          false,
      allowVertical:
          true,
      onScrolled:
          _refreshPreviewDuration,
    );
  }

  void _updateDrag(
    DragUpdateDetails details,
  ) {
    _dragDy +=
        details.delta.dy;

    widget.onAutoScrollUpdate(
      details.globalPosition,
      allowHorizontal:
          false,
      allowVertical:
          true,
      onScrolled:
          _refreshPreviewDuration,
    );

    _refreshPreviewDuration();
  }

  Future<void> _finishDrag(
    DragEndDetails details,
  ) async {
    final finalDuration =
        _durationForDrag(
      _effectiveDragDy(),
    );

    widget.onAutoScrollEnd();

    setState(() {
      _dragging = false;
      _dragDy = 0;
    });

    if (finalDuration ==
        widget.initialDurationMinutes) {
      return;
    }

    await widget.onResizeEnd(
      finalDuration,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    });
  }

  void _cancelDrag() {
    widget.onAutoScrollEnd();

    if (!_dragging) {
      return;
    }

    setState(() {
      _dragging = false;
      _dragDy = 0;
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final endMinutes =
        widget.startTimeMinutes +
        _previewDurationMinutes;

    final previewOffset =
        (_previewDurationMinutes -
                widget.initialDurationMinutes) /
            60 *
            widget.hourHeight;

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,
      onVerticalDragStart:
          _startDrag,
      onVerticalDragUpdate:
          _updateDrag,
      onVerticalDragEnd:
          _finishDrag,
      onVerticalDragCancel:
          _cancelDrag,
      child:
          Transform.translate(
        offset:
            Offset(
          0,
          previewOffset,
        ),
        child:
            Stack(
        clipBehavior:
            Clip.none,
        alignment:
            Alignment.bottomCenter,
        children: [
          if (_dragging)
            Positioned(
              bottom:
                  16,
              child:
                  IgnorePointer(
                child:
                    Material(
                  color:
                      colorScheme
                          .surfaceContainerHighest,
                  elevation:
                      2,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          7,
                      vertical:
                          4,
                    ),
                    child:
                        Text(
                      '${_clockLabel(widget.startTimeMinutes)}–'
                      '${_clockLabel(endMinutes)} · '
                      '${_durationLabel(_previewDurationMinutes)}',
                      maxLines:
                          1,
                      style:
                          Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurface,
                                fontSize:
                                    9,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment:
                Alignment.bottomCenter,
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom:
                    3,
              ),
              child:
                  Container(
                width:
                    22,
                height:
                    3,
                decoration:
                    BoxDecoration(
                  color:
                      widget.accentColor
                          .withValues(
                    alpha:
                        _dragging
                            ? 1
                            : 0.72,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    99,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}


