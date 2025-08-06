import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/syllabus/presentation/widgets/add_syllabus_modal.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  String? _groupId;
  String? _role;
  List<dynamic> _syllabus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndSyllabus();
  }

  Future<void> _loadUserDataAndSyllabus() async {
    final user = await AuthService.getUser();
    if (user == null) return;

    setState(() {
      _groupId = user['groupId'];
      _role = user['role'];
    });

    try {
      final data = await FrostCoreAPI.getSyllabus(_groupId!);
      setState(() {
        _syllabus = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch syllabus: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSyllabus(String syllabusId, String subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete "$subject"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FrostCoreAPI.deleteSyllabus(syllabusId);
      _loadUserDataAndSyllabus(); // refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syllabus'),
        actions: _role == 'admin' && _groupId != null
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddSyllabusModal(
                        groupId: _groupId!,
                        onAdded: _loadUserDataAndSyllabus,
                      ),
                    );
                  },
                )
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _syllabus.isEmpty
              ? const Center(child: Text('No subjects added yet.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _syllabus.map((item) {
                      final subject = item['subject'] ?? '';
                      final link = item['link'] ?? '';
                      final id = item['_id'];

                      return GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(link);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid link')),
                            );
                          }
                        },
                        onLongPress: _role == 'admin'
                            ? () => _deleteSyllabus(id, subject)
                            : null,
                        child: Chip(
                          label: Text(subject),
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
