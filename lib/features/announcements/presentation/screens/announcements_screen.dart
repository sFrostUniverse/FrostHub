import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool isAdmin = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    if (data == null) return;

    setState(() {
      isAdmin = data['role'] == 'admin';
      _groupId = data['groupId'];
    });
  }

  void _showAddAnnouncementDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  print('❌ User is null');
                  return;
                }

                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                final groupId = userDoc.data()?['groupId'];
                print('📌 groupId: $groupId');

                if (groupId == null) {
                  print('❌ No groupId found');
                  return;
                }

                final title = titleController.text.trim();
                final message = messageController.text.trim();

                if (title.isEmpty || message.isEmpty) {
                  print('⚠️ Title or message is empty');
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupId)
                      .collection('announcements')
                      .add({
                    'title': title,
                    'message': message,
                    'createdAt': FieldValue.serverTimestamp(),
                    'authorId': user.uid,
                  });

                  print('✅ Announcement posted successfully');
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  print('🔥 Error posting announcement: $e');
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(_groupId) // We'll fetch this in initState
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No announcements yet.'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final title = doc['title'];
                final message = doc['message'];
                final createdAt = doc['createdAt']?.toDate();

                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      '$message\n${createdAt != null ? createdAt.toString() : ''}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddAnnouncementDialog(context),
              child: const Icon(Icons.add_comment),
            )
          : null,
    );
  }
}
