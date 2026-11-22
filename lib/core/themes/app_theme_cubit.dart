import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/async_serial_queue.dart';

abstract interface class ThemePreference {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalThemePreference implements ThemePreference {
  final SharedPreferencesAsync preferences;
  LocalThemePreference({SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();
  static const key = 'bepxinh.appearance.v1';
  @override
  Future<String?> read() => preferences.getString(key);
  @override
  Future<void> write(String value) => preferences.setString(key, value);
}

class AppThemeCubit extends Cubit<ThemeMode> {
  final ThemePreference preference;
  final _writes = AsyncSerialQueue();
  int _revision = 0;
  AppThemeCubit(this.preference) : super(ThemeMode.system);
  Future<void> load() async {
    final revision = _revision;
    try {
      final saved = await preference.read();
      if (!isClosed && revision == _revision) {
        emit(
          ThemeMode.values.firstWhere(
            (mode) => mode.name == saved,
            orElse: () => ThemeMode.system,
          ),
        );
      }
    } catch (_) {
      /* Không chặn mở app khi thiết bị không đọc được tùy chọn giao diện. */
    }
  }

  Future<bool> select(ThemeMode mode) async {
    ++_revision;
    if (isClosed) return false;
    emit(mode);
    try {
      await _writes.run(() => preference.write(mode.name));
      return true;
    } catch (_) {
      return false;
    }
  }
}
