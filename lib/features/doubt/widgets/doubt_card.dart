import 'package:flutter/material.dart';
import 'package:frosthub/features/doubt/screens/doubt_detail_screen.dart';

// Helper to fix image URLs that might be relative
String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) {
    return url;
  } else {
    return 'http://frostcore.onrender.com$url';
  }
}

class DoubtCard extends StatelessWidget {
  final Map<String, dynamic> doubt;
  final VoidCallback onAnswered;

  const DoubtCard({
    super.key,
    required this.doubt,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';
    final author = doubt['createdBy']?['username'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';
    final imageUrl = fixImageUrl(doubt['imageUrl']); // <-- Fix URL here

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoubtDetailScreen(
              doubtId: doubt['_id'], // ✅ pass the ID
              initialDoubt: doubt, // ✅ pass the full map for initial render
            ),
          ),
        ).then((_) {
          onAnswered(); // Refresh after returning
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Show image if present
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By $author',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    timestamp.toString().split('T').first,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
