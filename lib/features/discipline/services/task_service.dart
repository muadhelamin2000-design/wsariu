import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import 'notification_service.dart';
import '../../profile/services/user_service.dart';
import '../../dashboard/services/prayer_service.dart';
import 'package:flutter/material.dart';

class TaskService {
  static const String boxName = 'tasks_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<Task> getTasks() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((t) => Task.fromMap(Map<dynamic, dynamic>.from(t as Map)))
        .where((t) => t.userId == currentUserId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveTasksOrder(List<Task> tasks) async {
    final box = Hive.box(boxName);
    for (int i = 0; i < tasks.length; i++) {
      final updated = tasks[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
  }

  static Future<void> saveTask(Task task) async {
    final box = Hive.box(boxName);
    await box.put(task.id, task.toMap());
    
    // جدولة التذكيرات
    for (int i = 0; i < task.reminderTimes.length; i++) {
      await NotificationService.scheduleNotification(
        id: (task.id + i.toString()).hashCode,
        title: 'تذكير بمهمة: ${task.title}',
        body: 'موعد تنفيذ المهمة الآن',
        time: TimeOfDay.fromDateTime(task.reminderTimes[i]),
      );
    }
  }

  static Future<void> deleteTask(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
    for (int i = 0; i < 5; i++) {
      await NotificationService.cancelNotification((id + i.toString()).hashCode);
    }
  }

  static Future<void> toggleTaskStatus(String id) async {
    final box = Hive.box(boxName);
    final taskMap = box.get(id);
    if (taskMap != null) {
      final task = Task.fromMap(Map<dynamic, dynamic>.from(taskMap));
      task.isCompleted = !task.isCompleted;
      
      // تحديث التاريخ ليتناسب مع "اليوم الإسلامي" إذا تم الإنجاز الآن
      if (task.isCompleted) {
        task.date = PrayerService.getIslamicDayDate();
      }

      await box.put(id, task.toMap());
    }
  }
}
