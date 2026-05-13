import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;
import 'shared_preferences_stub.dart' as stub;

class SettingsData {
  final ThemeMode themeMode;
  final double textScale;
  final bool offlineChatEnabled;
  final bool autoSummariesEnabled;
  final bool flashcardsEnabled;

  const SettingsData({
    required this.themeMode,
    required this.textScale,
    required this.offlineChatEnabled,
    required this.autoSummariesEnabled,
    required this.flashcardsEnabled,
  });
}

class SettingsService {
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _textScaleKey = 'settings_text_scale';
  static const String _offlineChatKey = 'settings_offline_chat';
  static const String _autoSummariesKey = 'settings_auto_summaries';
  static const String _flashcardsKey = 'settings_flashcards';

  Future<SettingsData> load() async {
    final prefsStore = await _getPrefs();

    final themeName =
        prefsStore.getString(_themeModeKey) ?? ThemeMode.system.name;
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
    final textScale = prefsStore.getDouble(_textScaleKey) ?? 1.0;

    return SettingsData(
      themeMode: themeMode,
      textScale: textScale,
      offlineChatEnabled: prefsStore.getBool(_offlineChatKey) ?? true,
      autoSummariesEnabled: prefsStore.getBool(_autoSummariesKey) ?? true,
      flashcardsEnabled: prefsStore.getBool(_flashcardsKey) ?? true,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefsStore = await _getPrefs();
    await prefsStore.setString(_themeModeKey, mode.name);
  }

  Future<void> saveTextScale(double scale) async {
    final prefsStore = await _getPrefs();
    await prefsStore.setDouble(_textScaleKey, scale);
  }

  Future<void> saveOfflineChatEnabled(bool value) async {
    final prefsStore = await _getPrefs();
    await prefsStore.setBool(_offlineChatKey, value);
  }

  Future<void> saveAutoSummariesEnabled(bool value) async {
    final prefsStore = await _getPrefs();
    await prefsStore.setBool(_autoSummariesKey, value);
  }

  Future<void> saveFlashcardsEnabled(bool value) async {
    final prefsStore = await _getPrefs();
    await prefsStore.setBool(_flashcardsKey, value);
  }

  Future<_PrefsStore> _getPrefs() async {
    try {
      final instance = await prefs.SharedPreferences.getInstance();
      return _PrefsStore.real(instance);
    } on MissingPluginException {
      final instance = await stub.SharedPreferences.getInstance();
      return _PrefsStore.stub(instance);
    } catch (_) {
      final instance = await stub.SharedPreferences.getInstance();
      return _PrefsStore.stub(instance);
    }
  }
}

class _PrefsStore {
  final prefs.SharedPreferences? _real;
  final stub.SharedPreferences? _stub;

  const _PrefsStore.real(this._real) : _stub = null;
  const _PrefsStore.stub(this._stub) : _real = null;

  String? getString(String key) => _real?.getString(key) ?? _stub?.getString(key);
  double? getDouble(String key) => _real?.getDouble(key) ?? _stub?.getDouble(key);
  bool? getBool(String key) => _real?.getBool(key) ?? _stub?.getBool(key);

  Future<bool> setString(String key, String value) {
    return _real?.setString(key, value) ?? _stub!.setString(key, value);
  }

  Future<bool> setDouble(String key, double value) {
    return _real?.setDouble(key, value) ?? _stub!.setDouble(key, value);
  }

  Future<bool> setBool(String key, bool value) {
    return _real?.setBool(key, value) ?? _stub!.setBool(key, value);
  }
}
