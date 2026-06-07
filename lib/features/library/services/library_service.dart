import 'package:hive_flutter/hive_flutter.dart';
import '../models/library_models.dart';
import '../../profile/services/user_service.dart';

class LibraryService {
  static const String categoryBoxName = 'library_categories_box';
  static const String fileBoxName = 'library_files_box';

  static Future<void> init() async {
    await Hive.openBox(categoryBoxName);
    await Hive.openBox(fileBoxName);
  }

  // --- Categories ---
  static List<LibraryCategory> getCategories({String? parentId, LibraryType type = LibraryType.pdf, bool includeAll = false}) {
    final box = Hive.box(categoryBoxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return [];

    var entries = box.values
        .map((e) => LibraryCategory.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId && e.type == type);

    if (!includeAll) {
      entries = entries.where((e) => e.parentId == parentId);
    }

    return entries.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveCategory(LibraryCategory category) async {
    await Hive.box(categoryBoxName).put(category.id, category.toMap());
  }

  static Future<void> saveCategoriesOrder(List<LibraryCategory> categories) async {
    final box = Hive.box(categoryBoxName);
    for (int i = 0; i < categories.length; i++) {
      final updated = categories[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
  }

  static Future<void> deleteCategory(String id) async {
    final box = Hive.box(categoryBoxName);
    final data = box.get(id);
    if (data == null) return;
    
    final category = LibraryCategory.fromMap(Map<dynamic, dynamic>.from(data));
    await box.delete(id);
    
    final files = getFiles(categoryId: id, type: category.type);
    for (var f in files) {
      await deleteFile(f.id);
    }

    final subs = getCategories(parentId: id, type: category.type);
    for (var s in subs) {
      await deleteCategory(s.id);
    }
  }

  // --- Files ---
  static List<LibraryFile> getFiles({String? categoryId, bool? isFavorite, LibraryType type = LibraryType.pdf}) {
    final box = Hive.box(fileBoxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return [];

    var entries = box.values
        .map((e) => LibraryFile.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId && e.type == type);

    if (categoryId != null) {
      entries = entries.where((e) => e.categoryId == categoryId);
    }
    if (isFavorite != null) {
      entries = entries.where((e) => e.isFavorite == isFavorite);
    }

    return entries.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveFile(LibraryFile file) async {
    await Hive.box(fileBoxName).put(file.id, file.toMap());
  }

  static LibraryFile? getFileById(String id) {
    final box = Hive.box(fileBoxName);
    final data = box.get(id);
    if (data == null) return null;
    return LibraryFile.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static Future<void> saveFilesOrder(List<LibraryFile> files) async {
    final box = Hive.box(fileBoxName);
    for (int i = 0; i < files.length; i++) {
      final updated = files[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
  }

  static Future<void> deleteFile(String id) async {
    await Hive.box(fileBoxName).delete(id);
  }

  static Future<void> updateCurrentUnit(String fileId, int unit) async {
    final box = Hive.box(fileBoxName);
    final data = box.get(fileId);
    if (data != null) {
      final file = LibraryFile.fromMap(Map<dynamic, dynamic>.from(data));
      bool isNowCompleted = file.isCompleted;
      if (unit >= file.totalUnits && file.totalUnits > 0) {
        isNowCompleted = true;
      }
      final updated = file.copyWith(currentUnit: unit, lastOpenedAt: DateTime.now(), isCompleted: isNowCompleted);
      await saveFile(updated);
    }
  }

  static Future<void> toggleCompletion(String fileId) async {
    final box = Hive.box(fileBoxName);
    final data = box.get(fileId);
    if (data != null) {
      final file = LibraryFile.fromMap(Map<dynamic, dynamic>.from(data));
      final updated = file.copyWith(isCompleted: !file.isCompleted);
      await saveFile(updated);
    }
  }

  static List<LibraryFile> searchFiles(String query, {LibraryType type = LibraryType.pdf}) {
    final all = getFiles(type: type);
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  static double getCategoryProgress(String categoryId, LibraryType type) {
    final files = getFiles(categoryId: categoryId, type: type);
    if (files.isEmpty) return 0.0;
    
    int completedCount = files.where((f) => f.isCompleted).length;
    return completedCount / files.length;
  }
}
