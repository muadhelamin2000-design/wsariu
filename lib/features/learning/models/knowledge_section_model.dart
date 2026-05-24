class KnowledgeSection {
  final String id;
  final String userId;
  final String name;

  KnowledgeSection({
    required this.id,
    required this.userId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
    };
  }

  factory KnowledgeSection.fromMap(Map<dynamic, dynamic> map) {
    return KnowledgeSection(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

class KnowledgeEntry {
  final String id;
  final String userId;
  final String sectionId;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> linkedEntryIds;
  final String? imagePath;
  final String? videoPath;
  final String? mediaLink;
  final DateTime createdAt;

  KnowledgeEntry({
    required this.id,
    required this.userId,
    required this.sectionId,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.linkedEntryIds = const [],
    this.imagePath,
    this.videoPath,
    this.mediaLink,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sectionId': sectionId,
      'title': title,
      'content': content,
      'tags': tags,
      'linkedEntryIds': linkedEntryIds,
      'imagePath': imagePath,
      'videoPath': videoPath,
      'mediaLink': mediaLink,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KnowledgeEntry.fromMap(Map<dynamic, dynamic> map) {
    return KnowledgeEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      linkedEntryIds: List<String>.from(map['linkedEntryIds'] ?? []),
      imagePath: map['imagePath'],
      videoPath: map['videoPath'],
      mediaLink: map['mediaLink'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  KnowledgeEntry copyWith({
    String? title,
    String? content,
    List<String>? tags,
    List<String>? linkedEntryIds,
    String? imagePath,
    String? videoPath,
    String? mediaLink,
  }) {
    return KnowledgeEntry(
      id: id,
      userId: userId,
      sectionId: sectionId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      linkedEntryIds: linkedEntryIds ?? this.linkedEntryIds,
      imagePath: imagePath ?? this.imagePath,
      videoPath: videoPath ?? this.videoPath,
      mediaLink: mediaLink ?? this.mediaLink,
      createdAt: createdAt,
    );
  }
}
