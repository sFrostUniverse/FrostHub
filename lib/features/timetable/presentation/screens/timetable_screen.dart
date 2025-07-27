import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frosthub/models/timetable_model.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  Map<String, List<TimetableEntry>> _groupedEntries = {};
  bool _isLoading = true;
  String _role = 'student';

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    if (data == null || !data.containsKey('groupId')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not part of a group yet.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final groupId = data['groupId'];
    _role = data['role'] ?? 'student';

    final snap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('timetable')
        .get();

    final entries = snap.docs
        .map((doc) => TimetableEntry.fromMap(doc.id, doc.data()))
        .toList();

    // Group by day
    final Map<String, List<TimetableEntry>> grouped = {};
    for (final day in _weekdays) {
      grouped[day] = entries.where((entry) => entry.day == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    setState(() {
      _groupedEntries = grouped;
      _isLoading = false;
    });
  }

  void _showAddTimetableDialog() {
    final titleController = TextEditingController();
    String selectedDay = 'Monday';
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Class'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Class Title'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: _weekdays
                        .map((day) =>
                            DropdownMenuItem(value: day, child: Text(day)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDay = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Day'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => startTime = picked);
                            }
                          },
                          child: Text(startTime == null
                              ? 'Start Time'
                              : 'Start: ${startTime!.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => endTime = picked);
                            }
                          },
                          child: Text(endTime == null
                              ? 'End Time'
                              : 'End: ${endTime!.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    startTime == null ||
                    endTime == null) {
                  return;
                }

                final formattedStart = startTime!.format(context);
                final formattedEnd = endTime!.format(context);

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                final groupId = userDoc['groupId'];

                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('timetable')
                    .add({
                  'title': titleController.text.trim(),
                  'day': selectedDay,
                  'startTime': formattedStart,
                  'endTime': formattedEnd,
                });

                if (!mounted) return;
                Navigator.of(context).pop(); // use the State's own context
                _loadTimetable();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Timetable')),
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
              leading: const Icon(Icons.group),
              title: const Text('Group Info'),
              onTap: () => Navigator.pushNamed(context, '/groupInfo'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Timetable'),
              onTap: () => Navigator.pop(context),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _weekdays.map((day) {
                  final entries = _groupedEntries[day] ?? [];

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entries.map((entry) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('${entry.startTime} → ${entry.endTime}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (entries.isEmpty)
                          const Text('No classes',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: _role == 'admin'
          ? FloatingActionButton(
              onPressed: _showAddTimetableDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
