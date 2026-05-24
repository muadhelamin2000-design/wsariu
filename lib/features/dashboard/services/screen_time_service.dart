import 'package:hive_flutter/hive_flutter.dart';
import 'package:usage_stats/usage_stats.dart';

class AppUsage {
  final String appName;
  final int minutes;
  final String packageName;

  AppUsage({required this.appName, required this.minutes, this.packageName = ''});

  Map<String, dynamic> toMap() => {'appName': appName, 'minutes': minutes, 'packageName': packageName};
  factory AppUsage.fromMap(Map<dynamic, dynamic> map) => AppUsage(
    appName: map['appName'],
    minutes: map['minutes'],
    packageName: map['packageName'] ?? '',
  );
}

class ScreenTimeService {
  static const String boxName = 'screen_time_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static int getDailyLimit() {
    final box = Hive.box(boxName);
    return box.get('daily_usage_limit', defaultValue: 120); // الافتراضي ساعتان
  }

  static Future<void> setDailyLimit(int minutes) async {
    final box = Hive.box(boxName);
    await box.put('daily_usage_limit', minutes);
  }

  static Future<bool> checkPermission() async {
    bool? granted = await UsageStats.checkUsagePermission();
    return granted ?? false;
  }

  static Future<void> requestPermission() async {
    await UsageStats.grantUsagePermission();
  }

  static Future<List<AppUsage>> getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    List<UsageInfo> stats = await UsageStats.queryUsageStats(startOfDay, now);
    
    List<AppUsage> results = [];
    
    for (var info in stats) {
      int millis = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      if (millis <= 0) continue;
      
      String pkg = info.packageName ?? '';
      // استثناء تطبيقات النظام المزعجة
      if (pkg.contains('systemui') || 
          pkg.contains('launcher') || 
          pkg.contains('android.google') ||
          pkg.contains('com.google.android.gms')) {
        continue;
      }

      results.add(AppUsage(
        appName: pkg.split('.').last, // محاولة تقريب الاسم، في الوضع الحقيقي نحتاج package_info
        packageName: pkg,
        minutes: (millis / 1000 / 60).round(),
      ));
    }

    // ترتيب من الأكثر استهلاكاً
    results.sort((a, b) => b.minutes.compareTo(a.minutes));
    return results;
  }

  static int getTotalMinutes(List<AppUsage> apps) {
    return apps.fold(0, (sum, item) => sum + item.minutes);
  }

  static String formatDuration(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (hours > 0) return '$hours ساعة و $minutes دقيقة';
    return '$minutes دقيقة';
  }
}
