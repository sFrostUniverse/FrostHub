import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:frosthub/constant/api_constant.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  String? _groupId;
  String? _groupCode;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final userRes = await http.get(
        Uri.parse('$apiBaseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (userRes.statusCode != 200) {
        throw Exception('Failed to fetch user');
      }

      final userData = jsonDecode(userRes.body);
      final groupId = userData['groupId'];
      final isAdmin = userData['role'] == 'admin';

      final groupRes = await http.get(
        Uri.parse('$apiBaseUrl/api/groups/$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (groupRes.statusCode != 200) {
        throw Exception('Failed to fetch group');
      }

      final groupData = jsonDecode(groupRes.body);
      final groupCode = groupData['groupCode'];

      final membersRes = await http.get(
        Uri.parse('$apiBaseUrl/api/groups/$groupId/members'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (membersRes.statusCode != 200) {
        throw Exception('Failed to fetch members');
      }

      final membersList =
          List<Map<String, dynamic>>.from(jsonDecode(membersRes.body));
      membersList.sort((a, b) {
        final roleA = a['role'];
        final roleB = b['role'];
        if (roleA == 'admin' && roleB != 'admin') return -1;
        if (roleA != 'admin' && roleB == 'admin') return 1;
        return 0;
      });

      setState(() {
        _groupId = groupId;
        _groupCode = groupCode;
        _isAdmin = isAdmin;
        _members = membersList;
      });
    } catch (e) {
      print('❌ Error loading group info: $e');
    }
  }

  void _shareInstallLink() async {
    const apkUrl =
        'https://github.com/sFrostUniverse/FrostHub/raw/main/apk/app-release.apk';
    final message =
        'Join our FrostHub group! Download the app:\n$apkUrl\nThen enter the group code: $_groupCode';

    final url =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open share dialog')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Info')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: _isAdmin && _groupCode != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      'Code: $_groupCode',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ]
            : null,
      ),
      body: _members.isEmpty
          ? const Center(child: Text('No group members found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final member = _members[index];
                final name = member['username'] ?? 'Unnamed';
                final email = member['email'] ?? '';
                final role = member['role'] ?? 'student';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'admin'
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: role == 'admin' ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _shareInstallLink,
              tooltip: 'Invite to Group',
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
