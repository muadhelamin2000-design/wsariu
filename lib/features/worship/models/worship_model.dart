import 'package:flutter/material.dart';
import '../../discipline/models/habit_model.dart';

enum WorshipCategory { soulAtPeace, soulCommandingEvil, independent }
enum WorshipItemType { fixed, variable }
enum WorshipRecurrence { daily, everyOtherDay, specificDays, interval }

class WorshipSection {
  final String id;
  final String userId; 
  final String name;
  final WorshipCategory category;
  final int colorValue; 
  final String emoji;
  final int orderIndex;

  WorshipSection({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.colorValue = 0xFF0F3D2E,
    this.emoji = '🌙',
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category.index,
      'colorValue': colorValue,
      'emoji': emoji,
      'orderIndex': orderIndex,
    };
  }

  factory WorshipSection.fromMap(Map<dynamic, dynamic> map) {
    return WorshipSection(
      id: map['id'],
      userId: map['userId'] ?? '',
      name: map['name'],
      category: WorshipCategory.values[map['category']],
      colorValue: map['colorValue'] ?? 0xFF0F3D2E,
      emoji: map['emoji'] ?? '🌙',
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  WorshipSection copyWith({
    String? name,
    WorshipCategory? category,
    int? colorValue,
    String? emoji,
    int? orderIndex,
  }) {
    return WorshipSection(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

class WorshipItem {
  final String id;
  final String userId; 
  final String sectionId;
  final String name;
  final WorshipItemType type;
  final double basePoints;
  final String? unitName;
  final WorshipRecurrence recurrence;
  final List<int> specificDays;
  final int intervalValue;
  final DateTime createdAt;
  final DateTime? challengeStartDate;
  final Map<String, double> completionLog;
  final int colorValue;
  final String emoji;
  final int orderIndex;
  final ReminderType reminderType;
  final int? reminderHour;
  final int? reminderMinute;
  final int? flexibleStartHour;
  final int? flexibleEndHour;
  final int? flexibleCount;
  final String? linkedPrayer;

  WorshipItem({
    required this.id,
    required this.userId,
    required this.sectionId,
    required this.name,
    required this.type,
    required this.basePoints,
    this.unitName,
    required this.recurrence,
    this.specificDays = const [],
    this.intervalValue = 1,
    required this.createdAt,
    this.challengeStartDate,
    this.completionLog = const {},
    this.colorValue = 0xFFC8A24A,
    this.emoji = '📍',
    this.orderIndex = 0,
    this.reminderType = ReminderType.fixed,
    this.reminderHour,
    this.reminderMinute,
    this.flexibleStartHour,
    this.flexibleEndHour,
    this.flexibleCount,
    this.linkedPrayer,
  });

  TimeOfDay? get reminderTime => (reminderHour != null && reminderMinute != null)
      ? TimeOfDay(hour: reminderHour!, minute: reminderMinute!)
      : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sectionId': sectionId,
      'name': name,
      'type': type.index,
      'basePoints': basePoints,
      'unitName': unitName,
      'recurrence': recurrence.index,
      'specificDays': specificDays,
      'intervalValue': intervalValue,
      'createdAt': createdAt.toIso8601String(),
      'challengeStartDate': challengeStartDate?.toIso8601String(),
      'completionLog': completionLog,
      'colorValue': colorValue,
      'emoji': emoji,
      'orderIndex': orderIndex,
      'reminderType': reminderType.index,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'flexibleStartHour': flexibleStartHour,
      'flexibleEndHour': flexibleEndHour,
      'flexibleCount': flexibleCount,
      'linkedPrayer': linkedPrayer,
    };
  }

  factory WorshipItem.fromMap(Map<dynamic, dynamic> map) {
    return WorshipItem(
      id: map['id'],
      userId: map['userId'] ?? '',
      sectionId: map['sectionId'],
      name: map['name'],
      type: WorshipItemType.values[map['type'] ?? 0],
      basePoints: (map['basePoints'] as num?)?.toDouble() ?? 10.0,
      unitName: map['unitName'],
      recurrence: WorshipRecurrence.values[map['recurrence'] ?? 0],
      specificDays: List<int>.from(map['specificDays'] ?? []),
      intervalValue: map['intervalValue'] ?? 1,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      challengeStartDate: map['challengeStartDate'] != null ? DateTime.parse(map['challengeStartDate']) : null,
      completionLog: Map<String, double>.from(
        (map['completionLog'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      ),
      colorValue: map['colorValue'] ?? 0xFFC8A24A,
      emoji: map['emoji'] ?? '📍',
      orderIndex: map['orderIndex'] ?? 0,
      reminderType: ReminderType.values[map['reminderType'] ?? 0],
      reminderHour: map['reminderHour'],
      reminderMinute: map['reminderMinute'],
      flexibleStartHour: map['flexibleStartHour'],
      flexibleEndHour: map['flexibleEndHour'],
      flexibleCount: map['flexibleCount'],
      linkedPrayer: map['linkedPrayer'],
    );
  }

  WorshipItem copyWith({
    String? name,
    WorshipItemType? type,
    double? basePoints,
    String? unitName,
    WorshipRecurrence? recurrence,
    List<int>? specificDays,
    int? intervalValue,
    DateTime? challengeStartDate,
    DateTime? createdAt,
    Map<String, double>? completionLog,
    int? colorValue,
    String? emoji,
    int? orderIndex,
    ReminderType? reminderType,
    int? reminderHour,
    int? reminderMinute,
    int? flexibleStartHour,
    int? flexibleEndHour,
    int? flexibleCount,
    String? sectionId,
    String? linkedPrayer,
    bool clearReminder = false,
  }) {
    return WorshipItem(
      id: id,
      userId: userId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      type: type ?? this.type,
      basePoints: basePoints ?? this.basePoints,
      unitName: unitName ?? this.unitName,
      recurrence: recurrence ?? this.recurrence,
      specificDays: specificDays ?? this.specificDays,
      intervalValue: intervalValue ?? this.intervalValue,
      createdAt: createdAt ?? this.createdAt,
      challengeStartDate: challengeStartDate ?? this.challengeStartDate,
      completionLog: completionLog ?? this.completionLog,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      orderIndex: orderIndex ?? this.orderIndex,
      reminderType: reminderType ?? this.reminderType,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      flexibleStartHour: clearReminder ? null : (flexibleStartHour ?? this.flexibleStartHour),
      flexibleEndHour: clearReminder ? null : (flexibleEndHour ?? this.flexibleEndHour),
      flexibleCount: clearReminder ? null : (flexibleCount ?? this.flexibleCount),
      linkedPrayer: clearReminder ? null : (linkedPrayer ?? this.linkedPrayer),
    );
  }

  bool isRequiredOn(DateTime date) {
    // 1. Calculate days since creation
    final daysSinceCreation = date.difference(DateTime(createdAt.year, createdAt.month, createdAt.day)).inDays;
    if (daysSinceCreation < 0) return false;

    switch (recurrence) {
      case WorshipRecurrence.daily:
        return true;
      case WorshipRecurrence.everyOtherDay:
        return daysSinceCreation % 2 == 0;
      case WorshipRecurrence.specificDays:
        // Adjust to Saturday-indexed days if needed, but Flutter/Dart uses 1=Mon, 7=Sun
        // Our specificDays are 0=Sat, 1=Sun, 2=Mon... (based on HabitsScreen.fullArabicDays)
        // Saturday in Dart is 6.
        int day = date.weekday; // 1=Mon... 6=Sat, 7=Sun
        int habitIndex;
        if (day == 6) habitIndex = 0; // Sat
        else if (day == 7) habitIndex = 1; // Sun
        else habitIndex = day + 1; // Mon=2, Tue=3...
        return specificDays.contains(habitIndex);
      case WorshipRecurrence.interval:
        return daysSinceCreation % intervalValue == 0;
    }
  }

  double calculatePoints(DateTime date) {
    String key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    if (!completionLog.containsKey(key)) return 0;
    return completionLog[key]! * basePoints;
  }

  int get currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    while (completionLog.containsKey("${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}")) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get commitmentRate {
    if (completionLog.isEmpty) return 0;
    int totalDays = DateTime.now().difference(createdAt).inDays + 1;
    return (completionLog.length / totalDays).clamp(0.0, 1.0) * 100;
  }
}
