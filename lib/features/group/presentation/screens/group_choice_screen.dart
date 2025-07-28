import 'package:flutter/material.dart';
import 'group_setup_screen.dart'; // Make sure this path is correct
// (we'll create this next)

class GroupChoiceScreen extends StatelessWidget {
  const GroupChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Group Option')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to FrostHub!\nJoin or create a group to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupSetupScreen()),
                );
              },
              child: const Text('Create a Group'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/join-group');
              },
              child: const Text('Join a Group'),
            ),
          ],
        ),
      ),
    );
  }
}
