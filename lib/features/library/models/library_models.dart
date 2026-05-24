enum LibraryType { pdf, video, audio }

class LibraryCategory {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String? parentId;
  final int orderIndex;
  final LibraryType type;

  LibraryCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.emoji = '📁',
    this.parentId,
    this.orderIndex = 0,
    this.type = LibraryType.pdf,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'parentId': parentId,
      'orderIndex': orderIndex,
      'type': type.index,
    };
  }

  factory LibraryCategory.fromMap(Map<dynamic, dynamic> map) {
    return LibraryCategory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '📁',
      parentId: map['parentId'],
      orderIndex: map['orderIndex'] ?? 0,
      type: LibraryType.values[map['type'] ?? 0],
    );
  }

  LibraryCategory copyWith({
    String? name,
    String? emoji,
    String? parentId,
    int? orderIndex,
    LibraryType? type,
  }) {
    return LibraryCategory(
      id: id,
      userId: userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      parentId: parentId ?? this.parentId,
      orderIndex: orderIndex ?? this.orderIndex,
      type: type ?? this.type,
    );
  }
}

class LibraryFile {
  final String id;
  final String userId;
  final String name;
  final String path;
  final String categoryId;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final int currentUnit; // Renamed from lastPage
  final int totalUnits; // New: total pages or total minutes
  final bool isCompleted; // New
  final bool isFavorite;
  final int orderIndex;
  final String notes;
  final LibraryType type;

  LibraryFile({
    required this.id,
    required this.userId,
    required this.name,
    required this.path,
    required this.categoryId,
    required this.addedAt,
    this.lastOpenedAt,
    this.currentUnit = 0,
    this.totalUnits = 1,
    this.isCompleted = false,
    this.isFavorite = false,
    this.orderIndex = 0,
    this.notes = '',
    this.type = LibraryType.pdf,
  });

  double get progressPercentage {
    if (isCompleted) return 1.0;
    if (totalUnits <= 0) return 0.0;
    return (currentUnit / totalUnits).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'path': path,
      'categoryId': categoryId,
      'addedAt': addedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'currentUnit': currentUnit,
      'totalUnits': totalUnits,
      'isCompleted': isCompleted,
      'isFavorite': isFavorite,
      'orderIndex': orderIndex,
      'notes': notes,
      'type': type.index,
    };
  }

  factory LibraryFile.fromMap(Map<dynamic, dynamic> map) {
    return LibraryFile(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      categoryId: map['categoryId'] ?? 'root',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
      lastOpenedAt: map['lastOpenedAt'] != null ? DateTime.parse(map['lastOpenedAt']) : null,
      currentUnit: map['currentUnit'] ?? map['lastPage'] ?? 0,
      totalUnits: map['totalUnits'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      orderIndex: map['orderIndex'] ?? 0,
      notes: map['notes'] ?? '',
      type: LibraryType.values[map['type'] ?? 0],
    );
  }

  LibraryFile copyWith({
    String? name,
    String? categoryId,
    DateTime? lastOpenedAt,
    int? currentUnit,
    int? totalUnits,
    bool? isCompleted,
    bool? isFavorite,
    int? orderIndex,
    String? notes,
    LibraryType? type,
  }) {
    return LibraryFile(
      id: id,
      userId: userId,
      name: name ?? this.name,
      path: path,
      categoryId: categoryId ?? this.categoryId,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      currentUnit: currentUnit ?? this.currentUnit,
      totalUnits: totalUnits ?? this.totalUnits,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      type: type ?? this.type,
    );
  }
}
