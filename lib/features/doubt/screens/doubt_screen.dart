import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/doubt/widgets/ask_doubt_modal.dart';
import 'package:frosthub/features/doubt/widgets/doubt_card.dart';

class DoubtScreen extends StatefulWidget {
  final String groupId;

  const DoubtScreen({super.key, required this.groupId});

  @override
  State<DoubtScreen> createState() => _DoubtScreenState();
}

class _DoubtScreenState extends State<DoubtScreen> {
  late Future<List<dynamic>> _doubtsFuture;

  @override
  void initState() {
    super.initState();
    _loadDoubts();
  }

  void _loadDoubts() {
    print('📦 groupId: ${widget.groupId}'); // 👈 Debug print
    setState(() {
      _doubtsFuture = FrostCoreAPI.getDoubts(widget.groupId);
    });
  }

  Future<void> _refreshDoubts() async {
    _loadDoubts();
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
                return DoubtCard(doubt: doubt);
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
