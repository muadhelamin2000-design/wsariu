import 'package:hive_flutter/hive_flutter.dart';
import 'prayer_service.dart';

class SunanService {
  static const String boxName = 'sunan_management_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Map<String, int> getSunanForPrayer(String prayerName) {
    // توزيع السنن الرواتب (12 ركعة)
    switch (prayerName) {
      case 'الفجر': return {'قبلية': 2};
      case 'الظهر': return {'قبلية': 4, 'بعدية': 2};
      case 'المغرب': return {'بعدية': 2};
      case 'العشاء': return {'بعدية': 2};
      default: return {};
    }
  }

  static Map<String, int> getTodayProgress() {
    final box = Hive.box(boxName);
    final todayKey = PrayerService.getIslamicDayKey();
    return Map<String, int>.from(box.get('progress_$todayKey', defaultValue: {}));
  }

  static Future<void> updateProgress(String prayerName, String type, int count) async {
    final box = Hive.box(boxName);
    final todayKey = PrayerService.getIslamicDayKey();
    final progress = getTodayProgress();
    
    final key = '${prayerName}_$type';
    progress[key] = count;
    
    await box.put('progress_$todayKey', progress);
    
    // التحقق من اكتمال البيت
    await _checkAndBuildHouse(todayKey);
  }

  static int getTotalRakaatToday() {
    final progress = getTodayProgress();
    return progress.values.fold(0, (sum, val) => sum + val);
  }

  static int getTargetRakaat() {
    final now = DateTime.now();
    if (now.weekday == DateTime.friday) return 10; // السنن في يوم الجمعة تختلف (أقلها 8 أو 10)
    return 12;
  }

  static Future<void> _checkAndBuildHouse(String dateKey) async {
    final box = Hive.box(boxName);
    final progress = Map<String, int>.from(box.get('progress_$dateKey', defaultValue: {}));
    final total = progress.values.fold(0, (sum, val) => sum + val);
    
    final houses = Map<String, bool>.from(box.get('houses_log', defaultValue: {}));
    
    // إذا وصل للعدد المطلوب ولم يُبنى البيت لهذا اليوم بعد
    if (total >= getTargetRakaat() && !(houses[dateKey] ?? false)) {
      houses[dateKey] = true;
      await box.put('houses_log', houses);
      
      // زيادة العداد الإجمالي
      int totalHouses = box.get('total_houses_count', defaultValue: 0);
      await box.put('total_houses_count', totalHouses + 1);
    } else if (total < getTargetRakaat() && (houses[dateKey] ?? false)) {
      // إذا تراجع عن ركعات وأصبح المجموع أقل، نهدم البيت لهذا اليوم
      houses[dateKey] = false;
      await box.put('houses_log', houses);
      int totalHouses = box.get('total_houses_count', defaultValue: 0);
      await box.put('total_houses_count', (totalHouses - 1).clamp(0, 999999));
    }
  }

  static int getTotalHousesBuilt() {
    final box = Hive.box(boxName);
    return box.get('total_houses_count', defaultValue: 0);
  }

  static bool isHouseBuiltToday() {
    final box = Hive.box(boxName);
    final todayKey = PrayerService.getIslamicDayKey();
    final houses = Map<String, bool>.from(box.get('houses_log', defaultValue: {}));
    return houses[todayKey] ?? false;
  }

  static Future<void> setTotalHouses(int count) async {
    final box = Hive.box(boxName);
    await box.put('total_houses_count', count.clamp(0, 999999));
  }
}
