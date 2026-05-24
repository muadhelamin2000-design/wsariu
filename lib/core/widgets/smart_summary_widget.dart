import 'package:flutter/material.dart';
import '../../features/dashboard/services/prayer_service.dart';
import '../../features/discipline/services/habit_service.dart';
import '../../features/discipline/services/routine_service.dart';
import '../../features/worship/services/worship_service.dart';
import '../services/theme_service.dart';
import '../../features/discipline/models/habit_model.dart';

class SmartSummaryWidget extends StatelessWidget {
  final Map<String, dynamic>? report;
  final bool isDark;

  const SmartSummaryWidget({super.key, this.report, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final habits = HabitService.getHabits();
    final goodHabits = habits.where((h) => h.goal == HabitGoal.good).toList();
    final badHabits = habits.where((h) => h.goal == HabitGoal.bad).toList();
    
    // صافي العادات: المكتملة الحسنة - المرتكبة السيئة
    final completedGood = goodHabits.where((h) => h.isCompletedToday()).length;
    final committedBad = badHabits.where((h) => h.completionLog.containsKey(PrayerService.getIslamicDayKey())).length;
    final habitsNet = completedGood - committedBad;

    final schedule = RoutineService.getTodaysSchedule();
    final completedRoutine = schedule.where((s) => s['routine'].isDoneOn(DateTime.now())).length;
    
    final today = PrayerService.getIslamicDayDate();
    final worshipItems = WorshipService.getItems();
    double worshipPoints = 0;
    for (var w in worshipItems) {
       worshipPoints += w.calculatePoints(today);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('صافي العادات', '$habitsNet', Icons.stars_rounded, Colors.green),
              _buildStatItem('الروتين اليومي', '$completedRoutine/${schedule.length}', Icons.repeat_rounded, Colors.blue),
              _buildStatItem('صافي العبادات', '${worshipPoints.toInt()}', Icons.account_balance_wallet_rounded, Colors.amber),
            ],
          ),
          if (report?['insight'] != null) ...[
            const Divider(height: 32),
            Text(
              report!['insight'],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
