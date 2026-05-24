import 'zad_model.dart';

enum AddictionType { gradual, absolute }

class AddictionHabit {
  final String id;
  final String userId;
  final String title;
  final AddictionType type;
  final DateTime startDate;
  final List<String> harms;
  final List<String> benefits;
  final List<String> alternatives; // البدائل المقترحة
  final List<ZadItem> hindrances; // أسباب زلة
  final List<ZadItem> facilitators; // أسباب نصر
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastRelapse;
  final List<DateTime> urgeHistory;
  final bool isActive;
  final String? linkedAppPackage; // الحزمة المرتبطة (اختياري)
  final int? dailyLimitMinutes; // الحد اليومي المقترح

  AddictionHabit({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.startDate,
    this.harms = const [],
    this.benefits = const [],
    this.alternatives = const [],
    this.hindrances = const [],
    this.facilitators = const [],
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastRelapse,
    this.urgeHistory = const [],
    this.isActive = true,
    this.linkedAppPackage,
    this.dailyLimitMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.index,
      'startDate': startDate.toIso8601String(),
      'harms': harms,
      'benefits': benefits,
      'alternatives': alternatives,
      'hindrances': hindrances.map((e) => e.toMap()).toList(),
      'facilitators': facilitators.map((e) => e.toMap()).toList(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastRelapse': lastRelapse?.toIso8601String(),
      'urgeHistory': urgeHistory.map((d) => d.toIso8601String()).toList(),
      'isActive': isActive,
      'linkedAppPackage': linkedAppPackage,
      'dailyLimitMinutes': dailyLimitMinutes,
    };
  }

  factory AddictionHabit.fromMap(Map<dynamic, dynamic> map) {
    return AddictionHabit(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      type: AddictionType.values[map['type']],
      startDate: DateTime.parse(map['startDate']),
      harms: List<String>.from(map['harms'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
      alternatives: List<String>.from(map['alternatives'] ?? []),
      hindrances: (map['hindrances'] as List?)?.map((e) => ZadItem.fromMap(e)).toList() ?? [],
      facilitators: (map['facilitators'] as List?)?.map((e) => ZadItem.fromMap(e)).toList() ?? [],
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      lastRelapse: map['lastRelapse'] != null ? DateTime.parse(map['lastRelapse']) : null,
      urgeHistory: (map['urgeHistory'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [],
      isActive: map['isActive'] ?? true,
      linkedAppPackage: map['linkedAppPackage'],
      dailyLimitMinutes: map['dailyLimitMinutes'],
    );
  }

  AddictionHabit copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastRelapse,
    List<DateTime>? urgeHistory,
    bool? isActive,
    List<String>? harms,
    List<String>? benefits,
    List<String>? alternatives,
    List<ZadItem>? hindrances,
    List<ZadItem>? facilitators,
    String? linkedAppPackage,
    int? dailyLimitMinutes,
  }) {
    return AddictionHabit(
      id: id,
      userId: userId,
      title: title,
      type: type,
      startDate: startDate,
      harms: harms ?? this.harms,
      benefits: benefits ?? this.benefits,
      alternatives: alternatives ?? this.alternatives,
      hindrances: hindrances ?? this.hindrances,
      facilitators: facilitators ?? this.facilitators,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastRelapse: lastRelapse ?? this.lastRelapse,
      urgeHistory: urgeHistory ?? this.urgeHistory,
      isActive: isActive ?? this.isActive,
      linkedAppPackage: linkedAppPackage ?? this.linkedAppPackage,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    );
  }

  String get currentWeeklyReward {
    int weeks = currentStreak ~/ 7;
    if (weeks == 0) return "صمود الأسبوع الأول هو الأصعب، استمر!";
    
    final rewards = [
      "وجبة مفضلة مكافأة لك",
      "شراء كتاب جديد أو هدية بسيطة",
      "نزهة في مكان تحبه",
      "جلسة استرخاء أو قهوة فاخرة",
      "يوم كامل من الهوايات المفضلة",
      "هدية قيمة كنت تؤجلها",
      "رحلة قصيرة للاحتفال بالإنجاز",
    ];
    
    int index = (weeks - 1) % rewards.length;
    return "مكافأة الأسبوع $weeks: ${rewards[index]}";
  }
}
