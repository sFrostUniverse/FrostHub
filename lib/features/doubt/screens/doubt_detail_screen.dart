import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/features/doubt/widgets/answer_doubt_modal.dart';
import 'package:frosthub/features/doubt/screens/image_preview_screen.dart';

String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return 'http://frostcore.onrender.com$url';
}

class DoubtDetailScreen extends StatefulWidget {
  final String doubtId;
  final Map<String, dynamic> initialDoubt;

  const DoubtDetailScreen({
    super.key,
    required this.doubtId,
    required this.initialDoubt,
  });

  @override
  State<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends State<DoubtDetailScreen> {
  late Map<String, dynamic> doubt;
  bool loading = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    doubt = widget.initialDoubt;
    _loadCurrentUser();
    _refreshDoubt();
  }

  Future<void> _loadCurrentUser() async {
    currentUserId = await AuthService.getUserId();
    setState(() {});
  }

  Future<void> _refreshDoubt() async {
    setState(() => loading = true);
    try {
      final fresh = await FrostCoreAPI.getDoubtById(widget.doubtId);
      setState(() => doubt = fresh);
    } catch (e) {
      debugPrint("⚠️ Failed to refresh doubt: $e");
    }
    setState(() => loading = false);
  }

  Future<void> _deleteDoubt() async {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No auth token found')));
      return;
    }

    try {
      await FrostCoreAPI.deleteDoubt(token: token, doubtId: widget.doubtId);
      if (mounted) Navigator.pop(context); // go back after deletion
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting doubt: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';
    final imageUrl = fixImageUrl(doubt['imageUrl']);
    final author = doubt['createdBy']?['username'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';
    final answer = doubt['answer'];
    final answerImage = fixImageUrl(doubt['answerImage']);
    final ownerId = doubt['createdBy']?['_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doubt Details'),
        actions: [
          if (currentUserId != null && currentUserId == ownerId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteDoubt,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDoubt,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(description),
                    const SizedBox(height: 12),
                    if (imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ImagePreviewScreen(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Image.network(imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 16),
                    Text(
                        'By $author on ${timestamp.toString().split("T").first}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),
                    if (answer != null && answer.isNotEmpty) ...[
                      const Divider(),
                      const Text('Answer:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(answer),
                      const SizedBox(height: 12),
                      if (answerImage.isNotEmpty)
                        Image.network(answerImage,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.reply),
                        label: const Text('Answer This Doubt'),
                        onPressed: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                AnswerDoubtModal(doubtId: widget.doubtId),
                          );
                          _refreshDoubt();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
