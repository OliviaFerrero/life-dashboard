part of 'task_form_page.dart';

class _InlineDurationPicker
    extends StatelessWidget {
  final int? value;
  final String Function(
    int? minutes,
  ) labelBuilder;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCustom;

  const _InlineDurationPicker({
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    required this.onCustom,
  });

  static const _presets = <int>[
    15,
    30,
    45,
    60,
    90,
    120,
    180,
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final isCustom =
        value != null &&
            !_presets.contains(
              value,
            );

    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 12,
      ),
      child: Container(
        padding:
            const EdgeInsets
                .fromLTRB(
          14,
          13,
          14,
          12,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme
                  .surfaceContainerHighest
                  .withValues(
                    alpha: 0.30,
                  ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border:
              Border.all(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
                      alpha: 0.42,
                    ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  Icons
                      .timer_outlined,
                  size: 20,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durata',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      labelBuilder(
                        value,
                      ),
                      style:
                          Theme.of(context)
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding:
                const EdgeInsets.only(
              left: 36,
            ),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _InlineDurationChoice(
                  label:
                      'Nessuna',
                  selected:
                      value == null,
                  onTap: () {
                    onChanged(
                      null,
                    );
                  },
                ),
                for (final minutes
                    in _presets)
                  _InlineDurationChoice(
                    label:
                        labelBuilder(
                      minutes,
                    ),
                    selected:
                        value ==
                            minutes,
                    onTap: () {
                      onChanged(
                        minutes,
                      );
                    },
                  ),
                _InlineDurationChoice(
                  label:
                      isCustom
                          ? 'Altro · ${labelBuilder(value)}'
                          : 'Altro',
                  selected:
                      isCustom,
                  onTap:
                      onCustom,
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

class _InlineDurationChoice
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InlineDurationChoice({
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
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          6,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            7,
            5,
            7,
            4,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                label,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                          fontWeight:
                              selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                        ),
              ),
              const SizedBox(
                height: 4,
              ),
              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 140,
                ),
                height: 2,
                width:
                    selected
                        ? 22
                        : 0,
                decoration:
                    BoxDecoration(
                  color:
                      colorScheme.primary,
                  borderRadius:
                      BorderRadius.circular(
                    999,
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

class _RecurrencePickerSheet
    extends StatefulWidget {
  final TaskRecurrence initialRecurrence;
  final int anchorWeekday;

  const _RecurrencePickerSheet({
    required this.initialRecurrence,
    required this.anchorWeekday,
  });

  @override
  State<_RecurrencePickerSheet>
      createState() =>
          _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState
    extends State<_RecurrencePickerSheet> {
  late TaskRecurrenceType _type;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();

    _type =
        widget.initialRecurrence.type;

    _weekdays =
        widget.initialRecurrence.weekdays
            .toSet();

    if (_type ==
            TaskRecurrenceType.weekly &&
        _weekdays.isEmpty) {
      _weekdays.add(
        widget.anchorWeekday,
      );
    }
  }

  void _selectType(
    TaskRecurrenceType type,
  ) {
    setState(() {
      _type = type;

      if (_type ==
              TaskRecurrenceType.weekly &&
          _weekdays.isEmpty) {
        _weekdays.add(
          widget.anchorWeekday,
        );
      }
    });
  }

  void _toggleWeekday(
    int weekday,
  ) {
    setState(() {
      if (_weekdays.contains(
        weekday,
      )) {
        if (_weekdays.length > 1) {
          _weekdays.remove(
            weekday,
          );
        }
      } else {
        _weekdays.add(
          weekday,
        );
      }
    });
  }

  void _confirm() {
    switch (_type) {
      case TaskRecurrenceType.none:
        Navigator.pop(
          context,
          const TaskRecurrence.none(),
        );
        return;

      case TaskRecurrenceType.daily:
        Navigator.pop(
          context,
          const TaskRecurrence.daily(),
        );
        return;

      case TaskRecurrenceType.weekly:
        Navigator.pop(
          context,
          TaskRecurrence.weekly(
            _weekdays,
          ),
        );
        return;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

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
          18,
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
              alpha: 0.55,
            ),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              'RIPETIZIONE',
              style:
                  Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w800,
                        letterSpacing:
                            1,
                      ),
            ),

            const SizedBox(
              height: 8,
            ),

            _RecurrenceChoiceRow(
              label:
                  'Non ripetere',
              selected:
                  _type ==
                      TaskRecurrenceType
                          .none,
              onTap: () {
                _selectType(
                  TaskRecurrenceType
                      .none,
                );
              },
            ),

            const _FormDivider(),

            _RecurrenceChoiceRow(
              label:
                  'Ogni giorno',
              selected:
                  _type ==
                      TaskRecurrenceType
                          .daily,
              onTap: () {
                _selectType(
                  TaskRecurrenceType
                      .daily,
                );
              },
            ),

            const _FormDivider(),

            _RecurrenceChoiceRow(
              label:
                  'Ogni settimana',
              selected:
                  _type ==
                      TaskRecurrenceType
                          .weekly,
              onTap: () {
                _selectType(
                  TaskRecurrenceType
                      .weekly,
                );
              },
            ),

            if (_type ==
                TaskRecurrenceType
                    .weekly) ...[
              const SizedBox(
                height: 16,
              ),

              Text(
                'Giorni',
                style:
                    Theme.of(context)
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

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  for (final weekday
                      in const [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ])
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              2,
                        ),
                        child:
                            _WeekdayChoice(
                          label:
                              const {
                            DateTime.monday:
                                'L',
                            DateTime.tuesday:
                                'M',
                            DateTime.wednesday:
                                'M',
                            DateTime.thursday:
                                'G',
                            DateTime.friday:
                                'V',
                            DateTime.saturday:
                                'S',
                            DateTime.sunday:
                                'D',
                          }[weekday]!,
                          selected:
                              _weekdays
                                  .contains(
                            weekday,
                          ),
                          onTap: () {
                            _toggleWeekday(
                              weekday,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(
              height: 22,
            ),

            _SheetPrimaryAction(
              label:
                  'Conferma',
              onTap:
                  _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrenceChoiceRow
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RecurrenceChoiceRow({
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
          Colors.transparent,
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
            vertical: 13,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                selected
                                    ? colorScheme.primary
                                    : colorScheme
                                        .onSurface,
                            fontWeight:
                                selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                          ),
                ),
              ),
              AnimatedOpacity(
                duration:
                    const Duration(
                  milliseconds: 140,
                ),
                opacity:
                    selected
                        ? 1
                        : 0,
                child: Icon(
                  Icons.check_rounded,
                  size: 19,
                  color:
                      colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayChoice
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WeekdayChoice({
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
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 140,
          ),
          height: 36,
          decoration:
              BoxDecoration(
            color:
                selected
                    ? colorScheme.primary
                        .withValues(
                          alpha: 0.11,
                        )
                    : Colors
                        .transparent,
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? colorScheme.primary
                      : colorScheme
                          .outlineVariant
                          .withValues(
                            alpha: 0.72,
                          ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyMedium
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
      ),
    );
  }
}


class _DurationPickerSheet
    extends StatefulWidget {
  final int? initialMinutes;

  const _DurationPickerSheet({
    required this.initialMinutes,
  });

  @override
  State<_DurationPickerSheet>
      createState() =>
          _DurationPickerSheetState();
}

class _DurationPickerSheetState
    extends State<_DurationPickerSheet> {
  late final TextEditingController
      _hoursController;
  late final TextEditingController
      _minutesController;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    final current =
        widget.initialMinutes ?? 0;

    _hoursController =
        TextEditingController(
      text:
          current >= 60
              ? (current ~/ 60)
                  .toString()
              : '',
    );

    _minutesController =
        TextEditingController(
      text:
          current % 60 == 0
              ? ''
              : (current % 60)
                  .toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();

    super.dispose();
  }

  void _confirmCustomDuration() {
    final hours =
        int.tryParse(
              _hoursController.text,
            ) ??
            0;

    final minutes =
        int.tryParse(
              _minutesController.text,
            ) ??
            0;

    if (minutes >= 60) {
      setState(() {
        _errorText =
            'I minuti devono essere compresi tra 0 e 59.';
      });
      return;
    }

    final total =
        hours * 60 + minutes;

    if (total <= 0) {
      setState(() {
        _errorText =
            'Inserisci una durata maggiore di zero.';
      });
      return;
    }

    FocusScope.of(context)
        .unfocus();

    Navigator.pop(
      context,
      total,
    );
  }

  void _removeDuration() {
    FocusScope.of(context)
        .unfocus();

    Navigator.pop(
      context,
      -1,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            MediaQuery
                .viewInsetsOf(
          context,
        ).bottom,
      ),
      child: SafeArea(
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
          child:
              SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Durata esatta',
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
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Usa ore e minuti quando i valori rapidi non bastano.',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            height:
                                1.35,
                          ),
                ),
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 112,
                      child:
                          _NumberPickerField(
                        controller:
                            _hoursController,
                        label:
                            'Ore',
                        onSubmitted:
                            (_) {
                          _confirmCustomDuration();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                    ),
                    SizedBox(
                      width: 128,
                      child:
                          _NumberPickerField(
                        controller:
                            _minutesController,
                        label:
                            'Minuti',
                        helper:
                            '0–59',
                        onSubmitted:
                            (_) {
                          _confirmCustomDuration();
                        },
                      ),
                    ),
                  ],
                ),
                if (_errorText !=
                    null) ...[
                  const SizedBox(
                    height: 9,
                  ),
                  Text(
                    _errorText!,
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  colorScheme.error,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                  ),
                ],
                const SizedBox(
                  height: 18,
                ),
                _SheetPrimaryAction(
                  label:
                      'Conferma',
                  onTap:
                      _confirmCustomDuration,
                ),
                const SizedBox(
                  height: 4,
                ),
                _SheetTextAction(
                  label:
                      'Rimuovi durata',
                  onTap:
                      _removeDuration,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

