class StudySection {
  final String id;
  final String userId;
  final String name;

  StudySection({required this.id, required this.userId, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'userId': userId, 'name': name};
  factory StudySection.fromMap(Map<dynamic, dynamic> map) => StudySection(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    name: map['name'] ?? '',
  );
}

class StudyEntry {
  final String id;
  final String userId;
  final String sectionId;
  final String title;
  final String description;
  final List<String> tags;
  final List<String> linkedIds;
  final DateTime createdAt;

  StudyEntry({
    required this.id,
    required this.userId,
    required this.sectionId,
    required this.title,
    this.description = '',
    this.tags = const [],
    this.linkedIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sectionId': sectionId,
      'title': title,
      'description': description,
      'tags': tags,
      'linkedIds': linkedIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudyEntry.fromMap(Map<dynamic, dynamic> map) {
    return StudyEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      linkedIds: List<String>.from(map['linkedIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  StudyEntry copyWith({
    String? title,
    String? description,
    List<String>? tags,
    List<String>? linkedIds,
  }) {
    return StudyEntry(
      id: id,
      userId: userId,
      sectionId: sectionId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      linkedIds: linkedIds ?? this.linkedIds,
      createdAt: createdAt,
    );
  }
}
