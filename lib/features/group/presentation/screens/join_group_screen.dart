import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:flutter/material.dart';

import '../../../main/presentation/screens/dashboard_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _error = 'You are not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final group = await FrostCoreAPI.joinGroup(code, token);
      final groupName = group['groupName'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined group: $groupName')),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('🔥 Join group error: $e');
      setState(() {
        _error = 'Failed to join group. ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Group')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Text(
                    'Enter the group code:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g., X3Y8ZK',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _joinGroup,
                    child: const Text('Join Group'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
