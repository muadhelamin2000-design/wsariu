import 'package:hive_flutter/hive_flutter.dart';
import '../models/knowledge_section_model.dart';
import '../../profile/services/user_service.dart';

class KnowledgeService {
  static const String sectionBoxName = 'knowledge_sections';
  static const String entryBoxName = 'knowledge_entries';

  static Future<void> init() async {
    await Hive.openBox(sectionBoxName);
    await Hive.openBox(entryBoxName);
  }

  // Sections
  static List<KnowledgeSection> getSections() {
    final box = Hive.box(sectionBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((e) => KnowledgeSection.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList();
  }

  static Future<void> saveSection(KnowledgeSection section) async {
    final box = Hive.box(sectionBoxName);
    await box.put(section.id, section.toMap());
  }

  static Future<void> deleteSection(String id) async {
    final box = Hive.box(sectionBoxName);
    await box.delete(id);
    
    // Delete entries in this section
    final entries = getEntriesBySection(id);
    for (var e in entries) {
      await deleteEntry(e.id);
    }
  }

  // Entries
  static List<KnowledgeEntry> getAllEntries() {
    final box = Hive.box(entryBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((e) => KnowledgeEntry.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList();
  }

  static List<KnowledgeEntry> getEntriesBySection(String sectionId) {
    return getAllEntries().where((e) => e.sectionId == sectionId).toList();
  }

  static KnowledgeEntry? getEntryById(String id) {
    final box = Hive.box(entryBoxName);
    final data = box.get(id);
    if (data == null) return null;
    return KnowledgeEntry.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static Future<void> saveEntry(KnowledgeEntry entry) async {
    final box = Hive.box(entryBoxName);
    await box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    final entry = getEntryById(id);
    if (entry != null) {
      for (var linkedId in entry.linkedEntryIds) {
        await unlinkEntries(id, linkedId);
      }
    }
    final box = Hive.box(entryBoxName);
    await box.delete(id);
  }

  static Future<void> linkEntries(String id1, String id2) async {
    final e1 = getEntryById(id1);
    final e2 = getEntryById(id2);
    if (e1 != null && e2 != null) {
      if (!e1.linkedEntryIds.contains(id2)) {
        await saveEntry(e1.copyWith(linkedEntryIds: [...e1.linkedEntryIds, id2]));
      }
      if (!e2.linkedEntryIds.contains(id1)) {
        await saveEntry(e2.copyWith(linkedEntryIds: [...e2.linkedEntryIds, id1]));
      }
    }
  }

  static Future<void> unlinkEntries(String id1, String id2) async {
    final e1 = getEntryById(id1);
    final e2 = getEntryById(id2);
    if (e1 != null && e2 != null) {
      await saveEntry(e1.copyWith(linkedEntryIds: e1.linkedEntryIds.where((id) => id != id2).toList()));
      await saveEntry(e2.copyWith(linkedEntryIds: e2.linkedEntryIds.where((id) => id != id1).toList()));
    }
  }

  static List<KnowledgeEntry> searchEntries(String query) {
    final all = getAllEntries();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((e) =>
      e.title.toLowerCase().contains(q) ||
      e.content.toLowerCase().contains(q) ||
      e.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }
}
