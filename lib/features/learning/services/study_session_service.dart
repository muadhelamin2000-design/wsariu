import 'package:hive_flutter/hive_flutter.dart';
import '../models/study_session_model.dart';
import '../../profile/services/user_service.dart';

class StudySessionService {
  static const String boxName = 'study_sessions_box';
  static const String categoryBoxName = 'study_session_categories_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
    await Hive.openBox(categoryBoxName);
  }

  static List<StudySession> getAllSessions() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((e) => StudySession.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveSession(StudySession session) async {
    final box = Hive.box(boxName);
    await box.put(session.id, session.toMap());
  }

  static List<String> getCategories() {
    final box = Hive.box(categoryBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return ['عام'];
    
    final List<String> categories = box.get(currentUserId, defaultValue: <String>['طب', 'برمجة', 'قراءة كتاب', 'عام']).cast<String>();
    return categories;
  }

  static Future<void> addCategory(String category) async {
    final box = Hive.box(categoryBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return;
    
    final List<String> categories = List<String>.from(getCategories());
    if (!categories.contains(category)) {
      categories.add(category);
      await box.put(currentUserId, categories);
    }
  }
}
