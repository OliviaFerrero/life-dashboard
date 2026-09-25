import 'package:flutter/foundation.dart';

import '../core/time/civil_date.dart';
import 'day_settings_store.dart';

class DaySettingsController extends ChangeNotifier {
  final DaySettingsStore _store;

  factory DaySettingsController({
    required DaySettingsStore store,
  }) {
    return DaySettingsController._(
      store,
    );
  }

  DaySettingsController._(
    this._store,
  );

  static const int defaultStartMinutes = 6 * 60;
  static const int defaultEndMinutes = 3 * 60;

  int _startMinutes = defaultStartMinutes;
  int _endMinutes = defaultEndMinutes;
  bool _isLoaded = false;

  int get startMinutes => _startMinutes;
  int get endMinutes => _endMinutes;
  bool get isLoaded => _isLoaded;

  bool get endsOnNextCivilDay {
    return _endMinutes <= _startMinutes;
  }

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    try {
      final stored =
          await _store.load();

      final storedStart =
          stored?.startMinutes;
      final storedEnd =
          stored?.endMinutes;

      if (storedStart != null) {
        _startMinutes =
            _normalizeMinutes(
          storedStart,
        );
      }

      if (storedEnd != null) {
        _endMinutes =
            _normalizeMinutes(
          storedEnd,
        );
      }
    } catch (_) {
      // Se il file è mancante/corrotto, manteniamo i default locali.
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setStartMinutes(
    int minutes,
  ) async {
    final normalized = _normalizeMinutes(minutes);

    if (_startMinutes == normalized) {
      return;
    }

    _startMinutes = normalized;
    notifyListeners();

    await _save();
  }

  Future<void> setEndMinutes(
    int minutes,
  ) async {
    final normalized = _normalizeMinutes(minutes);

    if (_endMinutes == normalized) {
      return;
    }

    _endMinutes = normalized;
    notifyListeners();

    await _save();
  }

  Future<void> resetDefaults() async {
    _startMinutes = defaultStartMinutes;
    _endMinutes = defaultEndMinutes;

    notifyListeners();

    await _save();
  }

  DateTime personalDayStartFor(
    DateTime moment,
  ) {
    final civilDate =
        CivilDate.dateOnly(
      moment,
    );

    final currentMinutes =
        moment.hour * 60 + moment.minute;

    final anchorDate =
        currentMinutes < _startMinutes
            ? CivilDate.previousDay(
                civilDate,
              )
            : civilDate;

    return DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day,
      _startMinutes ~/ 60,
      _startMinutes % 60,
    );
  }

  DateTime configuredEndForStart(
    DateTime dayStart,
  ) {
    var end = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
      _endMinutes ~/ 60,
      _endMinutes % 60,
    );

    if (!end.isAfter(dayStart)) {
      final nextDay =
          CivilDate.nextDay(
        dayStart,
      );

      end = DateTime(
        nextDay.year,
        nextDay.month,
        nextDay.day,
        _endMinutes ~/ 60,
        _endMinutes % 60,
      );
    }

    return end;
  }

  DateTime nextPersonalDayStart(
    DateTime dayStart,
  ) {
    final nextDay =
        CivilDate.nextDay(
      dayStart,
    );

    return DateTime(
      nextDay.year,
      nextDay.month,
      nextDay.day,
      _startMinutes ~/ 60,
      _startMinutes % 60,
    );
  }

  int _normalizeMinutes(
    int value,
  ) {
    final normalized = value % (24 * 60);

    return normalized < 0
        ? normalized + 24 * 60
        : normalized;
  }

  Future<void> _save() async {
    try {
      await _store.save(
        startMinutes:
            _startMinutes,
        endMinutes:
            _endMinutes,
      );
    } catch (_) {
      // Le impostazioni restano valide per la sessione corrente anche
      // se il salvataggio locale dovesse fallire eccezionalmente.
    }
  }
}
