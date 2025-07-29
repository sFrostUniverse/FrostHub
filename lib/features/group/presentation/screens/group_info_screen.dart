import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  String? _groupId;
  String? _groupCode;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not signed in.');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      if (userData == null) {
        print('User document not found.');
        return;
      }

      final groupId = userData['groupId'] as String?;
      final isAdmin = userData['role'] == 'admin';

      String? groupCode;

      if (groupId != null) {
        final groupDoc = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .get();

        final groupData = groupDoc.data();
        groupCode = groupData?['groupCode'];

        print('Group found: $groupId, code: $groupCode');
      } else {
        print('User has no groupId.');
      }

      setState(() {
        _groupId = groupId;
        _isAdmin = isAdmin;
        _groupCode = groupCode;
      });
    } catch (e) {
      print('Error loading group info: $e');
    }
  }

  Stream<List<QueryDocumentSnapshot>> getSortedGroupMembers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('groupId', isEqualTo: _groupId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final roleA = a['role'];
        final roleB = b['role'];
        if (roleA == 'admin' && roleB != 'admin') return -1;
        if (roleA != 'admin' && roleB == 'admin') return 1;
        return 0;
      });
      return docs;
    });
  }

  void _shareInstallLink() async {
    const apkUrl =
        'https://github.com/sFrostUniverse/FrostHub/raw/main/apk/app-release.apk';
    final message =
        'Join our FrostHub group! Download the app:\n$apkUrl\nThen enter the group code: $_groupCode';

    final Uri url =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open share dialog')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = _groupId;

    if (groupId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Info')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: _isAdmin && _groupCode != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      'Code: $_groupCode',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ]
            : null,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('groupId', isEqualTo: groupId) // ✅ only runs when ready
            .snapshots()
            .map((snapshot) {
          final docs = snapshot.docs;
          docs.sort((a, b) {
            final roleA = a['role'];
            final roleB = b['role'];
            if (roleA == 'admin' && roleB != 'admin') return -1;
            if (roleA != 'admin' && roleB == 'admin') return 1;
            return 0;
          });
          return docs;
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!;
          if (members.isEmpty) {
            return const Center(child: Text('No group members found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final member = members[index];
              final name = member['name'] ?? 'Unnamed';
              final email = member['email'] ?? '';
              final role = member['role'] ?? 'student';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin'
                      ? Colors.blue.shade700
                      : Colors.grey.shade400,
                  child: Text(name.isNotEmpty ? name[0] : '?'),
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: role == 'admin' ? Colors.blue : Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _shareInstallLink,
              tooltip: 'Invite to Group',
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
