import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FrostCoreService {
  static const String baseUrl = 'https://frostcore.onrender.com/api';

  // Save JWT token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get JWT token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Clear token on logout
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Helper for Authorization header
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
  }

  // --- Authentication ---

  // Google Sign-In (send Google uid, name, email; get user & token)
  static Future<Map<String, dynamic>> googleSignIn({
    required String uid,
    required String name,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google-signin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'name': name, 'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Save token locally
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception('Google Sign-In failed: ${response.body}');
    }
  }

  // Logout (optional backend endpoint, else just clear locally)
  static Future<void> logout() async {
    await clearToken();
    // If your backend supports logout endpoint, call it here.
  }

  // --- User info ---

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('$baseUrl/users/me');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  // --- Group info ---

  static Future<Map<String, dynamic>> getGroupInfo(String groupId) async {
    final url = Uri.parse('$baseUrl/groups/$groupId');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch group info');
    }
  }

  // --- Announcements ---

  static Future<List<Map<String, dynamic>>> getLatestAnnouncements(
      String groupId) async {
    final url =
        Uri.parse('$baseUrl/groups/$groupId/announcements?limit=10&order=desc');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  // --- Timetable ---

  static Future<List<Map<String, dynamic>>> getTimetable(
      String groupId, String day) async {
    final url = Uri.parse('$baseUrl/groups/$groupId/timetable?day=$day');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load timetable');
    }
  }

  // --- Group Chat ---

  static Future<List<Map<String, dynamic>>> getRecentChatMessages(
      String groupId,
      {int limit = 20}) async {
    final url =
        Uri.parse('$baseUrl/groups/$groupId/chat?limit=$limit&order=desc');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load chat messages');
    }
  }

  // --- Notes ---

  static Future<List<Map<String, dynamic>>> getNotes(String groupId) async {
    final url = Uri.parse('$baseUrl/groups/$groupId/notes');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load notes');
    }
  }
}
