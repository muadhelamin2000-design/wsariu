class LifeLink {
  final String id;
  final String userId;
  final String sourceId;
  final String sourceType; // habit, goal, worship, task, routine
  final String sourceName;
  final String targetId;
  final String targetType;
  final String targetName;
  final String relationDescription; // e.g., "يؤثر سلباً على", "يدعم"
  final bool isNegativeImpact; // if true, source failing ruins target

  LifeLink({
    required this.id,
    required this.userId,
    required this.sourceId,
    required this.sourceType,
    required this.sourceName,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    required this.relationDescription,
    this.isNegativeImpact = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'sourceName': sourceName,
      'targetId': targetId,
      'targetType': targetType,
      'targetName': targetName,
      'relationDescription': relationDescription,
      'isNegativeImpact': isNegativeImpact,
    };
  }

  factory LifeLink.fromMap(Map<dynamic, dynamic> map) {
    return LifeLink(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      sourceId: map['sourceId'] ?? '',
      sourceType: map['sourceType'] ?? '',
      sourceName: map['sourceName'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      targetName: map['targetName'] ?? '',
      relationDescription: map['relationDescription'] ?? '',
      isNegativeImpact: map['isNegativeImpact'] ?? false,
    );
  }
}
