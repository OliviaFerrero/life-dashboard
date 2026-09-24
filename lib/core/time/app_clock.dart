import 'dart:async';

import 'package:flutter/widgets.dart';

typedef AppNowProvider = DateTime Function();

/// Unica sorgente del tempo "corrente" per l'interfaccia.
///
/// In produzione usa DateTime.now() e pubblica un tick ogni 30 secondi.
/// Nei test può ricevere un nowProvider controllabile e non avviare timer.
class AppClock extends ChangeNotifier {
  final AppNowProvider _nowProvider;
  final Duration _tickInterval;

  Timer? _timer;
  late DateTime _now;

  AppClock({
    AppNowProvider? nowProvider,
    Duration tickInterval =
        const Duration(
      seconds: 30,
    ),
    bool autoStart = true,
  })  : _nowProvider =
            nowProvider ??
                DateTime.now,
        _tickInterval =
            tickInterval {
    assert(
      tickInterval >
          Duration.zero,
    );

    _now =
        _nowProvider();

    if (autoStart) {
      _timer =
          Timer.periodic(
        _tickInterval,
        (_) {
          refresh();
        },
      );
    }
  }

  DateTime get now => _now;

  void refresh() {
    final next =
        _nowProvider();

    if (next == _now) {
      return;
    }

    _now = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// Rende [AppClock] disponibile all'intero albero senza introdurre
/// una libreria esterna di state management.
class AppClockScope
    extends InheritedNotifier<AppClock> {
  const AppClockScope({
    super.key,
    required AppClock clock,
    required super.child,
  }) : super(
          notifier: clock,
        );

  static AppClock watch(
    BuildContext context,
  ) {
    final scope =
        context
            .dependOnInheritedWidgetOfExactType<
                AppClockScope>();

    assert(
      scope != null,
      'AppClockScope non trovato sopra questo widget.',
    );

    return scope!.notifier!;
  }

  static AppClock read(
    BuildContext context,
  ) {
    final element =
        context
            .getElementForInheritedWidgetOfExactType<
                AppClockScope>();

    final scope =
        element?.widget
            as AppClockScope?;

    assert(
      scope != null,
      'AppClockScope non trovato sopra questo widget.',
    );

    return scope!.notifier!;
  }
}
