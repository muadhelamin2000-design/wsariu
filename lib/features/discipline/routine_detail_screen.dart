import 'package:flutter/material.dart';
import 'models/routine_model.dart';
import 'services/routine_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import 'package:intl/intl.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;
  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late Routine _currentRoutine;

  @override
  void initState() {
    super.initState();
    _currentRoutine = widget.routine;
  }

  void _refreshData() {
    final all = RoutineService.getRoutines();
    setState(() {
      _currentRoutine = all.firstWhere((r) => r.id == _currentRoutine.id);
    });
  }

  int _calculateChallengeStreak() {
    if (_currentRoutine.challengeStartDate == null) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    DateTime start = _currentRoutine.challengeStartDate!;
    DateTime startDateOnly = DateTime(start.year, start.month, start.day);

    while (!checkDate.isBefore(startDateOnly)) {
      String dateKey = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (_currentRoutine.executionLog[dateKey] ?? false) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(_currentRoutine.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildChallengeSection(),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildHistoryStats(),
            const SizedBox(height: 32),
            _buildDeleteButton(),
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
        color: isDark ? AppTheme.darkCard : Colors.white,
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
                  Text('التزم بالروتين لجمع الدروع', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              if (_currentRoutine.challengeStartDate == null)
                ElevatedButton(
                  onPressed: () async {
                    await RoutineService.startChallenge(_currentRoutine.id);
                    _refreshData();
                    if (mounted) {
                      ModernDialog.show(
                        context: context, 
                        title: 'بدأ التحدي! 🚀', 
                        content: const Text('بالتوفيق في رحلة الانضباط بالروتين اليومي.')
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
          if (_currentRoutine.challengeStartDate != null) ...[
            const SizedBox(height: 20),
            _buildShieldsProgress(streak),
          ],
        ],
      ),
    );
  }

  Widget _buildShieldsProgress(int currentStreak) {
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
                  const Text('🛡️', style: TextStyle(fontSize: 22)),
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

  Widget _buildInfoCard() {
    int doneCount = _currentRoutine.executionLog.values.where((v) => v).length;
    DateTime start = _currentRoutine.createdAt;
    int daysSinceStart = DateTime.now().difference(start).inDays + 1;
    double rate = daysSinceStart > 0 ? (doneCount / daysSinceStart) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeService.isDarkMode ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('مرات الإنجاز', '$doneCount', Icons.check_circle_outline, Colors.green),
              _statItem('نسبة النجاح', '${rate.toInt()}%', Icons.analytics_outlined, Colors.blue),
            ],
          ),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('تاريخ البدء', DateFormat('yyyy/MM/dd').format(start), Icons.calendar_month_outlined, Colors.grey),
              _statItem('الأهمية', _currentRoutine.type == RoutineType.major ? 'أساسي' : 'ثانوي', Icons.priority_high, const Color(0xFFC8A24A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showBackfillDialog,
            icon: const Icon(Icons.history),
            label: const Text('استدراك فائت'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showResetConfirmDialog,
            icon: const Icon(Icons.refresh),
            label: const Text('تصفير السجل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showBackfillDialog() {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));

    ModernDialog.show(
      context: context,
      title: 'استدراك يوم سابق',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل قمت بتنفيذ هذا الروتين في يوم سابق؟', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("التاريخ: ${DateFormat('yyyy/MM/dd').format(selectedDate)}"),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: _currentRoutine.createdAt,
                  lastDate: DateTime.now(),
                );
                if (p != null) setDialogState(() => selectedDate = p);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            await RoutineService.updateRoutineLog(_currentRoutine.id, selectedDate, true);
            if (mounted) {
              Navigator.pop(context);
              _refreshData();
            }
          },
          child: const Text('تم التنفيذ'),
        ),
      ],
    );
  }

  void _showResetConfirmDialog() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير السجل',
      message: 'سيتم مسح كافة سجلات الإنجاز لهذا الروتين. هل تود الاستمرار؟',
      isDestructive: true,
    );
    if (result == true) {
      await RoutineService.resetRoutineCompletion(_currentRoutine.id);
      _refreshData();
    }
  }

  Widget _buildHistoryStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(_currentRoutine.colorValue).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(_currentRoutine.colorValue).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('نصيحة الانضباط 💡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            _currentRoutine.type == RoutineType.major 
              ? "هذا الروتين أساسي في يومك. الالتزام به يمنحك شعوراً بالإنجاز والسيطرة على وقتك."
              : "الروتينات الثانوية تساعد في تحسين جودة الحياة. لا تضغط على نفسك ولكن حاول الاستمرار.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return TextButton.icon(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: const Text('حذف الروتين نهائياً', style: TextStyle(color: Colors.red)),
      onPressed: () async {
        final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'هل أنت متأكد من حذف هذا الروتين؟', isDestructive: true);
        if (confirm == true) {
          await RoutineService.deleteRoutine(_currentRoutine.id);
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }
}
