import 'package:flutter/material.dart';
import 'habit_model.dart';

class IncrementalHabit {
  final String id;
  final String userId;
  final String title;
  final double startValue;
  final double targetValue;
  final double incrementValue;
  final int daysBetweenIncrements;
  final String unit;
  final DateTime createdAt;
  final Map<String, double> executionLog;
  final int colorValue;
  final int orderIndex;
  final int? reminderHour;
  final int? reminderMinute;
  final ReminderType reminderType;
  final String? linkedPrayer;

  IncrementalHabit({
    required this.id,
    required this.userId,
    required this.title,
    required this.startValue,
    required this.targetValue,
    required this.incrementValue,
    required this.daysBetweenIncrements,
    required this.unit,
    required this.createdAt,
    this.executionLog = const {},
    this.colorValue = 0xFF0F3D2E,
    this.orderIndex = 0,
    this.reminderHour,
    this.reminderMinute,
    this.reminderType = ReminderType.fixed,
    this.linkedPrayer,
  });

  Color get color => Color(colorValue);

  TimeOfDay? get reminderTime => (reminderHour != null && reminderMinute != null)
      ? TimeOfDay(hour: reminderHour!, minute: reminderMinute!)
      : null;

  double getTargetForDate(DateTime date) {
    int daysPassed = date.difference(DateTime(createdAt.year, createdAt.month, createdAt.day)).inDays;
    if (daysPassed < 0) return startValue;
    int incrementCycles = daysPassed ~/ daysBetweenIncrements;
    double calculatedTarget = startValue + (incrementCycles * incrementValue);
    return calculatedTarget > targetValue ? targetValue : calculatedTarget;
  }

  bool isCompletedOn(DateTime date) {
    String key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    double achieved = executionLog[key] ?? 0;
    return achieved >= getTargetForDate(date);
  }

  double getAchievedOn(DateTime date) {
    String key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return executionLog[key] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'startValue': startValue,
      'targetValue': targetValue,
      'incrementValue': incrementValue,
      'daysBetweenIncrements': daysBetweenIncrements,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'executionLog': executionLog,
      'colorValue': colorValue,
      'orderIndex': orderIndex,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'reminderType': reminderType.index,
      'linkedPrayer': linkedPrayer,
    };
  }

  factory IncrementalHabit.fromMap(Map<dynamic, dynamic> map) {
    return IncrementalHabit(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      startValue: (map['startValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 100.0,
      incrementValue: (map['incrementValue'] as num?)?.toDouble() ?? 1.0,
      daysBetweenIncrements: map['daysBetweenIncrements'] ?? 1,
      unit: map['unit'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      executionLog: Map<String, double>.from(
        (map['executionLog'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      ),
      colorValue: map['colorValue'] ?? 0xFF0F3D2E,
      orderIndex: map['orderIndex'] ?? 0,
      reminderHour: map['reminderHour'],
      reminderMinute: map['reminderMinute'],
      reminderType: ReminderType.values[map['reminderType'] ?? 0],
      linkedPrayer: map['linkedPrayer'],
    );
  }

  IncrementalHabit copyWith({
    String? title,
    double? startValue,
    double? targetValue,
    double? incrementValue,
    int? daysBetweenIncrements,
    String? unit,
    Map<String, double>? executionLog,
    int? colorValue,
    int? orderIndex,
    int? reminderHour,
    int? reminderMinute,
    ReminderType? reminderType,
    String? linkedPrayer,
    bool clearReminder = false,
  }) {
    return IncrementalHabit(
      id: id,
      userId: userId,
      title: title ?? this.title,
      startValue: startValue ?? this.startValue,
      targetValue: targetValue ?? this.targetValue,
      incrementValue: incrementValue ?? this.incrementValue,
      daysBetweenIncrements: daysBetweenIncrements ?? this.daysBetweenIncrements,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      executionLog: executionLog ?? this.executionLog,
      colorValue: colorValue ?? this.colorValue,
      orderIndex: orderIndex ?? this.orderIndex,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      reminderType: reminderType ?? this.reminderType,
      linkedPrayer: linkedPrayer ?? this.linkedPrayer,
    );
  }
}
