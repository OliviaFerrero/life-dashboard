import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/clock_format.dart';

void main() {
  test(
    'formatClockMinutes formats and normalizes a 24-hour clock',
    () {
      expect(
        formatClockMinutes(
          6 * 60 + 5,
        ),
        '06:05',
      );

      expect(
        formatClockMinutes(
          25 * 60,
        ),
        '01:00',
      );

      expect(
        formatClockMinutes(
          -30,
        ),
        '23:30',
      );
    },
  );
}
