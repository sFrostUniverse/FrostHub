import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AnswerDoubtModal extends StatefulWidget {
  final String doubtId;
  final VoidCallback? onAnswered;

  const AnswerDoubtModal({
    Key? key,
    required this.doubtId,
    this.onAnswered,
  }) : super(key: key);

  @override
  State<AnswerDoubtModal> createState() => _AnswerDoubtModalState();
}

class _AnswerDoubtModalState extends State<AnswerDoubtModal> {
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await FrostCoreAPI.answerDoubt(
      widget.doubtId,
      answer,
      imageFile: _selectedImage,
    );

    setState(() => _isSubmitting = false);

    if (success && context.mounted) {
      widget.onAnswered?.call();
      Navigator.pop(context); // Close modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Answer submitted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to submit answer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Answer Doubt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              labelText: 'Your Answer',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.attach_file),
                label: const Text("Attach Image"),
              ),
              const SizedBox(width: 8),
              if (_selectedImage != null)
                Expanded(
                  child: Text(
                    _selectedImage!.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Image.file(_selectedImage!, height: 150),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAnswer,
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text('Submit Answer'),
          ),
        ],
      ),
    );
  }
}
