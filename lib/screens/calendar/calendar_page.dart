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

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  static const double _weekHourHeight = 68;
  static const double _weekGutterWidth = 54;
  static const double _weekMinDayWidth = 96;
  static const double _weekHeaderDragDistance = 120;

  late DateTime _selectedDay;
  late DateTime _focusedDay;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _weekHeaderCollapsed = false;
  bool _weekUntimedExpanded = false;

  late final AnimationController _weekHeaderController;
  final ScrollController _weekVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();

    _weekHeaderController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
      value: 0,
    );

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
    _weekHeaderController.dispose();
    _weekVerticalController.dispose();
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

    _weekHeaderController.value = 0;

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
        alpha:
            0.24,
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
          child:
              SafeArea(
            child:
                SizedBox(
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
        );
      },
      transitionBuilder:
          (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return child;
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

  void _updateWeekHeaderDrag(
    DragUpdateDetails details,
  ) {
    if (_calendarFormat !=
        CalendarFormat.week) {
      return;
    }

    final delta =
        details.primaryDelta ??
            0;

    final next =
        (_weekHeaderController.value -
                delta /
                    _weekHeaderDragDistance)
            .clamp(
              0.0,
              1.0,
            );

    _weekHeaderController.value =
        next;
  }

  void _endWeekHeaderDrag(
    DragEndDetails details,
  ) {
    if (_calendarFormat !=
        CalendarFormat.week) {
      return;
    }

    final velocity =
        details.primaryVelocity ??
            0;

    final collapse =
        velocity < -220
            ? true
            : velocity > 220
                ? false
                : _weekHeaderController.value >=
                    0.5;

    setState(() {
      _weekHeaderCollapsed =
          collapse;
    });

    _weekHeaderController.animateTo(
      collapse
          ? 1
          : 0,
      curve:
          Curves.easeInOutCubic,
    );
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
                  AnimatedBuilder(
                    animation:
                        _weekHeaderController,
                    child:
                        _PeriodNavigationHeader(
                      label:
                          _periodLabel(),
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
                    builder:
                        (
                      context,
                      child,
                    ) {
                      if (_calendarFormat !=
                          CalendarFormat.week) {
                        return child!;
                      }

                      final visibleFraction =
                          (1 -
                                  _weekHeaderController
                                      .value)
                              .clamp(
                                0.0,
                                1.0,
                              );

                      return ClipRect(
                        child:
                            Align(
                          alignment:
                              Alignment.topCenter,
                          heightFactor:
                              visibleFraction,
                          child:
                              Opacity(
                            opacity:
                                visibleFraction,
                            child:
                                child,
                          ),
                        ),
                      );
                    },
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
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final selectedOccurrences = _occurrencesForDay(
      occurrences,
      _selectedDay,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        100,
      ),
      children: [
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: TableCalendar<TaskOccurrence>(
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
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
              selectedDayPredicate: (day) {
                return isSameDay(
                  _selectedDay,
                  day,
                );
              },
              eventLoader: (day) {
                return _occurrencesForDay(
                  occurrences,
                  day,
                );
              },
              calendarBuilders: CalendarBuilders<TaskOccurrence>(
                markerBuilder: (
                  context,
                  day,
                  events,
                ) {
                  if (events.isEmpty) {
                    return null;
                  }

                  final visible = events.take(3).toList();

                  return Positioned(
                    bottom: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0;
                            i < visible.length;
                            i++) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _categoryColor(
                                context,
                                visible[i].displayTask,
                                categoryMap,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (i != visible.length - 1)
                            const SizedBox(
                              width: 3,
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              onDaySelected: (
                selectedDay,
                focusedDay,
              ) {
                setState(() {
                  _selectedDay = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  );
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
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
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mese',
              },
              headerVisible: false,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextFormatter: _monthYearLabel,
                titleTextStyle: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                    const TextStyle(),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: _weekdayLetter,
                weekdayStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                markersMaxCount: 3,
                markerSize: 5,
                markerMargin: const EdgeInsets.symmetric(
                  horizontal: 1.5,
                ),
                markerDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
                outsideTextStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
            if (selectedOccurrences.isNotEmpty)
              Text(
                selectedOccurrences.length == 1
                    ? '1 attività'
                    : '${selectedOccurrences.length} attività',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        if (selectedOccurrences.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 22,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Text(
                    'Nessuna attività programmata per questo giorno.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                  i < selectedOccurrences.length;
                  i++) ...[
                _CalendarTaskRow(
                  task: selectedOccurrences[i].displayTask,
                  timeLabel: _timeLabelForOccurrenceOnDay(
                    selectedOccurrences[i],
                    _selectedDay,
                  ),
                  secondaryLabel: _secondaryLabelForOccurrenceOnDay(
                    selectedOccurrences[i],
                    _selectedDay,
                  ),
                  category: selectedOccurrences[i]
                              .displayTask
                              .categoryId ==
                          null
                      ? null
                      : categoryMap[
                          selectedOccurrences[i].displayTask.categoryId
                        ],
                  priorityColor: _priorityColor(
                    context,
                    selectedOccurrences[i].displayTask.priority,
                  ),
                  priorityLabel: _priorityLabel(
                    selectedOccurrences[i].displayTask.priority,
                  ),
                  onCompletedChanged: (completed) async {
                    final occurrence = selectedOccurrences[i];

                    if (completed) {
                      final remaining = occurrence.subtasks
                          .where(
                            (subtask) => !subtask.isCompleted,
                          )
                          .length;

                      if (remaining > 0) {
                        final confirmed = await _confirmCompleteAll(
                          remaining,
                        );

                        if (!confirmed) {
                          return;
                        }
                      }
                    }

                    await widget.taskRepository.setOccurrenceCompleted(
                      occurrence,
                      completed,
                    );
                  },
                  onTap: () {
                    _openTaskDetail(
                      selectedOccurrences[i],
                    );
                  },
                ),
                if (i != selectedOccurrences.length - 1)
                  Divider(
                    indent: 96,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: 0.55,
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

    final untimedOverlayHeight =
        math.min(
      176.0,
      math.max(
        52.0,
        14 +
            maxUntimed *
                34.0,
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

        final dayWidth =
            math.max(
          _weekMinDayWidth,
          (viewportWidth -
                  _weekGutterWidth) /
              7,
        ).toDouble();

        final totalWidth =
            _weekGutterWidth +
            dayWidth *
                7;

        return SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
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
                  onVerticalDragUpdate:
                      _updateWeekHeaderDrag,
                  onVerticalDragEnd:
                      _endWeekHeaderDrag,
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
                            SingleChildScrollView(
                          controller:
                              _weekVerticalController,
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
        );
      },
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

  const _PeriodNavigationHeader({
    required this.label,
    required this.selectedDateLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        4,
        12,
        12,
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
    extends StatefulWidget {
  final CalendarFormat selected;

  const _CalendarViewMenu({
    required this.selected,
  });

  @override
  State<_CalendarViewMenu>
      createState() =>
          _CalendarViewMenuState();
}

class _CalendarViewMenuState
    extends State<_CalendarViewMenu> {
  static const _animationDuration =
      Duration(
    milliseconds:
        240,
  );

  bool _visible =
      false;
  bool _closing =
      false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _visible =
              true;
        });
      },
    );
  }

  Future<void> _select(
    CalendarFormat format,
  ) async {
    if (_closing) {
      return;
    }

    setState(() {
      _closing =
          true;
      _visible =
          false;
    });

    await Future<void>.delayed(
      _animationDuration,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      format,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return AnimatedSlide(
      duration:
          _animationDuration,
      curve:
          _visible
              ? Curves.easeOutCubic
              : Curves.easeInCubic,
      offset:
          _visible
              ? Offset.zero
              : const Offset(
                  -1,
                  0,
                ),
      child:
          AnimatedOpacity(
        duration:
            const Duration(
          milliseconds:
              170,
        ),
        opacity:
            _visible
                ? 1
                : 0.92,
        child:
            Material(
          color:
              colorScheme.surface,
          child:
              DecoratedBox(
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
            child:
                Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                28,
                18,
                20,
              ),
              child:
                  Column(
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
                        Icons
                            .calendar_month_outlined,
                    label:
                        'Mese',
                    selected:
                        widget.selected ==
                        CalendarFormat.month,
                    onTap:
                        () {
                      _select(
                        CalendarFormat.month,
                      );
                    },
                  ),
                  _CalendarViewMenuRow(
                    icon:
                        Icons
                            .view_week_outlined,
                    label:
                        'Settimana',
                    selected:
                        widget.selected ==
                        CalendarFormat.week,
                    onTap:
                        () {
                      _select(
                        CalendarFormat.week,
                      );
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
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
  final Map<int, List<TaskOccurrence>> untimedByDay;
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;
  final VoidCallback onClose;
  final Color backgroundColor;

  const _WeekUntimedOverlay({
    required this.gutterWidth,
    required this.dayWidth,
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
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .wb_sunny_outlined,
                    size:
                        16,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
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
                ],
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
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;

  const _UntimedDayLane({
    required this.occurrences,
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
            const EdgeInsets.symmetric(
          horizontal:
              4,
          vertical:
              6,
        ),
        itemCount:
            occurrences.length,
        separatorBuilder:
            (_, _) =>
                const SizedBox(
          height:
              5,
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
                28,
            child:
                _UntimedOccurrenceChip(
              occurrence:
                  occurrence,
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
  final Map<String, TaskCategory> categoryMap;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _UntimedOccurrenceChip({
    required this.occurrence,
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
              const EdgeInsets.symmetric(
            horizontal:
                6,
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
                    12,
                color:
                    color,
              ),
              const SizedBox(
                width:
                    4,
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

    final block =
        Material(
      color:
          color.withValues(
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
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.fromLTRB(
            5,
            4,
            4,
            4,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color:
                  color.withValues(
                alpha:
                    0.48,
              ),
            ),
          ),
          child:
              ClipRect(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      category ==
                              null
                          ? Icons
                              .circle_outlined
                          : taskCategoryIcon(
                              category.iconKey,
                            ),
                      size:
                          11,
                      color:
                          color,
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
                            height >=
                                    52
                                ? 2
                                : 1,
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
                                  fontWeight:
                                      FontWeight.w800,
                                  height:
                                      1.05,
                                  decoration:
                                      task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                      ),
                    ),
                  ],
                ),
                if (height >=
                    46) ...[
                  const SizedBox(
                    height:
                        3,
                  ),
                  Text(
                    '$continuityPrefix'
                    '${_clock(segment.startMinute)}–'
                    '${_clock(segment.endMinute)}'
                    '$continuitySuffix',
                    maxLines:
                        1,
                    overflow:
                        TextOverflow.clip,
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
                ],
                if (height >=
                        68 &&
                    (subtaskText !=
                            null ||
                        task.priority !=
                            TaskPriority
                                .normal)) ...[
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
                              color,
                        ),
                        const SizedBox(
                          width:
                              2,
                        ),
                        Text(
                          subtaskText,
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
                                        9,
                                    fontWeight:
                                        FontWeight.w700,
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
                            _priorityColor(
                          task.priority,
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
