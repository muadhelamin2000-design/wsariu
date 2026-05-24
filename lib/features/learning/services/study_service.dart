import 'package:hive_flutter/hive_flutter.dart';
import '../models/study_node_model.dart';
import '../../profile/services/user_service.dart';

class StudyService {
  static const String entryBoxName = 'study_entries_box';

  static Future<void> init() async {
    await Hive.openBox(entryBoxName);
  }

  // Entries
  static List<StudyEntry> getAllEntries() {
    final box = Hive.box(entryBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];
    return box.values
        .map((e) => StudyEntry.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList();
  }

  static List<StudyEntry> getEntriesBySection(String sectionId) {
    return getAllEntries().where((e) => e.sectionId == sectionId).toList();
  }

  static StudyEntry? getEntryById(String id) {
    final box = Hive.box(entryBoxName);
    final data = box.get(id);
    if (data == null) return null;
    return StudyEntry.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static Future<void> saveEntry(StudyEntry entry) async {
    final box = Hive.box(entryBoxName);
    await box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    final box = Hive.box(entryBoxName);
    final entry = getEntryById(id);
    if (entry != null) {
      for (var lid in entry.linkedIds) {
        await unlinkEntries(id, lid);
      }
    }
    await box.delete(id);
  }

  static Future<void> linkEntries(String id1, String id2) async {
    final e1 = getEntryById(id1);
    final e2 = getEntryById(id2);
    if (e1 != null && e2 != null) {
      if (!e1.linkedIds.contains(id2)) {
        await saveEntry(e1.copyWith(linkedIds: [...e1.linkedIds, id2]));
      }
      if (!e2.linkedIds.contains(id1)) {
        await saveEntry(e2.copyWith(linkedIds: [...e2.linkedIds, id1]));
      }
    }
  }

  static Future<void> unlinkEntries(String id1, String id2) async {
    final e1 = getEntryById(id1);
    final e2 = getEntryById(id2);
    if (e1 != null && e2 != null) {
      await saveEntry(e1.copyWith(linkedIds: e1.linkedIds.where((id) => id != id2).toList()));
      await saveEntry(e2.copyWith(linkedIds: e2.linkedIds.where((id) => id != id1).toList()));
    }
  }

  static List<StudyEntry> searchEntries(String query) {
    final all = getAllEntries();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((e) =>
      e.title.toLowerCase().contains(q) ||
      e.description.toLowerCase().contains(q) ||
      e.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }
}
