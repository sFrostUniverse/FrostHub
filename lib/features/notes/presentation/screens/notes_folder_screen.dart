import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/frostcore_api.dart';
import '../../../../services/auth_service.dart'; // assuming you store user/group info here
import 'package:frosthub/services/socket_service.dart';

class NotesFolderScreen extends StatefulWidget {
  final String? parentId; // null for root
  final String title;

  const NotesFolderScreen({super.key, this.parentId, required this.title});

  @override
  State<NotesFolderScreen> createState() => _NotesFolderScreenState();
}

class _NotesFolderScreenState extends State<NotesFolderScreen> {
  bool isAdmin = false;
  String? _groupId;
  bool _isLoading = true;
  List<dynamic> _notes = [];

  @override
  void initState() {
    super.initState();
    _initializeNotes();

    SocketService().socket.on('note-updated', (_) {
      if (mounted) _fetchNotes(); // only fetch notes
    });
  }

  Future<void> _initializeNotes() async {
    final user = await AuthService.getUser();
    if (user == null) return;

    setState(() {
      isAdmin = user['role'] == 'admin';
      _groupId = user['groupId'];
    });

    SocketService().joinGroup(_groupId!);
    await _fetchNotes(); // fetch notes separately
  }

  Future<void> _fetchNotes() async {
    if (_groupId == null) {
      print('❌ Group ID is null');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final notes = await FrostCoreAPI.getNotes(_groupId!, widget.parentId);
      print('📥 Notes fetched: $notes');

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching notes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Add PDF Link'),
              onTap: () {
                Navigator.pop(context);
                _showAddPdfDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty || _groupId == null) return;

              await FrostCoreAPI.createNote(
                groupId: _groupId!,
                title: name,
                type: 'folder',
                parentId: widget.parentId,
              );
              Navigator.pop(context);
              _fetchNotes();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddPdfDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add PDF Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'PDF URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final url = urlController.text.trim();
              if (title.isEmpty || url.isEmpty || _groupId == null) return;

              await FrostCoreAPI.createNote(
                groupId: _groupId!,
                title: title,
                type: 'file',
                url: url,
                parentId: widget.parentId,
              );
              Navigator.pop(context);
              _fetchNotes();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('No items yet.'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final title = note['title'] ?? 'Untitled';
                    final type = note['type'];

                    if (type == 'folder') {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(title),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotesFolderScreen(
                                  parentId: note['_id'],
                                  title: title,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    } else if (type == 'file') {
                      final url = note['url'] ?? '';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(title),
                          onTap: () async {
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
