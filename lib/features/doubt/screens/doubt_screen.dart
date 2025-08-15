import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/doubt/widgets/ask_doubt_modal.dart';
import 'package:frosthub/features/doubt/widgets/doubt_card.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/providers/notification_provider.dart';
import 'package:provider/provider.dart';

// Helper to fix image URLs
String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return 'https://frostcore.onrender.com$url';
}

class DoubtScreen extends StatefulWidget {
  final String groupId;
  final VoidCallback? onAnswered;

  const DoubtScreen({super.key, required this.groupId, this.onAnswered});

  @override
  State<DoubtScreen> createState() => _DoubtScreenState();
}

class _DoubtScreenState extends State<DoubtScreen> {
  late Future<List<dynamic>> _doubtsFuture;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();

    // ✅ Reset badge when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false)
            .markAsSeen(widget.groupId);
      }
    });

    _doubtsFuture = Future.value([]);
    _loadCurrentUser();
    _refreshDoubts();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = await AuthService.getUserId();
    setState(() {});
  }

  Future<void> _refreshDoubts() async {
    try {
      String groupId = widget.groupId;
      if (groupId.isEmpty) {
        groupId = (await AuthService.getCurrentGroupId()) ?? '';
      }

      if (groupId.isEmpty) {
        setState(() {
          _doubtsFuture = Future.error('No group ID found');
        });
        return;
      }

      final future = FrostCoreAPI.getDoubts(groupId).then((doubts) {
        return doubts.map((d) {
          final map = Map<String, dynamic>.from(d);
          return {...map, 'imageUrl': fixImageUrl(map['imageUrl'])};
        }).toList();
      });

      setState(() {
        _doubtsFuture = future;
      });
    } catch (e) {
      setState(() {
        _doubtsFuture = Future.error(e);
      });
    }
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
      appBar: AppBar(title: const Text('Doubts')),
      body: FutureBuilder<List<dynamic>>(
        future: _doubtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading doubts: ${snapshot.error}'),
            );
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
