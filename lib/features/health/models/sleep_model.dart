class SleepEntry {
  final String id;
  final String userId;
  final DateTime bedTime;
  final DateTime? wakeTime;
  final int quality; // 0-100
  final List<String> positiveHabits;
  final List<String> negativeHabits;
  final String notes;

  SleepEntry({
    required this.id,
    required this.userId,
    required this.bedTime,
    this.wakeTime,
    this.quality = 0,
    this.positiveHabits = const [],
    this.negativeHabits = const [],
    this.notes = '',
  });

  Duration get duration => wakeTime != null ? wakeTime!.difference(bedTime) : Duration.zero;

  int get sleepCycles => (duration.inMinutes / 90).floor();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime?.toIso8601String(),
      'quality': quality,
      'positiveHabits': positiveHabits,
      'negativeHabits': negativeHabits,
      'notes': notes,
    };
  }

  factory SleepEntry.fromMap(Map<dynamic, dynamic> map) {
    return SleepEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      bedTime: DateTime.parse(map['bedTime'] ?? DateTime.now().toIso8601String()),
      wakeTime: map['wakeTime'] != null ? DateTime.parse(map['wakeTime']) : null,
      quality: map['quality'] ?? 0,
      positiveHabits: List<String>.from(map['positiveHabits'] ?? []),
      negativeHabits: List<String>.from(map['negativeHabits'] ?? []),
      notes: map['notes'] ?? '',
    );
  }
}
