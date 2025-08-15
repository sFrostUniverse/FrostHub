import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _timeFormatKey = 'time_format_24h'; // true = 24h, false = 12h
  bool _is24HourFormat = true;

  bool get is24HourFormat => _is24HourFormat;

  SettingsProvider() {
    _loadTimeFormat();
  }

  Future<void> _loadTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    _is24HourFormat = prefs.getBool(_timeFormatKey) ?? true;
    notifyListeners();
  }

  Future<void> setTimeFormat(bool is24h) async {
    _is24HourFormat = is24h;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timeFormatKey, is24h);
    notifyListeners();
  }
}
