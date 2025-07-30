import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frosthub/features/syllabus/presentation/widgets/add_syllabus_modal.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  String? _groupId;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    if (data == null) return;

    setState(() {
      _groupId = data['groupId'];
      _role = data['role'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syllabus'),
        actions: _role == 'admin' && _groupId != null
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddSyllabusModal(groupId: _groupId!),
                    );
                  },
                )
              ]
            : null,
      ),
      body: _groupId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(_groupId)
                  .collection('syllabus')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }

                final syllabusDocs = snapshot.data?.docs ?? [];

                if (syllabusDocs.isEmpty) {
                  return const Center(child: Text('No subjects added yet.'));
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: syllabusDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final subject = data['subject'] ?? '';
                      final link = data['link'] ?? '';

                      return GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(link);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid link')),
                            );
                          }
                        },
                        onLongPress: _role == 'admin'
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Subject?'),
                                    content: Text(
                                        'Are you sure you want to delete "$subject"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await doc.reference.delete();
                                }
                              }
                            : null,
                        child: Chip(
                          label: Text(subject),
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
