import 'package:flutter/material.dart';

enum MemoType { memo, idea, data }

class MemoCategory {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final int colorValue;
  final bool isLocked;

  MemoCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.colorValue = 0xFF0F3D2E,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'icon': icon,
    'colorValue': colorValue,
    'isLocked': isLocked,
  };

  factory MemoCategory.fromMap(Map<dynamic, dynamic> map) => MemoCategory(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    icon: map['icon'],
    colorValue: map['colorValue'] ?? 0xFF0F3D2E,
    isLocked: map['isLocked'] ?? false,
  );
}

class Memo {
  final String id;
  final String userId;
  final String title;
  final String content; // Can be raw text or JSON for future rich text support
  final DateTime dateCreated;
  final DateTime dateModified;
  final String? categoryId;
  final MemoType type;
  
  // Customization & Meta
  final int colorValue;
  final double fontSize;
  final bool isFavorite;
  final bool isPinned;
  final bool isHidden;
  final String? imagePath;
  final List<String> tags;

  Memo({
    required this.id,
    required this.userId,
    this.title = '',
    required this.content,
    required this.dateCreated,
    required this.dateModified,
    this.categoryId,
    this.type = MemoType.memo,
    this.colorValue = 0xFF000000,
    this.fontSize = 16.0,
    this.isFavorite = false,
    this.isPinned = false,
    this.isHidden = false,
    this.imagePath,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'categoryId': categoryId,
      'type': type.index,
      'colorValue': colorValue,
      'fontSize': fontSize,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      'isHidden': isHidden,
      'imagePath': imagePath,
      'tags': tags,
    };
  }

  factory Memo.fromMap(Map<dynamic, dynamic> map) {
    return Memo(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      dateCreated: DateTime.parse(map['dateCreated'] ?? map['date'] ?? DateTime.now().toIso8601String()),
      dateModified: DateTime.parse(map['dateModified'] ?? map['date'] ?? DateTime.now().toIso8601String()),
      categoryId: map['categoryId'] ?? map['category'], // Backward compatibility
      type: MemoType.values[map['type'] ?? 0],
      colorValue: map['colorValue'] ?? 0xFF000000,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
      isFavorite: map['isFavorite'] ?? false,
      isPinned: map['isPinned'] ?? false,
      isHidden: map['isHidden'] ?? false,
      imagePath: map['imagePath'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Memo copyWith({
    String? title,
    String? content,
    DateTime? dateModified,
    String? categoryId,
    int? colorValue,
    double? fontSize,
    bool? isFavorite,
    bool? isPinned,
    bool? isHidden,
    String? imagePath,
    List<String>? tags,
  }) {
    return Memo(
      id: id,
      userId: userId,
      dateCreated: dateCreated,
      dateModified: dateModified ?? this.dateModified,
      type: type,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      colorValue: colorValue ?? this.colorValue,
      fontSize: fontSize ?? this.fontSize,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isHidden: isHidden ?? this.isHidden,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
    );
  }
}
