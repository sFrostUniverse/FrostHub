import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:frosthub/features/group/presentation/screens/group_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/features/auth/presentation/screens/google_signin_screen.dart';
import 'package:frosthub/features/timetable/presentation/widgets/add_timetable_modal.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:frosthub/features/announcements/presentation/widgets/add_announcement_modal.dart';
import 'package:frosthub/services/notification_service.dart'; // 👈 Import service
import 'package:frosthub/features/syllabus/presentation/widgets/add_syllabus_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _groupId;
  String? _role;

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
      _role = data['role'];
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
              leading: const Icon(Icons.chat),
              title: const Text('Group Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/group-chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Syllabus'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/syllabus');
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
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
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
                        .orderBy('startTime')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          child: ListTile(title: Text('Loading timetable...')),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      final now = TimeOfDay.now();

                      // Schedule class notifications here:
                      final nowDateTime = DateTime.now();
                      for (int i = 0; i < docs.length; i++) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final time = data['time'];
                        if (time == null || time is! String) continue;

                        final parts = time.split('-');
                        if (parts.length != 2) continue;

                        final start = _parseTimeOfDay(parts[0]);
                        if (start == null) continue;

                        final classDateTime = DateTime(
                          nowDateTime.year,
                          nowDateTime.month,
                          nowDateTime.day,
                          start.hour,
                          start.minute,
                        );

                        final diff =
                            classDateTime.difference(nowDateTime).inMinutes;
                        if (diff > 10) {
                          NotificationService.scheduleClassNotification(
                            id: i * 10 + 1,
                            title: 'Class Soon',
                            body:
                                'Your class "${data['subject']}" starts in 10 minutes.',
                            scheduledTime: classDateTime
                                .subtract(const Duration(minutes: 10)),
                          );
                        }

                        if (diff > 5) {
                          NotificationService.scheduleClassNotification(
                            id: i * 10 + 2,
                            title: 'Get Ready!',
                            body:
                                'Your class "${data['subject']}" starts in 5 minutes.',
                            scheduledTime: classDateTime
                                .subtract(const Duration(minutes: 5)),
                          );
                        }
                      }

                      // Now check for ongoing and upcoming
                      Map<String, dynamic>? ongoing;
                      Map<String, dynamic>? upcoming;

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final time = data['time'];
                        if (time == null || time is! String) continue;
                        final parts = time.split('-');
                        if (parts.length != 2) continue;
                        final start = _parseTimeOfDay(parts[0]);
                        final end = _parseTimeOfDay(parts[1]);

                        if (start != null && end != null) {
                          if (_isBetween(now, start, end)) {
                            ongoing = data;
                          } else if (start.hour > now.hour ||
                              (start.hour == now.hour &&
                                  start.minute > now.minute)) {
                            upcoming ??= data;
                          }
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildClassBar(ongoing, 'Ongoing', Colors.green),
                          const SizedBox(height: 8),
                          _buildClassBar(upcoming, 'Upcoming', Colors.blue),
                        ],
                      );
                    }),
            const SizedBox(height: 24),
            const Text(
              'Group Chat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _groupId == null
                ? const CircularProgressIndicator()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(_groupId)
                        .collection('chat')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final lastMsg = snapshot.data!.docs.isNotEmpty
                          ? snapshot.data!.docs.first.data()
                              as Map<String, dynamic>
                          : null;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pushNamed(context, '/group-chat');
                          },
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: const Text('Open Group Chat'),
                          subtitle: Text(
                            lastMsg != null
                                ? '${lastMsg['senderName'] ?? 'Someone'}: ${lastMsg['message'] ?? ''}'
                                : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('groups')
                                .doc(_groupId)
                                .collection('chat')
                                .snapshots(),
                            builder: (context, countSnapshot) {
                              if (!countSnapshot.hasData)
                                return const SizedBox();
                              final count = countSnapshot.data!.docs.length;
                              return CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: _role == 'admin' && _groupId != null
          ? SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Colors.blue,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.campaign),
                  label: 'Add Announcement',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddAnnouncementModal(groupId: _groupId!),
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.schedule),
                  label: 'Add Timetable Entry',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddTimetableModal(groupId: _groupId!),
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.book),
                  label: 'Add Syllabus',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddSyllabusModal(groupId: _groupId!),
                    );
                  },
                ),
              ],
            )
          : null,
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
