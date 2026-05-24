import 'package:flutter/material.dart';

class ProgressGoal {
  final String id;
  final String userId; // ربط الهدف بالمستخدم
  final String title;
  final String type;
  final String emoji;
  final String? imagePath;
  final double totalValue;
  double currentValue;
  final DateTime createdAt;
  DateTime lastUpdate;

  ProgressGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.emoji,
    this.imagePath,
    required this.totalValue,
    required this.currentValue,
    required this.createdAt,
    required this.lastUpdate,
  });

  double get progressPercentage {
    if (totalValue <= 0) return 0;
    return (currentValue / totalValue).clamp(0.0, 1.0);
  }

  double get remainingValue {
    double r = totalValue - currentValue;
    return r < 0 ? 0 : r;
  }

  String get remainingMessage {
    if (currentValue >= totalValue) return "تم الإنجاز!";
    String unit = "";
    String typeLower = type.toLowerCase();
    if (typeLower.contains('كتاب') || typeLower.contains('صفحة')) unit = "صفحة";
    else if (typeLower.contains('دقيقة') || typeLower.contains('وقت')) unit = "دقيقة";
    else if (typeLower.contains('يوم')) unit = "يوم";
    else unit = "وحدة";
    
    return "متبقي ${remainingValue.toInt()} $unit";
  }

  int get daysSinceLastUpdate {
    return DateTime.now().difference(lastUpdate).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type,
      'emoji': emoji,
      'imagePath': imagePath,
      'totalValue': totalValue,
      'currentValue': currentValue,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  factory ProgressGoal.fromMap(Map<dynamic, dynamic> map) {
    return ProgressGoal(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'],
      type: map['type'] ?? 'عام',
      emoji: map['emoji'],
      imagePath: map['imagePath'],
      totalValue: (map['totalValue'] as num).toDouble(),
      currentValue: (map['currentValue'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      lastUpdate: DateTime.parse(map['lastUpdate']),
    );
  }

  String get insightMessage {
    int days = daysSinceLastUpdate;
    if (currentValue >= totalValue) return "تم الإنجاز بفضل الله! 🎉";
    if (days >= 7) return "تنبيه: لقد غبت طويلاً عن هذا الهدف، ابدأ من جديد بقوة.";
    if (days >= 4) return "تذكير: هدفك ينتظر خطواتك، لا تتوقف.";
    if (days >= 2) return "خطوة واحدة اليوم تفرق كثيراً، استمر.";
    return "أنت تتقدم بخطوات ثابتة نحو هدفك، بوركت جهودك! 💪";
  }

  Color get statusColor {
    int days = daysSinceLastUpdate;
    if (currentValue >= totalValue) return Colors.green;
    if (days >= 7) return Colors.red;
    if (days >= 4) return Colors.orange;
    if (days >= 2) return Colors.amber;
    return const Color(0xFFC8A24A); // اللون الذهبي المميز
  }

  ProgressGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? type,
    String? emoji,
    String? imagePath,
    double? totalValue,
    double? currentValue,
    DateTime? createdAt,
    DateTime? lastUpdate,
  }) {
    return ProgressGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
      totalValue: totalValue ?? this.totalValue,
      currentValue: currentValue ?? this.currentValue,
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
