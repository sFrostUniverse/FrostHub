import 'package:flutter/material.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/features/doubt/screens/doubt_detail_screen.dart';
import 'package:frosthub/api/frostcore_api.dart';

String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return 'https://frostcore.onrender.com$url'; // HTTPS
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

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Doubt?'),
        content: const Text('Are you sure you want to delete this doubt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      await FrostCoreAPI.deleteDoubt(token: token, doubtId: doubt['_id']);
      onDeleted?.call();
      onAnswered();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting doubt: $e')));
    }
  }

  void _openDetailScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoubtDetailScreen(
          doubtId: doubt['_id'],
          initialDoubt: doubt,
        ),
      ),
    ).then((_) => onAnswered());
  }

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';
    final imageUrl = fixImageUrl(doubt['imageUrl']);
    final author = doubt['userId']?['email'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';
    final formattedDate = timestamp.toString().contains('T')
        ? timestamp.split('T').first
        : timestamp.toString();
    final answers = doubt['answers'] ?? [];
    final isAnswered = answers.isNotEmpty;

    return GestureDetector(
      onTap: () => _openDetailScreen(context),
      onLongPress: () {
        if (doubt['userId']?['_id'] == currentUserId) {
          _confirmAndDelete(context);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              if (imageUrl.isNotEmpty)
                Image.network(imageUrl,
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAnswered ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAnswered ? 'Answered' : 'Not Answered',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Text('By $author',
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 12)),
                  Text(formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
