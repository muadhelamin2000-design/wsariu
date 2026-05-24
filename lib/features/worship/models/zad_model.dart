import 'package:flutter/material.dart';

enum ZadItemType { internal, habit, worship, addiction, routine, task }
enum ZadCategory { balanced, independent }

class InternalHabit {
  final String id;
  final String name;
  bool isCompleted;

  InternalHabit({required this.id, required this.name, this.isCompleted = false});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'isCompleted': isCompleted};
  factory InternalHabit.fromMap(Map<dynamic, dynamic> map) => InternalHabit(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
  );
}

class ZadItem {
  final String id;
  final String name;
  final ZadItemType type;
  final String? linkedId;
  final Map<String, double> log; // dateKey (yyyy-MM-dd) -> value

  ZadItem({
    required this.id,
    required this.name,
    this.type = ZadItemType.internal,
    this.linkedId,
    this.log = const {},
  });

  bool isCompletedOn(DateTime date) {
    final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return (log[key] ?? 0) > 0;
  }

  double getValueOn(DateTime date) {
    final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return log[key] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'linkedId': linkedId,
      'log': log,
    };
  }

  factory ZadItem.fromMap(Map<dynamic, dynamic> map) {
    return ZadItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: ZadItemType.values[map['type'] ?? 0],
      linkedId: map['linkedId'],
      log: Map<String, double>.from((map['log'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))),
    );
  }

  ZadItem copyWith({
    String? name,
    Map<String, double>? log,
  }) {
    return ZadItem(
      id: id,
      name: name ?? this.name,
      type: type,
      linkedId: linkedId,
      log: log ?? this.log,
    );
  }
}

class ZadDeed {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<ZadItem> hindrances; 
  final List<ZadItem> facilitators; 
  final List<String> linkedHabitIds; 
  final List<String> linkedRoutineIds;
  final List<String> linkedWorshipIds;
  final List<String> linkedAddictionIds;
  final List<InternalHabit> internalHabits; 
  final String iconEmoji;
  final String quote; 
  final int colorValue;
  final ZadCategory category;
  final DateTime createdAt;

  ZadDeed({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    this.hindrances = const [],
    this.facilitators = const [],
    this.linkedHabitIds = const [],
    this.linkedRoutineIds = const [],
    this.linkedWorshipIds = const [],
    this.linkedAddictionIds = const [],
    this.internalHabits = const [],
    this.iconEmoji = '🧗',
    required this.quote,
    this.colorValue = 0xFF0F3D2E,
    this.category = ZadCategory.balanced,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'hindrances': hindrances.map((e) => e.toMap()).toList(),
      'facilitators': facilitators.map((e) => e.toMap()).toList(),
      'linkedHabitIds': linkedHabitIds,
      'linkedRoutineIds': linkedRoutineIds,
      'linkedWorshipIds': linkedWorshipIds,
      'linkedAddictionIds': linkedAddictionIds,
      'internalHabits': internalHabits.map((e) => e.toMap()).toList(),
      'iconEmoji': iconEmoji,
      'quote': quote,
      'colorValue': colorValue,
      'category': category.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ZadDeed.fromMap(Map<dynamic, dynamic> map) {
    return ZadDeed(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      hindrances: (map['hindrances'] as List?)?.map((e) {
        if (e is String) return ZadItem(id: UniqueKey().toString(), name: e);
        return ZadItem.fromMap(e);
      }).toList() ?? [],
      facilitators: (map['facilitators'] as List?)?.map((e) {
        if (e is String) return ZadItem(id: UniqueKey().toString(), name: e);
        return ZadItem.fromMap(e);
      }).toList() ?? [],
      linkedHabitIds: List<String>.from(map['linkedHabitIds'] ?? []),
      linkedRoutineIds: List<String>.from(map['linkedRoutineIds'] ?? []),
      linkedWorshipIds: List<String>.from(map['linkedWorshipIds'] ?? []),
      linkedAddictionIds: List<String>.from(map['linkedAddictionIds'] ?? []),
      internalHabits: (map['internalHabits'] as List?)?.map((e) => InternalHabit.fromMap(e)).toList() ?? [],
      iconEmoji: map['iconEmoji'] ?? '🧗',
      quote: map['quote'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF0F3D2E,
      category: ZadCategory.values[map['category'] ?? 0],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  ZadDeed copyWith({
    String? name,
    String? description,
    List<ZadItem>? hindrances,
    List<ZadItem>? facilitators,
    List<String>? linkedHabitIds,
    List<String>? linkedRoutineIds,
    List<String>? linkedWorshipIds,
    List<String>? linkedAddictionIds,
    List<InternalHabit>? internalHabits,
    String? iconEmoji,
    String? quote,
    int? colorValue,
    ZadCategory? category,
  }) {
    return ZadDeed(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      hindrances: hindrances ?? this.hindrances,
      facilitators: facilitators ?? this.facilitators,
      linkedHabitIds: linkedHabitIds ?? this.linkedHabitIds,
      linkedRoutineIds: linkedRoutineIds ?? this.linkedRoutineIds,
      linkedWorshipIds: linkedWorshipIds ?? this.linkedWorshipIds,
      linkedAddictionIds: linkedAddictionIds ?? this.linkedAddictionIds,
      internalHabits: internalHabits ?? this.internalHabits,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      quote: quote ?? this.quote,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      createdAt: createdAt,
    );
  }
}
