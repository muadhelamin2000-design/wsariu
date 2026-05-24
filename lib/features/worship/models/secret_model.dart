enum SecretType { dua, hiddenDeed, thought, covenant }

class SecretEntry {
  final String id;
  final String userId;
  final SecretType type;
  final String content;
  final DateTime date;
  final bool isBlurred;

  SecretEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.date,
    this.isBlurred = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'content': content,
      'date': date.toIso8601String(),
      'isBlurred': isBlurred,
    };
  }

  factory SecretEntry.fromMap(Map<dynamic, dynamic> map) {
    return SecretEntry(
      id: map['id'],
      userId: map['userId'],
      type: SecretType.values[map['type']],
      content: map['content'],
      date: DateTime.parse(map['date']),
      isBlurred: map['isBlurred'] ?? false,
    );
  }
}

class CharityMonth {
  final String id;
  final String userId;
  final String monthLabel; // e.g., "رمضان 2024" or "مايو 2024"
  final double income;
  final double percentage;
  final bool isExecuted;
  final DateTime createdAt;

  CharityMonth({
    required this.id,
    required this.userId,
    required this.monthLabel,
    required this.income,
    required this.percentage,
    this.isExecuted = false,
    required this.createdAt,
  });

  double get amount => income * (percentage / 100);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'monthLabel': monthLabel,
      'income': income,
      'percentage': percentage,
      'isExecuted': isExecuted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CharityMonth.fromMap(Map<dynamic, dynamic> map) {
    return CharityMonth(
      id: map['id'],
      userId: map['userId'],
      monthLabel: map['monthLabel'],
      income: (map['income'] as num).toDouble(),
      percentage: (map['percentage'] as num).toDouble(),
      isExecuted: map['isExecuted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
