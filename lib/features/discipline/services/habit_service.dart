import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit_model.dart';
import '../../profile/services/user_service.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import '../../dashboard/services/prayer_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/services/badge_service.dart';

class HabitService {
  static const String boxName = 'habits_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<Habit> getHabits() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];
    
    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((h) => Habit.fromMap(Map<dynamic, dynamic>.from(h as Map)))
        .where((h) => h.userId == currentUserId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Habit? getHabitById(String id) {
    final box = Hive.box(boxName);
    final data = box.get(id);
    if (data == null) return null;
    return Habit.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static Future<void> saveHabitsOrder(List<Habit> habits) async {
    final box = Hive.box(boxName);
    for (int i = 0; i < habits.length; i++) {
      final updated = habits[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
    WidgetService.updateAllWidgets();
  }

  static Future<void> saveHabit(Habit habit) async {
    final box = Hive.box(boxName);
    await box.put(habit.id, habit.toMap());
    
    await NotificationService.scheduleHabitReminders(habit);
    WidgetService.updateAllWidgets();
  }

  static Future<void> deleteHabit(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
    await NotificationService.cancelNotification(id.hashCode);
    WidgetService.updateAllWidgets();
  }

  static Map<String, dynamic> getSectionMetadata(HabitGoal goal) {
    final box = Hive.box(boxName);
    final key = 'section_metadata_${goal.index}';
    final data = box.get(key);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return {
      'title': goal == HabitGoal.good ? 'عادات جيدة' : 'عادات سيئة',
      'color': goal == HabitGoal.good ? 0xFF0F3D2E : 0xFFB71C1C,
      'emoji': goal == HabitGoal.good ? '🌟' : '⚠️',
    };
  }

  static Future<void> saveSectionMetadata(HabitGoal goal, Map<String, dynamic> metadata) async {
    final box = Hive.box(boxName);
    final key = 'section_metadata_${goal.index}';
    await box.put(key, metadata);
  }

  static List<HabitGoal> getSectionsOrder() {
    final box = Hive.box(boxName);
    final data = box.get('sections_order');
    if (data != null) {
      return (data as List).map((e) => HabitGoal.values[e as int]).toList();
    }
    return [HabitGoal.good, HabitGoal.bad];
  }

  static Future<void> saveSectionsOrder(List<HabitGoal> order) async {
    final box = Hive.box(boxName);
    await box.put('sections_order', order.map((e) => e.index).toList());
  }

  static Future<void> toggleHabitCompletion(String id, DateTime date, double value) async {
    final box = Hive.box(boxName);
    final habitMap = box.get(id);
    if (habitMap != null) {
      final habit = Habit.fromMap(Map<dynamic, dynamic>.from(habitMap));
      
      final now = DateTime.now();
      final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final targetDate = isToday ? PrayerService.getIslamicDayDate() : date;
      
      final String dateKey = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      
      final newLog = Map<String, double>.from(habit.completionLog);
      if (habit.type == HabitType.fixed) {
        if (newLog.containsKey(dateKey)) {
          newLog.remove(dateKey);
        } else {
          newLog[dateKey] = 1.0;
        }
      } else {
        double currentVal = newLog[dateKey] ?? 0;
        newLog[dateKey] = currentVal + value;
        if (newLog[dateKey]! <= 0) newLog.remove(dateKey);
      }
      
      final updatedHabit = habit.copyWith(completionLog: newLog);
      await box.put(id, updatedHabit.toMap());
      
      // التحقق من الدروع الجديدة عند الإنجاز
      if (updatedHabit.challengeStartDate != null) {
        int streak = 0;
        DateTime checkDate = DateTime.now();
        DateTime start = updatedHabit.challengeStartDate!;
        DateTime startDateOnly = DateTime(start.year, start.month, start.day);
        while (!checkDate.isBefore(startDateOnly)) {
          String dk = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
          if (newLog.containsKey(dk)) { streak++; checkDate = checkDate.subtract(const Duration(days: 1)); }
          else break;
        }
        await BadgeService.checkAndUnlockShield('habit_$id', streak);
      }

      WidgetService.updateAllWidgets();
    }
  }

  static Future<void> updateHabitValue(String id, DateTime date, double value) async {
    final box = Hive.box(boxName);
    final habitMap = box.get(id);
    if (habitMap != null) {
      final habit = Habit.fromMap(Map<dynamic, dynamic>.from(habitMap));
      final now = DateTime.now();
      final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final targetDate = isToday ? PrayerService.getIslamicDayDate() : date;
      
      final String dateKey = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      
      final newLog = Map<String, double>.from(habit.completionLog);
      newLog[dateKey] = value;
      if (newLog[dateKey]! <= 0) newLog.remove(dateKey);
      
      final updatedHabit = habit.copyWith(completionLog: newLog);
      await box.put(id, updatedHabit.toMap());
      WidgetService.updateAllWidgets();
    }
  }

  static Future<void> resetAllHabitsCompletion() async {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return;

    final allHabits = getHabits();
    final now = DateTime.now();
    for (var habit in allHabits) {
      if (habit.userId == currentUserId) {
        final updatedHabit = habit.copyWith(
          completionLog: {},
          createdAt: now,
        );
        await box.put(habit.id, updatedHabit.toMap());
      }
    }
    WidgetService.updateAllWidgets();
  }

  static Future<void> resetHabitCompletion(String id) async {
    final box = Hive.box(boxName);
    final habitMap = box.get(id);
    if (habitMap != null) {
      final habit = Habit.fromMap(Map<dynamic, dynamic>.from(habitMap));
      final updatedHabit = habit.copyWith(
        completionLog: {},
        createdAt: DateTime.now(),
      );
      await box.put(id, updatedHabit.toMap());
      WidgetService.updateAllWidgets();
    }
  }

  static Future<void> startChallenge(String id) async {
    final box = Hive.box(boxName);
    final habitMap = box.get(id);
    if (habitMap != null) {
      final habit = Habit.fromMap(Map<dynamic, dynamic>.from(habitMap));
      final updatedHabit = habit.copyWith(challengeStartDate: DateTime.now());
      await box.put(id, updatedHabit.toMap());
      WidgetService.updateAllWidgets();
    }
  }
}
