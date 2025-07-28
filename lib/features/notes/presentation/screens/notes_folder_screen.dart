import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class NotesFolderScreen extends StatefulWidget {
  final String? parentId; // null for root
  final String title;

  const NotesFolderScreen({super.key, this.parentId, required this.title});

  @override
  State<NotesFolderScreen> createState() => _NotesFolderScreenState();
}

class _NotesFolderScreenState extends State<NotesFolderScreen> {
  bool isAdmin = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _checkRoleAndGroup();
  }

  Future<void> _checkRoleAndGroup() async {
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
              leading: const Icon(Icons.folder),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Add PDF Link'),
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
                'parentId': widget.parentId, // null for root
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
    final urlController = TextEditingController();

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
              controller: urlController,
              decoration: const InputDecoration(labelText: 'PDF URL'),
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
              final url = urlController.text.trim();
              if (title.isEmpty || url.isEmpty || _groupId == null) return;

              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(_groupId)
                  .collection('notes')
                  .add({
                'title': title,
                'type': 'file',
                'url': url,
                'parentId': widget.parentId,
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

  Stream<QuerySnapshot> _getNotesStream() {
    final notesRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(_groupId)
        .collection('notes');

    if (widget.parentId == null) {
      return notesRef
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: false)
          .snapshots();
    } else {
      return notesRef
          .where('parentId', isEqualTo: widget.parentId)
          .orderBy('createdAt', descending: false)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _groupId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _getNotesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No items yet.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final title = doc['title'] ?? 'Untitled';
                    final type = doc['type'];

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
                                  parentId: doc.id,
                                  title: title,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    } else if (type == 'file') {
                      final url = doc['url'] ?? '';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(title),
                          onTap: () async {
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
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
