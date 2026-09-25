import 'package:flutter/material.dart';

class LifeChoiceOption<T> {
  final T value;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;

  const LifeChoiceOption({
    required this.value,
    required this.icon,
    required this.title,
    this.subtitle,
    this.destructive = false,
  });
}

Future<T?> showLifeChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<LifeChoiceOption<T>> options,
  String cancelLabel = 'Annulla',
}) {
  return showModalBottomSheet<T>(
    context: context,
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
              for (var i = 0;
                  i < options.length;
                  i++) ...[
                _LifeChoiceRow<T>(
                  option:
                      options[i],
                ),
                if (i !=
                    options.length -
                        1)
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
              ],
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
                      Text(
                    cancelLabel,
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

class _LifeChoiceRow<T>
    extends StatelessWidget {
  final LifeChoiceOption<T> option;

  const _LifeChoiceRow({
    required this.option,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final color =
        option.destructive
            ? colorScheme.error
            : colorScheme.onSurface;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            () {
          Navigator.pop(
            context,
            option.value,
          );
        },
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets
                  .symmetric(
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
                  option.icon,
                  size:
                      20,
                  color:
                      option.destructive
                          ? colorScheme.error
                          : colorScheme.primary,
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
                      option.title,
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
                    if (option.subtitle !=
                        null) ...[
                      const SizedBox(
                        height:
                            3,
                      ),
                      Text(
                        option.subtitle!,
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
                                  height:
                                      1.35,
                                ),
                      ),
                    ],
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
