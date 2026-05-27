import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_model.dart';
import 'notification_service.dart';
import '../../profile/services/user_service.dart';
import '../../dashboard/services/prayer_service.dart';
import '../../../core/services/widget_service.dart';

import '../../../core/services/badge_service.dart';

class RoutineService {
  static const String boxName = 'routines_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<Routine> getRoutines() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((r) => Routine.fromMap(Map<dynamic, dynamic>.from(r as Map)))
        .where((r) => r.userId == currentUserId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveRoutinesOrder(List<Routine> routines) async {
    final box = Hive.box(boxName);
    for (int i = 0; i < routines.length; i++) {
      final updated = routines[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
    WidgetService.updateAllWidgets();
  }

  static Future<void> saveRoutine(Routine routine) async {
    final box = Hive.box(boxName);
    await box.put(routine.id, routine.toMap());
    
    if (routine.reminderTime != null) {
      await NotificationService.scheduleNotification(
        id: routine.id.hashCode,
        title: 'موعد الروتين: ${routine.title}',
        body: 'حان الآن موعد الالتزام بـ ${routine.title}',
        time: routine.reminderTime!,
      );
    }
    WidgetService.updateAllWidgets();
  }

  static Future<void> deleteRoutine(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
    await NotificationService.cancelNotification(id.hashCode);
    WidgetService.updateAllWidgets();
  }

  static Future<void> resetAllRoutinesCompletion() async {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return;

    final all = getRoutines();
    final now = DateTime.now();
    for (var r in all) {
      if (r.userId == currentUserId) {
        final updated = r.copyWith(
          executionLog: {},
          createdAt: now,
          challengeStartDate: null, // يعود لحالة لم يبدأ
        );
        await box.put(r.id, updated.toMap());
      }
    }
    WidgetService.updateAllWidgets();
  }

  static Future<void> toggleRoutineCompletion(String id, DateTime date) async {
    final box = Hive.box(boxName);
    final routineMap = box.get(id);
    if (routineMap != null) {
      final routine = Routine.fromMap(Map<dynamic, dynamic>.from(routineMap));
      final String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final newLog = Map<String, bool>.from(routine.executionLog);
      newLog[dateKey] = !(newLog[dateKey] ?? false);
      
      final updatedRoutine = routine.copyWith(executionLog: newLog);
      await box.put(id, updatedRoutine.toMap());

      // التحقق من الدروع
      if (updatedRoutine.challengeStartDate != null) {
        int streak = 0;
        DateTime checkDate = DateTime.now();
        DateTime startDateOnly = DateTime(updatedRoutine.challengeStartDate!.year, updatedRoutine.challengeStartDate!.month, updatedRoutine.challengeStartDate!.day);
        while (!checkDate.isBefore(startDateOnly)) {
          String dk = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
          if (newLog.containsKey(dk)) { streak++; checkDate = checkDate.subtract(const Duration(days: 1)); }
          else break;
        }
        await BadgeService.checkAndUnlockShield('routine_$id', streak);
      }

      WidgetService.updateAllWidgets();
    }
  }

  static Future<void> startChallenge(String id) async {
    final box = Hive.box(boxName);
    final routineMap = box.get(id);
    if (routineMap != null) {
      final routine = Routine.fromMap(Map<dynamic, dynamic>.from(routineMap));
      final updated = routine.copyWith(challengeStartDate: DateTime.now());
      await box.put(id, updated.toMap());
      WidgetService.updateAllWidgets();
    }
  }

  static Future<void> updateRoutineLog(String id, DateTime date, bool done) async {
    final box = Hive.box(boxName);
    final routineMap = box.get(id);
    if (routineMap != null) {
      final routine = Routine.fromMap(Map<dynamic, dynamic>.from(routineMap));
      final String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final newLog = Map<String, bool>.from(routine.executionLog);
      if (done) newLog[dateKey] = true; else newLog.remove(dateKey);
      final updatedRoutine = routine.copyWith(executionLog: newLog);
      await box.put(id, updatedRoutine.toMap());
      WidgetService.updateAllWidgets();
    }
  }

  static Future<void> resetRoutineCompletion(String id) async {
    final box = Hive.box(boxName);
    final routineMap = box.get(id);
    if (routineMap != null) {
      final routine = Routine.fromMap(Map<dynamic, dynamic>.from(routineMap));
      final updatedRoutine = routine.copyWith(
        executionLog: {},
        createdAt: DateTime.now(),
        challengeStartDate: null, // يعود لحالة لم يبدأ
      );
      await box.put(id, updatedRoutine.toMap());
      WidgetService.updateAllWidgets();
    }
  }

  static List<Map<String, dynamic>> getTodaysSchedule() {
    final allRoutines = getRoutines();
    final DateTime today = DateTime.now();
    List<Map<String, dynamic>> schedule = [];

    for (var routine in allRoutines) {
      if (routine.type == RoutineType.major) {
        for (int i = 7; i >= 1; i--) {
          DateTime pastDate = today.subtract(Duration(days: i));
          if (routine.isRequiredOn(pastDate) && !routine.isDoneOn(pastDate)) {
            schedule.add({
              'routine': routine,
              'date': pastDate,
              'isPending': true,
            });
          }
        }
      }
      if (routine.isRequiredOn(today)) {
        schedule.add({
          'routine': routine,
          'date': today,
          'isPending': false,
        });
      }
    }
    return schedule;
  }

  static List<Map<String, dynamic>> getInstancesForDate(DateTime date) {
    final allRoutines = getRoutines();
    List<Map<String, dynamic>> instances = [];
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final isPast = date.isBefore(startOfToday);

    for (var routine in allRoutines) {
      if (routine.isRequiredOn(date)) {
        instances.add({
          'routine': routine,
          'date': date,
          'isCarryOver': isPast && !routine.isDoneOn(date),
        });
      }
    }
    return instances;
  }
}
