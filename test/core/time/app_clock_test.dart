import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/app_clock.dart';

void main() {
  test(
    'AppClock uses an injected now provider and refreshes deterministically',
    () {
      var fakeNow =
          DateTime(
        2026,
        9,
        24,
        16,
        30,
      );

      final clock =
          AppClock(
        nowProvider:
            () => fakeNow,
        autoStart:
            false,
      );

      addTearDown(
        clock.dispose,
      );

      expect(
        clock.now,
        fakeNow,
      );

      var notifications = 0;

      clock.addListener(
        () {
          notifications++;
        },
      );

      fakeNow =
          DateTime(
        2026,
        9,
        24,
        17,
        5,
      );

      clock.refresh();

      expect(
        clock.now,
        fakeNow,
      );

      expect(
        notifications,
        1,
      );

      clock.refresh();

      expect(
        notifications,
        1,
      );
    },
  );

  testWidgets(
    'AppClockScope rebuilds dependents after a clock refresh',
    (
      WidgetTester tester,
    ) async {
      var fakeNow =
          DateTime(
        2026,
        9,
        24,
        16,
        30,
      );

      final clock =
          AppClock(
        nowProvider:
            () => fakeNow,
        autoStart:
            false,
      );

      addTearDown(
        clock.dispose,
      );

      await tester.pumpWidget(
        AppClockScope(
          clock:
              clock,
          child:
              MaterialApp(
            home:
                Builder(
              builder:
                  (context) {
                final now =
                    AppClockScope.watch(
                  context,
                ).now;

                return Text(
                  '${now.hour}:'
                  '${now.minute}',
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.text(
          '16:30',
        ),
        findsOneWidget,
      );

      fakeNow =
          DateTime(
        2026,
        9,
        24,
        17,
        5,
      );

      clock.refresh();

      await tester.pump();

      expect(
        find.text(
          '17:5',
        ),
        findsOneWidget,
      );
    },
  );
}
