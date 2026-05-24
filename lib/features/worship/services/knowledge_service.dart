import 'package:hive_flutter/hive_flutter.dart';
import '../models/knowledge_model.dart';
import '../../profile/services/user_service.dart';

class KnowledgeService {
  static const String boxName = 'knowledge_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<KnowledgeEntry> getEntries(KnowledgeType? type) {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    var entries = box.values
        .map((e) => KnowledgeEntry.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId);

    if (type != null) {
      entries = entries.where((e) => e.type == type);
    }

    return entries.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveEntry(KnowledgeEntry entry) async {
    final box = Hive.box(boxName);
    await box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    await Hive.box(boxName).delete(id);
  }

  static List<KnowledgeEntry> searchEntries(String query) {
    if (query.isEmpty) return getEntries(null);
    
    final all = getEntries(null);
    return all.where((e) =>
      e.contentText.contains(query) ||
      (e.sourceName?.contains(query) ?? false) ||
      e.benefits.any((b) => b.contains(query)) ||
      e.tags.any((t) => t.contains(query))
    ).toList();
  }
}
