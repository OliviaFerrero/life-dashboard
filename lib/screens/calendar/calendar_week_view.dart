part of 'calendar_page.dart';

// Composizione della vista Week. La logica di interazione vive nel file
// calendar_week_interactions.dart; griglia e widget sono separati negli altri part.
extension _CalendarWeekViewExtension on _CalendarPageState {
  Widget _buildWeekView(
    BuildContext context,
    List<TaskOccurrence> occurrences,
    Map<String, TaskCategory> categoryMap,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final days =
        _weekDays();

    final untimedByDay =
        <int, List<TaskOccurrence>>{
      for (var i = 0; i < 7; i++)
        i: <TaskOccurrence>[],
    };

    final timedSegmentsByDay =
        <int, List<_WeekTimedSegment>>{
      for (var i = 0; i < 7; i++)
        i: <_WeekTimedSegment>[],
    };

    for (final occurrence
        in occurrences) {
      final task =
          occurrence.displayTask;

      if (task.allDay ||
          task.startTimeMinutes == null) {
        final dayIndex =
            occurrence.date
                .difference(
                  days.first,
                )
                .inDays;

        if (dayIndex >= 0 &&
            dayIndex <= 6) {
          untimedByDay[
                  dayIndex]!
              .add(
            occurrence,
          );
        }

        continue;
      }

      final actualStart =
          occurrence.timedStart;

      if (actualStart == null) {
        continue;
      }

      final actualEnd =
          occurrence.timedEnd;

      for (var dayIndex = 0;
          dayIndex < 7;
          dayIndex++) {
        final dayStart =
            days[dayIndex];
        final dayEnd =
            dayStart.add(
          const Duration(days: 1),
        );

        if (!occurrence.overlapsWindow(
          dayStart,
          dayEnd,
        )) {
          continue;
        }

        final visibleStart =
            occurrence.visibleStartInWindow(
                  dayStart,
                  dayEnd,
                ) ??
                actualStart;

        DateTime visibleEnd;

        if (actualEnd == null) {
          final provisional =
              visibleStart.add(
            const Duration(
              minutes:
                  30,
            ),
          );

          visibleEnd =
              provisional.isAfter(
            dayEnd,
          )
                  ? dayEnd
                  : provisional;
        } else {
          visibleEnd =
              occurrence.visibleEndInWindow(
                    dayStart,
                    dayEnd,
                  ) ??
                  actualEnd;
        }

        final startMinute =
            visibleStart
                .difference(
                  dayStart,
                )
                .inMinutes
                .clamp(
                  0,
                  24 * 60,
                )
                .toInt();

        final endMinute =
            visibleEnd
                .difference(
                  dayStart,
                )
                .inMinutes
                .clamp(
                  0,
                  24 * 60,
                )
                .toInt();

        if (endMinute <=
            startMinute) {
          continue;
        }

        timedSegmentsByDay[
                dayIndex]!
            .add(
          _WeekTimedSegment(
            occurrence:
                occurrence,
            startMinute:
                startMinute,
            endMinute:
                endMinute,
            continuesFromPrevious:
                actualStart.isBefore(
              dayStart,
            ),
            continuesAfter:
                actualEnd != null &&
                actualEnd.isAfter(
                  dayEnd,
                ),
          ),
        );
      }
    }

    final maxUntimed =
        untimedByDay.values
            .fold<int>(
      0,
      (
        currentMax,
        dayItems,
      ) =>
          currentMax >
                  dayItems.length
              ? currentMax
              : dayItems.length,
    );

    final hasUntimed =
        maxUntimed >
        0;

    final untimedScale =
        (_weekHourHeight /
                _CalendarPageState._weekDefaultHourHeight)
            .clamp(
              0.65,
              1.35,
            )
            .toDouble();

    final untimedChipHeight =
        (28.0 *
                untimedScale)
            .clamp(
              22.0,
              34.0,
            )
            .toDouble();

    final untimedGap =
        (5.0 *
                untimedScale)
            .clamp(
              3.0,
              6.0,
            )
            .toDouble();

    final untimedVerticalPadding =
        (6.0 *
                untimedScale)
            .clamp(
              4.0,
              8.0,
            )
            .toDouble();

    final untimedOverlayHeight =
        math.min(
      176.0 *
          untimedScale,
      math.max(
        46.0,
        untimedVerticalPadding *
                2 +
            maxUntimed *
                untimedChipHeight +
            math.max(
                  0,
                  maxUntimed - 1,
                ) *
                untimedGap,
      ),
    ).toDouble();

    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final viewportWidth =
            constraints.maxWidth;

        final fittedDayWidth =
            math.max(
          _CalendarPageState._weekMinDayWidth,
          (viewportWidth -
                  _CalendarPageState._weekGutterWidth) /
              7,
        ).toDouble();

        // fittedDayWidth segna il punto in cui i sette giorni riempiono
        // esattamente lo spazio disponibile. _weekDayWidth può ora scendere
        // anche sotto quella soglia: è la modalità overview/dezoom.
        final dayWidth =
            _weekDayWidth
                .clamp(
                  _CalendarPageState._weekMinDayWidth,
                  _CalendarPageState._weekMaxDayWidth,
                )
                .toDouble();

        final totalWidth =
            _CalendarPageState._weekGutterWidth +
            dayWidth *
                7;

        return Stack(
          children: [
  SingleChildScrollView(
            controller:
                _weekHorizontalController,
            physics:
                _weekPinching
                    ? const NeverScrollableScrollPhysics()
                    : null,
            scrollDirection:
                Axis.horizontal,
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                right:
                    16,
              ),
              child:
                  SizedBox(
                width:
                    totalWidth,
                height:
                    constraints.maxHeight,
                child:
                    Column(
                children: [
                  _WeekDayHeader(
                    days:
                        days,
                    selectedDay:
                        _selectedDay,
                    gutterWidth:
                        _CalendarPageState._weekGutterWidth,
                    dayWidth:
                        dayWidth,
                    collapsed:
                        _weekHeaderCollapsed,
                    untimedExpanded:
                        _weekUntimedExpanded,
                    untimedByDay:
                        untimedByDay,
                    categoryMap:
                        categoryMap,
                    onVerticalDragUpdate:
                        _CalendarWeekInteractionsExtension(this)._handleWeekHeaderDragUpdate,
                    onVerticalDragEnd:
                        _CalendarWeekInteractionsExtension(this)._handleWeekHeaderDragEnd,
                    onUntimedToggle:
                        _CalendarWeekInteractionsExtension(this)._toggleWeekUntimed,
                    onDaySelected:
                        (day) {
                      _updateCalendarState(() {
                        _selectedDay =
                            day;
                        _focusedDay =
                            day;
                      });
                    },
                  ),
                  Expanded(
                    child:
                        Stack(
                      children: [
                        Positioned.fill(
                          child:
                              Listener(
                            behavior:
                                HitTestBehavior.translucent,
                            onPointerDown:
                                (event) {
                              _CalendarWeekInteractionsExtension(this)._handleWeekPointerDown(
                                event,
                                renderedDayWidth:
                                    dayWidth,
                                fittedDayWidth:
                                    fittedDayWidth,
                              );
                            },
                            onPointerMove:
                                _CalendarWeekInteractionsExtension(this)._handleWeekPointerMove,
                            onPointerUp:
                                (event) {
                              _CalendarWeekInteractionsExtension(this)._handleWeekPointerEnd(
                                event,
                                renderedDayWidth:
                                    dayWidth,
                                fittedDayWidth:
                                    fittedDayWidth,
                              );
                            },
                            onPointerCancel:
                                (event) {
                              _CalendarWeekInteractionsExtension(this)._handleWeekPointerEnd(
                                event,
                                renderedDayWidth:
                                    dayWidth,
                                fittedDayWidth:
                                    fittedDayWidth,
                              );
                            },
                            child:
                                SingleChildScrollView(
                              controller:
                                  _weekVerticalController,
                              physics:
                                  _weekPinching
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top:
                                      _CalendarPageState._weekGridTopPadding,
                                  bottom:
                                      _CalendarPageState._weekGridBottomPadding,
                                ),
                                child:
                                    _WeekHourlyGrid(
                                  days:
                                      days,
                                  selectedDay:
                                      _selectedDay,
                                  timedByDay:
                                      timedSegmentsByDay,
                                  categoryMap:
                                      categoryMap,
                                  hourHeight:
                                      _weekHourHeight,
                                  gutterWidth:
                                      _CalendarPageState._weekGutterWidth,
                                  dayWidth:
                                      dayWidth,
                                  verticalScrollController:
                                      _weekVerticalController,
                                  horizontalScrollController:
                                      _weekHorizontalController,
                                  viewportContext:
                                      context,
                                  onOpen:
                                      _openTaskDetail,
                                  onMove:
                                      _CalendarWeekInteractionsExtension(this)._moveOccurrenceInWeek,
                                  onResize:
                                      _CalendarWeekInteractionsExtension(this)._resizeOccurrenceInWeek,
                                  onActions:
                                      _CalendarWeekInteractionsExtension(this)._showOccurrenceActions,
                                  onEmptySlotLongPress:
                                      _CalendarWeekInteractionsExtension(this)._showWeekEmptySlotActions,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasUntimed &&
                            _weekUntimedExpanded)
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
                                _WeekUntimedOverlay(
                              gutterWidth:
                                  _CalendarPageState._weekGutterWidth,
                              dayWidth:
                                  dayWidth,
                              chipHeight:
                                  untimedChipHeight,
                              itemGap:
                                  untimedGap,
                              verticalPadding:
                                  untimedVerticalPadding,
                              untimedByDay:
                                  untimedByDay,
                              categoryMap:
                                  categoryMap,
                              onOpen:
                                  _openTaskDetail,
                              onActions:
                                  _CalendarWeekInteractionsExtension(this)._showOccurrenceActions,
                              onClose:
                                  _CalendarWeekInteractionsExtension(this)._closeWeekUntimed,
                              backgroundColor:
                                  colorScheme
                                      .surfaceContainerHigh
                                      .withValues(
                                alpha:
                                    0.97,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
            Positioned(
              left:
                  0,
              top:
                  0,
              bottom:
                  0,
              width:
                  _CalendarPageState._weekGutterWidth,
              child:
                  _WeekPinnedGutter(
                width:
                    _CalendarPageState._weekGutterWidth,
                hourHeight:
                    _weekHourHeight,
                gridTopPadding:
                    _CalendarPageState._weekGridTopPadding,
                verticalController:
                    _weekVerticalController,
                untimedExpanded:
                    hasUntimed &&
                    _weekUntimedExpanded,
                untimedOverlayHeight:
                    untimedOverlayHeight,
                onCloseUntimed:
                    _CalendarWeekInteractionsExtension(this)._closeWeekUntimed,
              ),
            ),
          ],
        );
      },
    );
  }
}

