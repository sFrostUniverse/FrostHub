import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/timetable/presentation/widgets/add_timetable_modal.dart';
import 'package:frosthub/services/notification_service.dart';
import 'package:frosthub/services/socket_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _groupId;
  String? _role;
  late Future<List<Map<String, dynamic>>> _timetableFuture;

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final profile = await FrostCoreAPI.getUserProfile(token);
      final groupId = profile['groupId'];
      final role = profile['role'];

      setState(() {
        _groupId = groupId;
        _role = role;
        _timetableFuture = _fetchTimetable();
      });

      SocketService().joinGroup(groupId);

      SocketService().socket.on('timetable-updated', (_) {
        if (mounted) {
          setState(() {
            _timetableFuture = _fetchTimetable();
          });
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || _groupId == null) return [];

    try {
      final List<Map<String, dynamic>> allEntries = [];

      for (final day in days) {
        final dayEntries = await FrostCoreAPI.getTimetable(
          token: token,
          groupId: _groupId!,
          day: day,
        );
        allEntries.addAll(dayEntries);
      }

      await NotificationService.scheduleClassReminders(allEntries);

      return allEntries;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching timetable: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _timetableFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allEntries = snapshot.data!;
            if (allEntries.isEmpty) {
              return const Center(child: Text('No timetable added yet.'));
            }

            final grouped = <String, List<Map<String, dynamic>>>{};
            for (final entry in allEntries) {
              final day = (entry['day'] as String?)?.replaceFirstMapped(
                    RegExp(r'^[a-z]'),
                    (m) => m.group(0)!.toUpperCase(),
                  ) ??
                  'Unknown';

              grouped.putIfAbsent(day, () => []).add(entry);
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: days.map((day) {
                  final classes = grouped[day] ?? [];

                  return Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...classes.map((entry) {
                          if (kDebugMode)
                            debugPrint('📚 Timetable Entry: $entry');
                          final subject =
                              entry['subject']?.toString() ?? 'Unknown';
                          final teacher = entry['teacher']?.toString() ?? '';
                          final time = entry['time']?.toString() ?? '';

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subject,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(time),
                                  Text(teacher),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _role == 'admin' && _groupId != null
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddTimetableModal(groupId: _groupId!),
                );
              },
              tooltip: 'Add Timetable Entry',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
