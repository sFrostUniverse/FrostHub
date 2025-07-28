import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notes_folder_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool isAdmin = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndGroup();
  }

  Future<void> _fetchUserRoleAndGroup() async {
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

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_folder_upload),
              title: const Text('Upload PDF to Drive'),
              onTap: () async {
                Navigator.pop(context);
                const url =
                    'https://drive.google.com/drive/folders/1peB8IflMRkzotwQvHy6YHxlXUljQWO8W?usp=sharing';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Add PDF from Drive Link'),
              subtitle: const Text(
                'Paste preview/file link like: https://drive.google.com/file/d/FILE_ID/view',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddPdfDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty || _groupId == null) return;

              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(_groupId)
                  .collection('notes')
                  .add({
                'title': name,
                'type': 'folder',
                'parentId': null,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddPdfDialog() {
    final titleController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add PDF Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: linkController,
              decoration:
                  const InputDecoration(labelText: 'Google Drive File URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final url = linkController.text.trim();
              if (title.isEmpty || url.isEmpty || _groupId == null) return;

              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(_groupId)
                  .collection('notes')
                  .add({
                'title': title,
                'url': url,
                'type': 'file',
                'parentId': null,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String convertToPreviewLink(String url) {
    final regex = RegExp(r'd/([^/]+)');
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/file/d/$fileId/preview';
    }
    return url;
  }

  Stream<QuerySnapshot> getNotesStream() {
    if (_groupId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('groups')
        .doc(_groupId)
        .collection('notes')
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: _groupId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notes added yet.'));
                }

                final notes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final item = notes[index];
                    final title = item['title'] ?? 'Untitled';
                    final type = item['type'] ?? 'file';

                    if (type == 'folder') {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(title),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotesFolderScreen(
                                  parentId: item.id,
                                  title: title,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      final url = item['url'] ?? '';
                      final previewUrl = convertToPreviewLink(url);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(title),
                          onTap: () async {
                            if (await canLaunchUrl(Uri.parse(previewUrl))) {
                              await launchUrl(Uri.parse(previewUrl),
                                  mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open the PDF'),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
