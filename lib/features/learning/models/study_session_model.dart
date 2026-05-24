class StudySession {
  final String id;
  final String userId;
  final String category;
  final int plannedMinutes;
  final int actualMinutes;
  final int breakMinutes;
  final DateTime date;

  StudySession({
    required this.id,
    required this.userId,
    required this.category,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.breakMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'breakMinutes': breakMinutes,
      'date': date.toIso8601String(),
    };
  }

  factory StudySession.fromMap(Map<dynamic, dynamic> map) {
    return StudySession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'عام',
      plannedMinutes: map['plannedMinutes'] ?? 0,
      actualMinutes: map['actualMinutes'] ?? 0,
      breakMinutes: map['breakMinutes'] ?? 0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}
