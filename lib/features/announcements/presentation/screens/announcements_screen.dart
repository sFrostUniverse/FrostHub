import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';
import '../widgets/add_announcement_modal.dart';
import 'package:frosthub/services/socket_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  String? _groupId;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();

    // 🧠 Listen to real-time updates
    SocketService().socket.on('new-announcement', (data) {
      if (data != null && mounted) {
        print('📢 Real-time announcement received: $data');
        _loadAnnouncements(); // reload from backend
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final user = await FrostCoreAPI.getUserProfile(token);
      final groupId = user['groupId'];
      final role = user['role'];

      SocketService().joinGroup(groupId);

      final announcements = await FrostCoreAPI.getAnnouncements(
        token: token,
        groupId: groupId,
      );

      setState(() {
        _groupId = groupId;
        _isAdmin = role == 'admin';
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshAnnouncements() async {
    setState(() => _isLoading = true);
    await _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements yet.'))
              : RefreshIndicator(
                  onRefresh: _refreshAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = _announcements[index];
                      return Card(
                        child: ListTile(
                          title: Text(announcement['title'] ?? 'No Title'),
                          subtitle: Text(announcement['message'] ?? ''),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _isAdmin && _groupId != null
          ? FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => AddAnnouncementModal(groupId: _groupId!),
                );
              },
              child: const Icon(Icons.add_comment),
            )
          : null,
    );
  }
}
