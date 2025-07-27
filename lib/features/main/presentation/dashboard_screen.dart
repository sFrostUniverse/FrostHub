import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:frosthub/models/timetable_model.dart';
import 'dart:ui';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:developer';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _role = 'student';
  List<TimetableEntry> _todayEntries = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists || userDoc.data()?['groupId'] == null) {
      setState(() => _isLoading = false);
      return;
    }

    final groupId = userDoc['groupId'];
    _role = userDoc['role'] ?? 'student';
    log("User role is $_role");

    final today = DateFormat('EEEE').format(DateTime.now());

    final timetableSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('timetable')
        .get();

    final entries = timetableSnap.docs
        .map((doc) => TimetableEntry.fromMap(doc.id, doc.data()))
        .where((entry) => entry.day == today)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final announcementsSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .get();

    final announcements =
        announcementsSnap.docs.map((doc) => doc.data()).toList();

    final notesSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .get();

    final notes = notesSnap.docs.map((doc) => doc.data()).toList();

    setState(() {
      _todayEntries = entries;
      _announcements = announcements;
      _notes = notes;
      _isLoading = false;
    });
  }

  void _showAddModal(String type) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              if (title.isEmpty) return;

              Navigator.pop(context); // ✅ Move this up before the async gap

              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get()
                  .then((userDoc) {
                final groupId = userDoc['groupId'];
                final data = {
                  'title': title,
                  'description': description,
                  'timestamp': FieldValue.serverTimestamp(),
                };
                return FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection(type == 'Note' ? 'notes' : 'announcements')
                    .add(data);
              }).then((_) {
                if (mounted) _loadDashboardData();
              });
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
      ),
    );
  }

  Widget _buildFrostCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isThreeLine = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: const Color.fromARGB(
              220, 255, 255, 255), // frosty translucent white
          child: ListTile(
            leading: Icon(icon, color: Colors.indigo),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle),
            isThreeLine: isThreeLine,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            final user = FirebaseAuth.instance.currentUser;
            final data = snapshot.data?.data() as Map<String, dynamic>?;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFb4d2f7), Color(0xFFd8eefe)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child:
                            Icon(Icons.person, size: 28, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data?['name'] ?? 'Frost User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.email ?? ''}  •  ${data?['role'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Drawer items...
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Group Info'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/groupInfo');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Timetable'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/timetable');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign),
                  title: const Text('Announcements'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/announcements');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note),
                  title: const Text('Notes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notes');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () => _logout(context),
                ),
              ],
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Foreground Layer
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Frosty header
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFb4d2f7), Color(0xFFd8eefe)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(24)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 12),
                            ],
                          )),

                      const SizedBox(height: 24),

                      // --- YOUR EXISTING CONTENT (like Today’s Classes etc) ---

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSectionTitle('📅 Today\'s Classes'),
                      ),
                      _todayEntries.isEmpty
                          ? _buildEmptyCard("No classes today 🎉")
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: _todayEntries.map((entry) {
                                  return _buildFrostCard(
                                    icon: Icons.schedule,
                                    title: entry.title,
                                    subtitle:
                                        '${entry.startTime} → ${entry.endTime}',
                                  );
                                }).toList(),
                              ),
                            ),
                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSectionTitle('📣 Announcements'),
                      ),
                      _announcements.isEmpty
                          ? _buildEmptyCard("No announcements yet.")
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: _announcements.map((ann) {
                                  final ts = ann['timestamp'] as Timestamp?;
                                  final date = ts != null
                                      ? DateFormat('dd MMM, hh:mm a')
                                          .format(ts.toDate())
                                      : 'No time';
                                  return _buildFrostCard(
                                    icon: Icons.campaign_outlined,
                                    title: ann['title'] ?? 'Untitled',
                                    subtitle: date,
                                  );
                                }).toList(),
                              ),
                            ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSectionTitle('📝 Latest Notes'),
                      ),
                      _notes.isEmpty
                          ? _buildEmptyCard("No notes uploaded yet.")
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: _notes.map((note) {
                                  final ts = note['timestamp'] as Timestamp?;
                                  final date = ts != null
                                      ? DateFormat('dd MMM, hh:mm a')
                                          .format(ts.toDate())
                                      : 'No time';

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/notes',
                                        arguments: note['id'],
                                      );
                                    },
                                    child: _buildFrostCard(
                                      icon: Icons.description_outlined,
                                      title: note['title'] ?? 'Untitled',
                                      subtitle:
                                          '${note['description'] ?? ''}\n$date',
                                      isThreeLine: true,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: _role == 'admin'
          ? SpeedDial(
              icon: Icons.add,
              backgroundColor: Colors.indigo,
              overlayOpacity: 0.3,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.campaign),
                  label: 'Add Announcement',
                  onTap: () => _showAddModal('Announcement'),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.note_add),
                  label: 'Add Note',
                  onTap: () => _showAddModal('Note'),
                ),
              ],
            )
          : null,
    );
  }
}
