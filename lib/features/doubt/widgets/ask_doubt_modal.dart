import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:frosthub/services/auth_service.dart';

class AskDoubtModal extends StatefulWidget {
  final String groupId;

  const AskDoubtModal({super.key, required this.groupId});

  @override
  State<AskDoubtModal> createState() => _AskDoubtModalState();
}

class _AskDoubtModalState extends State<AskDoubtModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitDoubt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final success = await FrostCoreAPI.postDoubtWithImage(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        groupId: widget.groupId,
        imageFile: _selectedImage != null ? File(_selectedImage!.path) : null,
      );

      if (!success) {
        throw Exception('API returned failure');
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doubt submitted successfully')),
        );
      }
    } catch (e) {
      print('❌ Submission error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit doubt: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask a Doubt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Attach Image'),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedImage != null)
                        Expanded(
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(_selectedImage!, height: 80),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() => _selectedImage = null);
                                },
                              )
                            ],
                          ),
                        )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submitDoubt,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit'),
                  ),
          ],
        ),
      ),
    );
  }
}
