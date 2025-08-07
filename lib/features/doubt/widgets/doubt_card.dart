import 'package:flutter/material.dart';

class DoubtCard extends StatelessWidget {
  final Map<String, dynamic> doubt;

  const DoubtCard({super.key, required this.doubt});

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';
    final author = doubt['createdBy']?['username'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('By $author',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, fontSize: 12)),
                Text(
                  timestamp.toString().split('T').first,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
