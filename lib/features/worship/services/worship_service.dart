import 'package:hive_flutter/hive_flutter.dart';
import '../models/worship_model.dart';
import '../../profile/services/user_service.dart';
import '../../discipline/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../dashboard/services/prayer_service.dart';

class WorshipService {
  static const String sectionBoxName = 'worship_sections_box';
  static const String itemBoxName = 'worship_items_box';

  static Future<void> init() async {
    await Hive.openBox(sectionBoxName);
    await Hive.openBox(itemBoxName);
  }

  // --- Sections ---
  static List<WorshipSection> getSections() {
    final box = Hive.box(sectionBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((s) => WorshipSection.fromMap(Map<dynamic, dynamic>.from(s as Map)))
        .where((s) => s.userId == currentUserId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveSection(WorshipSection section) async {
    final box = Hive.box(sectionBoxName);
    await box.put(section.id, section.toMap());
  }

  static Future<void> deleteSection(String id) async {
    final box = Hive.box(sectionBoxName);
    await box.delete(id);
    
    // Delete all items in this section
    final items = getItems().where((i) => i.sectionId == id).toList();
    for (var item in items) {
      await deleteItem(item.id);
    }
  }

  static Future<void> saveSectionsOrder(List<WorshipSection> sections) async {
    final box = Hive.box(sectionBoxName);
    for (int i = 0; i < sections.length; i++) {
      final updated = sections[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
  }

  // --- Items ---
  static List<WorshipItem> getItems() {
    final box = Hive.box(itemBoxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((i) => WorshipItem.fromMap(Map<dynamic, dynamic>.from(i as Map)))
        .where((i) => i.userId == currentUserId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  static Future<void> saveItem(WorshipItem item) async {
    final box = Hive.box(itemBoxName);
    await box.put(item.id, item.toMap());
    
    // Schedule notification
    final section = getSections().where((s) => s.id == item.sectionId).firstOrNull;
    await NotificationService.scheduleWorshipReminders(item, section?.category == WorshipCategory.soulAtPeace);
  }

  static Future<void> deleteItem(String id) async {
    final box = Hive.box(itemBoxName);
    await box.delete(id);
    await NotificationService.cancelNotification(id.hashCode);
  }

  static Future<void> updateItemValue(String id, DateTime date, double value, {bool increment = true}) async {
    final box = Hive.box(itemBoxName);
    final map = box.get(id);
    if (map != null) {
      final item = WorshipItem.fromMap(Map<dynamic, dynamic>.from(map));
      
      final now = DateTime.now();
      final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final targetDate = isToday ? PrayerService.getIslamicDayDate() : date;
      
      final String dateKey = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      
      final newLog = Map<String, double>.from(item.completionLog);
      if (item.type == WorshipItemType.fixed) {
        if (newLog.containsKey(dateKey)) {
          newLog.remove(dateKey);
        } else {
          newLog[dateKey] = 1.0;
        }
      } else {
        if (increment) {
          double currentVal = newLog[dateKey] ?? 0;
          newLog[dateKey] = currentVal + value;
        } else {
          newLog[dateKey] = value;
        }
        if (newLog[dateKey]! <= 0) newLog.remove(dateKey);
      }
      
      final updatedItem = item.copyWith(completionLog: newLog);
      await box.put(id, updatedItem.toMap());
    }
  }

  static Future<void> saveItemsOrder(List<WorshipItem> items) async {
    final box = Hive.box(itemBoxName);
    for (int i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(orderIndex: i);
      await box.put(updated.id, updated.toMap());
    }
  }

  static Future<void> resetAllWorshipCompletion() async {
    final box = Hive.box(itemBoxName);
    final currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return;

    final allItems = getItems();
    final now = DateTime.now();
    for (var item in allItems) {
      if (item.userId == currentUserId) {
        final updated = item.copyWith(
          completionLog: {},
          createdAt: now,
        );
        await box.put(item.id, updated.toMap());
      }
    }
  }

  static Future<void> resetWorshipCompletion(String id) async {
    final box = Hive.box(itemBoxName);
    final map = box.get(id);
    if (map != null) {
      final item = WorshipItem.fromMap(Map<dynamic, dynamic>.from(map));
      final updated = item.copyWith(
        completionLog: {},
        createdAt: DateTime.now(),
      );
      await box.put(id, updated.toMap());
    }
  }

  static Future<void> startChallenge(String id) async {
    final box = Hive.box(itemBoxName);
    final map = box.get(id);
    if (map != null) {
      final item = WorshipItem.fromMap(Map<dynamic, dynamic>.from(map));
      final updated = item.copyWith(challengeStartDate: DateTime.now());
      await box.put(id, updated.toMap());
    }
  }
}
