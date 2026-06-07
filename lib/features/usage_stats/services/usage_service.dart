import 'package:usage_stats/usage_stats.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/usage_models.dart';
import '../../dashboard/services/prayer_service.dart';
import 'dart:io';

class UsageService {
  static const String boxName = 'phone_usage_box';
  static const String limitsBoxName = 'app_limits_box';
  static const String settingsBoxName = 'usage_settings_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
    await Hive.openBox(limitsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Future<void> setUserDailyGoal(double hours) async {
    final box = Hive.box(settingsBoxName);
    await box.put('daily_hours_goal', hours);
  }

  static double getUserDailyGoal() {
    final box = Hive.box(settingsBoxName);
    return box.get('daily_hours_goal', defaultValue: 4.0); 
  }

  static List<DailyUsageSummary> getWeeklyHistory() {
    final box = Hive.box(boxName);
    final now = DateTime.now();
    List<DailyUsageSummary> history = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final data = box.get(key);
      if (data != null) {
        history.add(DailyUsageSummary.fromMap(Map<dynamic, dynamic>.from(data)));
      }
    }
    return history;
  }

  static Future<bool> checkPermission() async {
    bool? isGranted = await UsageStats.checkUsagePermission();
    return isGranted ?? false;
  }

  static Future<void> grantPermission() async {
    await UsageStats.grantUsagePermission();
  }

  static Future<DailyUsageSummary> getTodayUsage() async {
    DateTime now = DateTime.now();
    DateTime startOfIslamicDay = PrayerService.getIslamicDayStartTime();
    
    // جلب الأحداث بدلاً من الإحصائيات الجاهزة لدقة أعلى منذ وقت مخصص (الفجر)
    List<EventUsageInfo> events = await UsageStats.queryEvents(startOfIslamicDay, now);
    
    Map<String, int> appUsageMs = {};
    Map<String, int> appLaunchCount = {};
    Map<String, DateTime> lastForegroundTime = {};
    int unlockCount = 0;

    // ترتيب الأحداث زمنياً
    events.sort((a, b) => a.timeStamp!.compareTo(b.timeStamp!));

    for (var event in events) {
      final pkg = event.packageName!;
      final time = DateTime.fromMillisecondsSinceEpoch(int.parse(event.timeStamp!));
      
      if (event.eventType == '1') { // MOVE_TO_FOREGROUND
        lastForegroundTime[pkg] = time;
        appLaunchCount[pkg] = (appLaunchCount[pkg] ?? 0) + 1;
      } else if (event.eventType == '2') { // MOVE_TO_BACKGROUND
        if (lastForegroundTime.containsKey(pkg)) {
          final duration = time.difference(lastForegroundTime[pkg]!).inMilliseconds;
          appUsageMs[pkg] = (appUsageMs[pkg] ?? 0) + duration;
          lastForegroundTime.remove(pkg);
        }
      } else if (event.eventType == '15' || event.eventType == '16') { // SCREEN_INTERACTIVE / KEYGUARD_DISMISSED
        unlockCount++;
      }
    }

    // التعامل مع التطبيق المفتوح حالياً
    lastForegroundTime.forEach((pkg, startTime) {
      final duration = now.difference(startTime).inMilliseconds;
      appUsageMs[pkg] = (appUsageMs[pkg] ?? 0) + duration;
    });

    List<AppUsageInfo> appUsages = [];
    Duration totalScreenTime = Duration.zero;
    Map<AppCategory, Duration> categoryBreakdown = {
      for (var cat in AppCategory.values) cat: Duration.zero
    };

    appUsageMs.forEach((pkg, ms) {
      if (!_shouldIncludeApp(pkg, ms)) return;
      
      final duration = Duration(milliseconds: ms);
      final appName = _getAppName(pkg);
      final category = _guessCategory(pkg);

      appUsages.add(AppUsageInfo(
        packageName: pkg,
        appName: appName,
        usageDuration: duration,
        launchCount: appLaunchCount[pkg] ?? 0,
        category: category,
      ));

      totalScreenTime += duration;
      categoryBreakdown[category] = categoryBreakdown[category]! + duration;
    });

    appUsages.sort((a, b) => b.usageDuration.compareTo(a.usageDuration));

    final summary = DailyUsageSummary(
      date: PrayerService.getIslamicDayDate(),
      totalScreenTime: totalScreenTime,
      unlockCount: unlockCount,
      appUsages: appUsages,
      categoryBreakdown: categoryBreakdown,
    );

    await _saveToHistory(summary);
    return summary;
  }

  static Future<int> _getUnlockCount(DateTime start, DateTime end) async {
    // محاكاة أو استخدام EventStats إذا كان متاحاً بدقة
    // في أندرويد، يمكن حساب الـ SCREEN_INTERACTIVE من EventStats
    try {
      List<EventUsageInfo> events = await UsageStats.queryEvents(start, end);
      return events.where((e) => e.eventType == '15').length; // 15 is SCREEN_INTERACTIVE (approximate for unlock)
    } catch (e) {
      return 0;
    }
  }

  static bool _shouldIncludeApp(String pkg, int ms) {
    if (ms < 10000) return false; // تجاهل أقل من 10 ثوانٍ
    final p = pkg.toLowerCase();
    
    // قائمة بالتطبيقات التي نريد استبعادها لأنها تقنية أو نظام خلفي
    final excludedKeywords = [
      'systemui', 'launcher', 'inputmethod', 'keyboard', 'service', 
      'provider', 'overlay', 'wallpaper', 'bluetooth', 'location', 
      'settings', 'framework', 'carrier', 'setupwizard', 'backup'
    ];
    
    for (var keyword in excludedKeywords) {
      if (p.contains(keyword)) return false;
    }
    
    if (p.startsWith('com.android.comp') || p.startsWith('com.google.android.gms')) return false;
    if (p == 'android') return false;

    return true;
  }

  static String _getAppName(String packageName) {
    // ترجمة الحزم الشهيرة لأسماء عربية
    final commonApps = {
      'com.whatsapp': 'واتساب',
      'com.facebook.katana': 'فيسبوك',
      'com.facebook.orca': 'ماسينجر',
      'com.instagram.android': 'إنستجرام',
      'com.twitter.android': 'إكس (تويتر)',
      'com.x.android': 'إكس',
      'com.google.android.youtube': 'يوتيوب',
      'com.zhiliaoapp.musically': 'تيك توك',
      'com.snapchat.android': 'سناب شات',
      'com.telegram.messenger': 'تيليجرام',
      'com.google.android.apps.maps': 'خرائط جوجل',
      'com.google.android.gm': 'جيميل',
      'com.android.chrome': 'كروم',
      'org.mozilla.firefox': 'فايرفوكس',
      'com.microsoft.teams': 'تيمز',
      'com.zoom.videomeetings': 'زووم',
      'com.netflix.mediaclient': 'نتفليكس',
      'com.spotify.music': 'سبوتيفاي',
      'com.shazam.android': 'شازام',
      'com.adobe.reader': 'أدوبي ريدر',
    };

    if (commonApps.containsKey(packageName)) {
      return commonApps[packageName]!;
    }
    
    final parts = packageName.split('.');
    if (parts.isEmpty) return packageName;
    
    String name = parts.last;
    // إذا كان الاسم الأخير هو android أو app، نأخذ ما قبله
    if ((name == 'android' || name == 'app' || name == 'apps') && parts.length > 1) {
      name = parts[parts.length - 2];
    }
    
    return name[0].toUpperCase() + name.substring(1);
  }

  static AppCategory _guessCategory(String packageName) {
    final p = packageName.toLowerCase();
    if (p.contains('facebook') || p.contains('instagram') || p.contains('twitter') || p.contains('tiktok') || p.contains('snapchat') || p.contains('whatsapp')) {
      return AppCategory.social;
    }
    if (p.contains('youtube') || p.contains('netflix') || p.contains('player') || p.contains('game')) {
      return AppCategory.entertainment;
    }
    if (p.contains('quran') || p.contains('muslim') || p.contains('prayer') || p.contains('athkar')) {
      return AppCategory.worship;
    }
    if (p.contains('chrome') || p.contains('browser') || p.contains('drive') || p.contains('office') || p.contains('mail')) {
      return AppCategory.productivity;
    }
    if (p.contains('google.android.apps.books') || p.contains('coursera') || p.contains('duolingo') || p.contains('learning')) {
      return AppCategory.education;
    }
    return AppCategory.other;
  }

  static Future<void> _saveToHistory(DailyUsageSummary summary) async {
    final box = Hive.box(boxName);
    final key = "${summary.date.year}-${summary.date.month.toString().padLeft(2, '0')}-${summary.date.day.toString().padLeft(2, '0')}";
    await box.put(key, summary.toMap());
  }

  // --- Limits ---
  static List<AppLimit> getLimits() {
    final box = Hive.box(limitsBoxName);
    return box.values.map((e) => AppLimit.fromMap(Map<dynamic, dynamic>.from(e))).toList();
  }

  static Future<void> saveLimit(AppLimit limit) async {
    final box = Hive.box(limitsBoxName);
    await box.put(limit.packageName, limit.toMap());
  }

  // --- Analytics Engine (Local) ---
  static String generateInsight(DailyUsageSummary today, DailyUsageSummary? yesterday) {
    if (today.totalScreenTime.inHours > 6) {
      return "استخدام الهاتف مرتفع جداً اليوم (${today.totalScreenTime.inHours} ساعة). حاول التقليل لزيادة تركيزك.";
    }
    if (yesterday != null) {
      final diff = today.totalScreenTime.inMinutes - yesterday.totalScreenTime.inMinutes;
      if (diff > 30) {
        return "زاد استخدامك اليوم بمقدار ${diff} دقيقة عن الأمس. انتبه لمشتتات الانتباه.";
      } else if (diff < -30) {
        return "أحسنت! قللت استخدام الهاتف اليوم بمقدار ${diff.abs()} دقيقة مقارنة بالأمس.";
      }
    }
    return "استخدامك للهاتف اليوم متوازن. استمر في الانضباط.";
  }

  static int calculateDisciplineScore(DailyUsageSummary summary) {
    // معادلة بسيطة: 100 - (نقاط خصم بناء على السوشيال ميديا ووقت الشاشة)
    int score = 100;
    int socialMins = summary.categoryBreakdown[AppCategory.social]?.inMinutes ?? 0;
    int totalMins = summary.totalScreenTime.inMinutes;

    score -= (totalMins ~/ 15); // خصم نقطة لكل 15 دقيقة استخدام
    score -= (socialMins ~/ 5); // خصم نقطة لكل 5 دقائق سوشيال ميديا
    
    return score.clamp(0, 100);
  }
}
