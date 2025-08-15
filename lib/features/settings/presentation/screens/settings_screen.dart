import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frosthub/theme/theme_provider.dart';
import 'package:frosthub/theme/time_format_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final timeFormatProvider = Provider.of<TimeFormatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'General',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Theme selector
            DropdownButtonFormField<ThemeMode>(
              value: themeProvider.themeMode,
              decoration: const InputDecoration(
                labelText: 'Theme',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  themeProvider.setTheme(mode);
                }
              },
            ),

            const SizedBox(height: 24),

            // Time format toggle
            SwitchListTile(
              title: const Text('Use 24-hour time format'),
              value: timeFormatProvider.is24Hour,
              onChanged: timeFormatProvider.toggleFormat,
            ),
          ],
        ),
      ),
    );
  }
}
