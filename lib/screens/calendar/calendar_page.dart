import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_occurrence.dart';
import '../../models/task_recurrence.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../utils/task_category_icons.dart';
import '../tasks/task_detail_page.dart';
import '../tasks/task_form_page.dart';

enum _RecurringMoveScope {
  occurrence,
  series,
}

enum _RecurringActionScope {
  occurrence,
  series,
}

enum _WeekOccurrenceAction {
  edit,
  delete,
}

enum _WeekPinchAxis {
  horizontal,
  vertical,
}

class CalendarPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;

  const CalendarPage({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const double _weekDefaultHourHeight = 68;
  static const double _weekMinHourHeight = 40;
  static const double _weekMaxHourHeight = 110;

  static const double _weekDefaultDayWidth = 96;
  static const double _weekMinDayWidth = 48;
  static const double _weekMaxDayWidth = 180;

  static const double _weekGridTopPadding = 12;
  static const double _weekGridBottomPadding = 36;
  static const double _weekGutterWidth = 54;

  double _weekHourHeight = _weekDefaultHourHeight;
  double _weekDayWidth = _weekDefaultDayWidth;

  final Map<int, Offset> _weekPointers =
      <int, Offset>{};

  _WeekPinchAxis? _weekPinchAxis;

  double _weekPinchStartHorizontalSpan = 0;
  double _weekPinchStartVerticalSpan = 0;

  double _weekPinchStartHourHeight =
      _weekDefaultHourHeight;
  double _weekPinchStartDayWidth =
      _weekDefaultDayWidth;
  double _weekPinchFittedDayWidth =
      _weekMinDayWidth;

  double? _weekPinchAnchorMinutes;
  double? _weekPinchAnchorDayPosition;
  double? _weekPinchViewportFocalX;

  bool _weekPinching = false;

  late DateTime _selectedDay;
  late DateTime _focusedDay;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _weekHeaderCollapsed = false;
  bool _weekUntimedExpanded = false;

  final ScrollController _weekVerticalController = ScrollController();
  final ScrollController _weekHorizontalController = ScrollController();

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

  @override
  void dispose() {
    _weekVerticalController.dispose();
    _weekHorizontalController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          categoryRepository: widget.categoryRepository,
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
          taskRepository: widget.taskRepository,
          categoryRepository: widget.categoryRepository,
        ),
      ),
    );
  }


  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  DateTime _weekStartFor(
    DateTime date,
  ) {
    final normalized = _dateOnly(date);

    return normalized.subtract(
      Duration(
        days: normalized.weekday - DateTime.monday,
      ),
    );
  }

  List<DateTime> _weekDays() {
    final start = _weekStartFor(_focusedDay);

    return [
      for (var i = 0; i < 7; i++)
        start.add(
          Duration(days: i),
        ),
    ];
  }

  List<TaskOccurrence> _occurrencesForDay(
    List<TaskOccurrence> occurrences,
    DateTime day,
  ) {
    final start =
        _dateOnly(day);
    final end =
        start.add(
      const Duration(days: 1),
    );

    return occurrences
        .where(
          (occurrence) =>
              occurrence.overlapsWindow(
            start,
            end,
          ),
        )
        .toList();
  }

  DateTime _rangeStart() {
    if (_calendarFormat == CalendarFormat.week) {
      return _weekStartFor(_focusedDay);
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
    if (_calendarFormat == CalendarFormat.week) {
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
    return value.toString().padLeft(2, '0');
  }

  String _formatClockMinutes(
    int minutes,
  ) {
    final normalized = minutes % (24 * 60);

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
  }

  String _durationLabel(
    int minutes,
  ) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

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

    return '${months[date.month - 1]} ${date.year}';
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

  String _selectedAgendaDateLabel(
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
        '${months[date.month - 1]}';
  }

  String _weekRangeLabel() {
    final days = _weekDays();
    final start = days.first;
    final end = days.last;

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

    if (start.year == end.year &&
        start.month == end.month) {
      return '${start.day}–${end.day} '
          '${months[start.month - 1]} '
          '${start.year}';
    }

    if (start.year == end.year) {
      return '${start.day} ${months[start.month - 1]} – '
          '${end.day} ${months[end.month - 1]} '
          '${start.year}';
    }

    return '${start.day} ${months[start.month - 1]} ${start.year} – '
        '${end.day} ${months[end.month - 1]} ${end.year}';
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
        dayStart.add(
      const Duration(days: 1),
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
        dayStart.add(
      const Duration(days: 1),
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

  Future<bool> _confirmCompleteAll(
    int remainingSubtasks,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Completare attività?',
          ),
          content: Text(
            remainingSubtasks == 1
                ? 'C’è ancora 1 sottoattività da completare. '
                    'Vuoi completare tutto?'
                : 'Ci sono ancora $remainingSubtasks sottoattività '
                    'da completare. Vuoi completare tutto?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
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
              child: const Text(
                'Completa tutto',
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  void _setCalendarFormat(
    CalendarFormat format,
  ) {
    if (_calendarFormat == format) {
      return;
    }

    setState(() {
      _calendarFormat = format;
      _focusedDay = _selectedDay;
      _weekHeaderCollapsed = false;
      _weekUntimedExpanded = false;
    });

    if (format == CalendarFormat.week) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollWeekNearMorning(),
      );
    }
  }

  int _daysInMonth(
    int year,
    int month,
  ) {
    return DateTime(
      year,
      month + 1,
      0,
    ).day;
  }

  void _changeMonth(
    int monthOffset,
  ) {
    final targetMonth =
        DateTime(
      _focusedDay.year,
      _focusedDay.month + monthOffset,
      1,
    );

    final targetDay =
        math.min(
      _selectedDay.day,
      _daysInMonth(
        targetMonth.year,
        targetMonth.month,
      ),
    ).toInt();

    final target =
        DateTime(
      targetMonth.year,
      targetMonth.month,
      targetDay,
    );

    setState(() {
      _focusedDay =
          target;
      _selectedDay =
          target;
    });
  }

  void _changeWeek(
    int weekOffset,
  ) {
    setState(() {
      _selectedDay =
          _selectedDay.add(
        Duration(
          days:
              7 * weekOffset,
        ),
      );
      _focusedDay =
          _selectedDay;
      _weekUntimedExpanded = false;
    });
  }

  void _changePeriod(
    int offset,
  ) {
    if (_calendarFormat ==
        CalendarFormat.week) {
      _changeWeek(
        offset,
      );
      return;
    }

    _changeMonth(
      offset,
    );
  }

  String _periodLabel() {
    if (_calendarFormat ==
        CalendarFormat.week) {
      return _weekRangeLabel();
    }

    return _monthYearLabel(
      _focusedDay,
      null,
    );
  }

  Future<void> _showViewMenu() async {
    final selected =
        await showGeneralDialog<CalendarFormat>(
      context:
          context,
      barrierDismissible:
          true,
      barrierLabel:
          'Chiudi selettore vista',
      barrierColor:
          Colors.black.withValues(
        alpha: 0.24,
      ),
      transitionDuration:
          const Duration(
        milliseconds:
            220,
      ),
      pageBuilder:
          (
        dialogContext,
        animation,
        secondaryAnimation,
      ) {
        return Align(
          alignment:
              Alignment.centerLeft,
          child: SafeArea(
            child: Material(
              color:
                  Theme.of(
                dialogContext,
              ).colorScheme.surface,
              child: SizedBox(
                width:
                    math.min(
                  280.0,
                  MediaQuery.sizeOf(
                        dialogContext,
                      ).width *
                      0.76,
                ).toDouble(),
                height:
                    double.infinity,
                child:
                    _CalendarViewMenu(
                  selected:
                      _calendarFormat,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curved =
            CurvedAnimation(
          parent:
              animation,
          curve:
              Curves.easeOutCubic,
          reverseCurve:
              Curves.easeInCubic,
        );

        return SlideTransition(
          position:
              Tween<Offset>(
            begin:
                const Offset(
              -1,
              0,
            ),
            end:
                Offset.zero,
          ).animate(
            curved,
          ),
          child:
              child,
        );
      },
    );

    if (!mounted ||
        selected == null) {
      return;
    }

    _setCalendarFormat(
      selected,
    );
  }

  void _setWeekHeaderCollapsed(
    bool collapsed,
  ) {
    if (_weekHeaderCollapsed == collapsed) {
      return;
    }

    setState(() {
      _weekHeaderCollapsed = collapsed;
    });
  }

  void _toggleWeekUntimed(
    DateTime day,
  ) {
    final normalized =
        _dateOnly(day);

    final sameSelected =
        _selectedDay.year == normalized.year &&
        _selectedDay.month == normalized.month &&
        _selectedDay.day == normalized.day;

    setState(() {
      _selectedDay = normalized;
      _focusedDay = normalized;
      _weekUntimedExpanded =
          sameSelected
              ? !_weekUntimedExpanded
              : true;
    });
  }

  void _closeWeekUntimed() {
    if (!_weekUntimedExpanded) {
      return;
    }

    setState(() {
      _weekUntimedExpanded = false;
    });
  }

  LifeTask _taskForOccurrenceEditing(
    TaskOccurrence occurrence,
  ) {
    final effective =
        occurrence.displayTask;

    return LifeTask(
      id:
          occurrence.task.id,
      title:
          effective.title,
      description:
          effective.description,
      scheduledDate:
          occurrence.date,
      startTimeMinutes:
          effective.startTimeMinutes,
      durationMinutes:
          effective.durationMinutes,
      categoryId:
          effective.categoryId,
      allDay:
          effective.allDay,
      priority:
          effective.priority,
      recurrence:
          occurrence.task.recurrence,
      subtasks:
          occurrence.subtasks,
      isCompleted:
          occurrence.isCompleted,
    );
  }

  Future<_RecurringActionScope?>
      _showRecurringActionScope({
    required String title,
    bool destructive = false,
  }) {
    return showModalBottomSheet<
        _RecurringActionScope>(
      context:
          context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha:
            0.28,
      ),
      useSafeArea:
          true,
      builder:
          (sheetContext) {
        final colorScheme =
            Theme.of(
          sheetContext,
        ).colorScheme;

        return SafeArea(
          top:
              false,
          child:
              Container(
            margin:
                const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              10,
            ),
            decoration:
                BoxDecoration(
              color:
                  colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border:
                  Border.all(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                  alpha:
                      0.55,
                ),
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .labelMedium
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
                const SizedBox(
                  height:
                      8,
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .event_outlined,
                  label:
                      'Solo questa occorrenza',
                  isDestructive:
                      destructive,
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringActionScope
                          .occurrence,
                    );
                  },
                ),
                Divider(
                  height:
                      1,
                  indent:
                      44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons.repeat,
                  label:
                      'Tutta la serie',
                  isDestructive:
                      destructive,
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringActionScope
                          .series,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmWeekDelete({
    required String title,
    required String message,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context:
          context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              Text(
            title,
          ),
          content:
              Text(
            message,
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
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
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'Elimina',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ==
        true;
  }

  Future<void> _editOccurrenceFromWeek(
    TaskOccurrence occurrence,
  ) async {
    if (!occurrence.isRecurring) {
      final result =
          await Navigator.push<
              TaskFormResult>(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  TaskFormPage(
            categoryRepository:
                widget.categoryRepository,
            initialTask:
                _taskForOccurrenceEditing(
              occurrence,
            ),
          ),
        ),
      );

      if (result == null) {
        return;
      }

      if (result.shouldDelete) {
        await widget.taskRepository
            .deleteTask(
          occurrence.task.id,
        );
        return;
      }

      if (result.task != null) {
        await widget.taskRepository
            .updateTask(
          result.task!,
        );
      }

      return;
    }

    final scope =
        await _showRecurringActionScope(
      title:
          'Modifica',
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringActionScope.occurrence) {
      final result =
          await Navigator.push<
              TaskFormResult>(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  TaskFormPage(
            categoryRepository:
                widget.categoryRepository,
            initialTask:
                _taskForOccurrenceEditing(
              occurrence,
            ),
            occurrenceOnly:
                true,
          ),
        ),
      );

      final edited =
          result?.task;

      if (edited == null) {
        return;
      }

      await widget.taskRepository
          .saveOccurrenceOverride(
        occurrence:
            occurrence,
        editedTask:
            edited,
      );

      return;
    }

    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          initialTask:
              occurrence.task,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.shouldDelete) {
      await widget.taskRepository
          .deleteTask(
        occurrence.task.id,
      );
      return;
    }

    if (result.task != null) {
      await widget.taskRepository
          .updateTask(
        result.task!,
      );
    }
  }

  Future<void> _deleteOccurrenceFromWeek(
    TaskOccurrence occurrence,
  ) async {
    if (!occurrence.isRecurring) {
      final confirmed =
          await _confirmWeekDelete(
        title:
            'Eliminare attività?',
        message:
            'Vuoi eliminare "${occurrence.displayTask.title}"?',
      );

      if (!confirmed) {
        return;
      }

      await widget.taskRepository
          .deleteTask(
        occurrence.task.id,
      );
      return;
    }

    final scope =
        await _showRecurringActionScope(
      title:
          'Elimina',
      destructive:
          true,
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringActionScope.occurrence) {
      final confirmed =
          await _confirmWeekDelete(
        title:
            'Eliminare questa occorrenza?',
        message:
            'Verrà rimossa solo questa data. '
            'Le altre occorrenze della serie resteranno invariate.',
      );

      if (!confirmed) {
        return;
      }

      await widget.taskRepository
          .deleteOccurrence(
        occurrence,
      );
      return;
    }

    final confirmed =
        await _confirmWeekDelete(
      title:
          'Eliminare serie?',
      message:
          'Vuoi eliminare tutta la serie '
          '"${occurrence.task.title}"?',
    );

    if (!confirmed) {
      return;
    }

    await widget.taskRepository
        .deleteTask(
      occurrence.task.id,
    );
  }

  Future<void> _showOccurrenceActions(
    TaskOccurrence occurrence,
  ) async {
    final action =
        await showModalBottomSheet<
            _WeekOccurrenceAction>(
      context:
          context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha:
            0.28,
      ),
      useSafeArea:
          true,
      builder:
          (sheetContext) {
        final colorScheme =
            Theme.of(
          sheetContext,
        ).colorScheme;

        return SafeArea(
          top:
              false,
          child:
              Container(
            margin:
                const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              10,
            ),
            decoration:
                BoxDecoration(
              color:
                  colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border:
                  Border.all(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                  alpha:
                      0.55,
                ),
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  occurrence
                      .displayTask
                      .title,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .edit_outlined,
                  label:
                      'Modifica',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekOccurrenceAction
                          .edit,
                    );
                  },
                ),
                Divider(
                  height:
                      1,
                  indent:
                      44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .delete_outline,
                  label:
                      'Elimina',
                  isDestructive:
                      true,
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekOccurrenceAction
                          .delete,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    switch (action) {
      case _WeekOccurrenceAction.edit:
        await _editOccurrenceFromWeek(
          occurrence,
        );
        break;

      case _WeekOccurrenceAction.delete:
        await _deleteOccurrenceFromWeek(
          occurrence,
        );
        break;
    }
  }

  String _clockLabel(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    final hour =
        (normalized ~/ 60)
            .toString()
            .padLeft(2, '0');

    final minute =
        (normalized % 60)
            .toString()
            .padLeft(2, '0');

    return '$hour:$minute';
  }

  TaskRecurrence _shiftRecurrence(
    LifeTask series,
    int dayDelta,
  ) {
    final recurrence =
        series.recurrence;

    if (recurrence.type !=
        TaskRecurrenceType.weekly ||
        dayDelta % 7 == 0) {
      return recurrence;
    }

    final sourceWeekdays =
        recurrence.weekdays.isEmpty
            ? <int>[
                series.scheduledDate?.weekday ??
                    DateTime.monday,
              ]
            : recurrence.weekdays;

    final shift =
        dayDelta % 7;

    final shifted =
        sourceWeekdays.map(
      (weekday) {
        final zeroBased =
            weekday -
            DateTime.monday;

        final shiftedZeroBased =
            (zeroBased + shift) % 7;

        return shiftedZeroBased +
            DateTime.monday;
      },
    );

    return TaskRecurrence.weekly(
      shifted,
    );
  }

  LifeTask _copyTaskForMove({
    required LifeTask source,
    required DateTime date,
    required int startTimeMinutes,
    TaskRecurrence? recurrence,
  }) {
    return LifeTask(
      id:
          source.id,
      title:
          source.title,
      description:
          source.description,
      scheduledDate:
          _dateOnly(date),
      startTimeMinutes:
          startTimeMinutes,
      durationMinutes:
          source.durationMinutes,
      categoryId:
          source.categoryId,
      allDay:
          false,
      priority:
          source.priority,
      recurrence:
          recurrence ??
          source.recurrence,
      subtasks:
          source.subtasks,
      isCompleted:
          source.isCompleted,
    );
  }

  Future<_RecurringMoveScope?>
      _showRecurringMoveScope() {
    return showModalBottomSheet<
        _RecurringMoveScope>(
      context:
          context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      useSafeArea:
          true,
      builder:
          (sheetContext) {
        final colorScheme =
            Theme.of(
          sheetContext,
        ).colorScheme;

        return SafeArea(
          top:
              false,
          child:
              Container(
            margin:
                const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              10,
            ),
            decoration:
                BoxDecoration(
              color:
                  colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border:
                  Border.all(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                  alpha:
                      0.55,
                ),
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'SPOSTA ATTIVITÀ',
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .labelMedium
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
                const SizedBox(
                  height:
                      8,
                ),
                _MoveScopeRow(
                  icon:
                      Icons
                          .event_outlined,
                  title:
                      'Solo questa occorrenza',
                  subtitle:
                      'Sposta soltanto questo evento.',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringMoveScope
                          .occurrence,
                    );
                  },
                ),
                Divider(
                  height:
                      1,
                  indent:
                      44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _MoveScopeRow(
                  icon:
                      Icons
                          .repeat,
                  title:
                      'Tutta la serie',
                  subtitle:
                      'Sposta orario e giorni della serie.',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringMoveScope
                          .series,
                    );
                  },
                ),
                const SizedBox(
                  height:
                      4,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      TextButton(
                    onPressed:
                        () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    child:
                        const Text(
                      'Annulla',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moveOccurrenceInWeek(
    TaskOccurrence occurrence,
    DateTime targetDate,
    int targetStartMinutes,
  ) async {
    final effectiveTask =
        occurrence.displayTask;

    final currentStart =
        effectiveTask.startTimeMinutes;

    if (currentStart == null ||
        effectiveTask.allDay) {
      return;
    }

    final normalizedTargetDate =
        _dateOnly(
      targetDate,
    );

    final sameDate =
        occurrence.date.year ==
                normalizedTargetDate.year &&
            occurrence.date.month ==
                normalizedTargetDate.month &&
            occurrence.date.day ==
                normalizedTargetDate.day;

    if (sameDate &&
        currentStart ==
            targetStartMinutes) {
      return;
    }

    if (!occurrence.isRecurring) {
      final moved =
          _copyTaskForMove(
        source:
            effectiveTask,
        date:
            normalizedTargetDate,
        startTimeMinutes:
            targetStartMinutes,
      );

      await widget.taskRepository
          .updateTask(
        moved,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDay =
            normalizedTargetDate;
        _focusedDay =
            normalizedTargetDate;
      });

      _showMoveConfirmation(
        normalizedTargetDate,
        targetStartMinutes,
      );
      return;
    }

    final scope =
        await _showRecurringMoveScope();

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringMoveScope.occurrence) {
      final editedOccurrence =
          _copyTaskForMove(
        source:
            effectiveTask,
        date:
            normalizedTargetDate,
        startTimeMinutes:
            targetStartMinutes,
        recurrence:
            occurrence.task.recurrence,
      );

      await widget.taskRepository
          .saveOccurrenceOverride(
        occurrence:
            occurrence,
        editedTask:
            editedOccurrence,
      );
    } else {
      final series =
          occurrence.task;

      final startDate =
          series.scheduledDate;

      if (startDate == null) {
        return;
      }

      final dayDelta =
          normalizedTargetDate
              .difference(
                occurrence.date,
              )
              .inDays;

      final shiftedRecurrence =
          _shiftRecurrence(
        series,
        dayDelta,
      );

      final movedSeries =
          _copyTaskForMove(
        source:
            series,
        date:
            startDate.add(
          Duration(
            days:
                dayDelta,
          ),
        ),
        startTimeMinutes:
            targetStartMinutes,
        recurrence:
            shiftedRecurrence,
      );

      await widget.taskRepository
          .updateTask(
        movedSeries,
      );

      if (occurrence.hasOverride) {
        await widget.taskRepository
            .clearOccurrenceOverride(
          occurrence,
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedDay =
          normalizedTargetDate;
      _focusedDay =
          normalizedTargetDate;
    });

    _showMoveConfirmation(
      normalizedTargetDate,
      targetStartMinutes,
    );
  }

  void _showMoveConfirmation(
    DateTime date,
    int startTimeMinutes,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        duration:
            const Duration(
          milliseconds:
              1600,
        ),
        content:
            Text(
          'Spostata a ${_selectedDateLabel(date)}, '
          '${_clockLabel(startTimeMinutes)}',
        ),
      ),
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    setState(() {
      _selectedDay = today;
      _focusedDay = today;
      _weekUntimedExpanded = false;
    });

    if (_calendarFormat == CalendarFormat.week) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollWeekNearMorning(),
      );
    }
  }

  void _startWeekPinchIfPossible({
    required double renderedDayWidth,
    required double fittedDayWidth,
  }) {
    if (_weekPointers.length != 2) {
      return;
    }

    final positions =
        _weekPointers.values.toList();

    final first =
        positions[0];
    final second =
        positions[1];

    _weekPinchStartHorizontalSpan =
        (first.dx - second.dx).abs();
    _weekPinchStartVerticalSpan =
        (first.dy - second.dy).abs();

    _weekPinchStartHourHeight =
        _weekHourHeight;
    _weekPinchStartDayWidth =
        renderedDayWidth;
    _weekPinchFittedDayWidth =
        fittedDayWidth;

    _weekPinchAxis = null;

    final focalX =
        (first.dx + second.dx) / 2;
    final focalY =
        (first.dy + second.dy) / 2;

    final verticalScrollOffset =
        _weekVerticalController.hasClients
            ? _weekVerticalController.offset
            : 0.0;

    final gridY =
        math.max(
      0.0,
      verticalScrollOffset +
          focalY -
          _weekGridTopPadding,
    ).toDouble();

    _weekPinchAnchorMinutes =
        gridY /
            _weekHourHeight *
            60;

    final horizontalScrollOffset =
        _weekHorizontalController.hasClients
            ? _weekHorizontalController.offset
            : 0.0;

    _weekPinchViewportFocalX =
        focalX -
            horizontalScrollOffset;

    _weekPinchAnchorDayPosition =
        ((focalX -
                    _weekGutterWidth) /
                renderedDayWidth)
            .clamp(
              0.0,
              7.0,
            )
            .toDouble();

    if (!_weekPinching) {
      setState(() {
        _weekPinching = true;
      });
    }
  }

  void _handleWeekPointerDown(
    PointerDownEvent event, {
    required double renderedDayWidth,
    required double fittedDayWidth,
  }) {
    _weekPointers[event.pointer] =
        event.localPosition;

    if (_weekPointers.length == 2) {
      _startWeekPinchIfPossible(
        renderedDayWidth:
            renderedDayWidth,
        fittedDayWidth:
            fittedDayWidth,
      );
    }
  }

  void _handleWeekPointerMove(
    PointerMoveEvent event,
  ) {
    if (!_weekPointers.containsKey(
      event.pointer,
    )) {
      return;
    }

    _weekPointers[event.pointer] =
        event.localPosition;

    if (_weekPointers.length != 2 ||
        !_weekPinching) {
      return;
    }

    final positions =
        _weekPointers.values.toList();

    final first =
        positions[0];
    final second =
        positions[1];

    final currentHorizontalSpan =
        (first.dx - second.dx).abs();
    final currentVerticalSpan =
        (first.dy - second.dy).abs();

    final horizontalDelta =
        currentHorizontalSpan -
            _weekPinchStartHorizontalSpan;

    final verticalDelta =
        currentVerticalSpan -
            _weekPinchStartVerticalSpan;

    if (_weekPinchAxis == null) {
      final horizontalIntent =
          horizontalDelta.abs();
      final verticalIntent =
          verticalDelta.abs();

      // Piccola dead-zone: evita che il normale tremolio delle dita
      // scelga subito un asse.
      if (math.max(
            horizontalIntent,
            verticalIntent,
          ) <
          8) {
        return;
      }

      _weekPinchAxis =
          horizontalIntent >
                  verticalIntent
              ? _WeekPinchAxis.horizontal
              : _WeekPinchAxis.vertical;
    }

    switch (_weekPinchAxis!) {
      case _WeekPinchAxis.vertical:
        final nextHourHeight =
            (_weekPinchStartHourHeight *
                    (1 +
                        verticalDelta /
                            140))
                .clamp(
                  _weekMinHourHeight,
                  _weekMaxHourHeight,
                )
                .toDouble();

        if ((nextHourHeight -
                    _weekHourHeight)
                .abs() <
            0.05) {
          return;
        }

        final focalY =
            (first.dy + second.dy) / 2;

        final anchorMinutes =
            _weekPinchAnchorMinutes;

        if (anchorMinutes == null) {
          return;
        }

        setState(() {
          _weekHourHeight =
              nextHourHeight;
        });

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted ||
                !_weekVerticalController
                    .hasClients) {
              return;
            }

            final targetOffset =
                _weekGridTopPadding +
                    anchorMinutes /
                        60 *
                        nextHourHeight -
                    focalY;

            final clampedOffset =
                targetOffset
                    .clamp(
                      0.0,
                      _weekVerticalController
                          .position
                          .maxScrollExtent,
                    )
                    .toDouble();

            _weekVerticalController
                .jumpTo(
              clampedOffset,
            );
          },
        );
        break;

      case _WeekPinchAxis.horizontal:
        final nextStoredDayWidth =
            (_weekPinchStartDayWidth *
                    (1 +
                        horizontalDelta /
                            140))
                .clamp(
                  _weekMinDayWidth,
                  _weekMaxDayWidth,
                )
                .toDouble();

        final nextRenderedDayWidth =
            math.max(
          _weekPinchFittedDayWidth,
          nextStoredDayWidth,
        ).toDouble();

        if ((nextStoredDayWidth -
                    _weekDayWidth)
                .abs() <
            0.05) {
          return;
        }

        final anchorDayPosition =
            _weekPinchAnchorDayPosition;
        final viewportFocalX =
            _weekPinchViewportFocalX;

        if (anchorDayPosition == null ||
            viewportFocalX == null) {
          return;
        }

        setState(() {
          _weekDayWidth =
              nextStoredDayWidth;
        });

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted ||
                !_weekHorizontalController
                    .hasClients) {
              return;
            }

            final targetOffset =
                _weekGutterWidth +
                    anchorDayPosition *
                        nextRenderedDayWidth -
                    viewportFocalX;

            final clampedOffset =
                targetOffset
                    .clamp(
                      0.0,
                      _weekHorizontalController
                          .position
                          .maxScrollExtent,
                    )
                    .toDouble();

            _weekHorizontalController
                .jumpTo(
              clampedOffset,
            );
          },
        );
        break;
    }
  }

  void _handleWeekPointerEnd(
    PointerEvent event, {
    required double renderedDayWidth,
    required double fittedDayWidth,
  }) {
    _weekPointers.remove(
      event.pointer,
    );

    _weekPinchAxis = null;
    _weekPinchAnchorMinutes = null;
    _weekPinchAnchorDayPosition = null;
    _weekPinchViewportFocalX = null;

    if (_weekPinching) {
      setState(() {
        _weekPinching = false;
      });
    }

    if (_weekPointers.length == 2) {
      _startWeekPinchIfPossible(
        renderedDayWidth:
            renderedDayWidth,
        fittedDayWidth:
            fittedDayWidth,
      );
    }
  }

  void _scrollWeekNearMorning() {
    if (!_weekVerticalController.hasClients) {
      return;
    }

    final target = (7 * _weekHourHeight).clamp(
      0.0,
      _weekVerticalController.position.maxScrollExtent,
    );

    _weekVerticalController.jumpTo(
      target.toDouble(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final rangeStart =
        _rangeStart();
    final rangeEndExclusive =
        _rangeEnd().add(
      const Duration(days: 1),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        leading: IconButton(
          tooltip:
              'Cambia vista calendario',
          onPressed:
              _showViewMenu,
          icon:
              const Icon(
            Icons.menu_rounded,
          ),
        ),
        title:
            const Text(
          'Calendario',
        ),
      ),
      body: StreamBuilder<
          List<TaskOccurrence>>(
        stream:
            widget.taskRepository
                .watchOccurrencesOverlappingWindow(
          rangeStart,
          rangeEndExclusive,
        ),
        builder:
            (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
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

          return StreamBuilder<
              Map<String, TaskCategory>>(
            stream:
                widget.categoryRepository
                    .watchCategoryMap(),
            initialData:
                const {},
            builder:
                (
              context,
              categorySnapshot,
            ) {
              final categoryMap =
                  categorySnapshot.data ??
                      const <
                          String,
                          TaskCategory>{};

              return Column(
                children: [
                  AnimatedSize(
                    duration:
                        const Duration(
                      milliseconds:
                          180,
                    ),
                    curve:
                        Curves.easeOutCubic,
                    alignment:
                        Alignment.topCenter,
                    child:
                        _calendarFormat ==
                                    CalendarFormat.week &&
                                _weekHeaderCollapsed
                            ? const SizedBox.shrink()
                            : _PeriodNavigationHeader(
                                label:
                                    _periodLabel(),
                                compact:
                                    _calendarFormat ==
                                        CalendarFormat.month,
                                selectedDateLabel:
                                    _selectedDateLabel(
                                  _selectedDay,
                                ),
                                onPrevious: () {
                                  _changePeriod(
                                    -1,
                                  );
                                },
                                onNext: () {
                                  _changePeriod(
                                    1,
                                  );
                                },
                                onToday:
                                    _goToToday,
                              ),
                  ),
                  Expanded(
                    child:
                        _calendarFormat ==
                                CalendarFormat
                                    .month
                            ? _buildMonthView(
                                context,
                                occurrences,
                                categoryMap,
                              )
                            : _buildWeekView(
                                context,
                                occurrences,
                                categoryMap,
                              ),
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

  Widget _buildMonthView(
    BuildContext context,
    List<TaskOccurrence> occurrences,
    Map<String, TaskCategory> categoryMap,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final now =
        DateTime.now();

    final selectedOccurrences =
        _occurrencesForDay(
      occurrences,
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
        100,
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
              return _occurrencesForDay(
                occurrences,
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

                final visible =
                    events
                        .take(
                          3,
                        )
                        .toList();

                final hiddenCount =
                    events.length -
                        visible.length;

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
                                visible.length;
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
                                visible[i]
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
                                  visible.length -
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
              final targetDay =
                  math.min(
                _selectedDay.day,
                _daysInMonth(
                  focusedDay.year,
                  focusedDay.month,
                ),
              ).toInt();

              setState(() {
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
                      selectedOccurrences[i],
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
                _weekDefaultHourHeight)
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
          _weekMinDayWidth,
          (viewportWidth -
                  _weekGutterWidth) /
              7,
        ).toDouble();

        final dayWidth =
            math.max(
          fittedDayWidth,
          _weekDayWidth,
        ).toDouble();

        final totalWidth =
            _weekGutterWidth +
            dayWidth *
                7;

        return SingleChildScrollView(
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
                      _weekGutterWidth,
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
                  onCollapsedChanged:
                      _setWeekHeaderCollapsed,
                  onUntimedToggle:
                      _toggleWeekUntimed,
                  onDaySelected:
                      (day) {
                    setState(() {
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
                            _handleWeekPointerDown(
                              event,
                              renderedDayWidth:
                                  dayWidth,
                              fittedDayWidth:
                                  fittedDayWidth,
                            );
                          },
                          onPointerMove:
                              _handleWeekPointerMove,
                          onPointerUp:
                              (event) {
                            _handleWeekPointerEnd(
                              event,
                              renderedDayWidth:
                                  dayWidth,
                              fittedDayWidth:
                                  fittedDayWidth,
                            );
                          },
                          onPointerCancel:
                              (event) {
                            _handleWeekPointerEnd(
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
                                    _weekGridTopPadding,
                                bottom:
                                    _weekGridBottomPadding,
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
                                    _weekGutterWidth,
                                dayWidth:
                                    dayWidth,
                                onOpen:
                                    _openTaskDetail,
                                onMove:
                                    _moveOccurrenceInWeek,
                                onActions:
                                    _showOccurrenceActions,
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
                                _weekGutterWidth,
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
                                _showOccurrenceActions,
                            onClose:
                                _closeWeekUntimed,
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
        );
      },
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

class _PeriodNavigationHeader
    extends StatelessWidget {
  final String label;
  final String selectedDateLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool compact;

  const _PeriodNavigationHeader({
    required this.label,
    required this.selectedDateLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.compact = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.fromLTRB(
        12,
        4,
        12,
        compact
            ? 4
            : 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip:
                    'Periodo precedente',
                onPressed:
                    onPrevious,
                icon:
                    const Icon(
                  Icons.chevron_left,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign:
                      TextAlign.center,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing:
                                -0.35,
                          ),
                ),
              ),
              IconButton(
                tooltip:
                    'Periodo successivo',
                onPressed:
                    onNext,
                icon:
                    const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.only(
              left: 8,
              right: 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDateLabel,
                    maxLines:
                        1,
                    overflow:
                        TextOverflow.ellipsis,
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
                              fontWeight:
                                  FontWeight.w500,
                            ),
                  ),
                ),
                TextButton(
                  onPressed:
                      onToday,
                  child:
                      const Text(
                    'Oggi',
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

class _CalendarViewMenu
    extends StatelessWidget {
  final CalendarFormat selected;

  const _CalendarViewMenu({
    required this.selected,
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
          right:
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
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          22,
          28,
          18,
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Calendario',
              style:
                  Theme.of(
                context,
              )
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing:
                            -0.5,
                      ),
            ),
            const SizedBox(
              height:
                  28,
            ),
            Text(
              'VISTA',
              style:
                  Theme.of(
                context,
              )
                      .textTheme
                      .labelMedium
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
            const SizedBox(
              height:
                  8,
            ),
            _CalendarViewMenuRow(
              icon:
                  Icons.calendar_month_outlined,
              label:
                  'Mese',
              selected:
                  selected ==
                  CalendarFormat.month,
              onTap: () {
                Navigator.pop(
                  context,
                  CalendarFormat.month,
                );
              },
            ),
            _CalendarViewMenuRow(
              icon:
                  Icons.view_week_outlined,
              label:
                  'Settimana',
              selected:
                  selected ==
                  CalendarFormat.week,
              onTap: () {
                Navigator.pop(
                  context,
                  CalendarFormat.week,
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _CalendarViewMenuRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CalendarViewMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
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
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                13,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds:
                      160,
                ),
                width:
                    3,
                height:
                    28,
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? colorScheme.primary
                          : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(
                    99,
                  ),
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Icon(
                icon,
                size:
                    20,
                color:
                    selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                            fontWeight:
                                selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
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

class _WeekDayHeader extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final double gutterWidth;
  final double dayWidth;
  final bool collapsed;
  final bool untimedExpanded;
  final Map<int, List<TaskOccurrence>> untimedByDay;
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<bool> onCollapsedChanged;
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
    required this.onCollapsedChanged,
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
        DateTime.now();

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
      onVerticalDragEnd:
          (details) {
        final velocity =
            details.primaryVelocity ??
                0;

        if (velocity <
            -120) {
          onCollapsedChanged(
            true,
          );
        } else if (velocity >
            120) {
          onCollapsedChanged(
            false,
          );
        }
      },
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
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _WeekOccurrenceBlock({
    required this.task,
    required this.category,
    required this.accentColor,
    required this.priorityColor,
    required this.timeText,
    required this.subtaskText,
    required this.height,
    required this.onTap,
    required this.onLongPress,
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

              final showTime =
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

              return Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  compact
                      ? 3
                      : 5,
                  4,
                  compact
                      ? 3
                      : 4,
                  4,
                ),
                child:
                    ClipRect(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (compact)
                        Text(
                          task.title,
                          maxLines:
                              height >= 46
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
            },
          ),
        ),
      ),
    );
  }
}


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
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;
  final Future<void> Function(
    TaskOccurrence occurrence,
    DateTime targetDate,
    int targetStartMinutes,
  ) onMove;

  const _WeekHourlyGrid({
    required this.days,
    required this.selectedDay,
    required this.timedByDay,
    required this.categoryMap,
    required this.hourHeight,
    required this.gutterWidth,
    required this.dayWidth,
    required this.onOpen,
    required this.onActions,
    required this.onMove,
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

    final availableWidth =
        dayWidth -
        8;
    final laneWidth =
        availableWidth /
        layout.laneCount;

    final left =
        gutterWidth +
        dayIndex *
            dayWidth +
        4 +
        layout.lane *
            laneWidth;

    final width =
        math.max(
      laneWidth -
          3,
      24.0,
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
        onDragEnd:
            (details) {
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

class _CalendarTaskRow extends StatelessWidget {
  final LifeTask task;
  final String timeLabel;
  final String secondaryLabel;
  final TaskCategory? category;
  final Color priorityColor;
  final String priorityLabel;
  final ValueChanged<bool> onCompletedChanged;
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
