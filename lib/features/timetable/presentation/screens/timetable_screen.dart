import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frosthub/features/timetable/presentation/widgets/add_timetable_modal.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _groupId;
  String? _role;

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
    if (_groupId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(_groupId)
              .collection('timetable')
              .orderBy('day')
              .orderBy('startTime') // ✅ Now using HH:mm format
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No timetable added yet.'));
            }

            final Map<String, List<DocumentSnapshot>> grouped = {};
            for (var doc in docs) {
              final day = doc['day'];
              grouped.putIfAbsent(day, () => []).add(doc);
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: days.map((day) {
                  final classes = grouped[day] ?? [];

                  return Container(
                    width: 200, // Width per day column
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
                        ...classes.map((classDoc) {
                          final subject = classDoc['subject'] ?? 'Unknown';
                          final teacher = classDoc['teacher'] ?? '';
                          final start = classDoc['startTime'] ?? '';
                          final end = classDoc['endTime'] ?? '';

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subject,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('$start - $end'),
                                  Text(teacher),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
