import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frosthub/services/auth_service.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // gives you XFile
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:mime/mime.dart';

const String timetableCacheBox = 'timetable_cache';
const String announcementsCacheBox = 'announcements_cache';
const String notesCacheBox = 'notes_cache';

class FrostCoreAPI {
  static const String baseUrl = 'https://frostcore.onrender.com';

// Replace getToken() with:
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // Use hardcoded JWT if token is null
    return token ??
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4OGZjNTMwNWUxYTc0NGNiNmYxOWE4MCIsImVtYWlsIjoiZnJvc3R5eXVuaXZlcnNlQGdtYWlsLmNvbSIsImlhdCI6MTc1NTA3ODI4NCwiZXhwIjoxNzU1NjgzMDg0fQ.-rmNCX9Ue6eWMfcz6A_UDIaI7rvPMPDSUElZ4b10sZ4";
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> googleSignIn({
    required String uid,
    required String name,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/google-signin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'name': name, 'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sign in with Google: ${response.body}');
    }
  }

  // Email Signup (if needed)
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  // Email Login (if needed)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createGroup(
      String groupName, String token) async {
    final url = Uri.parse('$baseUrl/api/groups/create');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'groupName': groupName}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create group: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> joinGroup(
      String groupCode, String token) async {
    final url = Uri.parse('$baseUrl/api/groups/join');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'groupCode': groupCode}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to join group: ${response.body}');
    }
  }

  // Add announcement
  static Future<void> postAnnouncement({
    required String token,
    required String groupId,
    required String title,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/api/announcements');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'groupId': groupId,
        'title': title,
        'message': message,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to post announcement: ${response.body}');
    }

    // ✅ Invalidate using groupId directly
    await Hive.box(announcementsCacheBox).delete('announcements_$groupId');
  }

  static Future<void> deleteAnnouncement({
    required String token,
    required String announcementId,
    required String groupId,
  }) async {
    final url = Uri.parse('$baseUrl/api/announcements/$announcementId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete announcement: ${response.body}');
    }

    // 🧹 Invalidate cache
    await Hive.box(announcementsCacheBox).delete('announcements_$groupId');
  }

// Get announcements
  static Future<List<Map<String, dynamic>>> getAnnouncements({
    required String token,
    required String groupId,
  }) async {
    final box = Hive.box(announcementsCacheBox);
    final cacheKey = 'announcements_$groupId';

    try {
      final url = Uri.parse('$baseUrl/api/announcements/$groupId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final announcements =
            List<Map<String, dynamic>>.from(data['announcements']);

        // 🔄 Save to cache
        await box.put(cacheKey, announcements);

        return announcements;
      } else {
        // ❌ On error, try cached data
        final cached = box.get(cacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
        throw Exception('Failed to fetch announcements: ${response.body}');
      }
    } catch (e) {
      // 🔌 Offline fallback
      final cached = box.get(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      rethrow;
    }
  }

  // 🔹 Get Pinned Announcements
  static Future<List<Map<String, dynamic>>> getPinnedAnnouncements({
    required String token,
    required String groupId,
  }) async {
    final url = Uri.parse('$baseUrl/api/announcements/$groupId/pinned');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['pinned']);
    } else {
      throw Exception('Failed to load pinned announcements: ${response.body}');
    }
  }

  static Future<List<dynamic>> getDoubts(String groupId) async {
    if (groupId.isEmpty) throw Exception('❌ groupId is empty');

    final url = Uri.parse('$baseUrl/api/doubts/groups/$groupId/doubts');
    final headers = await getAuthHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to load doubts: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<bool> postDoubt({
    required String title,
    required String description,
    required String groupId,
  }) async {
    final url = Uri.parse('$baseUrl/api/doubts/groups/$groupId/doubts');
    final headers = await getAuthHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'title': title, 'description': description}),
    );

    print('📦 postDoubt status: ${response.statusCode}');
    print('📦 postDoubt body: ${response.body}');

    return response.statusCode == 201;
  }

  static Future<bool> postDoubtWithImage({
    required String title,
    required String description,
    required String groupId,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/doubts/groups/$groupId/doubts');
    final request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['description'] = description;

    if (imageFile != null && await imageFile.exists()) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType(parts[0], parts[1]),
      ));
    }

    final token = await getToken();
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📦 postDoubtWithImage status: ${response.statusCode}');
      print('📦 postDoubtWithImage body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Exception during postDoubtWithImage: $e');
      return false;
    }
  }

  static Future<bool> answerDoubt(
    String doubtId,
    String answer, {
    XFile? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/doubts/$doubtId/answer');
    final request = http.MultipartRequest('PUT', uri)
      ..fields['answer'] = answer;

    final token = await getToken();
    if (token == null || token.isEmpty) {
      debugPrint('❌ No auth token found');
      return false;
    }

    request.headers['Authorization'] = 'Bearer $token';

    if (imageFile != null) {
      String? mimeType;

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        mimeType = lookupMimeType(imageFile.name, headerBytes: bytes);
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));
      } else {
        mimeType = lookupMimeType(imageFile.path);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));
      }

      debugPrint("📦 Attaching image with MIME: $mimeType");
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint("📦 answerDoubt response: ${response.statusCode}");
      debugPrint("📦 response body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error in answerDoubt: $e");
      return false;
    }
  }

  static Future<void> deleteDoubt({
    required String token,
    required String doubtId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/doubts/$doubtId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete doubt: ${response.body}');
    }
  }

  static Future<void> deleteAnswer({
    required String token,
    required String answerId,
  }) async {
    final url = Uri.parse('$baseUrl/api/answers/$answerId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete answer: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getDoubtById(String doubtId) async {
    final headers = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/doubts/$doubtId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch doubt: ${response.statusCode}');
    }
  }

  static Future<bool> addAnswerToDoubt(
    String doubtId,
    String answerText, {
    XFile? imageFile,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/doubts/$doubtId/add-answer');
      var request = http.MultipartRequest('POST', uri);

      request.fields['text'] = answerText;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: imageFile.name,
        ));
      }

      final token = await AuthService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error adding answer: $e');
      return false;
    }
  }

  static Future<int> getNewDoubtsCount({required String groupId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/api/doubts/count/$groupId'), // use path param
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        print('Error fetching new doubts count: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Exception fetching new doubts count: $e');
      return 0;
    }
  }

// 🔹 Get Upcoming Announcements
  static Future<List<Map<String, dynamic>>> getUpcomingAnnouncements({
    required String token,
    required String groupId,
  }) async {
    final url = Uri.parse('$baseUrl/api/announcements/$groupId/upcoming');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['upcoming']);
    } else {
      throw Exception(
          'Failed to load upcoming announcements: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/api/users/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getTimetable({
    required String token,
    required String groupId,
    required String day,
  }) async {
    final box = Hive.box(timetableCacheBox);
    final cacheKey = 'timetable_${groupId}_$day';

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/groups/$groupId/timetable?day=${day.toLowerCase()}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🌀 [Timetable API] GET $day -> Status ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ $day timetable: ${data.length} entries');

        // 🔄 Save to cache
        await box.put(cacheKey, data);

        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Error for $day: ${response.body}');
        final cached = box.get(cacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
        return [];
      }
    } catch (e) {
      print('📴 Network error, loading cached timetable...');
      final cached = box.get(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      rethrow;
    }
  }

  // Add under other group/timetable methods
  static Future<void> addTimetableEntry({
    required String token,
    required String groupId,
    required String day,
    required String subject,
    required String teacher,
    required String time,
  }) async {
    final url = Uri.parse('$baseUrl/api/groups/$groupId/timetable');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'day': day,
        'subject': subject,
        'teacher': teacher,
        'time': time,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add timetable entry: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getGroupDetails(
      String token, String groupId) async {
    final url = Uri.parse('$baseUrl/api/groups/$groupId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load group details: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getGroupInfo(
      String token, String groupId) async {
    final url = Uri.parse('$baseUrl/api/groups/$groupId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch group info: ${response.body}');
    }
  }

  // Fetch notes
  static Future<List<Map<String, dynamic>>> getNotes(String groupId,
      [String? parentId]) async {
    final token = await AuthService.getToken();
    final box = Hive.box(notesCacheBox);

    final cacheKey =
        parentId != null ? 'notes_${groupId}_$parentId' : 'notes_$groupId';

    try {
      final uri = Uri.parse(
        '$baseUrl/api/notes/$groupId${parentId != null ? '?parentId=$parentId' : ''}',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notes = List<Map<String, dynamic>>.from(data['notes']);

        // 🔄 Save to cache
        await box.put(cacheKey, notes);

        return notes;
      } else {
        print('❌ Failed to fetch notes: ${response.statusCode}');
        final cached = box.get(cacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
        return [];
      }
    } catch (e) {
      print('📴 Network error loading notes...');
      final cached = box.get(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      rethrow;
    }
  }

// Create folder or file
  static Future<void> createNote({
    required String groupId,
    required String title,
    required String type, // 'folder' or 'file'
    String? url,
    String? parentId,
  }) async {
    final token = await AuthService.getToken();
    final body = {
      'title': title,
      'type': type,
      if (url != null) 'url': url,
      if (parentId != null) 'parentId': parentId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/notes/$groupId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      print('❌ Failed to create note: ${response.body}');
      throw Exception('Failed to create note: ${response.body}');
    }

    // 🧹 Invalidate cache
    final box = Hive.box(notesCacheBox);
    final cacheKey =
        parentId != null ? 'notes_${groupId}_$parentId' : 'notes_$groupId';
    await box.delete(cacheKey);
  }

  static Future<List<dynamic>> getSyllabus(String groupId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/api/syllabus/$groupId');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['syllabus'];
    } else {
      throw Exception('Failed to load syllabus: ${res.body}');
    }
  }

  static Future<void> deleteSyllabus(String syllabusId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/api/syllabus/$syllabusId');
    final res = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode != 200) {
      throw Exception('Failed to delete syllabus: ${res.body}');
    }
  }

  static Future<void> createSyllabus({
    required String groupId,
    required String subject,
    required String link,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/syllabus/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'groupId': groupId,
        'subject': subject,
        'link': link,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add syllabus: ${response.body}');
    }
  }

  static Future<void> updateNickname({
    required String token,
    required String nickname,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/me/nickname');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nickname': nickname}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update nickname: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUserProfileFromCacheOrServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception("No token found");

    // If you already cached the profile, return it
    final cachedProfile = prefs.getString('userProfile');
    if (cachedProfile != null) {
      return Map<String, dynamic>.from(jsonDecode(cachedProfile));
    }

    // Otherwise, fetch from server and cache it
    final profile = await getUserProfile(token);
    await prefs.setString('userProfile', jsonEncode(profile));
    return profile;
  }
}
