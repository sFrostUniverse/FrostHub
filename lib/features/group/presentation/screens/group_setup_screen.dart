import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';
import '../../../main/presentation/screens/dashboard_screen.dart';

class GroupSetupScreen extends StatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _groupName;
  String? _groupCode;

  Future<void> _createGroup() async {
    final groupName = _controller.text.trim();
    if (groupName.isEmpty) return;

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in.')),
      );
      return;
    }

    try {
      final groupData = await FrostCoreAPI.createGroup(groupName, token);

      setState(() {
        _groupName = groupData['group']?['groupName'];
        _groupCode = groupData['group']?['groupCode'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _groupCode != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Group Created!',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text('Name: $_groupName'),
                      const SizedBox(height: 8),
                      Text('Code: $_groupCode'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DashboardScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('Go to Dashboard'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Enter your group name:',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Group Name',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _createGroup,
                        child: const Text('Create Group'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
