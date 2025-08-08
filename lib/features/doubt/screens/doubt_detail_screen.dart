import 'package:flutter/material.dart';
import 'package:frosthub/features/doubt/widgets/answer_doubt_modal.dart';

class DoubtDetailScreen extends StatelessWidget {
  final Map<String, dynamic> doubt;

  const DoubtDetailScreen({super.key, required this.doubt});

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';
    final imageUrl = doubt['imageUrl']; // optional, if present
    final author = doubt['createdBy']?['username'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Doubt Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 12),
            if (imageUrl != null)
              Image.network(imageUrl,
                  height: 200, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text('By $author on ${timestamp.toString().split("T").first}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.reply),
                label: Text('Answer This Doubt'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AnswerDoubtModal(doubtId: doubt['_id']),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
