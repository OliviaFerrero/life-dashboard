import 'package:flutter/widgets.dart';

typedef IdNowProvider = DateTime Function();

/// Generatore condiviso degli identificativi persistenti creati dall'app.
///
/// Mantiene il formato numerico basato sui microsecondi già usato dal progetto,
/// ma centralizza la sorgente e garantisce valori strettamente crescenti anche
/// quando più ID vengono richiesti nello stesso microsecondo.
///
/// Nei test è possibile iniettare un `nowProvider` deterministico.
class IdGenerator {
  final IdNowProvider _nowProvider;

  int? _lastMicroseconds;

  IdGenerator({
    IdNowProvider? nowProvider,
  }) : _nowProvider =
            nowProvider ??
            DateTime.now;

  String next() {
    final candidate =
        _nowProvider()
            .microsecondsSinceEpoch;

    final previous =
        _lastMicroseconds;

    final nextValue =
        previous == null ||
                candidate > previous
            ? candidate
            : previous + 1;

    _lastMicroseconds =
        nextValue;

    return nextValue.toString();
  }
}

/// Espone una sola istanza di [IdGenerator] all'intera app.
///
/// A differenza di un notifier, il generatore non produce rebuild: le schermate
/// lo leggono soltanto quando devono creare un nuovo identificativo persistente.
class IdGeneratorScope
    extends InheritedWidget {
  final IdGenerator generator;

  const IdGeneratorScope({
    super.key,
    required this.generator,
    required super.child,
  });

  static IdGenerator read(
    BuildContext context,
  ) {
    final scope =
        context
            .dependOnInheritedWidgetOfExactType<
                IdGeneratorScope>();

    assert(
      scope != null,
      'IdGeneratorScope non trovato nel widget tree.',
    );

    return scope!.generator;
  }

  @override
  bool updateShouldNotify(
    IdGeneratorScope oldWidget,
  ) {
    return !identical(
      generator,
      oldWidget.generator,
    );
  }
}
