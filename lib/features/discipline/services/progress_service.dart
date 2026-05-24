import 'package:flutter/material.dart' hide Badge;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/progress_goal_model.dart';
import '../models/badge_model.dart';
import 'notification_service.dart';

class ProgressService {
  static const String boxName = 'progress_goals_box';
  static const String badgeBoxName = 'badges_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
    await Hive.openBox(badgeBoxName);
  }

  static List<ProgressGoal> getGoals() {
    final box = Hive.box(boxName);
    return box.values.map((g) => ProgressGoal.fromMap(Map<dynamic, dynamic>.from(g))).toList();
  }

  static List<AppBadge> getBadges() {
    final box = Hive.box(badgeBoxName);
    return box.values.map((b) => AppBadge.fromMap(Map<dynamic, dynamic>.from(b))).toList();
  }

  static Future<void> unlockBadge(String id, String name, String description, String icon) async {
    final box = Hive.box(badgeBoxName);
    if (!box.containsKey(id)) {
      final badge = AppBadge(
        id: id,
        name: name,
        description: description,
        icon: icon,
        unlockedAt: DateTime.now(),
      );
      await box.put(id, badge.toMap());
      
      // إشعار بالوسام الجديد
      await NotificationService.scheduleNotification(
        id: id.hashCode,
        title: '🌟 وسام جديد: $name',
        body: description,
        time: DateTime.now().add(const Duration(seconds: 2)),
      );
    }
  }

  static Future<void> saveGoal(ProgressGoal goal) async {
    final box = Hive.box(boxName);
    await box.put(goal.id, goal.toMap());
    
    // جدولة تنبيه إذا لم يتم التحديث لمدة 3 أيام
    await NotificationService.scheduleNotification(
      id: goal.id.hashCode,
      title: 'هدف ينتظرك: ${goal.title}',
      body: 'لقد مر 3 أيام بدون تقدم في ${goal.title}. استعن بالله وأكمل!',
      time: const TimeOfDay(hour: 10, minute: 0),
    );
  }

  static Future<void> deleteGoal(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
    await NotificationService.cancelNotification(id.hashCode);
  }

  static Future<void> updateProgress(String id, double newValue) async {
    final box = Hive.box(boxName);
    final goalMap = box.get(id);
    if (goalMap != null) {
      final goal = ProgressGoal.fromMap(Map<dynamic, dynamic>.from(goalMap));
      goal.currentValue = newValue;
      goal.lastUpdate = DateTime.now();
      await box.put(id, goal.toMap());

      // التحقق من الإنجاز لمنح وسام
      if (goal.currentValue >= goal.totalValue) {
        await unlockBadge(
          'goal_completed_${goal.id}',
          'بطل الإنجاز: ${goal.title}',
          'أتممت هدفك بنجاح، مبارك لك هذا الصمود!',
          '🏆',
        );
      }
    }
  }
}
