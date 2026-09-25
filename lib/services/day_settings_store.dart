import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class StoredDaySettings {
  final int? startMinutes;
  final int? endMinutes;

  const StoredDaySettings({
    required this.startMinutes,
    required this.endMinutes,
  });
}

abstract interface class DaySettingsStore {
  Future<StoredDaySettings?> load();

  Future<void> save({
    required int startMinutes,
    required int endMinutes,
  });
}

class JsonDaySettingsStore
    implements DaySettingsStore {
  const JsonDaySettingsStore();

  @override
  Future<StoredDaySettings?> load() async {
    final file = await _settingsFile();

    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final storedStart =
        decoded['dayStartMinutes'];
    final storedEnd =
        decoded['dayEndMinutes'];

    return StoredDaySettings(
      startMinutes:
          storedStart is int
              ? storedStart
              : null,
      endMinutes:
          storedEnd is int
              ? storedEnd
              : null,
    );
  }

  @override
  Future<void> save({
    required int startMinutes,
    required int endMinutes,
  }) async {
    final file = await _settingsFile();

    await file.writeAsString(
      jsonEncode(
        {
          'dayStartMinutes':
              startMinutes,
          'dayEndMinutes':
              endMinutes,
        },
      ),
      flush: true,
    );
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
}
