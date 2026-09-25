part of 'task_form_page.dart';

class _DatePickerSheet
    extends StatefulWidget {
  final DateTime initialDate;
  final DateTime today;

  const _DatePickerSheet({
    required this.initialDate,
    required this.today,
  });

  @override
  State<_DatePickerSheet>
      createState() =>
          _DatePickerSheetState();
}

class _DatePickerSheetState
    extends State<_DatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();

    _selectedDate =
        DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    _visibleMonth =
        DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
  }

  String _monthLabel(
    DateTime month,
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

    return '${months[month.month - 1]} '
        '${month.year}';
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _changeMonth(
    int delta,
  ) {
    setState(() {
      _visibleMonth =
          DateTime(
        _visibleMonth.year,
        _visibleMonth.month +
            delta,
        1,
      );
    });
  }

  void _chooseQuick(
    DateTime date,
  ) {
    setState(() {
      _selectedDate =
          DateTime(
        date.year,
        date.month,
        date.day,
      );

      _visibleMonth =
          DateTime(
        date.year,
        date.month,
        1,
      );
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final today =
        widget.today;

    final tomorrow =
        CivilDate.nextDay(
      today,
    );

    final firstDay =
        DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final leading =
        firstDay.weekday -
            DateTime.monday;

    final dayCount =
        DateTime(
      _visibleMonth.year,
      _visibleMonth.month +
          1,
      0,
    ).day;

    final usedCells =
        leading +
            dayCount;

    final rowCount =
        (usedCells / 7)
            .ceil();

    final cellCount =
        rowCount * 7;

    return SafeArea(
      top: false,
      child: Container(
        margin:
            const EdgeInsets
                .fromLTRB(
          12,
          0,
          12,
          12,
        ),
        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          18,
          20,
          16,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme.surface,
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
                      alpha: 0.52,
                    ),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data',
                    style:
                        Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing:
                                  -0.4,
                            ),
                  ),
                ),
                _TinyIconAction(
                  tooltip:
                      'Mese precedente',
                  icon:
                      Icons
                          .chevron_left,
                  onTap:
                      () {
                    _changeMonth(
                      -1,
                    );
                  },
                ),
                const SizedBox(
                  width: 2,
                ),
                _TinyIconAction(
                  tooltip:
                      'Mese successivo',
                  icon:
                      Icons
                          .chevron_right,
                  onTap:
                      () {
                    _changeMonth(
                      1,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthLabel(
                      _visibleMonth,
                    ),
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                  ),
                ),
                _DateQuickAction(
                  label:
                      'Oggi',
                  selected:
                      _sameDay(
                    _selectedDate,
                    today,
                  ),
                  onTap:
                      () {
                    _chooseQuick(
                      today,
                    );
                  },
                ),
                const SizedBox(
                  width: 6,
                ),
                _DateQuickAction(
                  label:
                      'Domani',
                  selected:
                      _sameDay(
                    _selectedDate,
                    tomorrow,
                  ),
                  onTap:
                      () {
                    _chooseQuick(
                      tomorrow,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                for (final label
                    in const [
                  'L',
                  'M',
                  'M',
                  'G',
                  'V',
                  'S',
                  'D',
                ])
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style:
                            Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 6,
            ),
            GridView.builder(
              shrinkWrap:
                  true,
              physics:
                  const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 42,
              ),
              itemCount:
                  cellCount,
              itemBuilder:
                  (context, index) {
                final day =
                    index -
                        leading +
                        1;

                if (day < 1 ||
                    day > dayCount) {
                  return const SizedBox
                      .shrink();
                }

                final date =
                    DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  day,
                );

                final selected =
                    _sameDay(
                  date,
                  _selectedDate,
                );

                final isToday =
                    _sameDay(
                  date,
                  today,
                );

                return _CalendarDayChoice(
                  day:
                      day,
                  selected:
                      selected,
                  isToday:
                      isToday,
                  onTap:
                      () {
                    setState(() {
                      _selectedDate =
                          date;
                    });
                  },
                );
              },
            ),
            const SizedBox(
              height: 14,
            ),
            _SheetPrimaryAction(
              label:
                  'Conferma ${_selectedDate.day}/${_selectedDate.month}',
              onTap:
                  () {
                Navigator.pop(
                  context,
                  _selectedDate,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DateQuickAction
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateQuickAction({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          selected
              ? colorScheme.primary
                  .withValues(
                    alpha: 0.10,
                  )
              : Colors
                  .transparent,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          child: Text(
            label,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          selected
                              ? colorScheme.primary
                              : colorScheme
                                  .onSurfaceVariant,
                      fontWeight:
                          FontWeight.w700,
                    ),
          ),
        ),
      ),
    );
  }
}

class _CalendarDayChoice
    extends StatelessWidget {
  final int day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayChoice({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Center(
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              onTap,
          customBorder:
              const CircleBorder(),
          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 140,
            ),
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  selected
                      ? colorScheme.primary
                          .withValues(
                            alpha: 0.13,
                          )
                      : Colors
                          .transparent,
              shape:
                  BoxShape.circle,
              border:
                  selected ||
                          isToday
                      ? Border.all(
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme
                                      .outlineVariant,
                          width:
                              selected
                                  ? 1.5
                                  : 1,
                        )
                      : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme
                                      .onSurface,
                          fontWeight:
                              selected ||
                                      isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
