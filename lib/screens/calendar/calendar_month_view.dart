part of 'calendar_page.dart';

// Vista mensile del Calendario e componenti usati esclusivamente dal mese.
// È un part della stessa libreria per mantenere invariata la visibilità dei
// membri privati e separare il codice senza cambiare il comportamento.
extension _CalendarMonthViewExtension on _CalendarPageState {
  int _monthDayKey(
    DateTime day,
  ) {
    return day.year * 10000 +
        day.month * 100 +
        day.day;
  }

  Map<int, List<TaskOccurrence>>
      _indexMonthOccurrencesByDay(
    List<TaskOccurrence> occurrences,
  ) {
    final result =
        <int, List<TaskOccurrence>>{};

    for (final occurrence
        in occurrences) {
      final task =
          occurrence.displayTask;

      var firstDay =
          _dateOnly(
        occurrence.date,
      );
      var lastDay =
          firstDay;

      if (!task.allDay &&
          task.startTimeMinutes != null) {
        final timedEnd =
            occurrence.timedEnd;

        if (timedEnd != null) {
          // L'estremo finale è esclusivo. Una task che termina
          // esattamente alle 00:00 non deve creare un marker
          // anche nel giorno successivo.
          final lastVisibleInstant =
              timedEnd.subtract(
            const Duration(
              microseconds:
                  1,
            ),
          );

          if (!lastVisibleInstant
              .isBefore(
            firstDay,
          )) {
            lastDay =
                _dateOnly(
              lastVisibleInstant,
            );
          }
        }
      }

      var day =
          firstDay;

      while (!day.isAfter(
        lastDay,
      )) {
        result
            .putIfAbsent(
          _monthDayKey(
            day,
          ),
          () =>
              <TaskOccurrence>[],
        )
            .add(
          occurrence,
        );

        day =
            CivilDate.nextDay(
          day,
        );
      }
    }

    return result;
  }

  List<TaskOccurrence>
      _occurrencesForIndexedDay(
    Map<int, List<TaskOccurrence>>
        occurrencesByDay,
    DateTime day,
  ) {
    return occurrencesByDay[
          _monthDayKey(
            day,
          )
        ] ??
        const <TaskOccurrence>[];
  }

  String _twoDigits(
    int value,
  ) {
    return value.toString().padLeft(2, '0');
  }

  String _formatClockMinutes(
    int minutes,
  ) {
    final normalized = minutes % (24 * 60);

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
  }

  String _weekdayLetter(
    DateTime date,
    dynamic locale,
  ) {
    const weekdays = [
      'LUN',
      'MAR',
      'MER',
      'GIO',
      'VEN',
      'SAB',
      'DOM',
    ];

    return weekdays[date.weekday - 1];
  }

  String _clock(
    DateTime value,
  ) {
    return '${_twoDigits(value.hour)}:'
        '${_twoDigits(value.minute)}';
  }

  String _timeLabelForOccurrenceOnDay(
    TaskOccurrence occurrence,
    DateTime day,
  ) {
    final task =
        occurrence.displayTask;

    if (task.allDay) {
      return 'Tutto\nil giorno';
    }

    if (task.startTimeMinutes == null) {
      return '';
    }

    final dayStart =
        _dateOnly(day);
    final dayEnd =
        CivilDate.nextDay(
      dayStart,
    );

    final visibleStart =
        occurrence.visibleStartInWindow(
      dayStart,
      dayEnd,
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

  String _secondaryLabelForOccurrenceOnDay(
    TaskOccurrence occurrence,
    DateTime day,
  ) {
    final task =
        occurrence.displayTask;
    final parts =
        <String>[];

    final dayStart =
        _dateOnly(day);
    final dayEnd =
        CivilDate.nextDay(
      dayStart,
    );

    final actualStart =
        occurrence.timedStart;
    final actualEnd =
        occurrence.timedEnd;

    if (!task.allDay &&
        actualStart != null &&
        actualEnd != null) {
      final visibleEnd =
          occurrence.visibleEndInWindow(
        dayStart,
        dayEnd,
      );

      if (actualStart.isBefore(
        dayStart,
      )) {
        parts.add(
          'continua dal giorno precedente',
        );
      }

      if (visibleEnd != null) {
        parts.add(
          'fino alle ${_clock(visibleEnd)}',
        );
      }

      if (actualEnd.isAfter(
        dayEnd,
      )) {
        parts.add(
          'continua domani',
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

    return parts.join(' · ');
  }

  Color _priorityColor(
    BuildContext context,
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF5F8F73);

      case TaskPriority.normal:
        return Theme.of(context).colorScheme.primary;

      case TaskPriority.high:
        return const Color(0xFFC65B61);
    }
  }

  String _priorityLabel(
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return 'Bassa';
      case TaskPriority.normal:
        return 'Normale';
      case TaskPriority.high:
        return 'Alta';
    }
  }

  Color _categoryColor(
    BuildContext context,
    LifeTask task,
    Map<String, TaskCategory> categoryMap,
  ) {
    final category = task.categoryId == null
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


  Widget _buildMonthView(
    BuildContext context,
    List<TaskOccurrence> occurrences,
    Map<String, TaskCategory> categoryMap,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final now =
        _now;

    final occurrencesByDay =
        _indexMonthOccurrencesByDay(
      occurrences,
    );

    final selectedOccurrences =
        _occurrencesForIndexedDay(
      occurrencesByDay,
      _selectedDay,
    );

    Widget buildMonthDay(
      DateTime day, {
      required bool selected,
      required bool today,
      required bool outside,
    }) {
      return _MonthDayCell(
        day:
            day,
        selected:
            selected,
        today:
            today,
        outside:
            outside,
      );
    }

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28,
      ),
      children: [
        Container(
          padding:
              const EdgeInsets.only(
            top:
                2,
            bottom:
                10,
          ),
          decoration:
              BoxDecoration(
            border:
                Border(
              bottom:
                  BorderSide(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                  alpha:
                      0.55,
                ),
              ),
            ),
          ),
          child:
              TableCalendar<
                  TaskOccurrence>(
            firstDay:
                DateTime(
              now.year - 5,
              1,
              1,
            ),
            lastDay:
                DateTime(
              now.year + 10,
              12,
              31,
            ),
            focusedDay:
                _focusedDay,
            calendarFormat:
                CalendarFormat.month,
            startingDayOfWeek:
                StartingDayOfWeek
                    .monday,
            availableGestures:
                AvailableGestures
                    .horizontalSwipe,
            rowHeight:
                50,
            daysOfWeekHeight:
                28,
            selectedDayPredicate:
                (day) {
              return isSameDay(
                _selectedDay,
                day,
              );
            },
            eventLoader:
                (day) {
              return _occurrencesForIndexedDay(
                occurrencesByDay,
                day,
              );
            },
            calendarBuilders:
                CalendarBuilders<
                    TaskOccurrence>(
              defaultBuilder:
                  (
                context,
                day,
                focusedDay,
              ) {
                return buildMonthDay(
                  day,
                  selected:
                      false,
                  today:
                      false,
                  outside:
                      false,
                );
              },
              outsideBuilder:
                  (
                context,
                day,
                focusedDay,
              ) {
                return buildMonthDay(
                  day,
                  selected:
                      false,
                  today:
                      false,
                  outside:
                      true,
                );
              },
              todayBuilder:
                  (
                context,
                day,
                focusedDay,
              ) {
                return buildMonthDay(
                  day,
                  selected:
                      false,
                  today:
                      true,
                  outside:
                      day.month !=
                          focusedDay.month,
                );
              },
              selectedBuilder:
                  (
                context,
                day,
                focusedDay,
              ) {
                return buildMonthDay(
                  day,
                  selected:
                      true,
                  today:
                      isSameDay(
                    day,
                    now,
                  ),
                  outside:
                      day.month !=
                          focusedDay.month,
                );
              },
              markerBuilder:
                  (
                context,
                day,
                events,
              ) {
                if (events.isEmpty) {
                  return null;
                }

                final visibleCount =
                    math.min(
                  3,
                  events.length,
                );

                final hiddenCount =
                    events.length -
                        visibleCount;

                return Positioned(
                  bottom:
                      6,
                  left:
                      0,
                  right:
                      0,
                  child:
                      Center(
                    child:
                        Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        for (var i = 0;
                            i <
                                visibleCount;
                            i++) ...[
                          Container(
                            width:
                                7,
                            height:
                                4,
                            decoration:
                                BoxDecoration(
                              color:
                                  _categoryColor(
                                context,
                                events[i]
                                    .displayTask,
                                categoryMap,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                99,
                              ),
                            ),
                          ),
                          if (i !=
                                  visibleCount -
                                      1 ||
                              hiddenCount >
                                  0)
                            const SizedBox(
                              width:
                                  3,
                            ),
                        ],
                        if (hiddenCount >
                            0)
                          Text(
                            '+$hiddenCount',
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
                                          8,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            onDaySelected:
                (
              selectedDay,
              focusedDay,
            ) {
              _updateCalendarState(() {
                _selectedDay =
                    DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
                _focusedDay =
                    focusedDay;
              });
            },
            onPageChanged:
                (focusedDay) {
              final targetDay =
                  math.min(
                _selectedDay.day,
                _daysInMonth(
                  focusedDay.year,
                  focusedDay.month,
                ),
              ).toInt();

              _updateCalendarState(() {
                _focusedDay =
                    focusedDay;
                _selectedDay =
                    DateTime(
                  focusedDay.year,
                  focusedDay.month,
                  targetDay,
                );
              });
            },
            availableCalendarFormats:
                const {
              CalendarFormat.month:
                  'Mese',
            },
            headerVisible:
                false,
            daysOfWeekStyle:
                DaysOfWeekStyle(
              dowTextFormatter:
                  _weekdayLetter,
              weekdayStyle:
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
                            FontWeight.w800,
                        letterSpacing:
                            0.75,
                      ) ??
                  TextStyle(
                    color:
                        colorScheme
                            .onSurfaceVariant,
                    fontWeight:
                        FontWeight.w800,
                  ),
              weekendStyle:
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
                            FontWeight.w800,
                        letterSpacing:
                            0.75,
                      ) ??
                  TextStyle(
                    color:
                        colorScheme
                            .onSurfaceVariant,
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),
            calendarStyle:
                CalendarStyle(
              outsideDaysVisible:
                  true,
              cellMargin:
                  EdgeInsets.zero,
              markersMaxCount:
                  3,
              canMarkersOverflow:
                  false,
              selectedDecoration:
                  const BoxDecoration(
                color:
                    Colors.transparent,
              ),
              todayDecoration:
                  const BoxDecoration(
                color:
                    Colors.transparent,
              ),
              defaultDecoration:
                  const BoxDecoration(
                color:
                    Colors.transparent,
              ),
              weekendDecoration:
                  const BoxDecoration(
                color:
                    Colors.transparent,
              ),
              outsideDecoration:
                  const BoxDecoration(
                color:
                    Colors.transparent,
              ),
            ),
          ),
        ),

        const SizedBox(
          height:
              18,
        ),

        Row(
          children: [
            Expanded(
              child:
                  Text(
                'AGENDA DEL GIORNO',
                style:
                    Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              1,
                        ),
              ),
            ),
            Material(
              color:
                  Colors.transparent,
              child:
                  InkWell(
                onTap:
                    _addTask,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                child:
                    Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        4,
                    vertical:
                        6,
                  ),
                  child:
                      Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size:
                            16,
                        color:
                            colorScheme.primary,
                      ),
                      const SizedBox(
                        width:
                            3,
                      ),
                      Text(
                        'Attività',
                        style:
                            Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color:
                                      colorScheme.primary,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
              8,
        ),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Expanded(
              child:
                  Text(
                _selectedAgendaDateLabel(
                  _selectedDay,
                ),
                maxLines:
                    1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing:
                              -0.3,
                        ),
              ),
            ),
            if (selectedOccurrences
                .isNotEmpty)
              Text(
                selectedOccurrences.length ==
                        1
                    ? '1 attività'
                    : '${selectedOccurrences.length} attività',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                          fontWeight:
                              FontWeight.w600,
                        ),
              ),
          ],
        ),

        const SizedBox(
          height:
              14,
        ),

        if (selectedOccurrences
            .isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical:
                  22,
            ),
            child:
                Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons
                      .event_available_outlined,
                  size:
                      21,
                  color:
                      colorScheme.primary,
                ),
                const SizedBox(
                  width:
                      14,
                ),
                Expanded(
                  child:
                      Text(
                    'Nessuna attività '
                    'programmata per questo giorno.',
                    style:
                        Theme.of(context)
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
          Column(
            children: [
              for (var i = 0;
                  i <
                      selectedOccurrences
                          .length;
                  i++) ...[
                _CalendarTaskRow(
                  task:
                      selectedOccurrences[i]
                          .displayTask,
                  timeLabel:
                      _timeLabelForOccurrenceOnDay(
                    selectedOccurrences[i],
                    _selectedDay,
                  ),
                  secondaryLabel:
                      _secondaryLabelForOccurrenceOnDay(
                    selectedOccurrences[i],
                    _selectedDay,
                  ),
                  category:
                      selectedOccurrences[i]
                                  .displayTask
                                  .categoryId ==
                              null
                          ? null
                          : categoryMap[
                              selectedOccurrences[i]
                                  .displayTask
                                  .categoryId
                            ],
                  priorityColor:
                      _priorityColor(
                    context,
                    selectedOccurrences[i]
                        .displayTask
                        .priority,
                  ),
                  priorityLabel:
                      _priorityLabel(
                    selectedOccurrences[i]
                        .displayTask
                        .priority,
                  ),
                  onCompletedChanged:
                      (completed) async {
                    final occurrence =
                        selectedOccurrences[i];

                    if (completed) {
                      final confirmed =
                          await TaskPrompts
                              .confirmCompletionIfNeeded(
                        context,
                        subtasks:
                            occurrence
                                .subtasks,
                      );

                      if (!confirmed) {
                        return;
                      }
                    }

                    await _taskActions
                        .setCompleted(
                      task:
                          occurrence.task,
                      occurrence:
                          occurrence,
                      completed:
                          completed,
                    );
                  },
                  onTap:
                      () {
                    _openTaskDetail(
                      selectedOccurrences[i],
                    );
                  },
                  onLongPress:
                      () {
                    final occurrence =
                        selectedOccurrences[i];

                    TaskQuickActions.show(
                      context:
                          context,
                      task:
                          occurrence.task,
                      occurrence:
                          occurrence,
                      taskRepository:
                          widget.taskRepository,
                      categoryRepository:
                          widget.categoryRepository,
                    );
                  },
                ),
                if (i !=
                    selectedOccurrences
                            .length -
                        1)
                  Divider(
                    indent:
                        96,
                    color:
                        colorScheme
                            .outlineVariant
                            .withValues(
                      alpha:
                          0.48,
                    ),
                  ),
              ],
            ],
          ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final bool today;
  final bool outside;

  const _MonthDayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.outside,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final textColor =
        outside
            ? colorScheme
                .onSurfaceVariant
                .withValues(
                  alpha:
                      0.34,
                )
            : selected || today
                ? colorScheme.primary
                : colorScheme.onSurface;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            4,
        vertical:
            5,
      ),
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              150,
        ),
        curve:
            Curves.easeOutCubic,
        decoration:
            BoxDecoration(
          color:
              selected
                  ? colorScheme
                      .primary
                      .withValues(
                        alpha:
                            0.10,
                      )
                  : Colors
                      .transparent,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          border:
              selected
                  ? Border.all(
                      color:
                          colorScheme
                              .primary
                              .withValues(
                        alpha:
                            0.20,
                      ),
                    )
                  : null,
        ),
        child:
            Stack(
          alignment:
              Alignment.topCenter,
          children: [
            Positioned(
              top:
                  8,
              child:
                  Text(
                '${day.day}',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              textColor,
                          fontWeight:
                              selected || today
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                        ),
              ),
            ),
            if (today &&
                !selected &&
                !outside)
              Positioned(
                top:
                    30,
                child:
                    Container(
                  width:
                      12,
                  height:
                      2,
                  decoration:
                      BoxDecoration(
                    color:
                        colorScheme
                            .primary,
                    borderRadius:
                        BorderRadius.circular(
                      99,
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

class _CalendarTaskRow extends StatelessWidget {
  final LifeTask task;
  final String timeLabel;
  final String secondaryLabel;
  final TaskCategory? category;
  final Color priorityColor;
  final String priorityLabel;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CalendarTaskRow({
    required this.task,
    required this.timeLabel,
    required this.secondaryLabel,
    required this.category,
    required this.priorityColor,
    required this.priorityLabel,
    required this.onCompletedChanged,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final categoryColor = category == null
        ? colorScheme.onSurfaceVariant.withValues(
            alpha: 0.72,
          )
        : Color(
            category!.colorValue,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 18,
              right: 8,
            ),
            child: Text(
              timeLabel,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
        InkResponse(
          radius: 24,
          onTap: () {
            onCompletedChanged(
              !task.isCompleted,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              16,
              10,
              16,
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? categoryColor
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: categoryColor,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress:
                  onLongPress,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  4,
                  13,
                  4,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Tooltip(
                                message: 'Priorità $priorityLabel',
                                child: Icon(
                                  Icons.flag_outlined,
                                  size: 15,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 19,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ],
                    ),
                    if (secondaryLabel.isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        secondaryLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (category != null ||
                        task.subtasks.isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (category != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  taskCategoryIcon(
                                    category!.iconKey,
                                  ),
                                  size: 14,
                                  color: categoryColor,
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  category!.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: categoryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          if (task.subtasks.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 14,
                                  color: categoryColor,
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  '${task.subtasks.where((subtask) => subtask.isCompleted).length}'
                                  '/${task.subtasks.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: categoryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
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
      ],
    );
  }
}
