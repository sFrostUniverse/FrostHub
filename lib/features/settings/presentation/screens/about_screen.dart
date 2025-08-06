import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About FrostHub')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              'About FrostHub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'FrostHub is a student app designed to provide seamless access to your academic schedule, group announcements, chats, and notes—all powered by a custom backend without Firebase.\n\n'
              'Key Features:\n'
              '- Class timetable and reminders\n'
              '- Group announcements and chat\n'
              '- Notes and syllabus management\n\n'
              'This app is developed by Sehaj Arora, a student at Thapar University (COPC branch). It aims to simplify university life by integrating all essential academic tools into one place.\n\n'
              'Unlike many apps, FrostHub does not use Firebase for backend services; instead, it uses a custom backend called FrostCore for more control and customization.\n\n'
              'Thank you for using FrostHub!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
