import 'package:flutter/material.dart';

enum RoutineType { major, minor }
enum RoutineRecurrence { daily, everyOtherDay, specificDays, interval }
enum RelatedPrayer { none, fajr, dhuhr, asr, maghrib, isha }

class Routine {
  final String id;
  final String userId;
  final String title;
  final RoutineType type;
  final RoutineRecurrence recurrence;
  final List<int> specificDays; 
  final int intervalValue;
  final TimeOfDay? startTime; 
  final TimeOfDay? endTime;
  final TimeOfDay? reminderTime;
  final RelatedPrayer relatedPrayer;
  final bool afterPrayer;
  final DateTime createdAt;
  final DateTime? challengeStartDate;
  final Map<String, bool> executionLog;
  final int colorValue;
  final int orderIndex;

  Routine({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.recurrence,
    this.specificDays = const [],
    this.intervalValue = 1,
    this.startTime,
    this.endTime,
    this.reminderTime,
    this.relatedPrayer = RelatedPrayer.none,
    this.afterPrayer = true,
    required this.createdAt,
    this.challengeStartDate,
    this.executionLog = const {},
    this.colorValue = 0xFF0F3D2E,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.index,
      'recurrence': recurrence.index,
      'specificDays': specificDays,
      'intervalValue': intervalValue,
      'startHour': startTime?.hour,
      'startMinute': startTime?.minute,
      'endHour': endTime?.hour,
      'endMinute': endTime?.minute,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'relatedPrayer': relatedPrayer.index,
      'afterPrayer': afterPrayer,
      'createdAt': createdAt.toIso8601String(),
      'challengeStartDate': challengeStartDate?.toIso8601String(),
      'executionLog': executionLog,
      'colorValue': colorValue,
      'order_index': orderIndex,
    };
  }

  factory Routine.fromMap(Map<dynamic, dynamic> map) {
    return Routine(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      type: RoutineType.values[map['type'] ?? 0],
      recurrence: RoutineRecurrence.values[map['recurrence'] ?? 0],
      specificDays: List<int>.from(map['specificDays'] ?? []),
      intervalValue: map['intervalValue'] ?? 1,
      startTime: map['startHour'] != null ? TimeOfDay(hour: map['startHour'], minute: map['startMinute']) : null,
      endTime: map['endHour'] != null ? TimeOfDay(hour: map['endHour'], minute: map['endMinute']) : null,
      reminderTime: map['reminderHour'] != null ? TimeOfDay(hour: map['reminderHour'], minute: map['reminderMinute']) : null,
      relatedPrayer: RelatedPrayer.values[map['relatedPrayer'] ?? 0],
      afterPrayer: map['afterPrayer'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      challengeStartDate: map['challengeStartDate'] != null ? DateTime.parse(map['challengeStartDate']) : null,
      executionLog: Map<String, bool>.from(map['executionLog'] ?? {}),
      colorValue: map['colorValue'] ?? 0xFF0F3D2E,
      orderIndex: map['order_index'] ?? 0,
    );
  }

  Routine copyWith({
    String? title,
    TimeOfDay? reminderTime,
    DateTime? createdAt,
    DateTime? challengeStartDate,
    Map<String, bool>? executionLog,
    int? orderIndex,
  }) {
    return Routine(
      id: id,
      userId: userId,
      title: title ?? this.title,
      type: type,
      recurrence: recurrence,
      specificDays: specificDays,
      intervalValue: intervalValue,
      startTime: startTime,
      endTime: endTime,
      reminderTime: reminderTime ?? this.reminderTime,
      relatedPrayer: relatedPrayer,
      afterPrayer: afterPrayer,
      createdAt: createdAt ?? this.createdAt,
      challengeStartDate: challengeStartDate ?? this.challengeStartDate,
      executionLog: executionLog ?? this.executionLog,
      colorValue: colorValue,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  bool isDoneOn(DateTime date) {
    String key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return executionLog[key] ?? false;
  }

  bool isRequiredOn(DateTime date) {
    // لا يظهر الروتين في أيام تسبق تاريخ إنشائه
    if (date.isBefore(DateTime(createdAt.year, createdAt.month, createdAt.day))) {
      return false;
    }

    switch (recurrence) {
      case RoutineRecurrence.daily: return true;
      case RoutineRecurrence.everyOtherDay:
        int diff = date.difference(DateTime(createdAt.year, createdAt.month, createdAt.day)).inDays;
        return diff % 2 == 0;
      case RoutineRecurrence.specificDays:
        int dayIndex = (date.weekday == 6) ? 0 : (date.weekday == 7 ? 1 : date.weekday + 1);
        return specificDays.contains(dayIndex);
      case RoutineRecurrence.interval:
        int diff = date.difference(DateTime(createdAt.year, createdAt.month, createdAt.day)).inDays;
        return diff % intervalValue == 0;
    }
  }

  bool isRequiredToday(DateTime date) {
    if (type == RoutineType.minor) {
      return isRequiredOn(date);
    }
    if (isRequiredOn(date)) return true;
    for (int i = 1; i <= 7; i++) {
      DateTime pastDate = date.subtract(Duration(days: i));
      if (isRequiredOn(pastDate) && !isDoneOn(pastDate)) {
        return true;
      }
    }
    return false;
  }

  bool isOverdue() {
    if (endTime == null) return false;
    final now = TimeOfDay.now();
    if (now.hour > endTime!.hour) return true;
    if (now.hour == endTime!.hour && now.minute > endTime!.minute) return true;
    return false;
  }
}
