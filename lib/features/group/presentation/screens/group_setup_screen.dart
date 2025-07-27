import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:frosthub/models/group_model.dart';
import 'package:frosthub/services/group_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupSetupScreen extends StatefulWidget {
  final String role;

  const GroupSetupScreen({super.key, required this.role});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _isLoading = false;

  void _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final groupId = const Uuid().v4();
    final group = GroupModel(
      id: groupId,
      name: groupName,
      createdBy: user.uid,
      members: [user.uid],
    );

    try {
      await GroupService.createGroup(group);

      // Link user to the group
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'groupId': groupId});

      // Force-refresh the user data before navigating
      final updatedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final updatedGroupId = updatedDoc.data()?['groupId'];
      if (updatedGroupId != null && updatedGroupId.isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Group creation incomplete. Try again.')),
        );
      }

      // ✅ Go to dashboard and clear previous stack
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Enter Group Name', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createGroup,
                    child: const Text('Create Group'),
                  ),
          ],
        ),
      ),
    );
  }
}
