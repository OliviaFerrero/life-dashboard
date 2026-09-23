part of 'calendar_page.dart';

// Griglia oraria Week, segmentazione, overlap/lane layout, drag e painter.

class _WeekTimedSegment {
  final TaskOccurrence occurrence;
  final int startMinute;
  final int endMinute;
  final bool continuesFromPrevious;
  final bool continuesAfter;

  const _WeekTimedSegment({
    required this.occurrence,
    required this.startMinute,
    required this.endMinute,
    required this.continuesFromPrevious,
    required this.continuesAfter,
  });
}

class _WeekHourlyGrid
    extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final Map<int, List<_WeekTimedSegment>> timedByDay;
  final Map<String, TaskCategory> categoryMap;
  final double hourHeight;
  final double gutterWidth;
  final double dayWidth;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final BuildContext viewportContext;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;
  final Future<void> Function(
    DateTime targetDate,
    int targetStartMinutes,
  ) onEmptySlotLongPress;
  final Future<void> Function(
    TaskOccurrence occurrence,
    DateTime targetDate,
    int targetStartMinutes,
  ) onMove;
  final Future<void> Function(
    TaskOccurrence occurrence,
    int targetDurationMinutes,
  ) onResize;

  const _WeekHourlyGrid({
    required this.days,
    required this.selectedDay,
    required this.timedByDay,
    required this.categoryMap,
    required this.hourHeight,
    required this.gutterWidth,
    required this.dayWidth,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.viewportContext,
    required this.onOpen,
    required this.onActions,
    required this.onEmptySlotLongPress,
    required this.onMove,
    required this.onResize,
  });

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final gridHeight =
        24 * hourHeight;
    final totalWidth =
        gutterWidth +
        dayWidth * 7;

    final gridKey =
        GlobalKey();

    final autoScroller =
        _WeekEdgeAutoScroller(
      verticalController:
          verticalScrollController,
      horizontalController:
          horizontalScrollController,
      viewportContext:
          viewportContext,
      gutterWidth:
          gutterWidth,
      headerHeight:
          76,
    );

    void handleEmptySlotLongPress(
      LongPressStartDetails details,
    ) {
      final gridContext =
          gridKey.currentContext;

      if (gridContext == null) {
        return;
      }

      final renderObject =
          gridContext.findRenderObject();

      if (renderObject is! RenderBox) {
        return;
      }

      // Usiamo la posizione globale convertita rispetto al RenderBox reale
      // della griglia. Così la stessa ora resta la stessa sia con l'header
      // settimanale aperto sia con l'header compresso.
      final position =
          renderObject.globalToLocal(
        details.globalPosition,
      );

      if (position.dx <
              gutterWidth ||
          position.dx >=
              gutterWidth +
                  dayWidth * 7 ||
          position.dy < 0 ||
          position.dy >
              gridHeight) {
        return;
      }

      final targetDayIndex =
          ((position.dx -
                      gutterWidth) /
                  dayWidth)
              .floor()
              .clamp(
                0,
                6,
              )
              .toInt();

      final rawMinutes =
          position.dy /
              hourHeight *
              60;

      final snappedMinutes =
          ((rawMinutes / 15)
                      .round() *
                  15)
              .clamp(
                0,
                24 * 60 - 15,
              )
              .toInt();

      onEmptySlotLongPress(
        days[targetDayIndex],
        snappedMinutes,
      );
    }

    final layoutsByDay =
        <int, List<_WeekBlockLayout>>{
      for (var i = 0; i < 7; i++)
        i: _layoutSegments(
          timedByDay[i] ??
              const <
                  _WeekTimedSegment>[],
        ),
    };

    final now =
        DateTime.now();
    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    int? todayIndex;

    for (var i = 0;
        i < days.length;
        i++) {
      if (_sameDay(
        days[i],
        today,
      )) {
        todayIndex =
            i;
        break;
      }
    }

    final nowTop =
        (now.hour * 60 +
                now.minute) /
            60 *
            hourHeight;

    return SizedBox(
      key:
          gridKey,
      width:
          totalWidth,
      height:
          gridHeight,
      child: Stack(
        clipBehavior:
            Clip.none,
        children: [
          for (var dayIndex = 0;
              dayIndex < 7;
              dayIndex++)
            if (_sameDay(
              days[dayIndex],
              selectedDay,
            ))
              Positioned(
                left:
                    gutterWidth +
                    dayIndex *
                        dayWidth,
                top:
                    0,
                width:
                    dayWidth,
                height:
                    gridHeight,
                child:
                    ColoredBox(
                  color:
                      colorScheme
                          .primary
                          .withValues(
                    alpha:
                        0.035,
                  ),
                ),
              ),
          CustomPaint(
            size:
                Size(
              totalWidth,
              gridHeight,
            ),
            painter:
                _WeekGridPainter(
              hourHeight:
                  hourHeight,
              gutterWidth:
                  gutterWidth,
              dayWidth:
                  dayWidth,
              lineColor:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.55,
              ),
            ),
          ),
          for (var hour = 0;
              hour < 24;
              hour++)
            Positioned(
              left:
                  0,
              top:
                  hour *
                          hourHeight -
                      8,
              width:
                  gutterWidth -
                  7,
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
          Positioned.fill(
            child:
                GestureDetector(
              behavior:
                  HitTestBehavior.translucent,
              onLongPressStart:
                  handleEmptySlotLongPress,
            ),
          ),
          for (var dayIndex = 0;
              dayIndex < 7;
              dayIndex++)
            for (final layout
                in layoutsByDay[
                    dayIndex]!)
              _buildOccurrenceBlock(
                context,
                dayIndex,
                layout,
                gridKey,
                autoScroller,
              ),
          if (todayIndex !=
              null)
            Positioned(
              left:
                  gutterWidth +
                  todayIndex *
                      dayWidth,
              top:
                  nowTop,
              width:
                  dayWidth,
              child:
                  Row(
                children: [
                  Container(
                    width:
                        7,
                    height:
                        7,
                    decoration:
                        BoxDecoration(
                      color:
                          colorScheme
                              .error,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child:
                        Container(
                      height:
                          1.4,
                      color:
                          colorScheme
                              .error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceBlock(
    BuildContext context,
    int dayIndex,
    _WeekBlockLayout layout,
    GlobalKey gridKey,
    _WeekEdgeAutoScroller autoScroller,
  ) {
    final segment =
        layout.segment;
    final task =
        segment
            .occurrence
            .displayTask;

    final category =
        task.categoryId ==
                null
            ? null
            : categoryMap[
                task.categoryId];

    final colorScheme =
        Theme.of(context).colorScheme;

    final color =
        category == null
            ? colorScheme
                .onSurfaceVariant
            : Color(
                category.colorValue,
              );

    final segmentDuration =
        segment.endMinute -
        segment.startMinute;

    final rawTop =
        segment.startMinute /
            60 *
            hourHeight;
    final gridHeight =
        24 * hourHeight;

    final top =
        math.min(
      rawTop,
      gridHeight -
          28,
    ).toDouble();

    final rawHeight =
        math.max(
      segmentDuration /
          60 *
          hourHeight,
      28.0,
    ).toDouble();

    final height =
        math.max(
      28.0,
      math.min(
        rawHeight,
        gridHeight -
            top,
      ),
    ).toDouble();

    // In overview le colonne possono diventare molto strette. Il margine
    // laterale si riduce insieme alla colonna e ogni blocco resta confinato
    // nella propria lane, invece di forzare una larghezza minima che potrebbe
    // invadere il giorno vicino.
    final dayHorizontalInset =
        (dayWidth * 0.08)
            .clamp(
              2.0,
              4.0,
            )
            .toDouble();

    final availableWidth =
        math.max(
      1.0,
      dayWidth -
          dayHorizontalInset *
              2,
    ).toDouble();

    final laneWidth =
        availableWidth /
        layout.laneCount;

    final laneGap =
        math.min(
      3.0,
      math.max(
        1.0,
        laneWidth *
            0.12,
      ),
    ).toDouble();

    final left =
        gutterWidth +
        dayIndex *
            dayWidth +
        dayHorizontalInset +
        layout.lane *
            laneWidth;

    final width =
        math.max(
      1.0,
      laneWidth -
          laneGap,
    ).toDouble();

    final subtaskText =
        task.subtasks.isEmpty
            ? null
            : '${task.subtasks.where((subtask) => subtask.isCompleted).length}'
                '/${task.subtasks.length}';

    final continuityPrefix =
        segment.continuesFromPrevious
            ? '↳ '
            : '';

    final continuitySuffix =
        segment.continuesAfter
            ? ' →'
            : '';

    final timeText =
        '$continuityPrefix'
        '${_clock(segment.startMinute)}–'
        '${_clock(segment.endMinute)}'
        '$continuitySuffix';

    final block =
        _WeekOccurrenceBlock(
      task:
          task,
      category:
          category,
      accentColor:
          color,
      priorityColor:
          _priorityColor(
        task.priority,
        colorScheme,
      ),
      timeText:
          timeText,
      subtaskText:
          subtaskText,
      height:
          height,
      hourHeight:
          hourHeight,
      startTimeMinutes:
          task.startTimeMinutes ??
          segment.startMinute,
      initialDurationMinutes:
          math.max(
        15,
        task.durationMinutes ??
            30,
      ).toInt(),
      verticalScrollController:
          verticalScrollController,
      onAutoScrollUpdate:
          autoScroller.update,
      onAutoScrollEnd:
          autoScroller.stop,
      onTap:
          () {
        onOpen(
          segment.occurrence,
        );
      },
      onLongPress:
          segment.continuesFromPrevious
              ? () {
                  onActions(
                    segment.occurrence,
                  );
                }
              : null,
      onResizeEnd:
          segment.continuesAfter
              ? null
              : (durationMinutes) {
                  return onResize(
                    segment.occurrence,
                    durationMinutes,
                  );
                },
    );

    Widget draggableBlock =
        block;

    // Un segmento che arriva dal giorno precedente è solo la continuazione
    // visiva della stessa attività: lo si può aprire, ma il drag parte
    // dal segmento che contiene l'inizio reale dell'occorrenza.
    if (!segment.continuesFromPrevious) {
      draggableBlock =
          LongPressDraggable<
              TaskOccurrence>(
        data:
            segment.occurrence,
        delay:
            const Duration(
          milliseconds:
              380,
        ),
        dragAnchorStrategy:
            childDragAnchorStrategy,
        feedback:
            Material(
          color:
              Colors.transparent,
          child:
              Opacity(
            opacity:
                0.92,
            child:
                SizedBox(
              width:
                  width,
              height:
                  height -
                  2,
              child:
                  block,
            ),
          ),
        ),
        childWhenDragging:
            Opacity(
          opacity:
              0.22,
          child:
              block,
        ),
        onDragUpdate:
            (details) {
          autoScroller.update(
            details.globalPosition,
            allowHorizontal:
                true,
            allowVertical:
                true,
          );
        },
        onDragEnd:
            (details) {
          autoScroller.stop();

          final gridContext =
              gridKey.currentContext;

          if (gridContext ==
              null) {
            return;
          }

          final renderObject =
              gridContext.findRenderObject();

          if (renderObject
              is! RenderBox) {
            return;
          }

          final localOffset =
              renderObject.globalToLocal(
            details.offset,
          );

          final originalOffset =
              Offset(
            left,
            top + 1,
          );

          if ((localOffset -
                      originalOffset)
                  .distance <
              10) {
            onActions(
              segment.occurrence,
            );
            return;
          }

          final blockCenterX =
              localOffset.dx +
              width / 2;

          if (blockCenterX <
                  gutterWidth ||
              blockCenterX >=
                  gutterWidth +
                      dayWidth *
                          7 ||
              localOffset.dy <
                  0 ||
              localOffset.dy >
                  24 *
                      hourHeight) {
            return;
          }

          final targetDayIndex =
              ((blockCenterX -
                          gutterWidth) /
                      dayWidth)
                  .floor()
                  .clamp(
                    0,
                    6,
                  )
                  .toInt();

          final rawMinutes =
              localOffset.dy /
                  hourHeight *
                  60;

          final snappedMinutes =
              ((rawMinutes /
                              15)
                          .round() *
                      15)
                  .clamp(
                    0,
                    24 * 60 -
                        15,
                  )
                  .toInt();

          onMove(
            segment.occurrence,
            days[targetDayIndex],
            snappedMinutes,
          );
        },
        child:
            block,
      );
    }

    return Positioned(
      left:
          left,
      top:
          top +
          1,
      width:
          width,
      height:
          height -
          2,
      child:
          draggableBlock,
    );
  }

  Color _priorityColor(
    TaskPriority priority,
    ColorScheme colorScheme,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(
          0xFF5F8F73,
        );
      case TaskPriority.normal:
        return colorScheme.primary;
      case TaskPriority.high:
        return const Color(
          0xFFC65B61,
        );
    }
  }

  String _clock(
    int minutes,
  ) {
    if (minutes ==
        24 * 60) {
      return '00:00';
    }

    final normalized =
        minutes %
        (24 * 60);

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

  List<_WeekBlockLayout>
      _layoutSegments(
    List<_WeekTimedSegment> segments,
  ) {
    if (segments.isEmpty) {
      return const [];
    }

    final sorted =
        segments.toList()
          ..sort(
            (a, b) {
              final startCompare =
                  a.startMinute
                      .compareTo(
                b.startMinute,
              );

              if (startCompare !=
                  0) {
                return startCompare;
              }

              return a.endMinute
                  .compareTo(
                b.endMinute,
              );
            },
          );

    final result =
        <_WeekBlockLayout>[];
    var index =
        0;

    while (index <
        sorted.length) {
      final group =
          <_WeekTimedSegment>[];
      var groupEnd =
          -1;
      var cursor =
          index;

      while (cursor <
          sorted.length) {
        final segment =
            sorted[cursor];

        if (group.isNotEmpty &&
            segment.startMinute >=
                groupEnd) {
          break;
        }

        group.add(
          segment,
        );

        if (segment.endMinute >
            groupEnd) {
          groupEnd =
              segment.endMinute;
        }

        cursor++;
      }

      final laneEnds =
          <int>[];
      final laneByKey =
          <String, int>{};

      for (final segment
          in group) {
        var lane =
            -1;

        for (var laneIndex =
                0;
            laneIndex <
                laneEnds.length;
            laneIndex++) {
          if (laneEnds[
                  laneIndex] <=
              segment.startMinute) {
            lane =
                laneIndex;
            break;
          }
        }

        if (lane ==
            -1) {
          lane =
              laneEnds.length;
          laneEnds.add(
            segment.endMinute,
          );
        } else {
          laneEnds[lane] =
              segment.endMinute;
        }

        laneByKey[
                segment
                    .occurrence
                    .occurrenceKey] =
            lane;
      }

      final laneCount =
          laneEnds.isEmpty
              ? 1
              : laneEnds.length;

      for (final segment
          in group) {
        result.add(
          _WeekBlockLayout(
            segment:
                segment,
            lane:
                laneByKey[
                        segment
                            .occurrence
                            .occurrenceKey] ??
                    0,
            laneCount:
                laneCount,
          ),
        );
      }

      index =
          cursor;
    }

    return result;
  }
}

class _WeekBlockLayout {
  final _WeekTimedSegment segment;
  final int lane;
  final int laneCount;

  const _WeekBlockLayout({
    required this.segment,
    required this.lane,
    required this.laneCount,
  });
}

class _WeekGridPainter extends CustomPainter {
  final double hourHeight;
  final double gutterWidth;
  final double dayWidth;
  final Color lineColor;

  const _WeekGridPainter({
    required this.hourHeight,
    required this.gutterWidth,
    required this.dayWidth,
    required this.lineColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (var hour = 0; hour <= 24; hour++) {
      final y = hour * hourHeight;

      canvas.drawLine(
        Offset(
          gutterWidth,
          y,
        ),
        Offset(
          size.width,
          y,
        ),
        paint,
      );
    }

    for (var day = 0; day <= 7; day++) {
      final x = gutterWidth + day * dayWidth;

      canvas.drawLine(
        Offset(
          x,
          0,
        ),
        Offset(
          x,
          size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WeekGridPainter oldDelegate,
  ) {
    return oldDelegate.hourHeight != hourHeight ||
        oldDelegate.gutterWidth != gutterWidth ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.lineColor != lineColor;
  }
}
