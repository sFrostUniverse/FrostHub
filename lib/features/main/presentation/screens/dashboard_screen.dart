import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:frosthub/services/socket_service.dart';
import 'package:frosthub/features/group/presentation/screens/group_info_screen.dart';
import 'package:frosthub/features/auth/presentation/screens/google_signin_screen.dart';
import 'package:frosthub/features/timetable/presentation/widgets/add_timetable_modal.dart';
import 'package:frosthub/features/announcements/presentation/widgets/add_announcement_modal.dart';
import 'package:frosthub/features/syllabus/presentation/widgets/add_syllabus_modal.dart';
import 'package:frosthub/services/notification_service.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'dart:async';
import 'package:frosthub/features/doubt/widgets/ask_doubt_modal.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/features/doubt/screens/doubt_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _groupId;
  String? _role;

  bool _isLoadingAnnouncement = true;
  Map<String, dynamic>? _latestAnnouncement;

  List<Map<String, dynamic>> _todaysTimetable = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    // 🔁 Rebuild every minute to keep class status accurate
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // 🔒 Clean up the timer
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final cachedGroupId = prefs.getString('groupId');
    final cachedRole = prefs.getString('role');

    if (mounted) {
      setState(() {
        _groupId = cachedGroupId;
        _role = cachedRole;
      });
    }

    try {
      final profile = await FrostCoreAPI.getUserProfile(token);
      await prefs.setString('groupId', profile['groupId']);
      await prefs.setString('role', profile['role']);

      SocketService().initSocket(profile['_id']);
      SocketService().socket.on('notification', (data) {
        NotificationService.showAnnouncementNotification(
          title: data['title'] ?? 'New Notification',
          body: data['body'] ?? 'You have a new notification.',
        );
      });
      SocketService().socket.on('announcement:new', (_) {
        _fetchLatestAnnouncement(token);
      });

      SocketService().socket.on('timetable:update', (_) {
        _fetchTodayTimetable(token);
      });

      setState(() {
        _groupId = profile['groupId'];
        _role = profile['role'];
      });

      await _fetchLatestAnnouncement(token);
      await _fetchTodayTimetable(token);
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  Future<void> _fetchLatestAnnouncement(String token) async {
    try {
      final announcements = await FrostCoreAPI.getAnnouncements(
        token: token,
        groupId: _groupId!,
      );
      setState(() {
        _latestAnnouncement =
            announcements.isNotEmpty ? announcements.first : null;
        _isLoadingAnnouncement = false;
      });
    } catch (e) {
      print('Error fetching announcement: $e');
      setState(() {
        _isLoadingAnnouncement = false;
      });
    }
  }

  Future<void> _fetchTodayTimetable(String token) async {
    try {
      final day = DateFormat('EEEE').format(DateTime.now());
      final timetable = await FrostCoreAPI.getTimetable(
        token: token,
        groupId: _groupId!,
        day: day,
      );

      setState(() {
        _todaysTimetable = timetable;
      });

      final now = DateTime.now();
      final classList = timetable
          .map((entry) {
            final parts = (entry['time'] as String).split('-');
            if (parts.length != 2) return null;
            final start = _parseTimeOfDay(parts[0]);
            if (start == null) return null;

            final startDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              start.hour,
              start.minute,
            );

            return {
              'subject': entry['subject'] ?? 'Class',
              'startTime': startDateTime.toIso8601String(),
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      await NotificationService.scheduleClassReminders(classList);
    } catch (e) {
      print('Error fetching timetable: $e');
    }
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

  Widget _buildClassBar(Map<String, dynamic>? data, String label, Color color) {
    if (data == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.class_),
          title: Text('No $label class'),
          subtitle: Text('We’ll show $label class if scheduled.'),
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
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();

    if (_groupId == null || _role == null) {
      // ✅ Show full loader instead of half-built UI
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic>? ongoing;
    Map<String, dynamic>? upcoming;

    for (final entry in _todaysTimetable) {
      final time = entry['time'];
      if (time == null || time is! String) continue;
      final parts = time.split('-');
      if (parts.length != 2) continue;
      final start = _parseTimeOfDay(parts[0]);
      final end = _parseTimeOfDay(parts[1]);
      if (start != null && end != null) {
        if (_isBetween(now, start, end)) {
          ongoing = entry;
        } else if (start.hour > now.hour ||
            (start.hour == now.hour && start.minute > now.minute)) {
          upcoming ??= entry;
        }
      }
    }
    final nowMinutes = now.hour * 60 + now.minute;

    final remainingClasses = _todaysTimetable.where((entry) {
      final time = entry['time'];
      if (time == null || time is! String) return false;
      final parts = time.split('-');
      if (parts.length != 2) return false;
      final end = _parseTimeOfDay(parts[1]);
      if (end == null) return false;
      final endMinutes = end.hour * 60 + end.minute;
      return nowMinutes < endMinutes;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('FrostHub Dashboard')),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadData, // 🔁 Pull-to-refresh calls this
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(), // ensures swipe works
            children: [
              const Text(
                'Latest Announcement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _isLoadingAnnouncement
                  ? const Card(child: ListTile(title: Text('Loading...')))
                  : _latestAnnouncement == null
                      ? const Card(
                          child: ListTile(
                            title: Text('No announcements yet'),
                            subtitle:
                                Text('Your announcements will appear here.'),
                          ),
                        )
                      : Card(
                          child: ListTile(
                            title: Text(
                                _latestAnnouncement!['title'] ?? 'No Title'),
                            subtitle:
                                Text(_latestAnnouncement!['message'] ?? ''),
                          ),
                        ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 600;

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Class Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Class Status',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildClassBar(
                                      ongoing, 'Ongoing', Colors.green),
                                  const SizedBox(height: 8),
                                  _buildClassBar(
                                      upcoming, 'Upcoming', Colors.blue),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class Status',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildClassBar(ongoing, 'Ongoing', Colors.green),
                            const SizedBox(height: 8),
                            _buildClassBar(upcoming, 'Upcoming', Colors.blue),
                            if (remainingClasses.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Today\'s Classes',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...remainingClasses.map((entry) => Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.schedule),
                                      title: Text(entry['subject'] ?? 'Class'),
                                      subtitle: Text(
                                          '${entry['teacher'] ?? ''} — ${entry['time'] ?? ''}'),
                                    ),
                                  )),
                            ],
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (_role == 'admin' || _role == 'member')
          ? SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Colors.blue,
              children: _role == 'admin'
                  ? [
                      SpeedDialChild(
                        child: const Icon(Icons.campaign),
                        label: 'Add Announcement',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                AddAnnouncementModal(groupId: _groupId!),
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
                            builder: (_) =>
                                AddTimetableModal(groupId: _groupId!),
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
                            builder: (_) =>
                                AddSyllabusModal(groupId: _groupId!),
                          );
                        },
                      ),
                      SpeedDialChild(
                        child: const Icon(Icons.question_answer),
                        label: 'Ask a Doubt',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AskDoubtModal(groupId: _groupId!),
                          );
                        },
                      ),
                    ]
                  : [
                      // Only ask doubt for members
                      SpeedDialChild(
                        child: const Icon(Icons.question_answer),
                        label: 'Ask a Doubt',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AskDoubtModal(groupId: _groupId!),
                          );
                        },
                      ),
                    ],
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: FrostCoreAPI.getUserProfileFromCacheOrServer(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.hasError) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Center(
                    child: Text(
                      'FrostHub',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                );
              }

              final user = snapshot.data!;
              final name = user['nickname']?.isNotEmpty == true
                  ? user['nickname']
                  : user['username'] ?? 'User';
              final email = user['email'] ?? '';
              final profilePic = (user['profilePic']?.isNotEmpty ?? false)
                  ? user['profilePic']
                  : 'https://ui-avatars.com/api/?name=$name';

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (user['role'] == 'admin') {
                    Navigator.pushNamed(context, '/adminPage');
                  }
                },
                child: UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blue),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(profilePic),
                  ),
                  accountName: Text(name),
                  accountEmail: Text(email),
                ),
              );
            },
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
            leading: const Icon(Icons.question_answer),
            title: const Text('Doubts'),
            onTap: () async {
              Navigator.pop(context);
              final groupId = await AuthService.getCurrentGroupId();
              if (groupId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoubtScreen(groupId: groupId),
                  ),
                );
              }
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GoogleSignInScreen(),
                  ),
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
