String formatClockMinutes(
  int minutes,
) {
  final normalized =
      _normalizeClockMinutes(
    minutes,
  );

  final hour =
      (normalized ~/ 60)
          .toString()
          .padLeft(
            2,
            '0',
          );

  final minute =
      (normalized % 60)
          .toString()
          .padLeft(
            2,
            '0',
          );

  return '$hour:$minute';
}

int _normalizeClockMinutes(
  int value,
) {
  final normalized =
      value % (24 * 60);

  return normalized < 0
      ? normalized + 24 * 60
      : normalized;
}
