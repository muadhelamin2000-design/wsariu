import 'package:flutter/material.dart';

enum TaskPriority { urgent, medium, low }

class Task {
  final String id;
  final String userId; 
  final String title;
  final String? description;
  final TaskPriority priority;
  DateTime date; 
  final List<DateTime> reminderTimes;
  bool isCompleted;
  final int orderIndex;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    required this.date,
    this.reminderTimes = const [],
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.index,
      'date': date.toIso8601String(),
      'reminderTimes': reminderTimes.map((t) => t.toIso8601String()).toList(),
      'isCompleted': isCompleted,
      'orderIndex': orderIndex,
    };
  }

  factory Task.fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'],
      description: map['description'],
      priority: TaskPriority.values[map['priority']],
      date: DateTime.parse(map['date']),
      reminderTimes: (map['reminderTimes'] as List?)
              ?.map((t) => DateTime.parse(t))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] ?? false,
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? date,
    bool? isCompleted,
    int? orderIndex,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      reminderTimes: reminderTimes,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.urgent: return Colors.red;
      case TaskPriority.medium: return Colors.amber;
      case TaskPriority.low: return Colors.green;
    }
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.urgent: return 'عاجل';
      case TaskPriority.medium: return 'متوسط';
      case TaskPriority.low: return 'غير عاجل';
    }
  }
}
