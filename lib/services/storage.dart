import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BreezeStorage {
  factory BreezeStorage() {
    return _instance;
  }

  BreezeStorage._internal();

  static final BreezeStorage _instance = BreezeStorage._internal();

  SharedPreferences? _prefs;

  static const String aiBackendKey = 'aiBackend';
  static const String aiModelKey = 'aiModel';
  static const String actionDelayKey = 'actionDelay';
  static const String searchEngineKey = 'searchEngine';
  static const String _userDataItemsKey = 'userDataItems';
  static const String privacyModeKey = 'privacyMode';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _setDefaultValues();
  }

  Future<void> _setDefaultValues() async {
    if (!_prefs!.containsKey(aiBackendKey)) {
      await _prefs!.setString(aiBackendKey, 'OpenAI');
    }
    if (!_prefs!.containsKey(aiModelKey)) {
      await _prefs!.setString(aiModelKey, 'gpt-4o-mini');
    }
    if (!_prefs!.containsKey(actionDelayKey)) {
      await _prefs!.setDouble(actionDelayKey, 2.0);
    }
    if (!_prefs!.containsKey(searchEngineKey)) {
      await _prefs!.setString(searchEngineKey, 'DuckDuckGo');
    }
    if (!_prefs!.containsKey(_userDataItemsKey)) {
      await _prefs!.setString(_userDataItemsKey, jsonEncode({}));
    }
    if (!_prefs!.containsKey(privacyModeKey)) {
      await _prefs!.setBool(privacyModeKey, false); // Off by default
    }
  }

  // Generic getters
  String getString(final String key) => _prefs!.getString(key)!;
  double getDouble(final String key) => _prefs!.getDouble(key)!;
  bool getBool(final String key) => _prefs!.getBool(key)!;

  // Generic setters
  Future<void> setString(final String key, final String value) async {
    await _prefs!.setString(key, value);
  }

  Future<void> setDouble(final String key, final double value) async {
    await _prefs!.setDouble(key, value);
  }

  Future<void> setBool(final String key, final bool value) async {
    await _prefs!.setBool(key, value);
  }

  Map<String, String> get userDataItems {
    final data = _prefs!.getString(_userDataItemsKey);
    return Map<String, String>.from(jsonDecode(data!));
  }

  Future<void> _setAllUserDataItems(final Map<String, String> items) async {
    await _prefs!.setString(_userDataItemsKey, jsonEncode(items));
  }

  Future<void> deleteUserDataItem(final String key) async {
    final currentItems = userDataItems;
    currentItems.remove(key);
    await _setAllUserDataItems(currentItems);
  }

  Future<void> updateUserDataItems(final Map<String, String> newItems) async {
    final currentItems = userDataItems;
    currentItems.addAll(newItems);
    await _setAllUserDataItems(currentItems);
  }

  Future<void> setUserDataItem(final String key, final String value) async {
    final currentItems = userDataItems;
    currentItems[key] = value;
    await _setAllUserDataItems(currentItems);
  }
}
