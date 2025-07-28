import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../main/presentation/screens/dashboard_screen.dart';

class GroupCreatedScreen extends StatelessWidget {
  final String groupName;
  final String groupCode;

  const GroupCreatedScreen({
    super.key,
    required this.groupName,
    required this.groupCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Created')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉 Group "$groupName" has been created!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            Text('Group Code:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SelectableText(groupCode,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: groupCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                        'Join my FrostHub group using code: $groupCode');
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  (route) => false,
                );
              },
              child: const Text('Continue to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
