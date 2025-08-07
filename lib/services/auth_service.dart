import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    // If userId is null, attempt to extract from user object
    if (userId == null) {
      final userJson = prefs.getString('user');
      if (userJson != null) {
        try {
          final user = jsonDecode(userJson);
          userId = user['_id'] ?? user['id'];
          if (userId != null) {
            await prefs.setString('userId', userId); // Cache it again
          }
        } catch (e) {
          print('❌ Failed to extract userId from userJson: $e');
        }
      }
    }

    print('🔍 Final userId: $userId');
    return userId;
  }

  static Future<void> saveAuthData(
      String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));

    final userId = user['_id'] ?? user['id'];
    if (userId != null) {
      await prefs.setString('userId', userId);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    print('🔐 Stored userId: ${prefs.getString('userId')}');
    return prefs.getString('token');
  }

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

  static Future<String?> getCurrentGroupId() async {
    final user = await getUser();
    return user?['groupId'];
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
