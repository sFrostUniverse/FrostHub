import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frosthub/models/timetable_model.dart';
import 'package:frosthub/services/timetable_service.dart';
import 'package:frosthub/features/timetable/presentation/widgets/add_timetable_entry_dialog.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableEntry> _entries = [];
  String? _role;
  bool _isLoading = true;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
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

    final groupId = userDoc['groupId'];
    _role = userDoc['role'];

    final entries = await TimetableService.getEntries(groupId);

    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  void _openAddEntryDialog() {
    showDialog(
      context: context,
      builder: (_) => AddTimetableEntryDialog(onAdded: _loadTimetable),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Timetable'),
        actions: [
          if (_role == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openAddEntryDialog,
              tooltip: 'Add Entry',
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text("No entries yet"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _days.map((day) {
                    final dayEntries = _entries
                        .where((e) => e.day == day)
                        .toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime));

                    if (dayEntries.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...dayEntries.map((entry) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(entry.title),
                                subtitle: Text(
                                    '${entry.startTime} → ${entry.endTime}'),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
