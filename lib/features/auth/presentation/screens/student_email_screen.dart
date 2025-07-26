import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/services/auth_service.dart';

class StudentEmailScreen extends StatefulWidget {
  final String name;

  const StudentEmailScreen({super.key, required this.name});

  @override
  State<StudentEmailScreen> createState() => _StudentEmailScreenState();
}

class _StudentEmailScreenState extends State<StudentEmailScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await AuthService.sendSignInLink(email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link sent! Check your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Sign-In")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, ${widget.name}!"),
            const SizedBox(height: 12),
            const Text("Enter your email to receive a sign-in link:"),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'yourname@example.com',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSending ? null : _sendLink,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Send Sign-In Link"),
            ),
          ],
        ),
      ),
    );
  }
}
