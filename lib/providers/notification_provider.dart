import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';

class NotificationProvider extends ChangeNotifier {
  int _newDoubtsCount = 0;
  int get newDoubtsCount => _newDoubtsCount;

  static const _lastSeenKey = 'last_seen_doubt_id';

  /// Fetch new doubts count from FrostCore API
  Future<void> fetchNewDoubts(String groupId) async {
    try {
      final doubts = await FrostCoreAPI.getDoubts(groupId);

      final prefs = await SharedPreferences.getInstance();
      final lastSeenId = prefs.getString(_lastSeenKey);

      // Find all doubts newer than last seen
      if (lastSeenId != null && lastSeenId.isNotEmpty) {
        final index = doubts.indexWhere((d) => d['_id'] == lastSeenId);
        if (index > 0) {
          _newDoubtsCount = index; // count before last seen doubt
        } else if (index == -1) {
          // If last seen doubt not found, assume all are new
          _newDoubtsCount = doubts.length;
        } else {
          _newDoubtsCount = 0;
        }
      } else {
        _newDoubtsCount = doubts.length; // first time — all new
      }

      notifyListeners();
    } catch (e) {
      print('Error fetching new doubts count: $e');
    }
  }

  /// Mark all current doubts as seen
  Future<void> markAsSeen(String groupId) async {
    try {
      final doubts = await FrostCoreAPI.getDoubts(groupId);
      if (doubts.isNotEmpty) {
        final latestId = doubts.first['_id'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSeenKey, latestId);
      }
      _newDoubtsCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking doubts as seen: $e');
    }
  }
}
