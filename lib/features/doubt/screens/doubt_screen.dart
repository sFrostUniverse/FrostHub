import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/doubt/widgets/doubt_card.dart';
import 'package:frosthub/services/auth_service.dart';

class DoubtScreen extends StatefulWidget {
  final String groupId;

  const DoubtScreen({super.key, required this.groupId});

  @override
  State<DoubtScreen> createState() => _DoubtScreenState();
}

class _DoubtScreenState extends State<DoubtScreen> {
  List<Map<String, dynamic>> _doubts = [];
  bool _isLoading = true;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndDoubts();
  }

  Future<void> _loadUserAndDoubts() async {
    final userId = await AuthService.getUserId() ?? '';
    setState(() {
      _currentUserId = userId;
    });
    await _fetchDoubts();
  }

  Future<void> _fetchDoubts() async {
    setState(() => _isLoading = true);
    try {
      final data = await FrostCoreAPI.getDoubts(widget.groupId);

      // Sort newest first based on createdAt
      data.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _doubts = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print('❌ Failed to fetch doubts: $e');
    }
    setState(() => _isLoading = false);
  }

  void _refreshDoubts() {
    _fetchDoubts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doubts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doubts.isEmpty
              ? const Center(child: Text('No doubts yet'))
              : RefreshIndicator(
                  onRefresh: _fetchDoubts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _doubts.length,
                    itemBuilder: (context, index) {
                      return DoubtCard(
                        doubt: _doubts[index],
                        onAnswered: _refreshDoubts,
                        currentUserId: _currentUserId,
                      );
                    },
                  ),
                ),
    );
  }
}
