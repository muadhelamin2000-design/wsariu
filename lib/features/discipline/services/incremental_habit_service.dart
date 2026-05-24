import 'package:hive_flutter/hive_flutter.dart';
import '../models/incremental_habit_model.dart';
import 'notification_service.dart';
import '../../profile/services/user_service.dart';
import '../../dashboard/services/prayer_service.dart';

class IncrementalHabitService {
  static const String boxName = 'incremental_habits_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<IncrementalHabit> getHabits() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];
    
    return box.values
        .map((h) => IncrementalHabit.fromMap(Map<dynamic, dynamic>.from(h)))
        .where((h) => h.userId == currentUserId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveHabitsOrder(List<IncrementalHabit> habits) async {
    final box = Hive.box(boxName);
    for (int i = 0; i < habits.length; i++) {
      final updated = habits[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
  }

  static Future<void> saveHabit(IncrementalHabit habit) async {
    final box = Hive.box(boxName);
    await box.put(habit.id, habit.toMap());

    if (habit.reminderTime != null) {
      await NotificationService.scheduleNotification(
        id: habit.id.hashCode,
        title: 'موعد تحدي وتزودوا: ${habit.title}',
        body: 'حان الوقت للتقدم في تحدي ${habit.title}',
        time: habit.reminderTime!,
      );
    } else {
      await NotificationService.cancelNotification(habit.id.hashCode);
    }
  }

  static Future<void> deleteHabit(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
    await NotificationService.cancelNotification(id.hashCode);
  }

  static Future<void> updateProgress(String id, DateTime date, double value) async {
    final box = Hive.box(boxName);
    final habitMap = box.get(id);
    if (habitMap != null) {
      final habit = IncrementalHabit.fromMap(Map<dynamic, dynamic>.from(habitMap));
      
      // إذا كان التاريخ هو اليوم، نستخدم التاريخ الإسلامي، وإلا نستخدم التاريخ الممرر
      final now = DateTime.now();
      final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final targetDate = isToday ? PrayerService.getIslamicDayDate() : date;
      
      final String dateKey = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      
      final newLog = Map<String, double>.from(habit.executionLog);
      double currentVal = newLog[dateKey] ?? 0;
      newLog[dateKey] = currentVal + value;
      if (newLog[dateKey]! < 0) newLog[dateKey] = 0;
      
      final updatedHabit = habit.copyWith(executionLog: newLog);
      await box.put(id, updatedHabit.toMap());
    }
  }
}
