import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _serverUrl = 'http://192.168.1.100:3000'; // Default CasaOS IP format
  SharedPreferences? _prefs;

  String get serverUrl => _serverUrl;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _serverUrl = _prefs?.getString('serverUrl') ?? 'http://192.168.1.100:3000';
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    if (_prefs != null) {
      await _prefs!.setString('serverUrl', url);
    }
    notifyListeners();
  }
}
