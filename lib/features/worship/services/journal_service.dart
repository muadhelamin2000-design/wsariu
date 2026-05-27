import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_model.dart';
import '../../profile/services/user_service.dart';
import '../../../core/services/security_service.dart';

class JournalService {
  static const String boxName = 'journal_box_v2';

  static Future<void> init() async {
    await SecurityService.openEncryptedBox(boxName);
  }

  static JournalEntry? getEntryForDate(DateTime date) {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return null;

    final String dateKey = "${currentUserId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final data = box.get(dateKey);
    if (data == null) return null;
    
    return JournalEntry.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static Future<void> saveEntry(JournalEntry entry) async {
    final box = Hive.box(boxName);
    final String dateKey = "${entry.userId}_${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}";
    await box.put(dateKey, entry.toMap());
  }

  static List<JournalEntry> getAllEntries() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((e) => JournalEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => e.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Settings ---
  static bool getBlurSetting() {
    final box = Hive.box(boxName);
    return box.get('is_blurred', defaultValue: false);
  }

  static Future<void> saveBlurSetting(bool isBlurred) async {
    final box = Hive.box(boxName);
    await box.put('is_blurred', isBlurred);
  }
}
