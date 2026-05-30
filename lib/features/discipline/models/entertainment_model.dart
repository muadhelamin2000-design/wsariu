import 'package:flutter/material.dart';

enum EntertainmentType { sports, social, psychology, educational, lightReligious }

class EntertainmentActivity {
  final String id;
  final String title;
  final String description;
  final String icon; // Changed to String (Emoji)
  final EntertainmentType type;
  final int durationMinutes;
  final String motivationalMessage;
  bool isFavorite;
  int executionCount;

  EntertainmentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.durationMinutes,
    this.motivationalMessage = "أحسنت! خطوة رائعة لتحسين حالتك النفسية.",
    this.isFavorite = false,
    this.executionCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.index,
      'durationMinutes': durationMinutes,
      'motivationalMessage': motivationalMessage,
      'isFavorite': isFavorite,
      'executionCount': executionCount,
    };
  }

  factory EntertainmentActivity.fromMap(Map<dynamic, dynamic> map) {
    return EntertainmentActivity(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon']?.toString() ?? '🎮',
      type: EntertainmentType.values[map['type']],
      durationMinutes: map['durationMinutes'],
      motivationalMessage: map['motivationalMessage'] ?? "أحسنت! خطوة رائعة لتحسين حالتك النفسية.",
      isFavorite: map['isFavorite'] ?? false,
      executionCount: map['executionCount'] ?? 0,
    );
  }

  EntertainmentActivity copyWith({bool? isFavorite, int? executionCount}) {
    return EntertainmentActivity(
      id: id,
      title: title,
      description: description,
      icon: icon,
      type: type,
      durationMinutes: durationMinutes,
      motivationalMessage: motivationalMessage,
      isFavorite: isFavorite ?? this.isFavorite,
      executionCount: executionCount ?? this.executionCount,
    );
  }
}
