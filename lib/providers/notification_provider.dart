import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';

class NotificationProvider extends ChangeNotifier {
  int _newDoubtsCount = 0;
  int get newDoubtsCount => _newDoubtsCount;

  /// Fetch new doubts count from FrostCore API
  Future<void> fetchNewDoubts(String groupId) async {
    try {
      final count = await FrostCoreAPI.getNewDoubtsCount(groupId: groupId);
      _newDoubtsCount = count;
      notifyListeners();
    } catch (e) {
      print('Error fetching new doubts count: $e');
    }
  }

  /// Reset badge when user views doubts
  void reset() {
    _newDoubtsCount = 0;
    notifyListeners();
  }
}
