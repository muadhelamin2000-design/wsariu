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
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return [];
    return box.values
        .map((e) => QiyamSession.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((s) => s.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveSession(QiyamSession session) async {
    final box = Hive.box(boxName);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return;

    // البحث عن جلسة موجودة لنفس اليوم
    final existingKey = box.keys.firstWhere(
      (k) {
        final s = box.get(k);
        if (s is Map && s['userId'] == userId) {
          final sDate = DateTime.parse(s['date']);
          return sDate.year == session.date.year && 
                 sDate.month == session.date.month && 
                 sDate.day == session.date.day;
        }
        return false;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      final existingMap = Map<dynamic, dynamic>.from(box.get(existingKey));
      final existingSession = QiyamSession.fromMap(existingMap);
      
      // دمج الجلسات
      final mergedSession = QiyamSession(
        id: existingSession.id,
        userId: userId,
        date: existingSession.date,
        totalPrayerMinutes: existingSession.totalPrayerMinutes + session.totalPrayerMinutes,
        totalBreakMinutes: existingSession.totalBreakMinutes + session.totalBreakMinutes,
        segments: [...existingSession.segments, ...session.segments],
      );
      await box.put(existingKey, mergedSession.toMap());
    } else {
      await box.put(session.id, session.toMap());
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
