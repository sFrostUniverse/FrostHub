import 'package:flutter/material.dart';
import 'package:frosthub/features/doubt/screens/doubt_detail_screen.dart';
import 'package:frosthub/api/frostcore_api.dart';

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
  final VoidCallback? onDeleted;
  final String currentUserId;

  const DoubtCard({
    super.key,
    required this.doubt,
    required this.onAnswered,
    required this.currentUserId,
    this.onDeleted,
  });

  // Confirm & delete dialog
  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Doubt'),
        content: const Text('Are you sure you want to delete this doubt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FrostCoreAPI.deleteDoubt(doubt['_id']);
        onDeleted?.call();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting doubt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';

    final author = doubt['userId']?['email'] ?? 'Unknown';

    final timestamp = doubt['createdAt'];
    String formattedDate = '';
    if (timestamp != null && timestamp is String && timestamp.contains('T')) {
      formattedDate = timestamp.split('T').first;
    } else if (timestamp != null) {
      formattedDate = timestamp.toString();
    }

    final imageUrl = fixImageUrl(doubt['imageUrl']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoubtDetailScreen(
              doubtId: doubt['_id'],
              initialDoubt: doubt,
            ),
          ),
        ).then((_) {
          onAnswered();
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + optional delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (doubt['userId']?['_id'] == currentUserId)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
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
                    formattedDate,
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
