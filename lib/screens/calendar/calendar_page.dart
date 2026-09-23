import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_occurrence.dart';
import '../../models/task_recurrence.dart';
import '../../models/task_subtask.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../utils/task_category_icons.dart';
import '../tasks/task_detail_page.dart';
import '../tasks/task_form_page.dart';

part 'calendar_month_view.dart';
part 'calendar_week_view.dart';


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
  static const double _weekDefaultHourHeight = 68;
  static const double _weekMinHourHeight = 40;
  static const double _weekMaxHourHeight = 110;

  static const double _weekDefaultDayWidth = 96;
  static const double _weekMinDayWidth = 48;
  static const double _weekMaxDayWidth = 180;

  static const double _weekGridTopPadding = 12;
  static const double _weekGridBottomPadding = 36;
  static const double _weekGutterWidth = 54;

  static const Duration _calendarViewMenuTransitionDuration =
      Duration(milliseconds: 220);
  static const Duration _weekHeaderSettleDuration =
      Duration(milliseconds: 180);
  static const double _weekHeaderDragDistance = 104;

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

  late final AnimationController _weekHeaderCollapseController;

  // Appunti interni del calendario. "Copia" prepara il contenuto che
  // verrà usato dal successivo comando "Incolla qui" sugli slot vuoti.
  LifeTask? _weekClipboardTask;

  final ScrollController _weekVerticalController = ScrollController();
  final ScrollController _weekHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();

    _weekHeaderCollapseController =
        AnimationController(
      vsync:
          this,
      duration:
          _weekHeaderSettleDuration,
      value:
          0,
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
    _weekHeaderCollapseController.dispose();
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


  // I file part usano extension per tenere separate Mese e Settimana.
  // La chiamata reale a setState resta qui, dentro la sottoclasse di State,
  // così l'analyzer non segnala accessi al membro protetto dalle extension.
  void _updateCalendarState(VoidCallback update) {
    setState(update);
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


  void _setCalendarFormat(
    CalendarFormat format,
  ) {
    if (_calendarFormat == format) {
      return;
    }

    _weekHeaderCollapseController.stop();
    _weekHeaderCollapseController.value = 0;

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
          _calendarViewMenuTransitionDuration,
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
              Curves.easeInOutCubic,
          reverseCurve:
              Curves.easeInOutCubic,
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

    // showGeneralDialog completa il Future quando parte il pop, mentre
    // l'animazione inversa è ancora in corso. Aspettiamo che la tendina
    // abbia finito di richiudersi prima di cambiare la vista sottostante:
    // così il tap su Mese/Settimana ha la stessa chiusura del tap fuori.
    await Future<void>.delayed(
      _calendarViewMenuTransitionDuration,
    );

    if (!mounted) {
      return;
    }

    _setCalendarFormat(
      selected,
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
                        _weekHeaderCollapseController,
                    builder:
                        (context, child) {
                      if (_calendarFormat !=
                          CalendarFormat.week) {
                        return child!;
                      }

                      final visibleFactor =
                          (1.0 -
                                  _weekHeaderCollapseController
                                      .value)
                              .clamp(
                                0.0,
                                1.0,
                              )
                              .toDouble();

                      return ClipRect(
                        child:
                            Align(
                          alignment:
                              Alignment.topCenter,
                          heightFactor:
                              visibleFactor,
                          child:
                              Opacity(
                            opacity:
                                visibleFactor,
                            child:
                                child,
                          ),
                        ),
                      );
                    },
                    child:
                        _PeriodNavigationHeader(
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
                            ? _CalendarMonthViewExtension(this)._buildMonthView(
                                context,
                                occurrences,
                                categoryMap,
                              )
                            : _CalendarWeekViewExtension(this)._buildWeekView(
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


