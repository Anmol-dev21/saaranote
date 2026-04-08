import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString(_themeModeKey) ?? ThemeMode.system.name;
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
    final textScale = prefs.getDouble(_textScaleKey) ?? 1.0;

    return SettingsData(
      themeMode: themeMode,
      textScale: textScale,
      offlineChatEnabled: prefs.getBool(_offlineChatKey) ?? true,
      autoSummariesEnabled: prefs.getBool(_autoSummariesKey) ?? true,
      flashcardsEnabled: prefs.getBool(_flashcardsKey) ?? true,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> saveTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
  }

  Future<void> saveOfflineChatEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineChatKey, value);
  }

  Future<void> saveAutoSummariesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSummariesKey, value);
  }

  Future<void> saveFlashcardsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flashcardsKey, value);
  }
}
