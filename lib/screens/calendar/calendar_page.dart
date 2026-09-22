import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_occurrence.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../utils/task_category_icons.dart';
import '../tasks/task_detail_page.dart';
import '../tasks/task_form_page.dart';

class CalendarPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;

  const CalendarPage({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
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
          categoryRepository:
              widget.categoryRepository,
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
    TaskOccurrence occurrence,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(
          task: occurrence.task,
          occurrence: occurrence,
          taskRepository:
              widget.taskRepository,
          categoryRepository:
              widget.categoryRepository,
        ),
      ),
    );
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<TaskOccurrence> _occurrencesForDay(
    List<TaskOccurrence> occurrences,
    DateTime day,
  ) {
    return occurrences.where(
      (occurrence) => _isSameDate(
        occurrence.date,
        day,
      ),
    ).toList();
  }

  DateTime _rangeStart() {
    if (_calendarFormat ==
        CalendarFormat.week) {
      final focused = DateTime(
        _focusedDay.year,
        _focusedDay.month,
        _focusedDay.day,
      );

      return focused.subtract(
        Duration(
          days:
              focused.weekday -
                  DateTime.monday,
        ),
      );
    }

    return DateTime(
      _focusedDay.year,
      _focusedDay.month,
      1,
    ).subtract(
      const Duration(days: 7),
    );
  }

  DateTime _rangeEnd() {
    if (_calendarFormat ==
        CalendarFormat.week) {
      return _rangeStart().add(
        const Duration(days: 6),
      );
    }

    return DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
    ).add(
      const Duration(days: 7),
    );
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(2, '0');
  }

  String _formatClockMinutes(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
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
          ? '1 ora'
          : '$hours ore';
    }

    return '$hours h $remaining min';
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

    return weekdays[date.weekday - 1];
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
    if (task.allDay) {
      return 'Tutto\nil giorno';
    }

    final start =
        task.startTimeMinutes;

    if (start == null) {
      return '';
    }

    return _formatClockMinutes(
      start,
    );
  }

  String _secondaryLabel(
    LifeTask task,
  ) {
    final parts = <String>[];

    final start =
        task.startTimeMinutes;
    final duration =
        task.durationMinutes;

    if (!task.allDay &&
        start != null &&
        duration != null) {
      final end =
          start + duration;

      var endLabel =
          _formatClockMinutes(end);

      final extraDays =
          end ~/ (24 * 60);

      if (extraDays > 0) {
        endLabel +=
            extraDays == 1
                ? ' (+1 g)'
                : ' (+$extraDays g)';
      }

      parts.add(
        'fino alle $endLabel',
      );
    }

    if (duration != null) {
      parts.add(
        _durationLabel(duration),
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

  Color _categoryColor(
    BuildContext context,
    LifeTask task,
    Map<String, TaskCategory> categoryMap,
  ) {
    final category =
        task.categoryId == null
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

  Future<bool> _confirmCompleteAll(
    int remainingSubtasks,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Completare attività?',
          ),
          content:
              Text(
            remainingSubtasks == 1
                ? 'C’è ancora 1 sottoattività da completare. Vuoi completare tutto?'
                : 'Ci sono ancora $remainingSubtasks sottoattività da completare. Vuoi completare tutto?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'Annulla',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'Completa tutto',
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
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

    final rangeStart =
        _rangeStart();
    final rangeEnd =
        _rangeEnd();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Calendario',
        ),
      ),
      body: StreamBuilder<
          List<TaskOccurrence>>(
        stream:
            widget.taskRepository
                .watchOccurrencesInRange(
          rangeStart,
          rangeEnd,
        ),
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

          final occurrences =
              snapshot.data!;

          final selectedOccurrences =
              _occurrencesForDay(
            occurrences,
            _selectedDay,
          );

          return StreamBuilder<
              Map<String, TaskCategory>>(
            stream:
                widget.categoryRepository
                    .watchCategoryMap(),
            initialData:
                const {},
            builder:
                (context, categorySnapshot) {
              final categoryMap =
                  categorySnapshot.data ??
                      const <
                          String,
                          TaskCategory>{};

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
                        icon:
                            Icon(
                          Icons
                              .calendar_month_outlined,
                        ),
                        label:
                            Text(
                          'Mese',
                        ),
                      ),
                      ButtonSegment(
                        value:
                            CalendarFormat
                                .week,
                        icon:
                            Icon(
                          Icons
                              .view_week_outlined,
                        ),
                        label:
                            Text(
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
                            selection
                                .first;
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
                      child: TableCalendar<
                          TaskOccurrence>(
                        firstDay:
                            DateTime(
                          now.year -
                              5,
                          1,
                          1,
                        ),
                        lastDay:
                            DateTime(
                          now.year +
                              10,
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
                          return _occurrencesForDay(
                            occurrences,
                            day,
                          );
                        },
                        calendarBuilders:
                            CalendarBuilders<
                                TaskOccurrence>(
                          markerBuilder:
                              (
                            context,
                            day,
                            events,
                          ) {
                            if (events
                                .isEmpty) {
                              return null;
                            }

                            final visible =
                                events
                                    .take(
                                      3,
                                    )
                                    .toList();

                            return Positioned(
                              bottom: 5,
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  for (int i =
                                          0;
                                      i <
                                          visible
                                              .length;
                                      i++) ...[
                                    Container(
                                      width:
                                          5,
                                      height:
                                          5,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            _categoryColor(
                                          context,
                                          visible[i]
                                              .displayTask,
                                          categoryMap,
                                        ),
                                        shape:
                                            BoxShape
                                                .circle,
                                      ),
                                    ),
                                    if (i !=
                                        visible.length -
                                            1)
                                      const SizedBox(
                                        width:
                                            3,
                                      ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
                          setState(() {
                            _focusedDay =
                                focusedDay;
                          });
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
                          markerSize:
                              5,
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
                      if (selectedOccurrences
                          .isNotEmpty)
                        Text(
                          selectedOccurrences
                                      .length ==
                                  1
                              ? '1 attività'
                              : '${selectedOccurrences.length} attività',
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

                  if (selectedOccurrences
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
                        for (int i =
                                0;
                            i <
                                selectedOccurrences
                                    .length;
                            i++) ...[
                          _CalendarTaskRow(
                            task:
                                selectedOccurrences[
                                        i]
                                    .displayTask,
                            timeLabel:
                                _timeLabel(
                              selectedOccurrences[
                                      i]
                                  .displayTask,
                            ),
                            secondaryLabel:
                                _secondaryLabel(
                              selectedOccurrences[
                                      i]
                                  .displayTask,
                            ),
                            category:
                                selectedOccurrences[
                                                i]
                                            .displayTask
                                            .categoryId ==
                                        null
                                    ? null
                                    : categoryMap[
                                        selectedOccurrences[
                                                i]
                                            .displayTask
                                            .categoryId],
                            priorityColor:
                                _priorityColor(
                              context,
                              selectedOccurrences[
                                      i]
                                  .displayTask
                                  .priority,
                            ),
                            priorityLabel:
                                _priorityLabel(
                              selectedOccurrences[
                                      i]
                                  .displayTask
                                  .priority,
                            ),
                            onCompletedChanged:
                                (completed) async {
                              final occurrence =
                                  selectedOccurrences[
                                      i];

                              if (completed) {
                                final remaining =
                                    occurrence
                                        .subtasks
                                        .where(
                                          (subtask) =>
                                              !subtask
                                                  .isCompleted,
                                        )
                                        .length;

                                if (remaining > 0) {
                                  final confirmed =
                                      await _confirmCompleteAll(
                                    remaining,
                                  );

                                  if (!confirmed) {
                                    return;
                                  }
                                }
                              }

                              await widget
                                  .taskRepository
                                  .setOccurrenceCompleted(
                                occurrence,
                                completed,
                              );
                            },
                            onTap:
                                () {
                              _openTaskDetail(
                                selectedOccurrences[
                                    i],
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
                                    0.55,
                              ),
                            ),
                        ],
                      ],
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _addTask,
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
  final TaskCategory? category;
  final Color priorityColor;
  final String priorityLabel;
  final ValueChanged<bool>
      onCompletedChanged;
  final VoidCallback onTap;

  const _CalendarTaskRow({
    required this.task,
    required this.timeLabel,
    required this.secondaryLabel,
    required this.category,
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

    final categoryColor =
        category == null
            ? colorScheme
                .onSurfaceVariant
                .withValues(
                  alpha: 0.72,
                )
            : Color(
                category!.colorValue,
              );

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Padding(
            padding:
                const EdgeInsets
                    .only(
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
                        ? categoryColor
                        : Colors
                            .transparent,
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      categoryColor,
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
              onTap:
                  onTap,
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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  task.title,
                                  maxLines:
                                      1,
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
                                width: 6,
                              ),
                              Tooltip(
                                message:
                                    'Priorità $priorityLabel',
                                child: Icon(
                                  Icons
                                      .flag_outlined,
                                  size: 15,
                                  color:
                                      priorityColor,
                                ),
                              ),
                            ],
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
                            alpha:
                                0.6,
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
                    if (category !=
                            null ||
                        task.subtasks
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment:
                            WrapCrossAlignment
                                .center,
                        children: [
                          if (category !=
                              null)
                            Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Icon(
                                  taskCategoryIcon(
                                    category!
                                        .iconKey,
                                  ),
                                  size: 14,
                                  color:
                                      categoryColor,
                                ),
                                const SizedBox(
                                  width:
                                      4,
                                ),
                                Text(
                                  category!.name,
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                categoryColor,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                ),
                              ],
                            ),

                          if (task.subtasks
                              .isNotEmpty)
                            Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Icon(
                                  Icons
                                      .checklist_rounded,
                                  size: 14,
                                  color:
                                      categoryColor,
                                ),
                                const SizedBox(
                                  width:
                                      4,
                                ),
                                Text(
                                  '${task.subtasks.where((subtask) => subtask.isCompleted).length}/${task.subtasks.length}',
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                categoryColor,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
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
