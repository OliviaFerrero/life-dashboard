import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/id/id_generator.dart';

void main() {
  test(
    'next is deterministic and strictly increasing for the same instant',
    () {
      final fixedNow =
          DateTime.fromMicrosecondsSinceEpoch(
        1000,
      );

      final generator =
          IdGenerator(
        nowProvider:
            () => fixedNow,
      );

      expect(
        generator.next(),
        '1000',
      );
      expect(
        generator.next(),
        '1001',
      );
      expect(
        generator.next(),
        '1002',
      );
    },
  );

  test(
    'next remains increasing when the clock does not move forward',
    () {
      final values =
          <int>[
        1000,
        2000,
        1500,
      ];

      var index = 0;

      final generator =
          IdGenerator(
        nowProvider:
            () => DateTime
                .fromMicrosecondsSinceEpoch(
          values[index++],
        ),
      );

      expect(
        generator.next(),
        '1000',
      );
      expect(
        generator.next(),
        '2000',
      );
      expect(
        generator.next(),
        '2001',
      );
    },
  );

  testWidgets(
    'IdGeneratorScope exposes the same shared generator instance',
    (tester) async {
      final generator =
          IdGenerator(
        nowProvider:
            () => DateTime
                .fromMicrosecondsSinceEpoch(
          5000,
        ),
      );

      IdGenerator? resolved;

      await tester.pumpWidget(
        IdGeneratorScope(
          generator:
              generator,
          child:
              Builder(
            builder: (context) {
              resolved =
                  IdGeneratorScope.read(
                context,
              );

              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        identical(
          resolved,
          generator,
        ),
        isTrue,
      );
    },
  );
}
