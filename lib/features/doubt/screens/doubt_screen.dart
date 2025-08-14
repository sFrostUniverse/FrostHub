import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/doubt/widgets/ask_doubt_modal.dart';
import 'package:frosthub/features/doubt/widgets/doubt_card.dart';
import 'package:frosthub/services/auth_service.dart';

// Helper to fix image URLs that may be partial or full URLs
String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return 'https://frostcore.onrender.com$url'; // use HTTPS
}

class DoubtScreen extends StatefulWidget {
  final String groupId;
  final VoidCallback? onAnswered;

  const DoubtScreen({
    super.key,
    required this.groupId,
    this.onAnswered,
  });

  @override
  State<DoubtScreen> createState() => _DoubtScreenState();
}

class _DoubtScreenState extends State<DoubtScreen> {
  late Future<List<dynamic>> _doubtsFuture;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _doubtsFuture = Future.value([]); // empty list until loaded
    _loadCurrentUser();
    _loadDoubts();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = await AuthService.getUserId();
    setState(() {}); // refresh UI to update delete permissions
  }

  void _loadDoubts() async {
    String groupId = widget.groupId;

    if (groupId.isEmpty) {
      groupId = (await AuthService.getCurrentGroupId()) ?? '';
      print('🧪 Fallback groupId: $groupId');
    }

    if (groupId.isEmpty) {
      print('❌ No groupId found, cannot fetch doubts');
      setState(() {
        _doubtsFuture = Future.error('No group ID found');
      });
      return;
    }

    print('📦 Loading doubts for groupId: $groupId');

    _doubtsFuture = FrostCoreAPI.getDoubts(groupId).then((doubts) {
      final fixedDoubts = doubts.map((d) {
        final map = Map<String, dynamic>.from(d);
        return {
          ...map,
          'imageUrl': fixImageUrl(map['imageUrl']),
          'answerImage': fixImageUrl(map['answerImage']),
        };
      }).toList();

      for (var d in fixedDoubts) {
        print('Fixed Image URL: ${d['imageUrl']}');
      }

      return fixedDoubts;
    }).catchError((e) {
      print('❌ Error fetching doubts: $e');
      throw e;
    });
  }

  Future<void> _refreshDoubts() async {
    _loadDoubts();
    setState(() {}); // refresh UI after reload
  }

  void _openAskDoubtModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AskDoubtModal(groupId: widget.groupId),
    ).then((_) => _refreshDoubts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doubts'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _doubtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading doubts'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No doubts yet.'));
          }

          final doubts = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshDoubts,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: doubts.length,
              itemBuilder: (context, index) {
                final doubt = doubts[index];
                return DoubtCard(
                  doubt: doubt,
                  onAnswered: _refreshDoubts,
                  currentUserId: _currentUserId ?? '',
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAskDoubtModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
