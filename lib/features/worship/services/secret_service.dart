import 'package:hive_flutter/hive_flutter.dart';
import '../models/secret_model.dart';
import '../../profile/services/user_service.dart';
import '../../../core/services/security_service.dart';

class SecretService {
  static const String secretEntriesBox = 'secret_entries_box_v2';
  static const String charityMonthsBox = 'charity_months_box_v2';

  static Future<void> init() async {
    await SecurityService.openEncryptedBox(secretEntriesBox);
    await SecurityService.openEncryptedBox(charityMonthsBox);
  }

  // --- Secret Entries ---
  static List<SecretEntry> getEntries(SecretType type) {
    final box = Hive.box(secretEntriesBox);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id')) // فلترة القيم لضمان أنها قيود وليست إعدادات
        .map((e) => SecretEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => e.userId == currentUserId && e.type == type)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveEntry(SecretEntry entry) async {
    final box = Hive.box(secretEntriesBox);
    await box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    await Hive.box(secretEntriesBox).delete(id);
  }

  // --- Monthly Charity ---
  static List<CharityMonth> getCharityMonths() {
    final box = Hive.box(charityMonthsBox);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((m) => CharityMonth.fromMap(Map<dynamic, dynamic>.from(m)))
        .where((m) => m.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveCharityMonth(CharityMonth month) async {
    final box = Hive.box(charityMonthsBox);
    await box.put(month.id, month.toMap());
  }

  static Future<void> deleteCharityMonth(String id) async {
    await Hive.box(charityMonthsBox).delete(id);
  }

  // --- Settings ---
  static bool getBlurSetting() {
    final box = Hive.box(secretEntriesBox);
    return box.get('is_blurred', defaultValue: false);
  }

  static Future<void> saveBlurSetting(bool isBlurred) async {
    final box = Hive.box(secretEntriesBox);
    await box.put('is_blurred', isBlurred);
  }
}
