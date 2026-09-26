import 'package:flutter/material.dart';

Future<TimeOfDay?> showEditorialTimePicker({
  required BuildContext context,
  required String title,
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(
      alpha: 0.24,
    ),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return EditorialTimePickerSheet(
        title: title,
        initialTime: initialTime,
      );
    },
  );
}

class EditorialTimePickerSheet
    extends StatefulWidget {
  final String title;
  final TimeOfDay initialTime;

  const EditorialTimePickerSheet({
    super.key,
    required this.title,
    required this.initialTime,
  });

  @override
  State<EditorialTimePickerSheet>
      createState() =>
          _EditorialTimePickerSheetState();
}

class _EditorialTimePickerSheetState
    extends State<EditorialTimePickerSheet> {
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController
      _hourController;

  late final FixedExtentScrollController
      _minuteController;

  @override
  void initState() {
    super.initState();

    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;

    _hourController =
        FixedExtentScrollController(
      initialItem: _hour,
    );

    _minuteController =
        FixedExtentScrollController(
      initialItem: _minute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _setMinute(
    int minute,
  ) {
    setState(() {
      _minute = minute;
    });

    _minuteController.animateToItem(
      minute,
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOutCubic,
    );
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(
          2,
          '0',
        );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          16,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(
            22,
          ),
          border: Border.all(
            color: colorScheme.outlineVariant
                .withValues(
              alpha: 0.52,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              '${_twoDigits(_hour)}:${_twoDigits(_minute)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(
              height: 14,
            ),
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme
                          .surfaceContainerHighest
                          .withValues(
                        alpha: 0.34,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeWheel(
                          controller:
                              _hourController,
                          itemCount: 24,
                          selectedValue: _hour,
                          keyPrefix:
                              'hour',
                          labelBuilder: _twoDigits,
                          onChanged: (value) {
                            setState(() {
                              _hour = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        ':',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: colorScheme
                                  .onSurfaceVariant,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                      ),
                      Expanded(
                        child: _TimeWheel(
                          controller:
                              _minuteController,
                          itemCount: 60,
                          selectedValue: _minute,
                          keyPrefix:
                              'minute',
                          labelBuilder: _twoDigits,
                          onChanged: (value) {
                            setState(() {
                              _minute = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                for (final minute in const [
                  0,
                  15,
                  30,
                  45,
                ]) ...[
                  Expanded(
                    child: _MinuteQuickChoice(
                      minute: minute,
                      selected:
                          _minute == minute,
                      onTap: () {
                        _setMinute(
                          minute,
                        );
                      },
                    ),
                  ),
                  if (minute != 45)
                    const SizedBox(
                      width: 7,
                    ),
                ],
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            _PrimaryAction(
              label: 'Conferma',
              onTap: () {
                Navigator.pop(
                  context,
                  TimeOfDay(
                    hour: _hour,
                    minute: _minute,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedValue;
  final String keyPrefix;
  final String Function(int value)
      labelBuilder;
  final ValueChanged<int> onChanged;

  const _TimeWheel({
    required this.controller,
    required this.itemCount,
    required this.selectedValue,
    required this.keyPrefix,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      perspective: 0.0025,
      diameterRatio: 1.7,
      physics:
          const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate:
          ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          if (index < 0 ||
              index >= itemCount) {
            return null;
          }

          final selected =
              index == selectedValue;

          final label =
              labelBuilder(
            index,
          );

          return Semantics(
            button:
                true,
            selected:
                selected,
            label:
                label,
            child:
                GestureDetector(
              key:
                  ValueKey(
                'editorial_time_${keyPrefix}_$index',
              ),
              behavior:
                  HitTestBehavior.opaque,
              onTap: () {
                onChanged(
                  index,
                );

                controller.animateToItem(
                  index,
                  duration:
                      const Duration(
                    milliseconds:
                        180,
                  ),
                  curve:
                      Curves.easeOutCubic,
                );
              },
              child:
                  Center(
                child:
                    Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color:
                                selected
                                    ? colorScheme
                                        .onSurface
                                    : colorScheme
                                        .onSurfaceVariant
                                        .withValues(
                                          alpha:
                                              0.48,
                                        ),
                            fontWeight:
                                selected
                                    ? FontWeight
                                        .w700
                                    : FontWeight
                                        .w500,
                          ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MinuteQuickChoice
    extends StatelessWidget {
  final int minute;
  final bool selected;
  final VoidCallback onTap;

  const _MinuteQuickChoice({
    required this.minute,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final label =
        ':${minute.toString().padLeft(2, '0')}';

    return Material(
      color: selected
          ? colorScheme.primary.withValues(
              alpha: 0.1,
            )
          : Colors.transparent,
      borderRadius: BorderRadius.circular(
        10,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          10,
        ),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant
                      .withValues(
                        alpha: 0.72,
                      ),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme
                          .onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(
        12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    color:
                        colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
