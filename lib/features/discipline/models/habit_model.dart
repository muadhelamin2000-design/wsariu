import 'package:flutter/material.dart';

enum HabitType { fixed, variable }
enum HabitGoal { good, bad }
enum RecurrenceType { daily, everyOtherDay, specificDays, interval }
enum ReminderType { fixed, flexible, prayer }

class Habit {
  final String id;
  final String userId; 
  final String name;
  final HabitType type;
  final HabitGoal goal;
  final int basePoints;
  final String? unitName;
  final RecurrenceType recurrence;
  final List<int> specificDays;
  final int intervalValue;
  final DateTime createdAt;
  final DateTime? challengeStartDate; // موعد بدء التحدي
  final Map<String, double> completionLog;
  final int colorValue;
  final int orderIndex;
  
  // New Reminder Fields
  final ReminderType reminderType;
  final int? reminderHour;
  final int? reminderMinute;
  final int? flexibleStartHour;
  final int? flexibleStartMinute;
  final int? flexibleEndHour;
  final int? flexibleEndMinute;
  final int? flexibleCount;
  final double? dailyTarget;
  final String? customReminderMessage;
  final String? linkedPrayer;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.goal,
    required this.basePoints,
    this.unitName,
    required this.recurrence,
    this.specificDays = const [],
    this.intervalValue = 1,
    required this.createdAt,
    this.challengeStartDate,
    this.completionLog = const {},
    this.colorValue = 0xFF0F3D2E,
    this.orderIndex = 0,
    this.reminderType = ReminderType.fixed,
    this.reminderHour,
    this.reminderMinute,
    this.flexibleStartHour,
    this.flexibleStartMinute,
    this.flexibleEndHour,
    this.flexibleEndMinute,
    this.flexibleCount,
    this.dailyTarget,
    this.customReminderMessage,
    this.linkedPrayer,
  });

  Color get color => Color(colorValue);

  TimeOfDay? get reminderTime => (reminderHour != null && reminderMinute != null)
      ? TimeOfDay(hour: reminderHour!, minute: reminderMinute!)
      : null;

  TimeOfDay? get flexibleStartTime => (flexibleStartHour != null && flexibleStartMinute != null)
      ? TimeOfDay(hour: flexibleStartHour!, minute: flexibleStartMinute!)
      : null;

  TimeOfDay? get flexibleEndTime => (flexibleEndHour != null && flexibleEndMinute != null)
      ? TimeOfDay(hour: flexibleEndHour!, minute: flexibleEndMinute!)
      : null;

  static const List<String> arabicDays = [
    'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.index,
      'goal': goal.index,
      'basePoints': basePoints,
      'unitName': unitName,
      'recurrence': recurrence.index,
      'specificDays': specificDays,
      'intervalValue': intervalValue,
      'createdAt': createdAt.toIso8601String(),
      'challengeStartDate': challengeStartDate?.toIso8601String(),
      'completionLog': completionLog,
      'colorValue': colorValue,
      'orderIndex': orderIndex,
      'reminderType': reminderType.index,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'flexibleStartHour': flexibleStartHour,
      'flexibleStartMinute': flexibleStartMinute,
      'flexibleEndHour': flexibleEndHour,
      'flexibleEndMinute': flexibleEndMinute,
      'flexibleCount': flexibleCount,
      'dailyTarget': dailyTarget,
      'customReminderMessage': customReminderMessage,
      'linkedPrayer': linkedPrayer,
    };
  }

  factory Habit.fromMap(Map<dynamic, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: HabitType.values[map['type'] ?? 0],
      goal: HabitGoal.values[map['goal'] ?? 0],
      basePoints: map['basePoints'] ?? 0,
      unitName: map['unitName'],
      recurrence: RecurrenceType.values[map['recurrence'] ?? 0],
      specificDays: List<int>.from(map['specificDays'] ?? []),
      intervalValue: map['intervalValue'] ?? 1,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      challengeStartDate: map['challengeStartDate'] != null ? DateTime.parse(map['challengeStartDate']) : null,
      completionLog: Map<String, double>.from(
        (map['completionLog'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      ),
      colorValue: map['colorValue'] ?? 0xFF0F3D2E,
      orderIndex: map['orderIndex'] ?? 0,
      reminderType: ReminderType.values[map['reminderType'] ?? 0],
      reminderHour: map['reminderHour'],
      reminderMinute: map['reminderMinute'],
      flexibleStartHour: map['flexibleStartHour'],
      flexibleStartMinute: map['flexibleStartMinute'],
      flexibleEndHour: map['flexibleEndHour'],
      flexibleEndMinute: map['flexibleEndMinute'],
      flexibleCount: map['flexibleCount'],
      dailyTarget: (map['dailyTarget'] as num?)?.toDouble(),
      customReminderMessage: map['customReminderMessage'],
      linkedPrayer: map['linkedPrayer'],
    );
  }

  Habit copyWith({
    String? name,
    HabitType? type,
    HabitGoal? goal,
    int? basePoints,
    String? unitName,
    RecurrenceType? recurrence,
    List<int>? specificDays,
    int? intervalValue,
    DateTime? challengeStartDate,
    DateTime? createdAt,
    Map<String, double>? completionLog,
    int? colorValue,
    int? orderIndex,
    ReminderType? reminderType,
    int? reminderHour,
    int? reminderMinute,
    int? flexibleStartHour,
    int? flexibleStartMinute,
    int? flexibleEndHour,
    int? flexibleEndMinute,
    int? flexibleCount,
    double? dailyTarget,
    String? customReminderMessage,
    String? linkedPrayer,
    bool clearReminder = false,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      goal: goal ?? this.goal,
      basePoints: basePoints ?? this.basePoints,
      unitName: unitName ?? this.unitName,
      recurrence: recurrence ?? this.recurrence,
      specificDays: specificDays ?? this.specificDays,
      intervalValue: intervalValue ?? this.intervalValue,
      createdAt: createdAt ?? this.createdAt,
      challengeStartDate: challengeStartDate ?? this.challengeStartDate,
      completionLog: completionLog ?? this.completionLog,
      colorValue: colorValue ?? this.colorValue,
      orderIndex: orderIndex ?? this.orderIndex,
      reminderType: reminderType ?? this.reminderType,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      flexibleStartHour: clearReminder ? null : (flexibleStartHour ?? this.flexibleStartHour),
      flexibleStartMinute: clearReminder ? null : (flexibleStartMinute ?? this.flexibleStartMinute),
      flexibleEndHour: clearReminder ? null : (flexibleEndHour ?? this.flexibleEndHour),
      flexibleEndMinute: clearReminder ? null : (flexibleEndMinute ?? this.flexibleEndMinute),
      flexibleCount: clearReminder ? null : (flexibleCount ?? this.flexibleCount),
      dailyTarget: dailyTarget ?? this.dailyTarget,
      customReminderMessage: customReminderMessage ?? this.customReminderMessage,
      linkedPrayer: clearReminder ? null : (linkedPrayer ?? this.linkedPrayer),
    );
  }

  double calculatePoints(DateTime date) {
    String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    if (!completionLog.containsKey(dateKey)) return 0;
    return completionLog[dateKey]! * basePoints;
  }

  int get currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    while (completionLog.containsKey("${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}")) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get commitmentRate {
    if (completionLog.isEmpty) return 0;
    int totalDays = DateTime.now().difference(createdAt).inDays + 1;
    return (completionLog.length / totalDays) * 100;
  }

  Color get statusColor {
    if (completionLog.isEmpty) return Colors.grey;
    DateTime lastDate = completionLog.keys.map((e) => DateTime.parse(e)).reduce((a, b) => a.isAfter(b) ? a : b);
    int daysSinceLastEntry = DateTime.now().difference(lastDate).inDays;
    if (daysSinceLastEntry >= 7) return Colors.red;
    if (daysSinceLastEntry >= 5) return Colors.orange;
    if (daysSinceLastEntry >= 3) return Colors.yellow.shade700;
    return Colors.green;
  }

  String get motivationMessage {
    double rate = commitmentRate;
    bool isBad = goal == HabitGoal.bad;

    if (isBad) {
      if (rate >= 75) return "انتبه! أنت تكرر هذه العادة بشكل كبير.. قاوم! ⚠️";
      if (rate >= 50) return "تحتاج لمزيد من الجهاد لترك هذه العادة 💪";
      if (rate >= 25) return "بداية جيدة في تقليلها، استمر في المجاهدة";
      return "ممتاز! أنت مسيطر تماماً على نفسك حالياً 🌟";
    } else {
      if (rate >= 75) return "أنت في تقدم ممتاز، استمر! 🚀";
      if (rate >= 50) return "ماشي كويس، كمل للاحسن";
      if (rate >= 25) return "بداية جيدة، محتاجين تركيز أكتر 💪";
      return "لا تستسلم، تقدر تبدأ تاني من دلوقتي 🔥";
    }
  }

  bool isCompletedToday() {
    final now = DateTime.now();
    final String dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    if (type == HabitType.fixed) {
      return completionLog.containsKey(dateKey) && completionLog[dateKey]! >= 1.0;
    } else {
      return completionLog.containsKey(dateKey) && completionLog[dateKey]! >= (dailyTarget ?? 1.0);
    }
  }
}
