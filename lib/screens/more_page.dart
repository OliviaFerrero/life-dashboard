import 'package:flutter/material.dart';

import '../core/time/clock_format.dart';
import '../services/day_settings_controller.dart';
import '../widgets/editorial_time_picker.dart';

class MorePage extends StatelessWidget {
  final DaySettingsController daySettingsController;

  const MorePage({
    super.key,
    required this.daySettingsController,
  });

  Future<void> _pickTime(
    BuildContext context, {
    required bool start,
  }) async {
    final currentMinutes = start
        ? daySettingsController.startMinutes
        : daySettingsController.endMinutes;

    final picked =
        await showEditorialTimePicker(
      context: context,
      title: start
          ? 'Inizio giornata'
          : 'Fine giornata',
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
    );

    if (picked == null) {
      return;
    }

    final minutes =
        picked.hour * 60 + picked.minute;

    if (start) {
      await daySettingsController.setStartMinutes(
        minutes,
      );
    } else {
      await daySettingsController.setEndMinutes(
        minutes,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: daySettingsController,
        builder: (context, _) {
          final startLabel =
              formatClockMinutes(
            daySettingsController.startMinutes,
          );

          final endLabel =
              formatClockMinutes(
            daySettingsController.endMinutes,
          );

          final endSuffix =
              daySettingsController
                      .endsOnNextCivilDay
                  ? ' · giorno dopo'
                  : '';

          final defaultsActive =
              daySettingsController.startMinutes ==
                      DaySettingsController
                          .defaultStartMinutes &&
                  daySettingsController.endMinutes ==
                      DaySettingsController
                          .defaultEndMinutes;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              40,
            ),
            children: [
              Text(
                'Altro',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'Preferenze che definiscono il ritmo '
                'della tua giornata.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              const SizedBox(
                height: 32,
              ),
              const _SectionLabel(
                text: 'GIORNATA PERSONALE',
              ),
              const SizedBox(
                height: 12,
              ),
              _DayWindowSummary(
                startLabel: startLabel,
                endLabel: endLabel,
                nextDay:
                    daySettingsController
                        .endsOnNextCivilDay,
              ),
              const SizedBox(
                height: 18,
              ),
              _SettingRow(
                icon: Icons.wb_sunny_outlined,
                title: 'Inizio giornata',
                value: startLabel,
                subtitle:
                    'Da questo orario comincia una nuova giornata in Oggi.',
                onTap: () {
                  _pickTime(
                    context,
                    start: true,
                  );
                },
              ),
              _EditorialDivider(
                colorScheme: colorScheme,
              ),
              _SettingRow(
                icon: Icons.nightlight_outlined,
                title: 'Fine giornata',
                value:
                    '$endLabel$endSuffix',
                subtitle:
                    'Limite normale della timeline. Le attività che finiscono più tardi la estendono automaticamente.',
                onTap: () {
                  _pickTime(
                    context,
                    start: false,
                  );
                },
              ),
              const SizedBox(
                height: 22,
              ),
              _InfoNote(
                text:
                    'La giornata cambia all’orario di inizio, non a mezzanotte. '
                    'Con 06:00 → 03:00, per esempio, un’attività delle 01:30 '
                    'appartiene ancora alla giornata iniziata il giorno prima.',
              ),
              if (!defaultsActive) ...[
                const SizedBox(
                  height: 18,
                ),
                _TextAction(
                  label:
                      'Ripristina 06:00 → 03:00',
                  onTap: () {
                    daySettingsController
                        .resetDefaults();
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel
    extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
    );
  }
}

class _DayWindowSummary
    extends StatelessWidget {
  final String startLabel;
  final String endLabel;
  final bool nextDay;

  const _DayWindowSummary({
    required this.startLabel,
    required this.endLabel,
    required this.nextDay,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Text(
            startLabel,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              4,
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 18,
              color:
                  colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            endLabel,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
          ),
          if (nextDay) ...[
            const SizedBox(
              width: 8,
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 4,
              ),
              child: Text(
                '+1',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color:
                          colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 2,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color:
                                    colorScheme.primary,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.55,
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

class _EditorialDivider
    extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EditorialDivider({
    required this.colorScheme,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Divider(
      height: 1,
      indent: 42,
      color: colorScheme.outlineVariant
          .withValues(
        alpha: 0.5,
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 2,
          ),
          child: Icon(
            Icons.info_outline,
            size: 17,
            color: colorScheme
                .onSurfaceVariant
                .withValues(
              alpha: 0.78,
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color:
                      colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _TextAction
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color =
        Theme.of(context).colorScheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            8,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 8,
            ),
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
