class QiyamSession {
  final String id;
  final String userId;
  final DateTime date;
  final int totalPrayerMinutes;
  final int totalBreakMinutes;
  final List<QiyamSegment> segments;

  QiyamSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalPrayerMinutes,
    required this.totalBreakMinutes,
    this.segments = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'totalPrayerMinutes': totalPrayerMinutes,
    'totalBreakMinutes': totalBreakMinutes,
    'segments': segments.map((s) => s.toMap()).toList(),
  };

  factory QiyamSession.fromMap(Map<dynamic, dynamic> map) => QiyamSession(
    id: map['id'],
    userId: map['userId'],
    date: DateTime.parse(map['date']),
    totalPrayerMinutes: map['totalPrayerMinutes'],
    totalBreakMinutes: map['totalBreakMinutes'],
    segments: (map['segments'] as List?)?.map((s) => QiyamSegment.fromMap(s)).toList() ?? [],
  );
}

enum SegmentType { prayer, rest }

class QiyamSegment {
  final DateTime start;
  final DateTime end;
  final SegmentType type;

  QiyamSegment({required this.start, required this.end, required this.type});

  int get durationMinutes => end.difference(start).inMinutes;

  Map<String, dynamic> toMap() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'type': type.index,
  };

  factory QiyamSegment.fromMap(Map<dynamic, dynamic> map) => QiyamSegment(
    start: DateTime.parse(map['start']),
    end: DateTime.parse(map['end']),
    type: SegmentType.values[map['type']],
  );
}
