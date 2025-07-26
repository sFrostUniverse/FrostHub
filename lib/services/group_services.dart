import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  static final _firestore = FirebaseFirestore.instance;
  static final _groupsCollection = _firestore.collection('groups');

  /// Create a new group (used by Admin)
  static Future<void> createGroup(GroupModel group) async {
    await _groupsCollection.doc(group.id).set(group.toMap());
  }

  /// Join existing group (used by Student)
  static Future<void> joinGroup(String groupId, String userId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (!doc.exists) throw Exception("Group not found");

    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId])
    });
  }

  static Future<GroupModel?> getGroup(String groupId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _groupsCollection.doc(groupId).get();

    final data = doc.data();
    if (data == null) return null;

    return GroupModel.fromMap(doc.id, data);
  }

  /// Check if a group with given ID exists
  static Future<bool> groupExists(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    return doc.exists;
  }
}
