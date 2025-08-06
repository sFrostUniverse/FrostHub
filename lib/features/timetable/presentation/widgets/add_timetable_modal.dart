import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';

class AddTimetableModal extends StatefulWidget {
  final String groupId;

  const AddTimetableModal({super.key, required this.groupId});

  @override
  State<AddTimetableModal> createState() => _AddTimetableModalState();
}

class _AddTimetableModalState extends State<AddTimetableModal> {
  final _formKey = GlobalKey<FormState>();
  String _day = 'Monday';
  String _subject = '';
  String _teacher = '';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both start and end time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token missing');

      final formattedStart =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
      final time = '$formattedStart-$formattedEnd';

      await FrostCoreAPI.addTimetableEntry(
        token: token,
        groupId: widget.groupId,
        day: _day,
        subject: _subject,
        teacher: _teacher,
        time: time,
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Timetable Entry',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _day,
                    items: days
                        .map((day) =>
                            DropdownMenuItem(value: day, child: Text(day)))
                        .toList(),
                    onChanged: (val) => setState(() => _day = val!),
                    decoration: const InputDecoration(labelText: 'Day'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Subject'),
                    onChanged: (val) => _subject = val,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter subject' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Teacher'),
                    onChanged: (val) => _teacher = val,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter teacher name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _pickTime(true),
                          child: Text(_startTime == null
                              ? 'Select Start Time'
                              : 'Start: ${_startTime!.format(context)}'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => _pickTime(false),
                          child: Text(_endTime == null
                              ? 'Select End Time'
                              : 'End: ${_endTime!.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Add Entry'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
