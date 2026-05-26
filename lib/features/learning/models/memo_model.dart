enum MemoType { memo, dialogue, idea, data }

class Memo {
  final String id;
  final String userId;
  final String title; // New
  final String content;
  final DateTime date;
  final MemoType type;
  
  // Memo specific
  final String? mood;
  final String? accomplishments;
  final String? shortcomings;
  
  // Dialogue specific
  final String? dialogueCategory; // Idea, Problem, Decision, Question
  
  // Idea specific
  final String? importance; // High, Medium, Low

  // Data Section specific (Favorites, Dislikes, Difficulties, Rewards, Consequences, Decisions)
  final String? dataCategory; 

  Memo({
    required this.id,
    required this.userId,
    this.title = '', // Default empty for old data
    required this.content,
    required this.date,
    required this.type,
    this.mood,
    this.accomplishments,
    this.shortcomings,
    this.dialogueCategory,
    this.importance,
    this.dataCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'type': type.index,
      'mood': mood,
      'accomplishments': accomplishments,
      'shortcomings': shortcomings,
      'dialogueCategory': dialogueCategory,
      'importance': importance,
      'dataCategory': dataCategory,
    };
  }

  factory Memo.fromMap(Map<dynamic, dynamic> map) {
    return Memo(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      type: MemoType.values[map['type'] ?? 0],
      mood: map['mood'],
      accomplishments: map['accomplishments'],
      shortcomings: map['shortcomings'],
      dialogueCategory: map['dialogueCategory'],
      importance: map['importance'],
      dataCategory: map['dataCategory'],
    );
  }
}
