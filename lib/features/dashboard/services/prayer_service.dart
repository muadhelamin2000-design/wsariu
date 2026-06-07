import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerService {
  // إحداثيات افتراضية (القاهرة كمثال)
  static const double latitude = 30.0444;
  static const double longitude = 31.2357;

  static PrayerTimes _getTodayTimes() {
    final myCoordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes.today(myCoordinates, params);
  }

  static Map<String, DateTime> getPrayerTimes() {
    final prayerTimes = _getTodayTimes();
    final now = DateTime.now();
    final bool isFriday = now.weekday == DateTime.friday;

    return {
      'الفجر': prayerTimes.fajr,
      'الشروق': prayerTimes.sunrise,
      'الضحى': prayerTimes.sunrise.add(const Duration(minutes: 20)),
      isFriday ? 'الجمعة' : 'الظهر': prayerTimes.dhuhr,
      'العصر': prayerTimes.asr,
      'المغرب': prayerTimes.maghrib,
      'العشاء': prayerTimes.isha,
    };
  }

  // الحصول على التاريخ الفعلي بناءً على صلاة الفجر
  static DateTime getIslamicDayDate() {
    final now = DateTime.now();
    final prayerTimes = _getTodayTimes();
    
    // إذا كان الوقت الحالي قبل الفجر، فنحن ما زلنا في "يوم أمس"
    if (now.isBefore(prayerTimes.fajr)) {
      return now.subtract(const Duration(days: 1));
    }
    return now;
  }

  static DateTime getIslamicDayStartTime() {
    final prayerTimes = _getTodayTimes();
    final now = DateTime.now();
    
    if (now.isBefore(prayerTimes.fajr)) {
      // نحن قبل فجر اليوم، إذاً بداية اليوم الإسلامي الحالي كانت فجر "أمس"
      final yesterday = now.subtract(const Duration(days: 1));
      final myCoordinates = Coordinates(latitude, longitude);
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;
      final yesterdayTimes = PrayerTimes(myCoordinates, DateComponents.from(yesterday), params);
      return yesterdayTimes.fajr;
    }
    // نحن بعد الفجر، بداية اليوم هي فجر اليوم
    return prayerTimes.fajr;
  }

  static String getIslamicDayKey() {
    final date = getIslamicDayDate();
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static String getNextPrayerCountdown() {
    final myCoordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    
    final now = DateTime.now();
    
    // Find the next upcoming event
    DateTime? nextTime;
    String prayerName = "";

    final sunrise = prayerTimes.sunrise;
    final duha = sunrise.add(const Duration(minutes: 20));

    if (now.isBefore(prayerTimes.fajr)) {
      nextTime = prayerTimes.fajr;
      prayerName = "الفجر";
    } else if (now.isBefore(sunrise)) {
      nextTime = sunrise;
      prayerName = "الشروق";
    } else if (now.isBefore(duha)) {
      nextTime = duha;
      prayerName = "الضحى";
    } else if (now.isBefore(prayerTimes.dhuhr)) {
      nextTime = prayerTimes.dhuhr;
      prayerName = "الظهر";
    } else if (now.isBefore(prayerTimes.asr)) {
      nextTime = prayerTimes.asr;
      prayerName = "العصر";
    } else if (now.isBefore(prayerTimes.maghrib)) {
      nextTime = prayerTimes.maghrib;
      prayerName = "المغرب";
    } else if (now.isBefore(prayerTimes.isha)) {
      nextTime = prayerTimes.isha;
      prayerName = "العشاء";
    } else {
      // It's after Isha, next is tomorrow's Fajr
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = PrayerTimes(myCoordinates, DateComponents.from(tomorrow), params);
      nextTime = tomorrowTimes.fajr;
      prayerName = "الفجر";
    }

    final diff = nextTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    
    return "باقي على $prayerName ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  static String _getPrayerArabicName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      default: return '';
    }
  }

  static String getCurrentPrayerName() {
    final prayerTimes = _getTodayTimes();
    final current = prayerTimes.currentPrayer();
    return _getPrayerArabicName(current);
  }

  static String getNextPrayerName() {
    final prayerTimes = _getTodayTimes();
    final next = prayerTimes.nextPrayer();
    if (next == Prayer.none) return 'الفجر'; 
    return _getPrayerArabicName(next);
  }

  static DateTime? getPrayerTime(String name) {
    final times = getPrayerTimes();
    return times[name];
  }

  static Map<String, dynamic> getTargetPrayerForNotification() {
    final times = _getTodayTimes();
    final now = DateTime.now();
    
    final current = times.currentPrayer();
    if (current != Prayer.none) {
      final currentTime = times.timeForPrayer(current);
      if (currentTime != null && now.difference(currentTime).inMinutes < 30) {
        return {
          'name': _getPrayerArabicName(current),
          'time': currentTime,
          'isPast': true,
        };
      }
    }
    
    final next = times.nextPrayer();
    if (next != Prayer.none) {
      final nextTime = times.timeForPrayer(next);
      if (nextTime != null) {
        return {
          'name': _getPrayerArabicName(next),
          'time': nextTime,
          'isPast': false,
        };
      }
    }
    
    // Default to tomorrow's Fajr
    final myCoordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowTimes = PrayerTimes(myCoordinates, DateComponents.from(tomorrow), params);
    
    return {
      'name': 'الفجر',
      'time': tomorrowTimes.fajr,
      'isPast': false,
    };
  }

  // --- Night Calculations ---
  
  static Map<String, DateTime> getNightTimes() {
    final times = _getTodayTimes();
    final maghrib = times.maghrib;
    final isha = times.isha;
    
    // فجر الغد
    final myCoordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowTimes = PrayerTimes(myCoordinates, DateComponents.from(tomorrow), params);
    final fajrTomorrow = tomorrowTimes.fajr;

    // 1. نصف الليل الشرعي (بين المغرب والفجر)
    final totalNightDuration = fajrTomorrow.difference(maghrib);
    final midnightSharia = maghrib.add(totalNightDuration ~/ 2);
    final lastThirdSharia = maghrib.add(totalNightDuration * 2 ~/ 3);

    // 2. من العشاء إلى الفجر
    final ishaToFajrDuration = fajrTomorrow.difference(isha);
    final midnightIsha = isha.add(ishaToFajrDuration ~/ 2);
    final lastThirdIsha = isha.add(ishaToFajrDuration * 2 ~/ 3);

    // 3. قيام داود (من العشاء: ينام نصف الليل، يقوم ثلثه، ينام سدسه)
    final halfNightPoint = isha.add(ishaToFajrDuration ~/ 2);
    final startDawud = halfNightPoint;
    final endDawud = halfNightPoint.add(ishaToFajrDuration ~/ 3);
    
    // 4. السدس الأخير من الليل (يستخدم للنوم في نظام داود أو للاستغفار)
    final lastSixthSharia = fajrTomorrow.subtract(totalNightDuration ~/ 6);

    return {
      'maghrib': maghrib,
      'isha': isha,
      'fajrTomorrow': fajrTomorrow,
      'midnightSharia': midnightSharia,
      'lastThirdSharia': lastThirdSharia,
      'lastSixthSharia': lastSixthSharia,
      'midnightIsha': midnightIsha,
      'lastThirdIsha': lastThirdIsha,
      'startDawud': startDawud,
      'endDawud': endDawud,
    };
  }
}
