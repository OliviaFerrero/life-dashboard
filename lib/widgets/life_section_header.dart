import 'package:flutter/material.dart';

class LifeSectionHeader
    extends StatelessWidget {
  final String title;
  final String? value;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LifeSectionHeader({
    super.key,
    required this.title,
    this.value,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing:
                          -0.3,
                    ),
          ),
        ),

        if (value != null) ...[
          Text(
            value!,
            style:
                Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant,
                      fontWeight:
                          FontWeight.w600,
                    ),
          ),

          const SizedBox(
            width: 10,
          ),
        ],

        if (actionLabel != null &&
            onAction != null)
          TextButton(
            onPressed: onAction,
            style:
                TextButton.styleFrom(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 6,
              ),
              minimumSize:
                  const Size(
                0,
                40,
              ),
            ),
            child: Text(
              actionLabel!,
            ),
          ),
      ],
    );
  }
}