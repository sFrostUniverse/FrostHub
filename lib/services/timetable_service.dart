import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';

class TimetableService {
  static final _firestore = FirebaseFirestore.instance;

  /// Save a new timetable entry to a specific group
  static Future<void> addEntry(String groupId, TimetableEntry entry) async {
    final docRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('timetable')
        .doc(entry.id);

    await docRef.set(entry.toMap());
  }

  /// Get all timetable entries for a specific group
  static Future<List<TimetableEntry>> getEntries(String groupId) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('timetable')
        .get();

    return snapshot.docs
        .map((doc) => TimetableEntry.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Delete a timetable entry
  static Future<void> deleteEntry(String groupId, String entryId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('timetable')
        .doc(entryId)
        .delete();
  }
}
