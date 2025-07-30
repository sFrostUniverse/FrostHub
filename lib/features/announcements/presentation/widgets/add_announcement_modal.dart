import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAnnouncementModal extends StatefulWidget {
  final String groupId;

  const AddAnnouncementModal({super.key, required this.groupId});

  @override
  State<AddAnnouncementModal> createState() => _AddAnnouncementModalState();
}

class _AddAnnouncementModalState extends State<AddAnnouncementModal> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPosting = false;

  Future<void> _postAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not signed in");

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('announcements')
          .add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': user.uid,
      });

      if (!mounted) return;
      Navigator.pop(context); // ✅ Always pop AFTER success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isPosting = false); // ✅ Reset loading only on error
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
