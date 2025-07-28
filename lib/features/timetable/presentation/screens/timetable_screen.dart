import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _groupId;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      _groupId = data['groupId'];
      isAdmin = data['role'] == 'admin';
    });
  }

  void _showAddTimetableDialog() {
    final subjectController = TextEditingController();
    final teacherController = TextEditingController();
    final timeController = TextEditingController();
    String selectedDay = 'Monday';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                items: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday'
                ]
                    .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedDay = value;
                },
              ),
              TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject')),
              TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(labelText: 'Teacher')),
              TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final subject = subjectController.text.trim();
                final teacher = teacherController.text.trim();
                final time = timeController.text.trim();

                if (_groupId == null || subject.isEmpty || time.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(_groupId)
                    .collection('timetable')
                    .add({
                  'day': selectedDay,
                  'subject': subject,
                  'teacher': teacher,
                  'time': time,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) Navigator.pop(context);
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
              .orderBy('time')
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

            return ListView(
              children: grouped.entries.map((entry) {
                final day = entry.key;
                final classes = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(day,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ...classes.map((classDoc) {
                      return Card(
                        child: ListTile(
                          title: Text(classDoc['subject']),
                          subtitle: Text(
                              '${classDoc['teacher']} • ${classDoc['time']}'),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddTimetableDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
