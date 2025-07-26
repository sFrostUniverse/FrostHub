import 'package:flutter/material.dart';
import 'student_email_screen.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/features/group/presentation/screens/group_setup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String name;

  const RoleSelectionScreen({super.key, required this.name});

  void _selectStudent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentEmailScreen(name: name),
      ),
    );
  }

  void _selectAdmin(BuildContext context) async {
    try {
      await AuthService.signInAsAdmin(name: name);

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const GroupSetupScreen(role: 'admin'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Who are you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('Student'),
              onPressed: () => _selectStudent(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin'),
              onPressed: () => _selectAdmin(context),
            ),
          ],
        ),
      ),
    );
  }
}
