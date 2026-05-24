import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/worship_model.dart';
import 'services/worship_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/badge_service.dart';

class WorshipItemDetailScreen extends StatefulWidget {
  final WorshipItem item;
  final bool isGood;

  const WorshipItemDetailScreen({super.key, required this.item, required this.isGood});

  @override
  State<WorshipItemDetailScreen> createState() => _WorshipItemDetailScreenState();
}

class _WorshipItemDetailScreenState extends State<WorshipItemDetailScreen> {
  late WorshipItem _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  void _refreshData() {
    final updated = WorshipService.getItems().firstWhere((i) => i.id == widget.item.id);
    setState(() {
      _currentItem = updated;
    });
  }

  int _calculateChallengeStreak() {
    if (_currentItem.challengeStartDate == null) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    DateTime start = _currentItem.challengeStartDate!;
    DateTime startDateOnly = DateTime(start.year, start.month, start.day);

    while (!checkDate.isBefore(startDateOnly)) {
      String dateKey = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (_currentItem.completionLog.containsKey(dateKey)) {
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
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF7F5EF),
      appBar: AppBar(title: Text(_currentItem.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildChallengeSection(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildCumulativeChart(),
            const SizedBox(height: 24),
            _buildInsightCard(),
            const SizedBox(height: 32),
            _buildDeleteButton(context),
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
                  Text('ابدأ التحدي لجمع الدروع الخاصة بهذا العمل', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              if (_currentItem.challengeStartDate == null)
                ElevatedButton(
                  onPressed: () async {
                    await WorshipService.startChallenge(_currentItem.id);
                    _refreshData();
                    if (mounted) {
                      ModernDialog.show(
                        context: context, 
                        title: 'بدأ التحدي! 🚀', 
                        content: const Text('بالتوفيق في رحلة الالتزام. حافظ على الاستمرار لفتح الدروع الإيمانية.')
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
          if (_currentItem.challengeStartDate != null) ...[
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

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeService.isDarkMode ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('الالتزام العام', '${_currentItem.commitmentRate.toInt()}%', Icons.pie_chart, Colors.blue),
              _statItem('أطول Streak', '${_currentItem.currentStreak} يوم', Icons.local_fire_department, Colors.orange),
            ],
          ),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('النوع', _currentItem.type == WorshipItemType.fixed ? 'ثابت' : 'متغير', Icons.category_outlined, Colors.grey),
              _statItem('النقاط', '${_currentItem.basePoints.toInt()}', Icons.stars, const Color(0xFFC8A24A)),
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
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
            label: const Text('استدراك ما فات'),
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
            label: const Text('تصفير التقدم'),
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
    final controller = TextEditingController(text: _currentItem.type == WorshipItemType.fixed ? '1' : '');

    ModernDialog.show(
      context: context,
      title: 'استدراك يوم سابق',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("التاريخ: ${DateFormat('yyyy/MM/dd').format(selectedDate)}"),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: _currentItem.createdAt,
                  lastDate: DateTime.now(),
                );
                if (p != null) setDialogState(() => selectedDate = p);
              },
            ),
            if (_currentItem.type == WorshipItemType.variable)
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'القيمة (${_currentItem.unitName})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          onPressed: () async {
            double val = double.tryParse(controller.text) ?? 1.0;
            await WorshipService.updateItemValue(_currentItem.id, selectedDate, val, increment: false);
            if (mounted) {
              Navigator.pop(context);
              _refreshData();
            }
          },
          child: const Text('حفظ الاستدراك'),
        ),
      ],
    );
  }

  void _showResetConfirmDialog() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير البيانات',
      message: 'هل أنت متأكد من مسح كافة سجلات الإنجاز لهذا العمل؟ لا يمكن التراجع عن هذا الفعل.',
      confirmLabel: 'تصفير الآن',
      isDestructive: true,
    );
    if (result == true) {
      final newItem = _currentItem.copyWith(completionLog: {});
      await WorshipService.saveItem(newItem);
      if (mounted) _refreshData();
    }
  }

  Widget _buildCumulativeChart() {
    DateTime start = DateTime(_currentItem.createdAt.year, _currentItem.createdAt.month, _currentItem.createdAt.day);
    DateTime end = DateTime.now();
    int totalDays = end.difference(start).inDays + 1;
    
    int daysToShow = totalDays > 30 ? 30 : totalDays;
    List<DateTime> dates = List.generate(daysToShow, (i) => end.subtract(Duration(days: daysToShow - 1 - i)));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeService.isDarkMode ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليل الأداء التراكمي (تاريخي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dates.map((date) {
                  double val = _currentItem.calculatePoints(date).abs();
                  double heightFactor = (val / (_currentItem.basePoints * 5)).clamp(0.05, 1.0);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text('${val.toInt()}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          width: 12,
                          height: 100 * heightFactor,
                          decoration: BoxDecoration(
                            color: val > 0 ? Color(_currentItem.colorValue) : Colors.grey.shade100.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(DateFormat('d MMM', 'ar').format(date), style: const TextStyle(fontSize: 8, color: Colors.grey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'منذ: ${DateFormat('d MMMM yyyy', 'ar').format(start)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    String message = widget.isGood 
      ? "استمر على هذا النهج، رصيدك الإيماني في ازدياد. كل خطوة تقربك من الله."
      : "المجاهدة صعبة ولكن أجرها عظيم. ابدأ صفحة جديدة الآن.";
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(_currentItem.colorValue).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(_currentItem.colorValue).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(_currentItem.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Color(_currentItem.colorValue),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: const Text('حذف العمل نهائياً', style: TextStyle(color: Colors.red)),
      onPressed: () => _confirmDelete(context),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد؟ سيتم مسح سجلاتك التاريخية لهذا العمل نهائياً.',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await WorshipService.deleteItem(_currentItem.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
