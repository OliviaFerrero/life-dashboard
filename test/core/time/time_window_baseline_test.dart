import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/civil_date.dart';
import 'package:life_hub/services/day_settings_controller.dart';
import 'package:life_hub/services/day_settings_store.dart';

class _NoopSettingsStore implements DaySettingsStore {
  @override
  Future<StoredDaySettings?> load() async => null;

  @override
  Future<void> save({
    required int startMinutes,
    required int endMinutes,
  }) async {}
}

void main() {
  test('civil-day arithmetic crosses leap years and DST dates', () {
    expect(CivilDate.nextDay(DateTime(2028, 2, 28)), DateTime(2028, 2, 29));
    expect(CivilDate.nextDay(DateTime(2026, 3, 29)), DateTime(2026, 3, 30));
    expect(CivilDate.nextDay(DateTime(2026, 10, 25)), DateTime(2026, 10, 26));
    expect(
      CivilDate.differenceInDays(
        DateTime(2026, 3, 28, 23, 45),
        DateTime(2026, 3, 30, 0, 15),
      ),
      2,
    );
  });

  test('personal-day end is based on next civil date, not 24 hours', () {
    final controller = DaySettingsController(store: _NoopSettingsStore());
    addTearDown(controller.dispose);

    final springStart = DateTime(2026, 3, 28, 6);
    final autumnStart = DateTime(2026, 10, 24, 6);

    expect(
      controller.configuredEndForStart(springStart),
      DateTime(2026, 3, 29, 3),
    );
    expect(
      controller.nextPersonalDayStart(springStart),
      DateTime(2026, 3, 29, 6),
    );
    expect(
      controller.configuredEndForStart(autumnStart),
      DateTime(2026, 10, 25, 3),
    );
    expect(
      controller.nextPersonalDayStart(autumnStart),
      DateTime(2026, 10, 25, 6),
    );
  });

  test('personal-day anchor stays on previous date before 06:00', () {
    final controller = DaySettingsController(store: _NoopSettingsStore());
    addTearDown(controller.dispose);

    expect(
      controller.personalDayStartFor(DateTime(2026, 3, 29, 4, 30)),
      DateTime(2026, 3, 28, 6),
    );
    expect(
      controller.personalDayStartFor(DateTime(2026, 3, 29, 6)),
      DateTime(2026, 3, 29, 6),
    );
    expect(
      controller.personalDayStartFor(DateTime(2026, 10, 25, 4, 30)),
      DateTime(2026, 10, 24, 6),
    );
  });

  test('Italian spring/fall personal days have real 20h/22h lengths', () {
    // The duration assertion is meaningful only when the host timezone
    // actually follows the Italian 2026 DST transitions.
    final springStart = DateTime(2026, 3, 28, 6);
    final springEnd = DateTime(2026, 3, 29, 3);
    final autumnStart = DateTime(2026, 10, 24, 6);
    final autumnEnd = DateTime(2026, 10, 25, 3);
    final isItalianDst =
        springStart.timeZoneOffset == const Duration(hours: 1) &&
        springEnd.timeZoneOffset == const Duration(hours: 2) &&
        autumnStart.timeZoneOffset == const Duration(hours: 2) &&
        autumnEnd.timeZoneOffset == const Duration(hours: 1);

    if (!isItalianDst) {
      return;
    }

    expect(springEnd.difference(springStart), const Duration(hours: 20));
    expect(autumnEnd.difference(autumnStart), const Duration(hours: 22));
  });
}
