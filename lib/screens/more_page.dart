import 'package:flutter/material.dart';

import '../services/day_settings_controller.dart';

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

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
      helpText: start
          ? 'Inizio giornata'
          : 'Fine giornata',
      cancelText: 'Annulla',
      confirmText: 'Salva',
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
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
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: daySettingsController,
        builder: (context, _) {
          final startLabel =
              daySettingsController.formatMinutes(
            daySettingsController.startMinutes,
          );

          final endLabel =
              daySettingsController.formatMinutes(
            daySettingsController.endMinutes,
          );

          final endSuffix =
              daySettingsController.endsOnNextCivilDay
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
                height: 34,
              ),

              Text(
                'GIORNATA',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
              ),

              const SizedBox(
                height: 8,
              ),

              _SettingRow(
                icon: Icons.wb_sunny_outlined,
                title: 'Inizio giornata',
                value: startLabel,
                subtitle:
                    'Da questo orario inizia una nuova giornata in Oggi.',
                onTap: () {
                  _pickTime(
                    context,
                    start: true,
                  );
                },
              ),

              Divider(
                color: colorScheme.outlineVariant
                    .withValues(
                  alpha: 0.55,
                ),
              ),

              _SettingRow(
                icon: Icons.nightlight_outlined,
                title: 'Fine giornata',
                value: '$endLabel$endSuffix',
                subtitle:
                    'È il limite normale. Se un’attività termina più tardi, la timeline si estende automaticamente.',
                onTap: () {
                  _pickTime(
                    context,
                    start: false,
                  );
                },
              ),

              const SizedBox(
                height: 18,
              ),

              Text(
                'La giornata cambia all’orario di inizio, non a mezzanotte. '
                'Con 06:00 → 03:00, per esempio, le attività delle 01:30 '
                'appartengono ancora alla giornata iniziata il giorno prima.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),

              if (!defaultsActive) ...[
                const SizedBox(
                  height: 12,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      daySettingsController
                          .resetDefaults();
                    },
                    child: const Text(
                      'Ripristina 06:00 → 03:00',
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 14,
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
                      height: 4,
                    ),

                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                            height: 1.25,
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
                  size: 19,
                  color: colorScheme
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.65,
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
