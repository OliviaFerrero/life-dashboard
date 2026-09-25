import 'package:flutter/material.dart';

import '../../models/task_category.dart';
import '../../utils/task_category_icons.dart';

class TaskCategorySettingRow
    extends StatelessWidget {
  final TaskCategory? category;
  final String? statusLabel;
  final VoidCallback? onTap;

  const TaskCategorySettingRow({
    super.key,
    this.category,
    this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final categoryColor =
        category == null
            ? colorScheme
                .onSurfaceVariant
            : Color(
                category!.colorValue,
              );

    final label =
        statusLabel ??
            category?.name ??
            'Nessuna categoria';

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
              const EdgeInsets
                  .symmetric(
            vertical: 12,
          ),

          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration:
                    BoxDecoration(
                  color:
                      categoryColor
                          .withValues(
                    alpha: 0.11,
                  ),
                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  category == null
                      ? Icons
                          .remove_circle_outline
                      : taskCategoryIcon(
                          category!
                              .iconKey,
                        ),
                  size: 18,
                  color:
                      categoryColor,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                statusLabel !=
                                        null
                                    ? colorScheme
                                        .onSurfaceVariant
                                    : null,
                          ),
                ),
              ),

              if (onTap != null)
                Icon(
                  Icons
                      .chevron_right,
                  size: 19,
                  color:
                      colorScheme
                          .onSurfaceVariant
                          .withValues(
                    alpha: 0.65,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

