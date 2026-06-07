import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'models/usage_models.dart';
import 'services/usage_service.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/quick_link_navigator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/modern_dialog.dart';

class UsageStatsScreen extends StatefulWidget {
  const UsageStatsScreen({super.key});

  @override
  State<UsageStatsScreen> createState() => _UsageStatsScreenState();
}

class _UsageStatsScreenState extends State<UsageStatsScreen> {
  DailyUsageSummary? _todaySummary;
  List<DailyUsageSummary> _weeklyHistory = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  double _dailyGoal = 4.0;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    bool perm = await UsageService.checkPermission();
    setState(() => _hasPermission = perm);
    if (perm) {
      _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await UsageService.getTodayUsage();
    final history = UsageService.getWeeklyHistory();
    final goal = UsageService.getUserDailyGoal();
    setState(() {
      _todaySummary = summary;
      _weeklyHistory = history;
      _dailyGoal = goal;
      _isLoading = false;
    });
  }

  void _showSetGoalDialog() async {
    final res = await ModernDialog.showInput(
      context: context,
      title: 'تحديد هدف الاستخدام',
      hint: 'أدخل عدد الساعات (مثلاً: 3.5)',
      initialValue: _dailyGoal.toString(),
    );
    if (res != null) {
      double? newGoal = double.tryParse(res);
      if (newGoal != null && newGoal > 0) {
        await UsageService.setUserDailyGoal(newGoal);
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('تتبع استخدام الهاتف 📱'),
        actions: [
          IconButton(icon: const Icon(Icons.track_changes, color: Color(0xFFC8A24A)), onPressed: _showSetGoalDialog, tooltip: 'ضبط الهدف'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : !_hasPermission 
          ? _buildPermissionRequest()
          : _buildDashboard(isDark),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text('تحتاج للصلاحية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'من أجل تتبع وقت الشاشة وتقديم تحليلات دقيقة، نحتاج لصلاحية "الوصول لبيانات الاستخدام" من إعدادات النظام.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await UsageService.grantPermission();
                _checkPermissionAndLoad();
              },
              child: const Text('منح الصلاحية الآن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    if (_todaySummary == null) return const Center(child: Text('لا توجد بيانات'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const QuickLinkNavigator(currentPageId: 'usage'),
        _buildScreenTimeCard(isDark),
        const SizedBox(height: 24),
        _buildGoalProgressCard(isDark),
        const SizedBox(height: 24),
        _buildDisciplineScoreRow(),
        const SizedBox(height: 24),
        _buildWeeklyChart(isDark),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(isDark),
        const SizedBox(height: 24),
        const Text('أكثر التطبيقات استهلاكاً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ..._todaySummary!.appUsages.take(10).map((app) => _buildAppRow(app, isDark)),
      ],
    );
  }

  Widget _buildScreenTimeCard(bool isDark) {
    final hours = _todaySummary!.totalScreenTime.inHours;
    final minutes = _todaySummary!.totalScreenTime.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F3D2E), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text('إجمالي وقت الشاشة اليوم', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$hours', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              const Text(' ساعة ', style: TextStyle(color: Colors.white, fontSize: 16)),
              Text('$minutes', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              const Text(' دقيقة', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(UsageService.generateInsight(_todaySummary!, null), 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(bool isDark) {
    double currentHours = _todaySummary!.totalScreenTime.inMinutes / 60.0;
    double percent = (currentHours / _dailyGoal).clamp(0.0, 1.0);
    bool exceeded = currentHours > _dailyGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الالتزام بالهدف اليومي', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(percent * 100).toInt()}%', style: TextStyle(color: exceeded ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.grey.withOpacity(0.1),
              color: exceeded ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exceeded 
              ? '⚠️ لقد تجاوزت هدفك المحدد بـ ${(currentHours - _dailyGoal).toStringAsFixed(1)} ساعة' 
              : '✅ متبقي لك ${( _dailyGoal - currentHours).toStringAsFixed(1)} ساعة للوصول للحد الأقصى',
            style: TextStyle(fontSize: 11, color: exceeded ? Colors.red : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool isDark) {
    if (_weeklyHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('استهلاك الأسبوع (بالساعات)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= _weeklyHistory.length) return const SizedBox();
                        return Text(intl.DateFormat('E', 'ar').format(_weeklyHistory[idx].date), style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _weeklyHistory.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalScreenTime.inMinutes / 60.0,
                        color: e.value.totalScreenTime.inMinutes / 60.0 > _dailyGoal ? Colors.red : const Color(0xFFC8A24A),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineScoreRow() {
    int score = UsageService.calculateDisciplineScore(_todaySummary!);
    return Row(
      children: [
        Expanded(child: _buildSmallStatCard('مؤشر الانضباط', '$score%', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatCard('مرات الفتح', '${_todaySummary!.unlockCount}', Colors.orange)),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('توزيع الاستخدام', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ..._todaySummary!.categoryBreakdown.entries.where((e) => e.value.inMinutes > 0).map((e) {
            double percent = e.value.inMilliseconds / _todaySummary!.totalScreenTime.inMilliseconds;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getCategoryName(e.key), style: const TextStyle(fontSize: 12)),
                      Text('${e.value.inMinutes} دقيقة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    color: _getCategoryColor(e.key),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAppRow(AppUsageInfo app, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.android, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.appName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_getCategoryName(app.category), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${app.usageDuration.inMinutes} دقيقة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Text('وقت الاستخدام', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryName(AppCategory cat) {
    switch(cat) {
      case AppCategory.social: return 'تواصل اجتماعي';
      case AppCategory.entertainment: return 'ترفيه';
      case AppCategory.productivity: return 'إنتاجية';
      case AppCategory.study: return 'دراسة';
      case AppCategory.worship: return 'عبادة';
      case AppCategory.education: return 'تعليم';
      case AppCategory.health: return 'صحة';
      case AppCategory.games: return 'ألعاب';
      default: return 'أخرى';
    }
  }

  Color _getCategoryColor(AppCategory cat) {
    switch(cat) {
      case AppCategory.social: return Colors.red;
      case AppCategory.entertainment: return Colors.orange;
      case AppCategory.productivity: return Colors.blue;
      case AppCategory.worship: return Colors.green;
      default: return Colors.grey;
    }
  }
}

