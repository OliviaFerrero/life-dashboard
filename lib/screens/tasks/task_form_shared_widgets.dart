part of 'task_form_page.dart';

class _FormSectionLabel
    extends StatelessWidget {
  final String text;

  const _FormSectionLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(
                color:
                    Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    1.0,
              ),
    );
  }
}

class _FormDivider
    extends StatelessWidget {
  const _FormDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Divider(
      height: 1,
      indent: 44,
      color:
          Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(
                alpha: 0.5,
              ),
    );
  }
}

class _SettingRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    this.enabled = true,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Opacity(
      opacity:
          enabled
              ? 1
              : 0.42,
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              enabled
                  ? onTap
                  : null,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 12,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  child: Icon(
                    icon,
                    size: 19,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        value,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w600,
                                  height:
                                      1.15,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                if (onClear !=
                    null)
                  _TinyIconAction(
                    tooltip:
                        'Rimuovi',
                    icon:
                        Icons.close,
                    onTap:
                        onClear!,
                  )
                else
                  Icon(
                    Icons
                        .chevron_right,
                    size: 18,
                    color:
                        colorScheme
                            .onSurfaceVariant
                            .withValues(
                              alpha: 0.52,
                            ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchSettingRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>
      onChanged;

  const _SwitchSettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
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
            () {
          onChanged(
            !value,
          );
        },
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  icon,
                  size: 19,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurfaceVariant,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      value
                          ? 'Attivo'
                          : 'Disattivo',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),
              _EditorialToggle(
                value:
                    value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TinyIconAction
    extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _TinyIconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Tooltip(
      message:
          tooltip,
      child: InkResponse(
        onTap:
            onTap,
        radius:
            20,
        child: Padding(
          padding:
              const EdgeInsets.all(
            6,
          ),
          child: Icon(
            icon,
            size: 17,
            color:
                colorScheme
                    .onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EditorialToggle
    extends StatelessWidget {
  final bool value;

  const _EditorialToggle({
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 160,
      ),
      curve:
          Curves.easeOutCubic,
      width: 42,
      height: 24,
      padding:
          const EdgeInsets.all(
        3,
      ),
      decoration:
          BoxDecoration(
        color:
            value
                ? colorScheme.primary
                    .withValues(
                      alpha: 0.14,
                    )
                : Colors
                    .transparent,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border:
            Border.all(
          color:
              value
                  ? colorScheme.primary
                  : colorScheme
                      .outlineVariant,
          width: 1.2,
        ),
      ),
      child: AnimatedAlign(
        duration:
            const Duration(
          milliseconds: 160,
        ),
        curve:
            Curves.easeOutCubic,
        alignment:
            value
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration:
              BoxDecoration(
            color:
                value
                    ? colorScheme.primary
                    : colorScheme
                        .onSurfaceVariant
                        .withValues(
                          alpha: 0.56,
                        ),
            shape:
                BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _FormPrimaryAction
    extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _FormPrimaryAction({
    required this.onTap,
    required this.icon,
    required this.label,
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
          colorScheme.primary,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    colorScheme
                        .onPrimary,
              ),
              const SizedBox(
                width: 9,
              ),
              Text(
                label,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onPrimary,
                          fontWeight:
                              FontWeight.w700,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryAction
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetPrimaryAction({
    required this.label,
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
          colorScheme.primary,
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: SizedBox(
          width:
              double.infinity,
          height: 48,
          child: Center(
            child: Text(
              label,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color:
                            colorScheme
                                .onPrimary,
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

class _SheetTextAction
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetTextAction({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final effectiveColor =
        color ??
            Theme.of(context)
                .colorScheme
                .primary;

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
        child: SizedBox(
          width:
              double.infinity,
          height: 42,
          child: Center(
            child: Text(
              label,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color:
                            effectiveColor,
                        fontWeight:
                            FontWeight.w600,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberPickerField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helper;
  final ValueChanged<String>?
      onSubmitted;

  const _NumberPickerField({
    required this.controller,
    required this.label,
    this.helper,
    this.onSubmitted,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Text(
          helper == null
              ? label
              : '$label · $helper',
          style:
              Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                    color:
                        colorScheme
                            .onSurfaceVariant,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        0.2,
                  ),
        ),
        const SizedBox(
          height: 3,
        ),
        TextField(
          controller:
              controller,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],
          onSubmitted:
              onSubmitted,
          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
          decoration:
              InputDecoration(
            hintText:
                '0',
            hintStyle:
                TextStyle(
              color:
                  colorScheme
                      .onSurfaceVariant
                      .withValues(
                        alpha: 0.45,
                      ),
            ),
            border:
                InputBorder.none,
            enabledBorder:
                InputBorder.none,
            focusedBorder:
                InputBorder.none,
            isDense:
                true,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              vertical: 4,
            ),
          ),
        ),
        Container(
          height: 1,
          color:
              colorScheme
                  .outlineVariant
                  .withValues(
                    alpha: 0.78,
                  ),
        ),
      ],
    );
  }
}

