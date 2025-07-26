import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final groupId = userDoc['groupId'];

    final snap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .orderBy('dueDate')
        .get();

    setState(() {
      _assignments = snap.docs.map((doc) => doc.data()).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssignments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _assignments.length,
                itemBuilder: (context, index) {
                  final assignment = _assignments[index];
                  final dueDate = assignment['dueDate'] != null
                      ? (assignment['dueDate'] as Timestamp).toDate()
                      : null;
                  final formattedDate = dueDate != null
                      ? DateFormat('dd MMM yyyy').format(dueDate)
                      : 'No due date';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(assignment['title'] ?? 'Untitled'),
                      subtitle: Text(
                        '${assignment['description'] ?? ''}\nDue: $formattedDate',
                      ),
                      isThreeLine: true,
                      leading: const Icon(Icons.assignment),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
