import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key});

  Future<Map<String, dynamic>?> _getGroupData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final groupId = userDoc.data()?['groupId'];
    final role = userDoc.data()?['role'];

    if (groupId == null) return null;

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();
    final groupCode = groupDoc.data()?['groupCode'];

    final membersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('groupId', isEqualTo: groupId)
        .get();

    final members = membersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Unnamed',
        'role': data['role'] ?? 'student',
        'email': data['email'] ?? '',
      };
    }).toList();

    // Sort: Admin first, then by name
    members.sort((a, b) {
      if (a['role'] == 'admin') return -1;
      if (b['role'] == 'admin') return 1;
      return a['name'].toLowerCase().compareTo(b['name'].toLowerCase());
    });

    return {
      'role': role,
      'groupCode': groupCode,
      'members': members,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Group Info")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getGroupData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text("Unable to load group data."));
          }

          final members = data['members'] as List<dynamic>;
          final isAdmin = data['role'] == 'admin';
          final groupCode = data['groupCode'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAdmin) ...[
                const Text("Group Code",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(groupCode ?? 'N/A',
                          style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: groupCode ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group code copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text("Members",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...members.map((member) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(member['name']),
                    subtitle: Text('${member['email']} • ${member['role']}'),
                    trailing: member['role'] == 'admin'
                        ? const Icon(Icons.star, color: Colors.amber)
                        : null,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
