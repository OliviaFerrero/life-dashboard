import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/screens/more_page.dart';
import 'package:life_hub/services/day_settings_controller.dart';
import 'package:life_hub/services/day_settings_store.dart';
import 'package:life_hub/widgets/editorial_time_picker.dart';

class _MemoryDaySettingsStore
    implements DaySettingsStore {
  StoredDaySettings? stored;

  @override
  Future<StoredDaySettings?> load() async {
    return stored;
  }

  @override
  Future<void> save({
    required int startMinutes,
    required int endMinutes,
  }) async {
    stored = StoredDaySettings(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
  }
}

Widget _app(
  Widget child,
) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets(
    'editorial time picker shows initial time and quick minute choices',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const EditorialTimePickerSheet(
            title: 'Ora prova',
            initialTime: TimeOfDay(
              hour: 9,
              minute: 15,
            ),
          ),
        ),
      );

      expect(
        find.text('Ora prova'),
        findsOneWidget,
      );
      expect(
        find.text('09:15'),
        findsOneWidget,
      );
      expect(
        find.text(':00'),
        findsOneWidget,
      );
      expect(
        find.text(':15'),
        findsOneWidget,
      );
      expect(
        find.text(':30'),
        findsOneWidget,
      );
      expect(
        find.text(':45'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'editorial time picker returns the chosen quick minute',
    (tester) async {
      TimeOfDay? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      result =
                          await showEditorialTimePicker(
                        context: context,
                        title: 'Ora prova',
                        initialTime:
                            const TimeOfDay(
                          hour: 9,
                          minute: 15,
                        ),
                      );
                    },
                    child: const Text(
                      'Apri',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.text('Apri'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(':30'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Conferma'),
      );
      await tester.pumpAndSettle();

      expect(
        result,
        const TimeOfDay(
          hour: 9,
          minute: 30,
        ),
      );
    },
  );

  testWidgets(
    'editorial time wheel values can be selected by tap',
    (tester) async {
      TimeOfDay? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      result =
                          await showEditorialTimePicker(
                        context:
                            context,
                        title:
                            'Ora prova',
                        initialTime:
                            const TimeOfDay(
                          hour:
                              9,
                          minute:
                              15,
                        ),
                      );
                    },
                    child:
                        const Text(
                      'Apri',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Apri',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey(
            'editorial_time_hour_10',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey(
            'editorial_time_minute_16',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(
          'Conferma',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        result,
        const TimeOfDay(
          hour:
              10,
          minute:
              16,
        ),
      );
    },
  );

  testWidgets(
    'MorePage uses the editorial picker for personal day settings',
    (tester) async {
      final store =
          _MemoryDaySettingsStore();

      final controller =
          DaySettingsController(
        store: store,
      );

      addTearDown(
        controller.dispose,
      );

      await tester.pumpWidget(
        _app(
          MorePage(
            daySettingsController:
                controller,
          ),
        ),
      );

      expect(
        find.text('GIORNATA PERSONALE'),
        findsOneWidget,
      );
      expect(
        find.text('06:00'),
        findsWidgets,
      );
      expect(
        find.text('03:00 · giorno dopo'),
        findsOneWidget,
      );

      await tester.tap(
        find.text('Inizio giornata'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(
          EditorialTimePickerSheet,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(
            EditorialTimePickerSheet,
          ),
          matching:
              find.text('Inizio giornata'),
        ),
        findsOneWidget,
      );
    },
  );
}
