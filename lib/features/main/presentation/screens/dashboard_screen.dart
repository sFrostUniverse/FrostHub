import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:frosthub/features/group/presentation/screens/group_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/features/auth/presentation/screens/google_signin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _fetchGroupId();
  }

  Future<void> _fetchGroupId() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FrostHub Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('FrostHub',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            const ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
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
              leading: const Icon(Icons.group),
              title: const Text('Group Info'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupInfoScreen()),
                );
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
              leading: const Icon(Icons.assignment),
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
              onTap: () async {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Optional: Clear SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to sign-in screen
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GoogleSignInScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Latest Announcement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _groupId == null
                ? const CircularProgressIndicator()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(_groupId)
                        .collection('announcements')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Card(
                          child: ListTile(
                            title: Text('Loading...'),
                          ),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Card(
                          child: ListTile(
                            title: Text('No announcements yet'),
                            subtitle:
                                Text('Your announcements will appear here.'),
                          ),
                        );
                      }
                      final data = docs.first.data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['title'] ?? 'No Title'),
                          subtitle: Text(data['message'] ?? ''),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            const Text(
              'Class Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _groupId == null
                ? const CircularProgressIndicator()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(_groupId)
                        .collection('timetable')
                        .where('day',
                            isEqualTo:
                                DateFormat('EEEE').format(DateTime.now()))
                        .orderBy('time')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      final now = TimeOfDay.now();

                      Map<String, dynamic>? ongoing;
                      Map<String, dynamic>? upcoming;

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final time = data['time'];
                        final parts = (time as String).split('-');
                        if (parts.length != 2) continue;
                        final start = _parseTimeOfDay(parts[0]);
                        final end = _parseTimeOfDay(parts[1]);

                        if (start != null && end != null) {
                          if (_isBetween(now, start, end)) {
                            ongoing = data;
                          } else if (start.hour > now.hour ||
                              (start.hour == now.hour &&
                                  start.minute > now.minute)) {
                            if (upcoming == null) upcoming = data;
                          }
                        }
                      }

                      return Column(
                        children: [
                          _buildClassBar(ongoing, 'Ongoing', Colors.green),
                          const SizedBox(height: 8),
                          _buildClassBar(upcoming, 'Upcoming', Colors.blue),
                        ],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String input) {
    final parts = input.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isBetween(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  Widget _buildClassBar(
      Map<String, dynamic>? data, String status, Color color) {
    if (data == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.class_),
          title: Text('No $status class'),
          subtitle: Text('We’ll show $status class if scheduled.'),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.class_),
        title: Text(data['subject'] ?? 'Unknown Subject'),
        subtitle: Text(data['time'] ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
