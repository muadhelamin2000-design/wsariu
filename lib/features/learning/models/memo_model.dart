import 'package:flutter/material.dart';

enum MemoType { memo, idea, data }

// --- Category Model ---
class MemoCategory {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final int colorValue;

  MemoCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.colorValue = 0xFF0F3D2E,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'icon': icon,
    'colorValue': colorValue,
  };

  factory MemoCategory.fromMap(Map<dynamic, dynamic> map) => MemoCategory(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    icon: map['icon'] ?? '📁',
    colorValue: map['colorValue'] ?? 0xFF0F3D2E,
  );
}

// --- Note Model ---
class MemoNote {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String content;
  final DateTime dateCreated;
  final DateTime dateModified;
  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final int colorValue;
  final double fontSize;
  final List<String> tags;
  final String? dataCategory; // For compatibility
  final MemoType type; // For compatibility

  MemoNote({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.dateModified,
    this.isFavorite = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.colorValue = 0xFFFFFFFF,
    this.fontSize = 16.0,
    this.tags = const [],
    this.dataCategory,
    this.type = MemoType.memo,
  });

  DateTime get date => dateCreated; // Compatibility getter

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'categoryId': categoryId,
    'title': title,
    'content': content,
    'dateCreated': dateCreated.toIso8601String(),
    'dateModified': dateModified.toIso8601String(),
    'isFavorite': isFavorite,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'isDeleted': isDeleted,
    'colorValue': colorValue,
    'fontSize': fontSize,
    'tags': tags,
    'dataCategory': dataCategory,
    'type': type.index,
  };

  factory MemoNote.fromMap(Map<dynamic, dynamic> map) => MemoNote(
    id: map['id'],
    userId: map['userId'],
    categoryId: map['categoryId'] ?? 'cat_general',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    dateCreated: DateTime.parse(map['dateCreated'] ?? map['date'] ?? DateTime.now().toIso8601String()),
    dateModified: DateTime.parse(map['dateModified'] ?? map['date'] ?? DateTime.now().toIso8601String()),
    isFavorite: map['isFavorite'] ?? false,
    isPinned: map['isPinned'] ?? false,
    isArchived: map['isArchived'] ?? false,
    isDeleted: map['isDeleted'] ?? false,
    colorValue: map['colorValue'] ?? 0xFFFFFFFF,
    fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
    tags: List<String>.from(map['tags'] ?? []),
    dataCategory: map['dataCategory'],
    type: MemoType.values[map['type'] ?? 0],
  );

  MemoNote copyWith({
    String? title, String? content, String? categoryId,
    bool? isFavorite, bool? isPinned, bool? isArchived, bool? isDeleted,
    int? colorValue, double? fontSize, List<String>? tags,
    String? dataCategory, MemoType? type,
  }) {
    return MemoNote(
      id: id, userId: userId, dateCreated: dateCreated,
      dateModified: DateTime.now(),
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      colorValue: colorValue ?? this.colorValue,
      fontSize: fontSize ?? this.fontSize,
      tags: tags ?? this.tags,
      dataCategory: dataCategory ?? this.dataCategory,
      type: type ?? this.type,
    );
  }
}

// --- Idea Model ---
class MemoIdea {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime date;
  final bool isFavorite;
  final List<String> tags;

  MemoIdea({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.date,
    this.isFavorite = false,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'title': title, 'description': description,
    'date': date.toIso8601String(), 'isFavorite': isFavorite, 'tags': tags,
  };

  factory MemoIdea.fromMap(Map<dynamic, dynamic> map) => MemoIdea(
    id: map['id'], userId: map['userId'], title: map['title'],
    description: map['description'] ?? '',
    date: DateTime.parse(map['date']),
    isFavorite: map['isFavorite'] ?? false,
    tags: List<String>.from(map['tags'] ?? []),
  );
}

// --- Future Project System Models ---
class MemoProject {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCompleted;
  final List<ProjectTask> tasks;

  MemoProject({
    required this.id, required this.userId, required this.name,
    this.description = '', required this.startDate, this.endDate,
    this.isCompleted = false, this.tasks = const [],
  });
}

class ProjectTask {
  final String id;
  final String title;
  final bool isCompleted;
  final List<ProjectSubTask> subTasks;

  ProjectTask({required this.id, required this.title, this.isCompleted = false, this.subTasks = const []});
}

class ProjectSubTask {
  final String id;
  final String title;
  final bool isCompleted;

  ProjectSubTask({required this.id, required this.title, this.isCompleted = false});
}
