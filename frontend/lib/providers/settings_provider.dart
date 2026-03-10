import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _serverUrl = 'http://192.168.1.100:3000'; // Default CasaOS IP format
  String _languageCode = 'en';
  List<String> _customCategories = [];
  SharedPreferences? _prefs;
  bool _isLoading = true;

  String get serverUrl => _serverUrl;
  String get languageCode => _languageCode;
  List<String> get customCategories => _customCategories;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _serverUrl = _prefs?.getString('serverUrl') ?? 'http://192.168.1.100:3000';
    _languageCode = _prefs?.getString('languageCode') ?? 'en';
    _customCategories = _prefs?.getStringList('customCategories') ?? [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    if (_prefs != null) {
      await _prefs!.setString('serverUrl', url);
    }
    notifyListeners();
  }
  
  Future<void> setLanguage(String code) async {
    _languageCode = code;
    if (_prefs != null) {
      await _prefs!.setString('languageCode', code);
    }
    notifyListeners();
  }
  
  Future<void> setCustomCategories(List<String> categories) async {
    _customCategories = categories.where((c) => c.trim().isNotEmpty).toList();
    if (_prefs != null) {
      await _prefs!.setStringList('customCategories', _customCategories);
    }
    notifyListeners();
  }
}
