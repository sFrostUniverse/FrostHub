import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frosthub/models/timetable_model.dart';
import 'package:frosthub/services/timetable_service.dart';
import 'package:uuid/uuid.dart';

class AddTimetableEntryDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const AddTimetableEntryDialog({super.key, required this.onAdded});

  @override
  State<AddTimetableEntryDialog> createState() =>
      _AddTimetableEntryDialogState();
}

class _AddTimetableEntryDialogState extends State<AddTimetableEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  String _selectedDay = 'Monday';

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final groupId = userDoc['groupId'];

    final entry = TimetableEntry(
      id: const Uuid().v4(),
      title: _subjectController.text.trim(), // ✅ required field
      day: _selectedDay,
      startTime: _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim(),
    );

    await TimetableService.addEntry(groupId, entry);
    widget.onAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Timetable Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDay,
                items: _days
                    .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDay = val!),
                decoration: const InputDecoration(labelText: 'Day'),
              ),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter subject' : null,
              ),
              TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter start time' : null,
              ),
              TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter end time' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
