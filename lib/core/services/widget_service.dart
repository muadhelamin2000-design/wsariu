import 'package:home_widget/home_widget.dart';
import '../../features/dashboard/services/prayer_service.dart';
import '../../features/discipline/services/habit_service.dart';
import '../../features/discipline/services/routine_service.dart';
import '../../features/worship/services/worship_service.dart';
import '../../features/worship/models/worship_model.dart';
import 'dart:async';

class WidgetService {
  static const String _groupId = 'group.wasariu.widget';
  static const String _androidWidgetName = 'WasariuWidgetProvider';

  static Future<void> updateAllWidgets() async {
    try {
      final nextPrayer = PrayerService.getNextPrayerName();
      final countdown = PrayerService.getNextPrayerCountdown();
      
      // Habits stats
      final habits = HabitService.getHabits();
      final totalHabits = habits.length;
      final completedHabits = habits.where((h) => h.isCompletedToday()).length;
      
      // Routine stats
      final schedule = RoutineService.getTodaysSchedule();
      final totalRoutine = schedule.length;
      final completedRoutine = schedule.where((s) => (s['routine'] as dynamic).isDoneOn(DateTime.now())).length;
      
      // Worship status
      final worshipItems = WorshipService.getItems();
      final today = PrayerService.getIslamicDayDate();
      double netScore = 0;
      for (var item in worshipItems) {
        netScore += item.calculatePoints(today);
      }

      await HomeWidget.saveWidgetData<String>('next_prayer', nextPrayer);
      await HomeWidget.saveWidgetData<String>('prayer_countdown', countdown);
      await HomeWidget.saveWidgetData<String>('habits_progress', '$completedHabits/$totalHabits');
      await HomeWidget.saveWidgetData<String>('routine_progress', '$completedRoutine/$totalRoutine');
      await HomeWidget.saveWidgetData<int>('net_score', netScore.toInt());
      
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
