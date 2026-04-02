import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _settingsService;

  bool _isLoaded = false;
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  bool _offlineChatEnabled = true;
  bool _autoSummariesEnabled = true;
  bool _flashcardsEnabled = true;
  String? _errorMessage;

  SettingsViewModel(this._settingsService);

  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  bool get offlineChatEnabled => _offlineChatEnabled;
  bool get autoSummariesEnabled => _autoSummariesEnabled;
  bool get flashcardsEnabled => _flashcardsEnabled;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final data = await _settingsService.load();
      _themeMode = data.themeMode;
      _textScale = data.textScale;
      _offlineChatEnabled = data.offlineChatEnabled;
      _autoSummariesEnabled = data.autoSummariesEnabled;
      _flashcardsEnabled = data.flashcardsEnabled;
      _isLoaded = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load settings: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _settingsService.saveThemeMode(mode);
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    await _settingsService.saveTextScale(scale);
  }

  Future<void> setOfflineChatEnabled(bool value) async {
    _offlineChatEnabled = value;
    notifyListeners();
    await _settingsService.saveOfflineChatEnabled(value);
  }

  Future<void> setAutoSummariesEnabled(bool value) async {
    _autoSummariesEnabled = value;
    notifyListeners();
    await _settingsService.saveAutoSummariesEnabled(value);
  }

  Future<void> setFlashcardsEnabled(bool value) async {
    _flashcardsEnabled = value;
    notifyListeners();
    await _settingsService.saveFlashcardsEnabled(value);
  }
}
