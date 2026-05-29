import 'package:hive_flutter/hive_flutter.dart';
import '../models/memo_model.dart';
import '../../profile/services/user_service.dart';
import '../../../core/services/security_service.dart';

class MemoService {
  static const String memoBoxName = 'memos_box_v3';
  static const String categoryBoxName = 'memo_categories_box';

  static Future<void> init() async {
    await SecurityService.openEncryptedBox(memoBoxName);
    await Hive.openBox(categoryBoxName);
    await _ensureDefaultCategories();
  }

  static Future<void> _ensureDefaultCategories() async {
    final box = Hive.box(categoryBoxName);
    if (box.isEmpty) {
      final userId = UserService.currentUser?.id ?? 'default';
      final defaults = [
        MemoCategory(id: 'cat_general', userId: userId, name: 'عام', icon: '📝', colorValue: 0xFF607D8B),
        MemoCategory(id: 'cat_family', userId: userId, name: 'العائلة', icon: '🏠', colorValue: 0xFF4CAF50),
        MemoCategory(id: 'cat_work', userId: userId, name: 'العمل', icon: '💼', colorValue: 0xFF2196F3),
        MemoCategory(id: 'cat_travel', userId: userId, name: 'السفر', icon: '✈️', colorValue: 0xFFFF9800),
        MemoCategory(id: 'cat_memories', userId: userId, name: 'الذكريات', icon: '🎞️', colorValue: 0xFF9C27B0),
        MemoCategory(id: 'cat_ideas', userId: userId, name: 'الأفكار', icon: '💡', colorValue: 0xFFFFEB3B),
      ];
      for (var cat in defaults) {
        await box.put(cat.id, cat.toMap());
      }
    }
  }

  // --- Memos ---
  static List<Memo> getAllMemos({bool includeHidden = false}) {
    final box = Hive.box(memoBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((e) => Memo.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .where((e) => includeHidden || !e.isHidden)
        .toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.dateModified.compareTo(a.dateModified);
      });
  }

  static Future<void> saveMemo(Memo memo) async {
    final box = Hive.box(memoBoxName);
    await box.put(memo.id, memo.toMap());
  }

  static Future<void> deleteMemo(String id) async {
    final box = Hive.box(memoBoxName);
    await box.delete(id);
  }

  // --- Categories ---
  static List<MemoCategory> getCategories() {
    final box = Hive.box(categoryBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((e) => MemoCategory.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList();
  }

  static Future<void> saveCategory(MemoCategory category) async {
    final box = Hive.box(categoryBoxName);
    await box.put(category.id, category.toMap());
  }

  static Future<void> deleteCategory(String id) async {
    final box = Hive.box(categoryBoxName);
    await box.delete(id);
    
    // Optionally: Move memos in this category to 'General'
    final memos = getAllMemos(includeHidden: true).where((m) => m.categoryId == id).toList();
    for (var m in memos) {
      await saveMemo(m.copyWith(categoryId: 'cat_general'));
    }
  }
}
