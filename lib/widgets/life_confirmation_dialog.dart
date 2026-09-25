import 'package:flutter/material.dart';

Future<bool> showLifeConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annulla',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chiudi',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 170),
    pageBuilder: (
      dialogContext,
      animation,
      secondaryAnimation,
    ) {
      return _LifeConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      );
    },
    transitionBuilder: (
      context,
      animation,
      secondaryAnimation,
      child,
    ) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.975,
            end: 1,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

  return result == true;
}

class _LifeConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  const _LifeConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent =
        destructive ? colorScheme.error : colorScheme.primary;

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: 0.55,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width:
                            34,
                        height:
                            34,
                        decoration:
                            BoxDecoration(
                          color:
                              accent.withValues(
                            alpha:
                                0.09,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child:
                            Icon(
                          icon,
                          size:
                              18,
                          color:
                              accent,
                        ),
                      ),
                      const SizedBox(
                        width:
                            12,
                      ),
                    ],
                    Expanded(
                      child:
                          Text(
                        title,
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
                                      -0.3,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.42,
                      ),
                ),
                const SizedBox(height: 22),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(
                    alpha: 0.48,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment:
                      Alignment.center,
                  child:
                      Wrap(
                    alignment:
                        WrapAlignment.center,
                    crossAxisAlignment:
                        WrapCrossAlignment.center,
                    spacing:
                        6,
                    runSpacing:
                        6,
                    children: [
                      _LifeDialogAction(
                        label:
                            cancelLabel,
                        onTap:
                            () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },
                      ),
                      _LifeDialogAction(
                        label:
                            confirmLabel,
                        accent:
                            accent,
                        emphasized:
                            true,
                        onTap:
                            () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },
                      ),
                    ],
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

class _LifeDialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool emphasized;

  const _LifeDialogAction({
    required this.label,
    required this.onTap,
    this.accent,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground =
        accent ?? colorScheme.onSurfaceVariant;

    return Material(
      color: emphasized
          ? foreground.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
