import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Get the saved user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      final userJson = prefs.getString('user');
      if (userJson != null) {
        try {
          final user = jsonDecode(userJson);
          userId = user['_id'] ?? user['id'];
          if (userId != null) await prefs.setString('userId', userId);
        } catch (e) {
          print('❌ Failed to extract userId: $e');
        }
      }
    }
    print('🔍 Final userId: $userId');
    return userId;
  }

  /// Get the saved auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get the full saved user object
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(userJson));
    } catch (e) {
      print('❌ Failed to decode user: $e');
      return null;
    }
  }

  /// Get the current user's groupId
  static Future<String?> getCurrentGroupId() async {
    final user = await getUser();
    final groupId = user?['groupId'];
    print('🔍 Current groupId: $groupId');
    return groupId;
  }

  /// Save auth token and user object
  static Future<void> saveAuthData(
      String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    // ✅ Ensure groupId exists in user object
    // IMPORTANT: Make sure the `user` object you pass includes the real groupId
    if (!user.containsKey('groupId') ||
        user['groupId'] == null ||
        user['groupId'].isEmpty) {
      user['groupId'] = '688e2d4b3f51ebc203e91dd8'; // default group
    }

    await prefs.setString('user', jsonEncode(user));

    final userId = user['_id'] ?? user['id'];
    if (userId != null) await prefs.setString('userId', userId);
  }

  /// Clear saved auth data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('userId');
  }
}
