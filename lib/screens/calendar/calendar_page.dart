import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';

class CalendarPage extends StatefulWidget {
  final TaskRepository taskRepository;

  const CalendarPage({
    super.key,
    required this.taskRepository,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  CalendarFormat _calendarFormat = CalendarFormat.month;

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

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatTime(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
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

    return weekdays[date.weekday - 1];
  }

  String _selectedDateLabel(DateTime date) {
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

  String _taskTimeLabel(LifeTask task) {
    if (task.startAt == null) {
      return '';
    }

    if (task.allDay) {
      return 'Tutto il giorno';
    }

    final start = _formatTime(
      task.startAt!,
    );

    if (task.endAt == null) {
      return start;
    }

    final end = _formatTime(
      task.endAt!,
    );

    return '$start – $end';
  }

  Color _priorityColor(
    BuildContext context,
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;

      case TaskPriority.normal:
        return Theme.of(context)
            .colorScheme
            .primary;

      case TaskPriority.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),

      body: StreamBuilder<List<LifeTask>>(
        stream:
            widget.taskRepository.watchAllTasks(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Errore nel caricamento:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allTasks = snapshot.data!;

          final selectedTasks =
              _tasksForDay(
            allTasks,
            _selectedDay,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              32,
            ),

            children: [
              SegmentedButton<CalendarFormat>(
                showSelectedIcon: false,

                segments: const [
                  ButtonSegment(
                    value: CalendarFormat.month,
                    icon: Icon(
                      Icons.calendar_month_outlined,
                    ),
                    label: Text('Mese'),
                  ),
                  ButtonSegment(
                    value: CalendarFormat.week,
                    icon: Icon(
                      Icons.view_week_outlined,
                    ),
                    label: Text('Settimana'),
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

              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,

                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),

                  child: TableCalendar<LifeTask>(
                    firstDay: DateTime(
                      now.year - 5,
                      1,
                      1,
                    ),

                    lastDay: DateTime(
                      now.year + 10,
                      12,
                      31,
                    ),

                    focusedDay: _focusedDay,

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

                    eventLoader: (day) {
                      return _tasksForDay(
                        allTasks,
                        day,
                      );
                    },

                    onDaySelected:
                        (selectedDay,
                            focusedDay) {
                      setState(() {
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
                      CalendarFormat.month:
                          'Mese',
                      CalendarFormat.week:
                          'Settimana',
                    },

                    headerStyle:
                        HeaderStyle(
                      titleCentered: true,

                      formatButtonVisible:
                          false,

                      titleTextFormatter:
                          _monthYearLabel,

                      titleTextStyle:
                          Theme.of(context)
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
                        Icons.chevron_left,
                        color: colorScheme
                            .onSurface,
                      ),

                      rightChevronIcon:
                          Icon(
                        Icons.chevron_right,
                        color: colorScheme
                            .onSurface,
                      ),
                    ),

                    daysOfWeekStyle:
                        DaysOfWeekStyle(
                      dowTextFormatter:
                          _weekdayLetter,

                      weekdayStyle:
                          TextStyle(
                        color: colorScheme
                            .onSurfaceVariant,
                        fontWeight:
                            FontWeight.w600,
                      ),

                      weekendStyle:
                          TextStyle(
                        color: colorScheme
                            .onSurfaceVariant,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    calendarStyle:
                        CalendarStyle(
                      outsideDaysVisible:
                          true,

                      markersMaxCount: 3,

                      markerSize: 5,

                      markerMargin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 1.5,
                      ),

                      markerDecoration:
                          BoxDecoration(
                        color:
                            colorScheme.primary,
                        shape:
                            BoxShape.circle,
                      ),

                      selectedDecoration:
                          BoxDecoration(
                        color:
                            colorScheme.primary,
                        shape:
                            BoxShape.circle,
                      ),

                      selectedTextStyle:
                          TextStyle(
                        color: colorScheme
                            .onPrimary,
                        fontWeight:
                            FontWeight.w700,
                      ),

                      todayDecoration:
                          BoxDecoration(
                        color: colorScheme
                            .primaryContainer,
                        shape:
                            BoxShape.circle,
                      ),

                      todayTextStyle:
                          TextStyle(
                        color: colorScheme
                            .onPrimaryContainer,
                        fontWeight:
                            FontWeight.w700,
                      ),

                      outsideTextStyle:
                          TextStyle(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateLabel(
                        _selectedDay,
                      ),

                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),
                  ),

                  if (selectedTasks.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius
                                .circular(20),
                      ),
                      child: Text(
                        '${selectedTasks.length}',
                        style: TextStyle(
                          color: colorScheme
                              .onPrimaryContainer,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (selectedTasks.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .event_available_outlined,
                          color:
                              colorScheme.primary,
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        const Expanded(
                          child: Text(
                            'Nessuna attività '
                            'programmata per '
                            'questo giorno.',
                          ),
                        ),
                      ],
                    ),
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
                      _CalendarTaskCard(
                        task:
                            selectedTasks[i],

                        priorityColor:
                            _priorityColor(
                          context,
                          selectedTasks[i]
                              .priority,
                        ),

                        timeLabel:
                            _taskTimeLabel(
                          selectedTasks[i],
                        ),

                        onCompletedChanged:
                            (completed) async {
                          await widget
                              .taskRepository
                              .setCompleted(
                            selectedTasks[i].id,
                            completed,
                          );
                        },
                      ),

                      if (i !=
                          selectedTasks.length -
                              1)
                        const SizedBox(
                          height: 8,
                        ),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarTaskCard
    extends StatelessWidget {
  final LifeTask task;

  final Color priorityColor;

  final String timeLabel;

  final ValueChanged<bool>
      onCompletedChanged;

  const _CalendarTaskCard({
    required this.task,
    required this.priorityColor,
    required this.timeLabel,
    required this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),

        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,

              onChanged: (value) {
                onCompletedChanged(
                  value ?? false,
                );
              },
            ),

            Container(
              width: 8,
              height: 40,

              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    task.title,

                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w600,

                          decoration:
                              task.isCompleted
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                        ),
                  ),

                  if (timeLabel
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      timeLabel,

                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],

                  if (task.description
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      task.description,

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}