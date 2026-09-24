import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/time/civil_date.dart';

class DaySettingsController extends ChangeNotifier {
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
      final file = await _settingsFile();

      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          final storedStart = decoded['dayStartMinutes'];
          final storedEnd = decoded['dayEndMinutes'];

          if (storedStart is int) {
            _startMinutes = _normalizeMinutes(storedStart);
          }

          if (storedEnd is int) {
            _endMinutes = _normalizeMinutes(storedEnd);
          }
        }
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

  String formatMinutes(
    int minutes,
  ) {
    final normalized = _normalizeMinutes(minutes);
    final hour =
        (normalized ~/ 60).toString().padLeft(2, '0');
    final minute =
        (normalized % 60).toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  int _normalizeMinutes(
    int value,
  ) {
    final normalized = value % (24 * 60);

    return normalized < 0
        ? normalized + 24 * 60
        : normalized;
  }

  Future<File> _settingsFile() async {
    final directory =
        await getApplicationSupportDirectory();

    return File(
      path.join(
        directory.path,
        'life_dashboard_settings.json',
      ),
    );
  }

  Future<void> _save() async {
    try {
      final file = await _settingsFile();

      await file.writeAsString(
        jsonEncode(
          {
            'dayStartMinutes': _startMinutes,
            'dayEndMinutes': _endMinutes,
          },
        ),
        flush: true,
      );
    } catch (_) {
      // Le impostazioni restano valide per la sessione corrente anche
      // se il salvataggio locale dovesse fallire eccezionalmente.
    }
  }
}
