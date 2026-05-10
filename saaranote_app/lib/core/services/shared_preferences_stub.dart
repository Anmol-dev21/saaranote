import 'dart:async';

class SharedPreferences {
  static final SharedPreferences _instance = SharedPreferences._internal();

  SharedPreferences._internal();

  static Future<SharedPreferences> getInstance() async => _instance;

  final Map<String, Object> _store = <String, Object>{};

  String? getString(String key) => _store[key] as String?;
  double? getDouble(String key) => _store[key] as double?;
  bool? getBool(String key) => _store[key] as bool?;

  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  Future<bool> setDouble(String key, double value) async {
    _store[key] = value;
    return true;
  }

  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }
}
