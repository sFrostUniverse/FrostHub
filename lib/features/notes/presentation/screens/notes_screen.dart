import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String _role = 'student';
  final ScrollController _scrollController = ScrollController();
  String? _highlightedNoteId;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
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
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .get();

    final noteList = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      _notes = noteList;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() => _highlightedNoteId = args);
        final index = _notes.indexWhere((n) => n['id'] == _highlightedNoteId);
        if (index != -1) {
          _scrollController.animateTo(
            index * 120.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final fileUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cloud_upload, color: Colors.indigo),
                    tooltip: 'Open shared Drive folder',
                    onPressed: () async {
                      const uploadLink =
                          'https://drive.google.com/drive/folders/YOUR_FOLDER_ID_HERE';
                      if (await canLaunchUrl(Uri.parse(uploadLink))) {
                        await launchUrl(Uri.parse(uploadLink),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Text(
                    'Upload file to shared Drive',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              TextField(
                controller: fileUrlController,
                decoration: const InputDecoration(
                  labelText: 'Paste file link',
                  hintText: 'https://drive.google.com/...',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // ✅ Safe usage
              await Future.delayed(
                  const Duration(milliseconds: 200)); // ensure pop is done
              await _uploadNote(
                titleController.text.trim(),
                descriptionController.text.trim(),
                fileUrlController.text.trim(),
              );
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadNote(String title, String desc, String fileUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final groupId = userDoc['groupId'];

    final data = {
      'title': title,
      'description': desc,
      'fileUrl': fileUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('notes')
        .add(data);

    if (!mounted) return;

    await _loadNotes();
  }

  Future<void> _deleteNote(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final groupId = userDoc['groupId'];

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('notes')
        .doc(id)
        .delete();

    _loadNotes();
  }

  void _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return; // ✅ Guard against disposed context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or inaccessible file URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: _role == 'admin'
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddNoteDialog,
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
          : _notes.isEmpty
              ? const Center(child: Text('No notes uploaded yet.'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final ts = note['timestamp'] as Timestamp?;
                    final date = ts != null
                        ? DateFormat('dd MMM, hh:mm a').format(ts.toDate())
                        : 'No time';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: note['id'] == _highlightedNoteId
                          ? Colors.indigo
                              .withValues(alpha: 26) // 0.1 * 255 ≈ 26
                          : null,
                      child: ListTile(
                        title: Text(note['title'] ?? 'Untitled'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((note['description'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Text(note['description']),
                            Text(date),
                            if (note['fileUrl'] != null &&
                                note['fileUrl'].toString().isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.attach_file,
                                        size: 18, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      "Attachment available",
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: note['fileUrl'] != null &&
                                note['fileUrl'].toString().isNotEmpty
                            ? () => _openFile(note['fileUrl'])
                            : null,
                        trailing: _role == 'admin'
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNote(note['id']),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
