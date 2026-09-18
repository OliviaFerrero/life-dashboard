import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';
import '../tasks/task_detail_page.dart';
import '../tasks/task_form_page.dart';

class CalendarPage extends StatefulWidget {
  final TaskRepository taskRepository;

  const CalendarPage({
    super.key,
    required this.taskRepository,
  });

  @override
  State<CalendarPage> createState() =>
      _CalendarPageState();
}

class _CalendarPageState
    extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  CalendarFormat _calendarFormat =
      CalendarFormat.month;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _focusedDay = _selectedDay;
  }

  Future<void> _addTask() async {
    final result =
        await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          initialDate: _selectedDay,
        ),
      ),
    );

    if (result == null ||
        result.shouldDelete ||
        result.task == null) {
      return;
    }

    await widget.taskRepository.addTask(
      result.task!,
    );
  }

  void _openTaskDetail(
    LifeTask task,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(
          task: task,
          taskRepository:
              widget.taskRepository,
        ),
      ),
    );
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  List<LifeTask> _tasksForDay(
    List<LifeTask> tasks,
    DateTime day,
  ) {
    return tasks.where((task) {
      final date = task.startAt;

      if (date == null) {
        return false;
      }

      return _isSameDate(
        date,
        day,
      );
    }).toList();
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(2, '0');
  }

  String _formatTime(
    DateTime date,
  ) {
    return '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _monthYearLabel(
    DateTime date,
    dynamic locale,
  ) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];

    return '${months[date.month - 1]} '
        '${date.year}';
  }

  String _weekdayLetter(
    DateTime date,
    dynamic locale,
  ) {
    const weekdays = [
      'L',
      'M',
      'M',
      'G',
      'V',
      'S',
      'D',
    ];

    return weekdays[
        date.weekday - 1];
  }

  String _selectedDateLabel(
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
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _timeLabel(
    LifeTask task,
  ) {
    if (task.startAt == null) {
      return '';
    }

    if (task.allDay) {
      return 'Tutto\nil giorno';
    }

    return _formatTime(
      task.startAt!,
    );
  }

  String _secondaryLabel(
    LifeTask task,
  ) {
    final parts = <String>[];

    if (!task.allDay &&
        task.endAt != null) {
      parts.add(
        'fino alle '
        '${_formatTime(task.endAt!)}',
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final now =
        DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendario',
        ),
      ),

      body: StreamBuilder<
          List<LifeTask>>(
        stream: widget
            .taskRepository
            .watchAllTasks(),

        builder:
            (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(24),
                child: Text(
                  'Errore nel caricamento:\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final allTasks =
              snapshot.data!;

          final selectedTasks =
              _tasksForDay(
            allTasks,
            _selectedDay,
          );

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              8,
              20,
              100,
            ),

            children: [
              SegmentedButton<
                  CalendarFormat>(
                showSelectedIcon:
                    false,

                segments:
                    const [
                  ButtonSegment(
                    value:
                        CalendarFormat
                            .month,
                    icon: Icon(
                      Icons
                          .calendar_month_outlined,
                    ),
                    label:
                        Text('Mese'),
                  ),

                  ButtonSegment(
                    value:
                        CalendarFormat
                            .week,
                    icon: Icon(
                      Icons
                          .view_week_outlined,
                    ),
                    label: Text(
                      'Settimana',
                    ),
                  ),
                ],

                selected: {
                  _calendarFormat,
                },

                onSelectionChanged:
                    (selection) {
                  setState(() {
                    _calendarFormat =
                        selection.first;
                  });
                },
              ),

              const SizedBox(
                height: 16,
              ),

              Card(
                margin:
                    EdgeInsets.zero,
                clipBehavior:
                    Clip.antiAlias,

                child: Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    bottom: 8,
                  ),

                  child:
                      TableCalendar<
                          LifeTask>(
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
                        _calendarFormat,

                    startingDayOfWeek:
                        StartingDayOfWeek
                            .monday,

                    availableGestures:
                        AvailableGestures
                            .horizontalSwipe,

                    selectedDayPredicate:
                        (day) {
                      return isSameDay(
                        _selectedDay,
                        day,
                      );
                    },

                    eventLoader:
                        (day) {
                      return _tasksForDay(
                        allTasks,
                        day,
                      );
                    },

                    onDaySelected:
                        (
                      selectedDay,
                      focusedDay,
                    ) {
                      setState(() {
                        _selectedDay =
                            DateTime(
                          selectedDay
                              .year,
                          selectedDay
                              .month,
                          selectedDay
                              .day,
                        );

                        _focusedDay =
                            focusedDay;
                      });
                    },

                    onPageChanged:
                        (focusedDay) {
                      _focusedDay =
                          focusedDay;
                    },

                    onFormatChanged:
                        (format) {
                      setState(() {
                        _calendarFormat =
                            format;
                      });
                    },

                    availableCalendarFormats:
                        const {
                      CalendarFormat
                              .month:
                          'Mese',

                      CalendarFormat
                              .week:
                          'Settimana',
                    },

                    headerStyle:
                        HeaderStyle(
                      titleCentered:
                          true,

                      formatButtonVisible:
                          false,

                      titleTextFormatter:
                          _monthYearLabel,

                      titleTextStyle:
                          Theme.of(
                        context,
                      )
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ) ??
                              const TextStyle(),

                      leftChevronIcon:
                          Icon(
                        Icons
                            .chevron_left,
                        color:
                            colorScheme
                                .onSurface,
                      ),

                      rightChevronIcon:
                          Icon(
                        Icons
                            .chevron_right,
                        color:
                            colorScheme
                                .onSurface,
                      ),
                    ),

                    daysOfWeekStyle:
                        DaysOfWeekStyle(
                      dowTextFormatter:
                          _weekdayLetter,

                      weekdayStyle:
                          TextStyle(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),

                      weekendStyle:
                          TextStyle(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),

                    calendarStyle:
                        CalendarStyle(
                      outsideDaysVisible:
                          true,

                      markersMaxCount:
                          3,

                      markerSize: 5,

                      markerMargin:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            1.5,
                      ),

                      markerDecoration:
                          BoxDecoration(
                        color:
                            colorScheme
                                .primary,
                        shape:
                            BoxShape
                                .circle,
                      ),

                      selectedDecoration:
                          BoxDecoration(
                        color:
                            colorScheme
                                .primary,
                        shape:
                            BoxShape
                                .circle,
                      ),

                      selectedTextStyle:
                          TextStyle(
                        color:
                            colorScheme
                                .onPrimary,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),

                      todayDecoration:
                          BoxDecoration(
                        color:
                            colorScheme
                                .primaryContainer,
                        shape:
                            BoxShape
                                .circle,
                      ),

                      todayTextStyle:
                          TextStyle(
                        color:
                            colorScheme
                                .onPrimaryContainer,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),

                      outsideTextStyle:
                          TextStyle(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .center,

                children: [
                  Expanded(
                    child: Text(
                      _selectedDateLabel(
                        _selectedDay,
                      ),

                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w700,

                                letterSpacing:
                                    -0.3,
                              ),
                    ),
                  ),

                  if (selectedTasks
                      .isNotEmpty)
                    Text(
                      selectedTasks
                                  .length ==
                              1
                          ? '1 attività'
                          : '${selectedTasks.length} attività',

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

                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                    ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              if (selectedTasks
                  .isEmpty)
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 22,
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Icon(
                        Icons
                            .event_available_outlined,
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
                          'programmata per '
                          'questo giorno.',

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
                Column(
                  children: [
                    for (int i = 0;
                        i <
                            selectedTasks
                                .length;
                        i++) ...[
                      _CalendarTaskRow(
                        task:
                            selectedTasks[
                                i],

                        timeLabel:
                            _timeLabel(
                          selectedTasks[
                              i],
                        ),

                        secondaryLabel:
                            _secondaryLabel(
                          selectedTasks[
                              i],
                        ),

                        priorityColor:
                            _priorityColor(
                          context,
                          selectedTasks[
                                  i]
                              .priority,
                        ),

                        priorityLabel:
                            _priorityLabel(
                          selectedTasks[
                                  i]
                              .priority,
                        ),

                        onCompletedChanged:
                            (
                          completed,
                        ) async {
                          await widget
                              .taskRepository
                              .setCompleted(
                            selectedTasks[
                                    i]
                                .id,
                            completed,
                          );
                        },

                        onTap: () {
                          _openTaskDetail(
                            selectedTasks[
                                i],
                          );
                        },
                      ),

                      if (i !=
                          selectedTasks
                                  .length -
                              1)
                        Divider(
                          indent: 96,
                          color:
                              colorScheme
                                  .outlineVariant
                                  .withValues(
                            alpha:
                                0.55,
                          ),
                        ),
                    ],
                  ],
                ),
            ],
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton
              .extended(
        onPressed: _addTask,

        icon:
            const Icon(
          Icons.add,
        ),

        label:
            const Text(
          'Attività',
        ),
      ),
    );
  }
}

class _CalendarTaskRow
    extends StatelessWidget {
  final LifeTask task;

  final String timeLabel;
  final String secondaryLabel;

  final Color priorityColor;
  final String priorityLabel;

  final ValueChanged<bool>
      onCompletedChanged;

  final VoidCallback onTap;

  const _CalendarTaskRow({
    required this.task,
    required this.timeLabel,
    required this.secondaryLabel,
    required this.priorityColor,
    required this.priorityLabel,
    required this.onCompletedChanged,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        SizedBox(
          width: 58,

          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 18,
              right: 8,
            ),

            child: Text(
              timeLabel,

              textAlign:
                  TextAlign.right,

              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color:
                            colorScheme
                                .onSurfaceVariant,

                        fontWeight:
                            FontWeight
                                .w500,
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
            padding:
                const EdgeInsets
                    .fromLTRB(
              8,
              16,
              10,
              16,
            ),

            child: Container(
              width: 18,
              height: 18,

              decoration:
                  BoxDecoration(
                color:
                    task.isCompleted
                        ? priorityColor
                        : Colors
                            .transparent,

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      priorityColor,
                  width: 2,
                ),
              ),

              child:
                  task.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color:
                              Colors.white,
                        )
                      : null,
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
                  4,
                  13,
                  4,
                  14,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Row(
                      children: [
                        Expanded(
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
                                          FontWeight
                                              .w600,

                                      decoration:
                                          task.isCompleted
                                              ? TextDecoration
                                                  .lineThrough
                                              : null,
                                    ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Icon(
                          Icons
                              .chevron_right,
                          size: 19,

                          color:
                              colorScheme
                                  .onSurfaceVariant
                                  .withValues(
                            alpha: 0.6,
                          ),
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

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Icon(
                          Icons
                              .flag_outlined,
                          size: 14,
                          color:
                              priorityColor,
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          priorityLabel,

                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        priorityColor,

                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                        ),
                      ],
                    ),
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