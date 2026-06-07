import 'package:hive_flutter/hive_flutter.dart';
import '../models/memo_model.dart';
import '../../profile/services/user_service.dart';
import '../../../core/services/security_service.dart';

class MemoService {
  static const String categoryBoxName = 'memo_categories_v4';
  static const String noteBoxName = 'memo_notes_v4';
  static const String ideaBoxName = 'memo_ideas_v4';

  static Future<void> init() async {
    await Hive.openBox(categoryBoxName);
    await SecurityService.openEncryptedBox(noteBoxName);
    await Hive.openBox(ideaBoxName);
  }

  // --- Categories ---
  static List<MemoCategory> getCategories() {
    final box = Hive.box(categoryBoxName);
    final userId = UserService.currentUser?.id;
    if (userId == null) return [];
    return box.values
        .map((e) => MemoCategory.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId)
        .toList();
  }

  static Future<void> saveCategory(MemoCategory category) async {
    final box = Hive.box(categoryBoxName);
    await box.put(category.id, category.toMap());
  }

  static Future<void> deleteCategory(String id) async {
    final box = Hive.box(categoryBoxName);
    await box.delete(id);
    // Optionally move notes to 'Uncategorized'
  }

  // --- Notes ---
  static List<MemoNote> getNotes({String? categoryId, bool showArchived = false, bool showDeleted = false}) {
    final box = Hive.box(noteBoxName);
    final userId = UserService.currentUser?.id;
    if (userId == null) return [];
    return box.values
        .map((e) => MemoNote.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId)
        .where((e) => categoryId == null || e.categoryId == categoryId)
        .where((e) => e.isArchived == showArchived)
        .where((e) => e.isDeleted == showDeleted)
        .toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.dateModified.compareTo(a.dateModified);
      });
  }

  static Future<void> saveNote(MemoNote note) async {
    final box = Hive.box(noteBoxName);
    await box.put(note.id, note.toMap());
  }

  static Future<void> deleteNotePermanently(String id) async {
    final box = Hive.box(noteBoxName);
    await box.delete(id);
  }

  // --- Compatibility ---
  static List<MemoNote> getAllMemos() {
    return getNotes(showArchived: true, showDeleted: true);
  }

  // --- Ideas ---
  static List<MemoIdea> getIdeas() {
    final box = Hive.box(ideaBoxName);
    final userId = UserService.currentUser?.id;
    if (userId == null) return [];
    return box.values
        .map((e) => MemoIdea.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveIdea(MemoIdea idea) async {
    final box = Hive.box(ideaBoxName);
    await box.put(idea.id, idea.toMap());
  }

  static Future<void> deleteIdea(String id) async {
    final box = Hive.box(ideaBoxName);
    await box.delete(id);
  }
}
