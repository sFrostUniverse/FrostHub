import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/services/auth_service.dart';

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

  /// Confirm & delete the doubt
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
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No auth token found')),
      );
      return;
    }

    try {
      await FrostCoreAPI.deleteDoubt(
        token: token,
        doubtId: doubt['_id'],
      );
      onDeleted?.call(); // optional callback
      onAnswered(); // refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting doubt: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';

    final author = doubt['userId']?['email'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';
    final formattedDate = timestamp.toString().contains('T')
        ? timestamp.split('T').first
        : timestamp.toString();

    return GestureDetector(
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
              // Title + optional delete button (for extra safety)
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
