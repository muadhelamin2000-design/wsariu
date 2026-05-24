import 'package:flutter/material.dart';
import 'models/habit_model.dart';
import 'services/habit_service.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit _currentHabit;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
  }

  void _refreshHabit() {
    final all = HabitService.getHabits();
    setState(() {
      _currentHabit = all.firstWhere((h) => h.id == _currentHabit.id);
    });
  }

  List<DateTime> _getCurrentWeekDates() {
    DateTime now = DateTime.now();
    int currentFlutterWeekday = now.weekday;
    int daysToSubtract;
    if (currentFlutterWeekday == 6) {
      daysToSubtract = 0;
    } else if (currentFlutterWeekday == 7) {
      daysToSubtract = 1;
    } else {
      daysToSubtract = currentFlutterWeekday + 1;
    }
    DateTime saturday = now.subtract(Duration(days: daysToSubtract));
    return List.generate(7, (i) => saturday.add(Duration(days: i)));
  }

  int _calculateChallengeStreak() {
    if (_currentHabit.challengeStartDate == null) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    DateTime start = _currentHabit.challengeStartDate!;
    DateTime startDateOnly = DateTime(start.year, start.month, start.day);

    while (!checkDate.isBefore(startDateOnly)) {
      String dateKey = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (_currentHabit.completionLog.containsKey(dateKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // إذا فوت يوم بعد تاريخ البدء ينكسر الاستريك
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentHabit.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChallengeSection(),
            const SizedBox(height: 20),
            _buildQuickStats(context),
            const SizedBox(height: 20),
            _buildReminderInfo(context),
            const SizedBox(height: 24),
            const Text('أداء العادة هذا الأسبوع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDynamicChart(),
            const SizedBox(height: 24),
            _buildMotivationSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSection() {
    final streak = _calculateChallengeStreak();
    final isDark = ThemeService.isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نظام تحدي الدروع 🛡️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('ابدأ التحدي لجمع الدروع الخاصة بالعادة', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              if (_currentHabit.challengeStartDate == null)
                ElevatedButton(
                  onPressed: () async {
                    await HabitService.startChallenge(_currentHabit.id);
                    _refreshHabit();
                    if (mounted) {
                      ModernDialog.show(
                        context: context, 
                        title: 'بدأ التحدي! 🚀', 
                        content: const Text('بالتوفيق في رحلة الالتزام. حافظ على الاستمرار لفتح الدروع.')
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  child: const Text('بداية التحدي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('🔥 $streak يوم', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
            ],
          ),
          if (_currentHabit.challengeStartDate != null) ...[
            const SizedBox(height: 20),
            _buildShieldsProgress(streak),
          ],
        ],
      ),
    );
  }

  Widget _buildShieldsProgress(int currentStreak) {
    // الأيام المستهدفة بناءً على دراسات تكوين العادات
    final List<Map<String, dynamic>> levels = [
      {'days': 3, 'name': 'درع البداية', 'color': Colors.brown.shade400},
      {'days': 7, 'name': 'درع الثبات', 'color': Colors.blueGrey.shade400},
      {'days': 21, 'name': 'درع العادة', 'color': Colors.blue.shade400},
      {'days': 40, 'name': 'درع الانضباط', 'color': Colors.teal.shade400},
      {'days': 66, 'name': 'درع التلقائية', 'color': Colors.amber.shade600},
      {'days': 90, 'name': 'درع أسلوب الحياة', 'color': Colors.deepOrange.shade600},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final bool isUnlocked = currentStreak >= (level['days'] as int);
          final color = level['color'] as Color;

          return Opacity(
            opacity: isUnlocked ? 1.0 : 0.3,
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: isUnlocked ? Border.all(color: color, width: 2) : Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛡️', style: TextStyle(fontSize: isUnlocked ? 28 : 22)),
                  const SizedBox(height: 4),
                  Text('${level['days']} يوم', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUnlocked ? color : Colors.grey)),
                  Text(level['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 8), maxLines: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E2A38) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoTile('Streak الكلي', '${_currentHabit.currentStreak} أيام',
                  Icons.local_fire_department, Colors.orange, textColor),
              _infoTile('نسبة الالتزام', '${_currentHabit.commitmentRate.toInt()}%',
                  Icons.pie_chart, Colors.blue, textColor),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoTile('نوع العادة',
                  _currentHabit.type == HabitType.fixed ? 'ثابتة' : 'متغيرة',
                  Icons.settings, Colors.grey, textColor),
              _infoTile('نقاط الوحدة', _currentHabit.basePoints.toString(), Icons.stars,
                  const Color(0xFFC8A24A), textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDynamicChart() {
    final isDark = ThemeService.isDarkMode;
    List<DateTime> weekDates = _getCurrentWeekDates();
    List<double> points = weekDates.map((d) => _currentHabit.calculatePoints(d).abs()).toList();
    
    double maxPoints = points.isEmpty ? 1 : points.reduce((a, b) => a > b ? a : b);
    if (maxPoints == 0) maxPoints = 1;

    final List<String> days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          double val = points[index];
          double heightRatio = (val / maxPoints).clamp(0.05, 1.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (val > 0)
                Text('${val.toInt()}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 120 * heightRatio,
                decoration: BoxDecoration(
                  color: val > 0 
                      ? (_currentHabit.goal == HabitGoal.good ? Colors.green.shade400 : Colors.red.shade400)
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(days[index], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReminderInfo(BuildContext context) {
    bool isFixed = _currentHabit.reminderType == ReminderType.fixed;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8A24A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFFC8A24A), size: 18),
              const SizedBox(width: 8),
              Text(isFixed ? 'نظام التذكير الثابت' : 'نظام التذكير المرن', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
            ],
          ),
          const SizedBox(height: 12),
          if (isFixed)
            Text('يتم تذكيرك يومياً في تمام الساعة: ${_currentHabit.reminderTime?.format(context) ?? "غير محدد"}',
              style: const TextStyle(fontSize: 13))
          else ...[
            Text('الفترة: من ${_currentHabit.flexibleStartTime?.format(context)} إلى ${_currentHabit.flexibleEndTime?.format(context)}',
              style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('عدد التذكيرات: ${_currentHabit.flexibleCount} مرات موزعة بالتساوي',
              style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildMotivationSection(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final accentColor = isDark ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(
            _currentHabit.motivationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor),
          ),
        ],
      ),
    );
  }
}
