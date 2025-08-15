import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeFormatProvider with ChangeNotifier {
  bool _is24Hour = false;
  bool get is24Hour => _is24Hour;

  TimeFormatProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _is24Hour = prefs.getBool('is24HourFormat') ?? false;
    notifyListeners();
  }

  Future<void> toggleFormat(bool value) async {
    _is24Hour = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is24HourFormat', value);
    notifyListeners();
  }
}
