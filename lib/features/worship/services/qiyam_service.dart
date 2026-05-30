import 'package:hive_flutter/hive_flutter.dart';
import '../models/qiyam_model.dart';
import '../../profile/services/user_service.dart';

class QiyamService {
  static const String boxName = 'qiyam_sessions_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<QiyamSession> getSessions() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    // جلب كل الجلسات وتجميعها برمجياً لضمان عرض موحد حتى لو كانت مخزنة بشكل منفصل
    final rawSessions = box.values
        .where((v) => v is Map && v.containsKey('userId'))
        .map((e) => QiyamSession.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((s) => s.userId == currentUserId)
        .toList();

    final Map<String, QiyamSession> grouped = {};
    for (var s in rawSessions) {
      final dayKey = "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}";
      if (grouped.containsKey(dayKey)) {
        final existing = grouped[dayKey]!;
        grouped[dayKey] = QiyamSession(
          id: dayKey, // نستخدم مفتاح اليوم كـ ID للمجموعة
          userId: currentUserId,
          date: existing.date,
          totalPrayerMinutes: existing.totalPrayerMinutes + s.totalPrayerMinutes,
          totalBreakMinutes: existing.totalBreakMinutes + s.totalBreakMinutes,
          segments: [...existing.segments, ...s.segments],
        );
      } else {
        grouped[dayKey] = QiyamSession(
          id: dayKey,
          userId: s.userId,
          date: s.date,
          totalPrayerMinutes: s.totalPrayerMinutes,
          totalBreakMinutes: s.totalBreakMinutes,
          segments: s.segments,
        );
      }
    }

    return grouped.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveSession(QiyamSession session) async {
    final box = Hive.box(boxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return;

    final String dayKey = "${userId}_${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}";
    
    final existingData = box.get(dayKey);
    if (existingData != null) {
      final existingSession = QiyamSession.fromMap(Map<dynamic, dynamic>.from(existingData));
      
      final mergedSession = QiyamSession(
        id: existingSession.id,
        userId: userId,
        date: existingSession.date,
        totalPrayerMinutes: existingSession.totalPrayerMinutes + session.totalPrayerMinutes,
        totalBreakMinutes: existingSession.totalBreakMinutes + session.totalBreakMinutes,
        segments: [...existingSession.segments, ...session.segments],
      );
      await box.put(dayKey, mergedSession.toMap());
    } else {
      await box.put(dayKey, session.toMap());
    }
  }

  static Future<void> deleteSessionByDate(DateTime date) async {
    final box = Hive.box(boxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return;

    final String dayKey = "${userId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // حذف المفتاح الأساسي (الجديد)
    await box.delete(dayKey);

    // حذف أي جلسات قديمة قد تكون مخزنة بمعرفات مختلفة لنفس اليوم
    final keysToDelete = box.keys.where((k) {
      final s = box.get(k);
      if (s is Map && s['userId'] == userId) {
        final sDate = DateTime.parse(s['date']);
        return sDate.year == date.year && sDate.month == date.month && sDate.day == date.day;
      }
      return false;
    }).toList();

    for (var k in keysToDelete) {
      await box.delete(k);
    }
  }

  static int getTodayTotalPrayerMinutes() {
    final now = DateTime.now();
    final sessions = getSessions().where((s) => 
      s.date.year == now.year && s.date.month == now.month && s.date.day == now.day
    );
    return sessions.fold(0, (sum, s) => sum + s.totalPrayerMinutes);
  }
}
