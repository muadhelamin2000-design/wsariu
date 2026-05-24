import 'package:hive_flutter/hive_flutter.dart';

part 'knowledge_model.g.dart';

@HiveType(typeId: 2)
enum KnowledgeType {
  @HiveField(0) quran,
  @HiveField(1) hadith,
  @HiveField(2) book
}

@HiveType(typeId: 1)
class KnowledgeEntry extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final KnowledgeType type;
  @HiveField(3) final String contentText;
  @HiveField(4) final String? sourceName;
  @HiveField(5) final String? detail;
  @HiveField(6) final List<String> benefits;
  @HiveField(7) final List<String> tags;
  @HiveField(8) final DateTime createdAt;

  KnowledgeEntry({
    required this.id, required this.userId, required this.type,
    required this.contentText, this.sourceName, this.detail,
    required this.benefits, this.tags = const [], required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'type': type.index,
    'contentText': contentText, 'sourceName': sourceName,
    'detail': detail, 'benefits': benefits, 'tags': tags,
    'createdAt': createdAt.toIso8601String(),
  };

  factory KnowledgeEntry.fromMap(Map<dynamic, dynamic> map) => KnowledgeEntry(
    id: map['id'], userId: map['userId'],
    type: KnowledgeType.values[map['type'] ?? 0],
    contentText: map['contentText'], sourceName: map['sourceName'],
    detail: map['detail'], benefits: List<String>.from(map['benefits'] ?? []),
    tags: List<String>.from(map['tags'] ?? []),
    createdAt: DateTime.parse(map['createdAt']),
  );

  KnowledgeEntry copyWith({String? contentText, String? sourceName, String? detail, List<String>? benefits, List<String>? tags, KnowledgeType? type}) =>
    KnowledgeEntry(id: id, userId: userId, type: type ?? this.type, contentText: contentText ?? this.contentText, sourceName: sourceName ?? this.sourceName, detail: detail ?? this.detail, benefits: benefits ?? this.benefits, tags: tags ?? this.tags, createdAt: createdAt);
}

@HiveType(typeId: 3)
class Node extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) List<String> categoryIds;
  @HiveField(3) final String contentText;
  @HiveField(4) final String? sourceName;
  @HiveField(5) final String? detail;
  @HiveField(6) List<String> benefits;
  @HiveField(7) List<String> tags;
  @HiveField(8) List<String> linkedNodeIds;
  @HiveField(9) final DateTime createdAt;
  @HiveField(10) List<String> mediaLinks; // لروابط الفيديو، الصور، المقالات

  Node({
    required this.id, required this.userId, required this.categoryIds,
    required this.contentText, this.sourceName, this.detail,
    required this.benefits, this.tags = const [], this.linkedNodeIds = const [],
    required this.createdAt, this.mediaLinks = const [],
  });

  Node copyWith({
    String? contentText, String? sourceName, String? detail,
    List<String>? benefits, List<String>? tags, List<String>? categoryIds,
    List<String>? linkedNodeIds, List<String>? mediaLinks,
  }) {
    return Node(
      id: id, userId: userId,
      categoryIds: categoryIds ?? this.categoryIds,
      contentText: contentText ?? this.contentText,
      sourceName: sourceName ?? this.sourceName,
      detail: detail ?? this.detail,
      benefits: benefits ?? this.benefits,
      tags: tags ?? this.tags,
      linkedNodeIds: linkedNodeIds ?? this.linkedNodeIds,
      createdAt: createdAt,
      mediaLinks: mediaLinks ?? this.mediaLinks,
    );
  }
}

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) final String userId;
  @HiveField(3) final DateTime createdAt;

  Category({required this.id, required this.name, required this.userId, required this.createdAt});

  factory Category.create({required String name, required String userId}) {
    return Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name, userId: userId, createdAt: DateTime.now(),
    );
  }
}
