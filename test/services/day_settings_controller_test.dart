import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/services/day_settings_controller.dart';
import 'package:life_hub/services/day_settings_store.dart';

class _FakeDaySettingsStore
    implements DaySettingsStore {
  StoredDaySettings? loaded;
  Object? loadError;
  Object? saveError;

  int saveCalls = 0;
  int? savedStart;
  int? savedEnd;

  @override
  Future<StoredDaySettings?> load() async {
    final error = loadError;

    if (error != null) {
      throw error;
    }

    return loaded;
  }

  @override
  Future<void> save({
    required int startMinutes,
    required int endMinutes,
  }) async {
    final error = saveError;

    if (error != null) {
      throw error;
    }

    saveCalls += 1;
    savedStart = startMinutes;
    savedEnd = endMinutes;
  }
}

void main() {
  test(
    'load reads persisted settings and normalizes minute values',
    () async {
      final store =
          _FakeDaySettingsStore()
            ..loaded =
                const StoredDaySettings(
              startMinutes:
                  25 * 60,
              endMinutes:
                  -60,
            );

      final controller =
          DaySettingsController(
        store:
            store,
      );

      addTearDown(
        controller.dispose,
      );

      await controller.load();

      expect(
        controller.startMinutes,
        60,
      );
      expect(
        controller.endMinutes,
        23 * 60,
      );
      expect(
        controller.isLoaded,
        isTrue,
      );
    },
  );

  test(
    'load failure keeps defaults and still marks controller loaded',
    () async {
      final store =
          _FakeDaySettingsStore()
            ..loadError =
                StateError(
              'boom',
            );

      final controller =
          DaySettingsController(
        store:
            store,
      );

      addTearDown(
        controller.dispose,
      );

      await controller.load();

      expect(
        controller.startMinutes,
        DaySettingsController
            .defaultStartMinutes,
      );
      expect(
        controller.endMinutes,
        DaySettingsController
            .defaultEndMinutes,
      );
      expect(
        controller.isLoaded,
        isTrue,
      );
    },
  );

  test(
    'setting values persists normalized settings',
    () async {
      final store =
          _FakeDaySettingsStore();

      final controller =
          DaySettingsController(
        store:
            store,
      );

      addTearDown(
        controller.dispose,
      );

      await controller.setStartMinutes(
        26 * 60 + 15,
      );

      expect(
        controller.startMinutes,
        2 * 60 + 15,
      );
      expect(
        store.savedStart,
        2 * 60 + 15,
      );
      expect(
        store.savedEnd,
        DaySettingsController
            .defaultEndMinutes,
      );
    },
  );

  test(
    'personal day before configured start belongs to previous civil day',
    () {
      final controller =
          DaySettingsController(
        store:
            _FakeDaySettingsStore(),
      );

      addTearDown(
        controller.dispose,
      );

      final result =
          controller.personalDayStartFor(
        DateTime(
          2026,
          9,
          25,
          2,
          30,
        ),
      );

      expect(
        result,
        DateTime(
          2026,
          9,
          24,
          6,
        ),
      );
    },
  );

  test(
    'configured end moves to next civil day when needed',
    () {
      final controller =
          DaySettingsController(
        store:
            _FakeDaySettingsStore(),
      );

      addTearDown(
        controller.dispose,
      );

      final result =
          controller.configuredEndForStart(
        DateTime(
          2026,
          9,
          25,
          6,
        ),
      );

      expect(
        result,
        DateTime(
          2026,
          9,
          26,
          3,
        ),
      );
    },
  );

  test(
    'reset restores defaults and persists them',
    () async {
      final store =
          _FakeDaySettingsStore();

      final controller =
          DaySettingsController(
        store:
            store,
      );

      addTearDown(
        controller.dispose,
      );

      await controller.setStartMinutes(
        8 * 60,
      );
      await controller.setEndMinutes(
        1 * 60,
      );

      await controller.resetDefaults();

      expect(
        controller.startMinutes,
        DaySettingsController
            .defaultStartMinutes,
      );
      expect(
        controller.endMinutes,
        DaySettingsController
            .defaultEndMinutes,
      );
      expect(
        store.savedStart,
        DaySettingsController
            .defaultStartMinutes,
      );
      expect(
        store.savedEnd,
        DaySettingsController
            .defaultEndMinutes,
      );
    },
  );
}
