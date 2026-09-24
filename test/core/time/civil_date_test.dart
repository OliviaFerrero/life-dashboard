import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/civil_date.dart';

void main() {
  test(
    'dateOnly removes the clock portion',
    () {
      expect(
        CivilDate.dateOnly(
          DateTime(
            2026,
            9,
            24,
            18,
            42,
            17,
          ),
        ),
        DateTime(
          2026,
          9,
          24,
        ),
      );
    },
  );

  test(
    'addDays follows civil calendar boundaries',
    () {
      expect(
        CivilDate.addDays(
          DateTime(
            2028,
            2,
            28,
          ),
          1,
        ),
        DateTime(
          2028,
          2,
          29,
        ),
      );

      expect(
        CivilDate.addDays(
          DateTime(
            2026,
            12,
            31,
          ),
          1,
        ),
        DateTime(
          2027,
          1,
          1,
        ),
      );

      expect(
        CivilDate.addDays(
          DateTime(
            2026,
            1,
            1,
          ),
          -1,
        ),
        DateTime(
          2025,
          12,
          31,
        ),
      );
    },
  );

  test(
    'differenceInDays compares civil dates instead of clock duration',
    () {
      expect(
        CivilDate.differenceInDays(
          DateTime(
            2026,
            3,
            28,
            23,
            55,
          ),
          DateTime(
            2026,
            3,
            29,
            0,
            5,
          ),
        ),
        1,
      );

      expect(
        CivilDate.differenceInDays(
          DateTime(
            2026,
            3,
            29,
            23,
          ),
          DateTime(
            2026,
            3,
            29,
            1,
          ),
        ),
        0,
      );

      expect(
        CivilDate.differenceInDays(
          DateTime(
            2026,
            4,
            1,
          ),
          DateTime(
            2026,
            3,
            31,
          ),
        ),
        -1,
      );
    },
  );

  test(
    'startOfWeek uses Monday and crosses month boundaries safely',
    () {
      expect(
        CivilDate.startOfWeek(
          DateTime(
            2026,
            10,
            1,
          ),
        ),
        DateTime(
          2026,
          9,
          28,
        ),
      );

      expect(
        CivilDate.startOfWeek(
          DateTime(
            2026,
            10,
            4,
          ),
        ),
        DateTime(
          2026,
          9,
          28,
        ),
      );
    },
  );
}
