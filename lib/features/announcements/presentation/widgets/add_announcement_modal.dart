import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';

class AddAnnouncementModal extends StatefulWidget {
  final String groupId;

  const AddAnnouncementModal({super.key, required this.groupId});

  @override
  State<AddAnnouncementModal> createState() => _AddAnnouncementModalState();
}

class _AddAnnouncementModalState extends State<AddAnnouncementModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("Not logged in");
      }

      await FrostCoreAPI.postAnnouncement(
        token: token,
        groupId: widget.groupId,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Announcement'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter a message' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isPosting ? null : _postAnnouncement,
          child: _isPosting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post'),
        ),
      ],
    );
  }
}
