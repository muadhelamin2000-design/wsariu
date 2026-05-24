import 'package:hive_flutter/hive_flutter.dart';

/// 📊 نموذج بيانات التحليلات
class AnalyticsData {
  final DateTime date;
  final String category;
  final double value;
  final String? metadata;

  AnalyticsData({
    required this.date,
    required this.category,
    required this.value,
    this.metadata,
  });
}

/// 📈 نموذج الإحصائيات الأسبوعية
class WeeklyStats {
  final String label;
  final double value;
  final DateTime startDate;
  final DateTime endDate;

  WeeklyStats({
    required this.label,
    required this.value,
    required this.startDate,
    required this.endDate,
  });
}

/// 🏆 نموذج الأهداف والتقدم
class GoalProgress {
  final String goalName;
  final double targetValue;
  final double currentValue;
  final DateTime createdAt;
  final DateTime? completedAt;

  GoalProgress({
    required this.goalName,
    required this.targetValue,
    required this.currentValue,
    required this.createdAt,
    this.completedAt,
  });

  double get progressPercentage => (currentValue / targetValue * 100).clamp(0, 100);
  bool get isCompleted => currentValue >= targetValue;
}

/// 🎯 خدمة التحليلات الرئيسية
class AnalyticsService {
  static late final AnalyticsService _instance;
  static late final Box<Map> _analyticsBox;
  static bool _initialized = false;

  AnalyticsService._();

  static Future<void> init() async {
    _instance = AnalyticsService._();
    _analyticsBox = await Hive.openBox<Map>('analytics_data');
    _initialized = true;
  }

  /// 📊 الحصول على متوسط النوم الأسبوعي
  static Future<List<WeeklyStats>> getWeeklySleepStats() async {
    final now = DateTime.now();
    List<WeeklyStats> stats = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStats = _calculateDaySleep(date);

      stats.add(WeeklyStats(
        label: _getDayName(date),
        value: dayStats,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      ));
    }

    return stats;
  }

  /// 📈 الحصول على متوسط النوم الشهري
  static Future<List<WeeklyStats>> getMonthlySleepStats() async {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    List<WeeklyStats> stats = [];

    for (int week = 0; week < 4; week++) {
      final weekStart = monthAgo.add(Duration(days: week * 7));
      double weekAverage = 0;

      for (int day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        weekAverage += _calculateDaySleep(date);
      }
      weekAverage /= 7;

      stats.add(WeeklyStats(
        label: 'الأسبوع ${week + 1}',
        value: weekAverage,
        startDate: weekStart,
        endDate: weekStart.add(const Duration(days: 6, hours: 23, minutes: 59)),
      ));
    }

    return stats;
  }

  /// 🎯 الحصول على جودة النوم
  static Future<double> getSleepQualityScore() async {
    final List<WeeklyStats> weekStats = await getWeeklySleepStats();

    if (weekStats.isEmpty) return 0.0;

    final double averageSleep = weekStats.fold<double>(
      0.0,
      (double prev, stat) => prev + stat.value,
    ) / weekStats.length;

    const double targetSleep = 8.0;
    final double score = (averageSleep / targetSleep * 100).clamp(0.0, 100.0);

    return score;
  }

  /// 📊 الحصول على نسبة تكمال العادات الأسبوعية
  static Future<Map<String, double>> getWeeklyHabitsCompletion() async {
    return {
      'الوضوء قبل النوم': 86.0,
      'ترك الهاتف': 71.0,
      'أذكار النوم': 43.0,
      'الصلاة في الموعد': 92.0,
      'ممارسة الرياضة': 57.0,
    };
  }

  /// 🏆 الحصول على أفضل العادات
  static Future<List<String>> getTopHabits({int limit = 5}) async {
    final habits = await getWeeklyHabitsCompletion();

    final sorted = habits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// 📉 الحصول على العادات التي تحتاج تحسين
  static Future<List<String>> getBottomHabits({int limit = 3}) async {
    final habits = await getWeeklyHabitsCompletion();

    final sorted = habits.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// ⏱️ إجمالي ساعات الدراسة
  static Future<double> getWeeklyStudyHours() async {
    return 15.5;
  }

  /// 📈 متوسط ساعات الدراسة يومياً
  static Future<double> getDailyAverageStudy() async {
    final weekly = await getWeeklyStudyHours();
    return weekly / 7;
  }

  /// 🔄 مقارنة هذا الأسبوع بالأسبوع الماضي
  static Future<Map<String, double>> compareWithLastWeek() async {
    final currentWeek = await getWeeklySleepStats();

    double currentAvg = currentWeek.isEmpty
      ? 0
      : currentWeek.fold<double>(0, (prev, stat) => prev + stat.value) / currentWeek.length;

    double lastWeekAvg = 7.2;

    return {
      'currentWeek': currentAvg,
      'lastWeek': lastWeekAvg,
      'difference': currentAvg - lastWeekAvg,
      'percentageChange': ((currentAvg - lastWeekAvg) / lastWeekAvg * 100),
    };
  }

  /// 🏆 الأهداف والتقدم
  static Future<List<GoalProgress>> getGoalsProgress() async {
    return [
      GoalProgress(
        goalName: 'النوم 8 ساعات يومياً',
        targetValue: 8.0,
        currentValue: 7.5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      GoalProgress(
        goalName: 'تكمال 5 عادات يومياً',
        targetValue: 5.0,
        currentValue: 3.0,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      GoalProgress(
        goalName: 'دراسة 2 ساعة يومياً',
        targetValue: 2.0,
        currentValue: 1.5,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  static double _calculateDaySleep(DateTime date) {
    final hour = date.day;
    if (hour % 2 == 0) return 7.5;
    if (hour % 3 == 0) return 8.0;
    return 6.5;
  }

  static String _getDayName(DateTime date) {
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[date.weekday % 7];
  }

  static Future<void> recordAnalyticsEvent({
    required String category,
    required double value,
    String? metadata,
  }) async {
    final now = DateTime.now();
    final key = '${category}_${now.millisecondsSinceEpoch}';

    await _analyticsBox.put(key, {
      'date': now.toIso8601String(),
      'category': category,
      'value': value,
      'metadata': metadata,
    });
  }

  static Future<List<AnalyticsData>> getAllAnalyticsData() async {
    final entries = _analyticsBox.values.toList();

    return entries.map((entry) {
      return AnalyticsData(
        date: DateTime.parse(entry['date'] as String),
        category: entry['category'] as String,
        value: entry['value'] as double,
        metadata: entry['metadata'] as String?,
      );
    }).toList();
  }
}

