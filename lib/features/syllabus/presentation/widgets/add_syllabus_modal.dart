import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';

class AddSyllabusModal extends StatefulWidget {
  final String groupId;
  final VoidCallback? onAdded;

  const AddSyllabusModal({
    super.key,
    required this.groupId,
    this.onAdded,
  });

  @override
  State<AddSyllabusModal> createState() => _AddSyllabusModalState();
}

class _AddSyllabusModalState extends State<AddSyllabusModal> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addSyllabus() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FrostCoreAPI.createSyllabus(
        groupId: widget.groupId,
        subject: _subjectController.text.trim(),
        link: _linkController.text.trim(),
      );

      widget.onAdded?.call(); // refresh syllabus list if needed
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error adding syllabus: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add syllabus')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Subject Syllabus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter subject' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'Drive Link'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter link' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _addSyllabus,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
