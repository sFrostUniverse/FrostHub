import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../main/presentation/screens/dashboard_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _isLoading = false;
  String? _generatedCode;

  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      print('Creating group for UID: $uid');

      final groupCode = _generateGroupCode();
      final groupRef = FirebaseFirestore.instance.collection('groups').doc();

      await groupRef.set({
        'groupName': groupName,
        'groupCode': groupCode,
        'adminUid': uid,
        'members': [uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Group created: ${groupRef.id}');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'groupId': groupRef.id,
        'role': 'admin',
      });
      print('User updated with groupId');

      setState(() {
        _generatedCode = groupCode;
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        print('Navigating to dashboard...');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during group creation: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Group')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Text(
                    'Enter your group name:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g., BTech CSE 2025',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createGroup,
                    child: const Text('Create Group'),
                  ),
                  if (_generatedCode != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Group Created! Share this code:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _generatedCode!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ]
                ],
              ),
      ),
    );
  }
}
