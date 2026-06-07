import 'package:hive_flutter/hive_flutter.dart';
import '../models/sleep_model.dart';
import '../../profile/services/user_service.dart';

class SleepService {
  static const String boxName = 'sleep_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<SleepEntry> getEntries() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];
    
    return box.values
        .map((e) => SleepEntry.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.bedTime.compareTo(a.bedTime));
  }

  static Future<void> saveEntry(SleepEntry entry) async {
    final box = Hive.box(boxName);
    await box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  static Future<void> clearLog() async {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return;
    
    final keysToDelete = box.keys.where((key) {
      if (key.toString().startsWith('settings_')) return false;
      final val = box.get(key);
      if (val is Map && val['userId'] == currentUserId) return true;
      return false;
    }).toList();
    
    await box.deleteAll(keysToDelete);
  }

  static SleepEntry? getActiveEntry() {
    final entries = getEntries();
    if (entries.isEmpty) return null;
    final last = entries.first;
    if (last.wakeTime == null) return last;
    return null;
  }

  static List<DateTime> calculateWakeUpTimes(DateTime bedTime, int waitToFallAsleepMinutes) {
    final startTime = bedTime.add(Duration(minutes: waitToFallAsleepMinutes));
    // 2, 3, 4, 5, 6 cycles
    return List.generate(5, (index) => startTime.add(Duration(minutes: 90 * (index + 2))));
  }

  // --- Settings ---
  static Map<String, dynamic> getSettings() {
    final box = Hive.box(boxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return {};
    return Map<String, dynamic>.from(box.get('settings_$userId') ?? {});
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final box = Hive.box(boxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return;
    await box.put('settings_$userId', settings);
  }

  static Future<void> resetHabitsSelection() async {
    final settings = getSettings();
    final List habits = settings['allHabits'] ?? [];
    for (var h in habits) {
      h['selected'] = false;
    }
    settings['allHabits'] = habits;
    await saveSettings(settings);
  }
}
