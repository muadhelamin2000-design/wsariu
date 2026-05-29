import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:adhan/adhan.dart';
import '../models/habit_model.dart';
import '../../dashboard/services/prayer_service.dart';
import '../../worship/services/addiction_service.dart';
import 'habit_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const MethodChannel _alarmChannel = MethodChannel('com.wasariu.app/alarm');
  static Timer? _countdownTimer;

  // تتبع الإشعارات النشطة لمنع التكرار
  static final Map<int, DateTime> _activeNotifications = {};

  // ================= INIT =================
  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'mark_done') {
          final habitId = response.payload;
          if (habitId != null) {
            await HabitService.toggleHabitCompletion(habitId, DateTime.now(), 1.0);
          }
        } else if (response.actionId == 'input_value') {
          final habitId = response.payload;
          final value = response.input;
          if (habitId != null && value != null) {
            final double? numVal = double.tryParse(value);
            if (numVal != null) {
              await HabitService.updateHabitValue(habitId, DateTime.now(), numVal);
            }
          }
        } else if (response.actionId == 'snooze') {
          final payload = response.payload ?? "";
          final parts = payload.split('|');
          final id = int.tryParse(parts[0]) ?? 0;
          final title = parts.length > 1 ? parts[1] : "تنبيه";
          final body = parts.length > 2 ? parts[2] : "";
          final snoozeMins = parts.length > 3 ? (int.tryParse(parts[3]) ?? 10) : 10;
          final soundPath = parts.length > 4 ? parts[4] : null;
          
          final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMins));
          await scheduleAlarm(
            id: id,
            title: title,
            body: "$body (بعد الغفوة)",
            time: snoozeTime,
            snoozeDuration: snoozeMins,
            customSoundPath: soundPath,
          );
        } else if (response.actionId == 'addiction_triumph_yes') {
          await AddictionService.logDailyTriumph(true);
        } else if (response.actionId == 'addiction_triumph_no') {
          await AddictionService.logDailyTriumph(false);
        }
      },
    );

    const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
      'habit_smart_reminders',
      'تذكيرات العادات',
      description: 'تذكيرات ذكية',
      importance: Importance.max,
    );

    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'smart_alarm_channel',
      'تنبيهات النظام',
      description: 'تنبيهات التطبيق العامة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(habitChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);

    await requestPermissions();
    
    // تم إزالة مسح كافة التنبيهات لضمان بقاء تنبيهات الأدوية
    // await cancelAllOldNotifications();

    scheduleIslamicAlarms();
    scheduleOngoingRefreshes();
    
    _startCountdownUpdate();
  }

  static Future<void> cancelAllOldNotifications() async {
    final List<PendingNotificationRequest> pending = await _notificationsPlugin.pendingNotificationRequests();
    for (var p in pending) {
      if (p.id != 8880) {
        await _notificationsPlugin.cancel(id: p.id);
      }
    }
    debugPrint("All non-prayer notifications cleared.");
  }

  static void scheduleOngoingRefreshes() async {
    final prayerTimes = PrayerService.getPrayerTimes();
    final sortedTimes = prayerTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < sortedTimes.length; i++) {
      final currentPrayerTime = sortedTimes[i].value;
      DateTime nextPrayerTime;
      String nextPrayerName;

      if (i < sortedTimes.length - 1) {
        nextPrayerTime = sortedTimes[i + 1].value;
        nextPrayerName = sortedTimes[i + 1].key;
      } else {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final myCoordinates = Coordinates(PrayerService.latitude, PrayerService.longitude);
        final params = CalculationMethod.egyptian.getParameters();
        final tomorrowTimes = PrayerTimes(myCoordinates, DateComponents.from(tomorrow), params);
        nextPrayerTime = tomorrowTimes.fajr;
        nextPrayerName = "الفجر";
      }

      await _scheduleOngoingRefresh(
        scheduleTime: currentPrayerTime,
        nextPrayerTime: nextPrayerTime,
        nextPrayerName: nextPrayerName,
      );
    }
  }

  static Future<void> _scheduleOngoingRefresh({
    required DateTime scheduleTime,
    required DateTime nextPrayerTime,
    required String nextPrayerName,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime.from(scheduleTime, tz.local);

    if (scheduledDate.isBefore(now)) return;

    final androidDetails = AndroidNotificationDetails(
      'prayer_countdown_channel',
      'العد التنازلي للصلاة',
      channelDescription: 'إشعار مستمر يوضح الوقت المتبقي للصلاة التالية',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: nextPrayerTime.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      color: const Color(0xFF0F3D2E),
      styleInformation: BigTextStyleInformation(
        "حان الآن موعد الصلاة السابقة، والعد التنازلي للصلاة التالية بدأ",
        contentTitle: "🕋 اقتربت صلاة $nextPrayerName",
        summaryText: "وَسَارِعُوا",
      ),
    );

    await _notificationsPlugin.zonedSchedule(
      id: 8880,
      title: "🕋 صلاة $nextPrayerName",
      body: "تطبيق وَسَارِعُوا | يرافقك في عبادتك",
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static void _startCountdownUpdate() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      updateOngoingPrayerCountdown();
    });
    updateOngoingPrayerCountdown();
  }

  static Future<void> updateOngoingPrayerCountdown() async {
    final now = DateTime.now();
    final myCoordinates = Coordinates(PrayerService.latitude, PrayerService.longitude);
    final params = CalculationMethod.egyptian.getParameters();
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    
    DateTime? nextTime;
    String prayerName = "";

    final sunrise = prayerTimes.sunrise;
    final duha = sunrise.add(const Duration(minutes: 20));

    if (now.isBefore(prayerTimes.fajr)) { nextTime = prayerTimes.fajr; prayerName = "الفجر"; }
    else if (now.isBefore(sunrise)) { nextTime = sunrise; prayerName = "الشروق"; }
    else if (now.isBefore(duha)) { nextTime = duha; prayerName = "الضحى"; }
    else if (now.isBefore(prayerTimes.dhuhr)) { nextTime = prayerTimes.dhuhr; prayerName = "الظهر"; }
    else if (now.isBefore(prayerTimes.asr)) { nextTime = prayerTimes.asr; prayerName = "العصر"; }
    else if (now.isBefore(prayerTimes.maghrib)) { nextTime = prayerTimes.maghrib; prayerName = "المغرب"; }
    else if (now.isBefore(prayerTimes.isha)) { nextTime = prayerTimes.isha; prayerName = "العشاء"; }
    else {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = PrayerTimes(myCoordinates, DateComponents.from(tomorrow), params);
      nextTime = tomorrowTimes.fajr; prayerName = "الفجر";
    }

    final androidDetails = AndroidNotificationDetails(
      'prayer_countdown_channel',
      'العد التنازلي للصلاة',
      channelDescription: 'إشعار مستمر يوضح الوقت المتبقي للصلاة التالية',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: nextTime?.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      color: const Color(0xFF0F3D2E),
      styleInformation: BigTextStyleInformation(
        "سيتحول التنبيه تلقائياً للصلاة التالية عند الموعد",
        contentTitle: "🕋 اقتربت صلاة $prayerName",
        summaryText: "وَسَارِعُوا",
      ),
    );

    await _notificationsPlugin.show(
      id: 8880,
      title: "🕋 صلاة $prayerName",
      body: "تطبيق وَسَارِعُوا | يرافقك في عبادتك",
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> scheduleIslamicAlarms() async {
    final prayerTimes = PrayerService.getPrayerTimes();
    final nightTimes = PrayerService.getNightTimes();

    final Map<int, String> prayerIds = {
      1001: 'الفجر', 1002: 'الشروق', 1003: 'الضحى', 1004: 'الظهر', 1005: 'العصر', 1006: 'المغرب', 1007: 'العشاء',
    };

    for (var entry in prayerIds.entries) {
      final time = prayerTimes[entry.value];
      if (time != null) {
        String title = "🕋 حان الآن وقت ${entry.value}";
        String body = "أقم صلاتك تنعم بحياتك";
        if (entry.value == 'الشروق') { title = "☀️ وقت الشروق"; body = "انتهى وقت الفجر، واقتربت صلاة الضحى"; }
        else if (entry.value == 'الضحى') { body = "صلاة الأوابين.. تجارة رابحة مع الله"; }
        await scheduleNotification(id: entry.key, title: title, body: body, time: time);
      }
    }

    await scheduleNotification(
      id: 1008, title: "🌌 منتصف الليل", body: "أفضل الصلاة بعد الفريضة صلاة الليل.. هل لك ركعات في جوف الليل؟",
      time: nightTimes['midnightSharia']!,
    );

    // إضافة إشعار "عوضه الله" عند الفجر
    final fajrTime = prayerTimes['الفجر'];
    if (fajrTime != null) {
      await scheduleAddictionTriumphNotification(fajrTime);
    }
  }

  static Future<void> scheduleAddictionTriumphNotification(DateTime fajrTime) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime.from(fajrTime, tz.local);
    if (scheduledDate.isBefore(now)) { scheduledDate = scheduledDate.add(const Duration(days: 1)); }

    await _notificationsPlugin.zonedSchedule(
      id: 7777,
      title: "🤝 عوضه الله: حصاد الأمس",
      body: "هل انتصرت في مجاهدة نفسك بالأمس؟",
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_smart_reminders', 'تذكيرات العادات',
          importance: Importance.max, priority: Priority.high,
          actions: [
            AndroidNotificationAction('addiction_triumph_yes', '✅ نعم، انتصرت', showsUserInterface: true),
            AndroidNotificationAction('addiction_triumph_no', '❌ لا، تعثرت', showsUserInterface: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ================= PERMISSIONS =================
  static Future<void> requestPermissions() async {
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    await Permission.notification.request();
  }

  static Future<void> requestOverlayPermission() async {
    if (await Permission.systemAlertWindow.isDenied) { await Permission.systemAlertWindow.request(); }
  }

  static Future<void> openSystemSettings() async { await openAppSettings(); }

  // ================= MAIN FUNCTION =================
  static Future<void> scheduleHabitReminders(Habit habit) async {
    final baseId = habit.id.hashCode.abs();
    await _scheduleGenericReminders(
      id: baseId,
      name: habit.name,
      reminderType: habit.reminderType,
      reminderHour: habit.reminderHour,
      reminderMinute: habit.reminderMinute,
      flexibleStartHour: habit.flexibleStartHour,
      flexibleEndHour: habit.flexibleEndHour,
      flexibleCount: habit.flexibleCount,
      linkedPrayer: habit.linkedPrayer,
      habitId: habit.id,
      body: _getSmartMessage(habit),
    );
  }

  static Future<void> scheduleWorshipReminders(dynamic item, bool isGood) async {
    final baseId = item.id.hashCode.abs();
    await _scheduleGenericReminders(
      id: baseId,
      name: item.name,
      reminderType: item.reminderType,
      reminderHour: item.reminderHour,
      reminderMinute: item.reminderMinute,
      flexibleStartHour: item.flexibleStartHour,
      flexibleEndHour: item.flexibleEndHour,
      flexibleCount: item.flexibleCount,
      linkedPrayer: item.linkedPrayer,
      body: getSmartWorshipMessage(item.name, isGood),
    );
  }

  static Future<void> _scheduleGenericReminders({
    required int id,
    required String name,
    required ReminderType reminderType,
    int? reminderHour,
    int? reminderMinute,
    int? flexibleStartHour,
    int? flexibleEndHour,
    int? flexibleCount,
    String? linkedPrayer,
    String? habitId,
    required String body,
  }) async {
    for (int i = 0; i < 21; i++) { await _notificationsPlugin.cancel(id: id + i); }

    if (reminderType == ReminderType.fixed) {
      if (reminderHour != null && reminderMinute != null) {
        await _scheduleDailyNotification(id: id, title: "${_getEmoji(name)} $name", body: body, hour: reminderHour, minute: reminderMinute, habitId: habitId);
      }
    } else if (reminderType == ReminderType.prayer) {
      if (linkedPrayer != null && linkedPrayer.isNotEmpty) {
        final prayerTime = PrayerService.getPrayerTime(linkedPrayer);
        if (prayerTime != null) {
          await _scheduleDailyNotification(id: id, title: "🕋 $linkedPrayer • $name", body: body, hour: prayerTime.hour, minute: prayerTime.minute, habitId: habitId);
        }
      }
    } else if (reminderType == ReminderType.flexible) {
      final start = (flexibleStartHour ?? 8) * 60;
      final end = (flexibleEndHour ?? 22) * 60;
      final count = flexibleCount ?? 1;
      int duration = end - start; if (duration <= 0) duration += 1440;
      final step = (duration / count).floor();
      for (int i = 0; i < count; i++) {
        final minutes = start + step * (i + 1);
        final hour = (minutes ~/ 60) % 24;
        final minute = minutes % 60;
        await _scheduleDailyNotification(id: id + i, title: "${_getEmoji(name)} $name", body: "تذكير ذكي: حان وقت $name 💪", hour: hour, minute: minute, habitId: habitId);
      }
    }
  }

  static String _getSmartMessage(Habit habit) {
    if (habit.customReminderMessage != null && habit.customReminderMessage!.isNotEmpty) return habit.customReminderMessage!;
    final name = habit.name.toLowerCase();
    bool isBad = habit.goal == HabitGoal.bad;
    if (isBad) {
      if (name.contains("تدخين")) return "تذكر / تذكري عهدك.. رئتيك تستحق الأفضل 🚫";
      if (name.contains("سهر")) return "النوم مبكراً هو سلاحك للفجر.. لا تضعفه / تضعفيه 🌙";
      return "⚠️ تحذير: هذه العادة تضعف إرادتك.. جاهد / جاهدي نفسك الآن!";
    } else {
      if (name.contains("ماء")) return "رشفة ماء الآن تجدد نشاطك وتطهر جسدك 💧";
      if (name.contains("صلاة") || name.contains("ذكر")) return "اتصالك بالله هو سر توفيقك.. حان الوقت 🕋";
      return "خطوة صغيرة نحو هدفك العظيم.. ابدأ / ابدئي الآن!";
    }
  }

  static String getSmartWorshipMessage(String name, bool isSoulAtPeace) {
    return isSoulAtPeace ? "فرصة للتقرب إلى الله: $name.. لا تضيع / تضيعي الأجر 🌟" : "⚠️ انتبه / انتبهي! جاهد / جاهدي نفسك لترك $name";
  }

  // ================= SCHEDULE =================
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required dynamic time,
    String? habitId,
    bool repeatable = true,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate;
    if (time is DateTime) { scheduledDate = tz.TZDateTime.from(time, tz.local); }
    else if (time is TimeOfDay) { scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute); }
    else { throw ArgumentError('time must be either DateTime or TimeOfDay'); }

    if (scheduledDate.isBefore(now)) { scheduledDate = scheduledDate.add(const Duration(days: 1)); }

    await _notificationsPlugin.zonedSchedule(
      id: id, title: title, body: body, scheduledDate: scheduledDate, payload: habitId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('habit_smart_reminders', 'تذكيرات العادات', importance: Importance.max, priority: Priority.high, showWhen: true),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeatable ? DateTimeComponents.time : null,
    );
  }

  static String _getEmoji(String name) {
    if (name.contains("ماء")) return "💧";
    if (name.contains("صلاة")) return "🕌";
    return "🎯";
  }

  static Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? habitId,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) { scheduledDate = scheduledDate.add(const Duration(days: 1)); }

    List<AndroidNotificationAction>? actions;
    if (habitId != null) {
      final habit = HabitService.getHabitById(habitId);
      if (habit != null) {
        if (habit.type == HabitType.fixed) {
          actions = [const AndroidNotificationAction('mark_done', '✅ تم الإنجاز', showsUserInterface: true, cancelNotification: true)];
        } else {
          actions = [const AndroidNotificationAction('input_value', '📝 إدخال القيمة', allowGeneratedReplies: true, inputs: [AndroidNotificationActionInput(label: 'أدخل القيمة')])];
        }
      }
    }

    await _notificationsPlugin.zonedSchedule(
      id: id, title: title, body: body, scheduledDate: scheduledDate, payload: habitId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('habit_smart_reminders', 'تذكيرات العادات', importance: Importance.max, priority: Priority.high, showWhen: true, actions: actions),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleTestNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    await _notificationsPlugin.zonedSchedule(
      id: 999, title: "اختبار", body: "وصل الإشعار ✅", scheduledDate: now.add(const Duration(seconds: 5)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('habit_smart_reminders', 'تذكيرات ذكية', importance: Importance.max, priority: Priority.high, showWhen: true),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> setSystemAlarm({required int hour, required int minutes, bool isTimer = false, int? durationMinutes}) async {
    try {
      await _alarmChannel.invokeMethod('checkConnection');
      await _alarmChannel.invokeMethod('setSystemAlarm', {'hour': hour, 'minutes': minutes, 'isTimer': isTimer, 'durationMinutes': durationMinutes});
    } on PlatformException catch (e) { debugPrint("Failed to set system alarm: ${e.message}"); }
  }

  static Future<void> scheduleAlarm({required int id, required String title, required String body, required DateTime time, int snoozeDuration = 10, String? customSoundPath}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime.from(time, tz.local);
    if (scheduledDate.isBefore(now)) { scheduledDate = scheduledDate.add(const Duration(days: 1)); }
    AndroidNotificationSound? alarmSound;
    if (customSoundPath != null && customSoundPath.isNotEmpty) {
      alarmSound = UriAndroidNotificationSound(customSoundPath.startsWith('http') || customSoundPath.startsWith('content://') || customSoundPath.startsWith('file://') ? customSoundPath : 'file://$customSoundPath');
    }
    await _notificationsPlugin.zonedSchedule(
      id: id, title: title, body: body, scheduledDate: scheduledDate, payload: "$id|$title|$body|$snoozeDuration|$customSoundPath",
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('smart_alarm_channel', 'منبه الاستيقاظ الذكي', importance: Importance.max, priority: Priority.max, fullScreenIntent: true, category: AndroidNotificationCategory.alarm, audioAttributesUsage: AudioAttributesUsage.alarm, playSound: true, sound: alarmSound, enableVibration: true, ongoing: true, autoCancel: false, actions: [AndroidNotificationAction('snooze', '🔔 غفوة ($snoozeDuration دقائق)', showsUserInterface: true, cancelNotification: true), const AndroidNotificationAction('stop_alarm', '🛑 إيقاف', showsUserInterface: true, cancelNotification: true)]),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, sound: customSoundPath, interruptionLevel: InterruptionLevel.critical),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNotification(int id) async { await _notificationsPlugin.cancel(id: id); _activeNotifications.remove(id); }

  static Future<void> cancelAllNapNotifications() async {
    for (var id in _activeNotifications.keys.toList()) { if (id >= 1000 && id < 2000) await cancelNotification(id); }
  }

  static Future<void> schedulePersonalReminder({required String id, required String title, required String body, required ReminderType reminderType, int? hour, int? minute, String? prayer, bool repeatable = true, int? flexibleStartHour, int? flexibleEndHour, int? flexibleCount}) async {
    final baseId = id.hashCode.abs();
    for (int i = 0; i < 21; i++) { await _notificationsPlugin.cancel(id: baseId + i); }

    if (reminderType == ReminderType.fixed) {
      if (hour != null && minute != null) {
        if (repeatable) { await _scheduleDailyNotification(id: baseId, title: title, body: body, hour: hour, minute: minute); }
        else { final now = DateTime.now(); DateTime sc = DateTime(now.year, now.month, now.day, hour, minute); if (sc.isBefore(now)) sc = sc.add(const Duration(days: 1)); await scheduleNotification(id: baseId, title: title, body: body, time: sc); }
      }
    } else if (reminderType == ReminderType.prayer) {
      if (prayer != null) {
        final pTime = PrayerService.getPrayerTime(prayer);
        if (pTime != null) {
          if (repeatable) { await _scheduleDailyNotification(id: baseId, title: "🕋 $prayer • $title", body: body, hour: pTime.hour, minute: pTime.minute); }
          else { await scheduleNotification(id: baseId, title: "🕋 $prayer • $title", body: body, time: pTime); }
        }
      }
    } else if (reminderType == ReminderType.flexible) {
      final start = (flexibleStartHour ?? 8) * 60;
      final end = (flexibleEndHour ?? 22) * 60;
      final count = flexibleCount ?? 1;
      int duration = end - start; if (duration <= 0) duration += 1440;
      final step = (duration / count).floor();
      for (int i = 0; i < count; i++) {
        final minutes = start + step * (i + 1);
        final h = (minutes ~/ 60) % 24;
        final m = minutes % 60;
        await _scheduleDailyNotification(id: baseId + i, title: title, body: "تذكير موزّع: $body", hour: h, minute: m);
      }
    }
  }

  static bool hasActiveNotification(int id) {
    if (_activeNotifications.containsKey(id)) { final sc = _activeNotifications[id]; if (sc != null && sc.isAfter(DateTime.now())) return true; else { _activeNotifications.remove(id); return false; } }
    return false;
  }
}
