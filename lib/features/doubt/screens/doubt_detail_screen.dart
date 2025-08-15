import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/features/doubt/screens/image_preview_screen.dart';
import 'package:frosthub/features/doubt/widgets/answer_doubt_modal.dart';

String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return 'https://frostcore.onrender.com$url'; // HTTPS
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
    if (token == null) return;

    try {
      await FrostCoreAPI.deleteDoubt(token: token, doubtId: widget.doubtId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting doubt: $e')));
    }
  }

  Future<void> _deleteAnswer(String answerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Answer?'),
        content: const Text('Are you sure you want to delete this answer?'),
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
      await FrostCoreAPI.deleteAnswer(token: token, answerId: answerId);
      _refreshDoubt();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting answer: $e')));
    }
  }

  Future<void> _addAnswer() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnswerDoubtModal(doubtId: widget.doubtId),
    );
    _refreshDoubt();
  }

  @override
  Widget build(BuildContext context) {
    final title = doubt['title'] ?? 'No Title';
    final description = doubt['description'] ?? 'No Description';
    final imageUrl = fixImageUrl(doubt['imageUrl']);
    final author = doubt['createdBy']?['username'] ?? 'Unknown';
    final timestamp = doubt['createdAt'] ?? '';
    final ownerId = doubt['createdBy']?['_id'];

    final answers = doubt['answers'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doubt Details'),
        actions: [
          if (currentUserId != null && currentUserId == ownerId)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteDoubt),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshDoubt),
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
                    const Text('Answers',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (answers.isEmpty)
                      const Text('No answers yet.',
                          style: TextStyle(color: Colors.red)),
                    ...answers.map<Widget>((a) {
                      final answerText = a['text'] ?? '';
                      final answerImage = fixImageUrl(a['imageUrl']);
                      final answerAuthor =
                          a['createdBy']?['username'] ?? 'Unknown';
                      final answerOwnerId = a['createdBy']?['_id'];
                      final answerId = a['_id'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(answerText),
                              if (answerImage.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ImagePreviewScreen(
                                            imageUrl: answerImage),
                                      ),
                                    );
                                  },
                                  child: Image.network(answerImage,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('By $answerAuthor',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12)),
                                  if (currentUserId != null &&
                                      currentUserId == answerOwnerId)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteAnswer(answerId),
                                    ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAnswer,
        icon: const Icon(Icons.reply),
        label: const Text('Answer Doubt'),
      ),
    );
  }
}
