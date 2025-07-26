import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _role = 'student';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    _role = userDoc['role'] ?? 'student';
    final groupId = userDoc['groupId'];

    final snap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _announcements = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isLoading = false;
    });
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Announcement'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get();
              final groupId = userDoc['groupId'];

              final data = {
                'title': titleController.text.trim(),
                'timestamp': FieldValue.serverTimestamp(),
              };

              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .collection('announcements')
                  .add(data);

              Navigator.pop(context);
              _loadAnnouncements();
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final groupId = userDoc['groupId'];

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(id)
        .delete();

    _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: _role == 'admin'
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddAnnouncementDialog,
                )
              ]
            : null,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('FrostHub Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pushNamed(context, '/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Timetable'),
              onTap: () => Navigator.pushNamed(context, '/timetable'),
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Announcements'),
              onTap: () => Navigator.pushNamed(context, '/announcements'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Notes'),
              onTap: () => Navigator.pushNamed(context, '/notes'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                }
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final ann = _announcements[index];
                    final ts = ann['timestamp'] as Timestamp?;
                    final date = ts != null
                        ? DateFormat('dd MMM, hh:mm a').format(ts.toDate())
                        : 'No time';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(ann['title'] ?? 'Untitled'),
                        subtitle: Text(date),
                        trailing: _role == 'admin'
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAnnouncement(ann['id']),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
