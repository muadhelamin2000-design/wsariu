import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/addiction_model.dart';
import 'models/zad_model.dart';
import 'services/addiction_service.dart';
import 'emergency_mode_screen.dart';
import '../discipline/services/habit_service.dart';
import 'services/worship_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';
import '../dashboard/services/screen_time_service.dart';
import '../../core/widgets/self_dialogue_widget.dart';
import '../../core/widgets/modern_link_picker.dart';

// Fixed file structure
import '../../core/mixins/help_feature_mixin.dart';

class AddictionScreen extends StatefulWidget {
  const AddictionScreen({super.key});

  @override
  State<AddictionScreen> createState() => _AddictionScreenState();
}

class _AddictionScreenState extends State<AddictionScreen> with HelpFeatureMixin {
  List<AddictionHabit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() {
    setState(() {
      _habits = AddictionService.getHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عوضه الله'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح عوضه الله', 
            description: 'هذا القسم يدعمكَ/يدعمكِ في ترك العادات الضارة:\n'
            '- تتبع أيام تعافيكَ/تعافيكِ ومجاهدتكَ/مجاهدتكِ.\n'
            '- سجل/سجلي المواقف التي تثير رغباتك لتتجنبها/لتتجنبيها.\n'
            '- استخدم/استخدمي المتصفح الآمن في لحظات الضعف.\n'
            '- تذكر/تذكري أن من ترك شيئاً لله عوضه الله خيراً منه.'
          ),
          TextButton(
            onPressed: _showAddHabitDialog,
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SelfDialogueWidget(),
          QuickLinkNavigator(currentPageId: 'addiction'),
          // البروز الخارجي للحديث الشريف
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ThemeService.isDarkMode 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFFDFCF0), Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text(
                  'قَالَ رَسُولُ اللهِ ﷺ:',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '«مَنْ تَرَكَ شَيْئاً للهِ عَوَّضَهُ اللهُ خَيْراً مِنْهُ»',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'رواه أحمد وغيره عن أبي قتادة وأبي الدهماء',
                  style: TextStyle(fontSize: 9, color: Colors.grey.withOpacity(0.8), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Expanded(
            child: _habits.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) => _buildHabitGridItem(_habits[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: AppTheme.primaryGreen.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('مَنْ تَرَكَ شَيْئاً للهِ عَوَّضَهُ اللهُ خَيْراً مِنْهُ', 
            style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentGold)
          ),
          const SizedBox(height: 8),
          const Text('لا يوجد تحديات حالية..', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text('ابدأ / ابدئي الآن تحدي الحرية واستعن / استعيني بالله على ترك ما يضرك / يضركِ.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitGridItem(AddictionHabit habit) {
    double progress = habit.currentStreak / 90.0;
    if (progress > 1.0) progress = 1.0;
    final isDark = ThemeService.isDarkMode;

    return Hero(
      tag: 'addiction_${habit.id}',
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddictionDetailScreen(habit: habit))).then((_) => _loadHabits()),
        onLongPress: () => _confirmDelete(habit),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A38) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.1), blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.shield, color: AppTheme.primaryGreen, size: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Text(
                    habit.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
                    textAlign: TextAlign.center, 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ),
              Text('${habit.currentStreak} يوم صمود', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                color: AppTheme.primaryGreen,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddHabitDialog() {
    final titleController = TextEditingController();
    final isDark = ThemeService.isDarkMode;

    ModernDialog.show(
      context: context,
      title: 'إضافة تحدي',
      accentColor: AppTheme.primaryGreen,
      content: TextField(
        controller: titleController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: const InputDecoration(
          labelText: 'ما هي العادة التي تريد كسرها؟',
          hintText: 'مثال: التدخين، إضاعة الوقت...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); }, child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          onPressed: () async {
            if (titleController.text.isNotEmpty) {
              final String userId = UserService.currentUser?.id ?? 'default_user';
              final aiContent = AddictionService.generateAIContent(titleController.text);
              final habit = AddictionHabit(
                id: const Uuid().v4(),
                userId: userId,
                title: titleController.text,
                type: AddictionType.absolute,
                startDate: DateTime.now(),
                harms: aiContent['harms'] ?? [],
                benefits: aiContent['benefits'] ?? [],
                alternatives: aiContent['alternatives'] ?? [],
              );
              await AddictionService.saveHabit(habit);
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                _loadHabits();
              }
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  void _confirmDelete(AddictionHabit habit) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف التحدي؟',
      message: 'سيتم حذف كافة البيانات الخاصة بهذا التحدي.',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await AddictionService.deleteHabit(habit.id);
      _loadHabits();
    }
  }
}

class AddictionDetailScreen extends StatefulWidget {
  final AddictionHabit habit;
  const AddictionDetailScreen({super.key, required this.habit});

  @override
  State<AddictionDetailScreen> createState() => _AddictionDetailScreenState();
}

class _AddictionDetailScreenState extends State<AddictionDetailScreen> {
  late AddictionHabit _currentHabit;
  Timer? _urgeTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
  }

  @override
  void dispose() {
    _urgeTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    final updated = AddictionService.getHabits().where((h) => h.id == _currentHabit.id).firstOrNull;
    if (updated != null) setState(() => _currentHabit = updated);
  }

  bool _isItemCompleted(ZadItem item, DateTime date) {
    if (item.type == ZadItemType.internal) {
      return item.isCompletedOn(date);
    } else if (item.type == ZadItemType.habit) {
      final h = HabitService.getHabits().where((it) => it.id == item.linkedId).firstOrNull;
      if (h == null) return false;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return (h.completionLog[key] ?? 0) > 0;
    } else if (item.type == ZadItemType.worship) {
      final w = WorshipService.getItems().where((it) => it.id == item.linkedId).firstOrNull;
      if (w == null) return false;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return (w.completionLog[key] ?? 0) > 0;
    }
    return false;
  }

  double _getDailyBalance() {
    final date = DateTime.now();
    int facilitatorsChecked = _currentHabit.facilitators.where((it) => _isItemCompleted(it, date)).length;
    int hindrancesChecked = _currentHabit.hindrances.where((it) => _isItemCompleted(it, date)).length;
    
    int total = _currentHabit.facilitators.length + _currentHabit.hindrances.length;
    if (total == 0) return 0;
    
    return (facilitatorsChecked - hindrancesChecked) / total;
  }

  String _getMizanMessage(double balance) {
    if (balance > 0.6) return "أداء استثنائي! أنت تسيطر على المعركة تماماً 💪";
    if (balance > 0.2) return "تقدم رائع، استمر في تعزيز أسباب النصر 🌟";
    if (balance > -0.2) return "المعركة متكافئة، خطوة واحدة إضافية ترجح كفتك";
    if (balance > -0.6) return "انتبه! أسباب الزلة بدأت تقوى، استعن بالله وجاهد نفسك ⚠️";
    return "خطر! أنت في وضع حرج جداً، فعل وضع الطوارئ فوراً 🛑";
  }

  void _startUrgeTimer() {
    setState(() {
      _secondsRemaining = 600; // 10 minutes
    });
    _urgeTimer?.cancel();
    _urgeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        if (mounted) {
           ModernDialog.showInfo(
            context: context,
            title: 'أنت بطل! 🏆',
            message: 'لقد صمدت في لحظة الاختبار.. كلما قاومت، تضعف العادة وتزداد قوتك أنت. استمر!',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double streakProgress = _currentHabit.currentStreak / 90.0;
    if (streakProgress > 1.0) streakProgress = 1.0;
    
    double dailyBalance = _getDailyBalance();
    Color mizanColor = dailyBalance >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(_currentHabit.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Hero(tag: 'addiction_${_currentHabit.id}', child: _buildHeaderCard(streakProgress, dailyBalance, mizanColor)),
            const SizedBox(height: 24),
            _buildActionButtons(),
            if (_secondsRemaining > 0) _buildUrgeTimerDisplay(),
            const SizedBox(height: 24),
            _buildMotivationalMessage(),
            const SizedBox(height: 24),
            _buildDualSection('⚠️ أسباب زلة', _currentHabit.hindrances, Colors.red, 'hindrance'),
            const SizedBox(height: 24),
            _buildDualSection('💪 أسباب نصر', _currentHabit.facilitators, Colors.green, 'facilitator'),
            const SizedBox(height: 24),
            _buildStringSection('🎯 فوائد الترك', _currentHabit.benefits, Colors.teal, 'benefit'),
            const SizedBox(height: 24),
            _buildStringSection('🥀 أضرار العادة', _currentHabit.harms, Colors.brown, 'harm'),
            const SizedBox(height: 24),
            _buildStringSection('⚡ بدائل مقترحة', _currentHabit.alternatives, Colors.blue, 'alternative'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(double streakProgress, double dailyBalance, Color mizanColor) {
    final isDark = ThemeService.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, size: 50, color: AppTheme.primaryGreen),
            const SizedBox(height: 12),
            Text(_currentHabit.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCol('اليوم', _currentHabit.currentStreak.toString()),
                _buildStatCol('الأفضل', _currentHabit.bestStreak.toString()),
                _buildStatCol('التقدم', '${(streakProgress * 100).toInt()}%'),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            
            // ميزان المعركة اليومية
            Text('ميزان الثبات اليومي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mizanColor)),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: dailyBalance.abs().clamp(0.0, 1.0),
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    color: mizanColor,
                    minHeight: 12,
                  ),
                ),
                Text('${(dailyBalance * 100).toInt().abs()}%', 
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
              ],
            ),
            const SizedBox(height: 8),
            Text(_getMizanMessage(dailyBalance), 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: mizanColor, fontWeight: FontWeight.w600)),
            
            // استخدام التطبيق إذا كان مرتبكاً
            if (_currentHabit.linkedAppPackage != null) ...[
              const SizedBox(height: 12),
              _buildAppUsageStatus(),
            ],
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            const Text('هدف الـ 90 يوماً للحرية', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageStatus() {
    return FutureBuilder<List<AppUsage>>(
      future: ScreenTimeService.getTodayUsage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
        
        final todayUsage = snapshot.data!.where((a) => a.packageName == _currentHabit.linkedAppPackage).firstOrNull;
        if (todayUsage == null) return const Text('لا يوجد بيانات استخدام لهذا التطبيق اليوم', style: TextStyle(fontSize: 10, color: Colors.grey));
        
        bool exceeded = _currentHabit.dailyLimitMinutes != null && todayUsage.minutes > _currentHabit.dailyLimitMinutes!;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: exceeded ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: exceeded ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('استهلاك اليوم:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: exceeded ? Colors.red : Colors.blue)),
                  Text(ScreenTimeService.formatDuration(todayUsage.minutes), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: exceeded ? Colors.red : Colors.blue)),
                ],
              ),
              if (_currentHabit.dailyLimitMinutes != null) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (todayUsage.minutes / _currentHabit.dailyLimitMinutes!).clamp(0.0, 1.0),
                  backgroundColor: Colors.white,
                  color: exceeded ? Colors.red : Colors.blue,
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text('الحد اليومي: ${_currentHabit.dailyLimitMinutes} دقيقة', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatCol(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.emergency_share),
            label: const Text('أنا على وشك الوقوع (وضع الطوارئ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergencyModeScreen(habit: _currentHabit)),
              ).then((_) => _refresh());
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                onPressed: _startUrgeTimer,
                child: const Text('جاتلي رغبة'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                onPressed: () async {
                  await AddictionService.incrementStreak(_currentHabit.id);
                  _refresh();
                },
                child: const Text('انتصرت'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                final res = await ModernDialog.showConfirm(context: context, title: 'زلة؟', message: 'سيتم خصم يوم واحد من العداد. استمر!');
                if (res == true) {
                  await AddictionService.lapseStreak(_currentHabit.id);
                  _refresh();
                }
              }, 
              icon: const Icon(Icons.replay_10, color: Colors.orange),
              tooltip: 'زلة',
            ),
            IconButton(
              onPressed: () async {
                 final res = await ModernDialog.showConfirm(context: context, title: 'نكسة؟', message: 'سيتم تصفير العداد. ابدأ من جديد بقوة!', isDestructive: true);
                 if (res == true) {
                   await AddictionService.resetStreak(_currentHabit.id);
                   _refresh();
                 }
              }, 
              icon: const Icon(Icons.restart_alt, color: Colors.red),
              tooltip: 'نكسة',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgeTimerDisplay() {
    String minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Text('اصمد لـ 10 دقائق: $minutes:$seconds', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildDualSection(String title, List<ZadItem> items, Color color, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton(
                  onPressed: () => _showAddMultipleTextDialog(type),
                  child: Text('إضافة أكثر من سبب', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showAddItemOptions(type),
                  child: Text('ربط بند', style: TextStyle(color: color.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty) const Text('لا يوجد بنود مضافة بعد', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ...items.map((item) => _buildZadItemCard(item, color, type)),
      ],
    );
  }

  void _showAddMultipleTextDialog(String listType) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة أسباب متعددة'),
        content: TextField(
          controller: nameController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'اكتب كل سبب في سطر منفصل',
            hintText: 'مثال:\nتجنب الهاتف\nالاستغفار\nالمشي',
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); }, child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final names = nameController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
                
                List<ZadItem> currentList = listType == 'hindrance' 
                    ? List.from(_currentHabit.hindrances) 
                    : List.from(_currentHabit.facilitators);
                
                for (var name in names) {
                  currentList.add(ZadItem(id: const Uuid().v4(), name: name.trim()));
                }

                final updated = listType == 'hindrance' 
                    ? _currentHabit.copyWith(hindrances: currentList)
                    : _currentHabit.copyWith(facilitators: currentList);
                
                await AddictionService.saveHabit(updated);
                _refresh();
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: const Text('إضافة الكل'),
          ),
        ],
      ),
    );
  }

  Widget _buildZadItemCard(ZadItem item, Color color, String listType) {
    final date = DateTime.now();
    bool isCompleted = item.isCompletedOn(date);
    if (item.type == ZadItemType.habit) {
      final h = HabitService.getHabits().where((it) => it.id == item.linkedId).firstOrNull;
      if (h != null) {
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        isCompleted = (h.completionLog[key] ?? 0) > 0;
      }
    } else if (item.type == ZadItemType.worship) {
      final w = WorshipService.getItems().where((it) => it.id == item.linkedId).firstOrNull;
      if (w != null) {
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        isCompleted = (w.completionLog[key] ?? 0) > 0;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: isCompleted,
          activeColor: color,
          onChanged: (val) => _toggleItem(item, val ?? false),
        ),
        title: Text(item.name, style: TextStyle(fontSize: 14, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
          onPressed: () => _removeItem(listType, item.id),
        ),
      ),
    );
  }

  void _showAddItemOptions(String listType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernLinkPicker(
        onItemPicked: (item) {
          _addItem(listType, item);
        },
      ),
    );
  }

  void _addItem(String listType, ZadItem item) async {
    List<ZadItem> list = listType == 'hindrance' ? List.from(_currentHabit.hindrances) : List.from(_currentHabit.facilitators);
    list.add(item);
    final updated = listType == 'hindrance' 
        ? _currentHabit.copyWith(hindrances: list)
        : _currentHabit.copyWith(facilitators: list);
    await AddictionService.saveHabit(updated);
    _refresh();
  }

  void _removeItem(String listType, String id) async {
    List<ZadItem> list = listType == 'hindrance' ? List.from(_currentHabit.hindrances) : List.from(_currentHabit.facilitators);
    list.removeWhere((it) => it.id == id);
    final updated = listType == 'hindrance' 
        ? _currentHabit.copyWith(hindrances: list)
        : _currentHabit.copyWith(facilitators: list);
    await AddictionService.saveHabit(updated);
    _refresh();
  }

  void _toggleItem(ZadItem item, bool val) async {
    final date = DateTime.now();
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    if (item.type == ZadItemType.internal) {
      final newLog = Map<String, double>.from(item.log);
      newLog[dateKey] = val ? 1.0 : 0.0;
      final newItem = item.copyWith(log: newLog);
      _updateItemInHabit(newItem);
    } else if (item.type == ZadItemType.habit) {
      await HabitService.toggleHabitCompletion(item.linkedId!, date, val ? 1.0 : 0.0);
      _refresh();
    } else if (item.type == ZadItemType.worship) {
      await WorshipService.updateItemValue(item.linkedId!, date, val ? 1.0 : 0.0, increment: false);
      _refresh();
    }
  }

  void _updateItemInHabit(ZadItem newItem) async {
    List<ZadItem> h = List.from(_currentHabit.hindrances);
    List<ZadItem> f = List.from(_currentHabit.facilitators);
    int hIdx = h.indexWhere((it) => it.id == newItem.id);
    if (hIdx != -1) h[hIdx] = newItem;
    int fIdx = f.indexWhere((it) => it.id == newItem.id);
    if (fIdx != -1) f[fIdx] = newItem;
    
    final updated = _currentHabit.copyWith(hindrances: h, facilitators: f);
    await AddictionService.saveHabit(updated);
    _refresh();
  }

  Widget _buildStringSection(String title, List<String> items, Color color, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton(
                  onPressed: () => _showAddSingleStringDialog(type, title),
                  child: Text('إضافة', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showAddMultipleStringDialog(type, title),
                  child: Text('إضافة أكثر من بند', style: TextStyle(color: color.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty) const Text('لا يوجد بنود مضافة بعد', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ...items.asMap().entries.map((e) => _buildStringItemCard(e.value, e.key, color, type)),
      ],
    );
  }

  Widget _buildStringItemCard(String text, int index, Color color, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(text, style: const TextStyle(fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
          onPressed: () => _removeStringItem(type, index),
        ),
      ),
    );
  }

  void _showAddSingleStringDialog(String type, String title) async {
    final res = await ModernDialog.showInput(context: context, title: title, hint: 'اكتب البند هنا...');
    if (res != null && res.isNotEmpty) {
      List<String> list;
      AddictionHabit updated;
      if (type == 'benefit') {
        list = List.from(_currentHabit.benefits)..add(res.trim());
        updated = _currentHabit.copyWith(benefits: list);
      } else if (type == 'harm') {
        list = List.from(_currentHabit.harms)..add(res.trim());
        updated = _currentHabit.copyWith(harms: list);
      } else {
        list = List.from(_currentHabit.alternatives)..add(res.trim());
        updated = _currentHabit.copyWith(alternatives: list);
      }
      await AddictionService.saveHabit(updated);
      _refresh();
    }
  }

  void _showAddMultipleStringDialog(String type, String title) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة $title'),
        content: TextField(
          controller: nameController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'اكتب كل بند في سطر منفصل',
            hintText: 'مثال:\nتوفير المال\nصحة أفضل\nراحة البال',
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); }, child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final names = nameController.text.split('\n').where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();
                
                List<String> list;
                AddictionHabit updated;
                if (type == 'benefit') {
                  list = List.from(_currentHabit.benefits)..addAll(names);
                  updated = _currentHabit.copyWith(benefits: list);
                } else if (type == 'harm') {
                  list = List.from(_currentHabit.harms)..addAll(names);
                  updated = _currentHabit.copyWith(harms: list);
                } else {
                  list = List.from(_currentHabit.alternatives)..addAll(names);
                  updated = _currentHabit.copyWith(alternatives: list);
                }

                await AddictionService.saveHabit(updated);
                _refresh();
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: const Text('إضافة الكل'),
          ),
        ],
      ),
    );
  }

  void _removeStringItem(String type, int index) async {
    List<String> list;
    AddictionHabit updated;
    if (type == 'benefit') {
      list = List.from(_currentHabit.benefits)..removeAt(index);
      updated = _currentHabit.copyWith(benefits: list);
    } else if (type == 'harm') {
      list = List.from(_currentHabit.harms)..removeAt(index);
      updated = _currentHabit.copyWith(harms: list);
    } else {
      list = List.from(_currentHabit.alternatives)..removeAt(index);
      updated = _currentHabit.copyWith(alternatives: list);
    }
    await AddictionService.saveHabit(updated);
    _refresh();
  }

  Widget _buildMotivationalMessage() {
    String msg = "";
    Color color = Colors.blue;
    IconData icon = Icons.info_outline;

    final date = DateTime.now();
    int hindrancesChecked = _currentHabit.hindrances.where((it) => _isItemCompleted(it, date)).length;
    bool hasRelapsedToday = hindrancesChecked > 0;

    if (hasRelapsedToday) {
      msg = "لقد حدث تعثر اليوم.. لا بأس، المهم ألا تستسلم / تستسلمي. غداً يوم جديد وبداية جديدة للصمود.";
      color = Colors.red;
      icon = Icons.warning_amber_rounded;
    } else if (_currentHabit.currentStreak == 0) {
      msg = "اليوم هو أول خطوة في طريق الحرية.. استعن / استعيني بالله ولا تعجز / تعجزي.";
      color = Colors.orange;
      icon = Icons.rocket_launch_outlined;
    } else if (_currentHabit.currentStreak < 7) {
      msg = "أنت بطل / بطلة! صمدت لـ ${_currentHabit.currentStreak} أيام. استمر / استمري في بناء نسخة أقوى من نفسك.";
      color = Colors.blue;
      icon = Icons.bolt;
    } else {
      msg = "ما شاء الله! ${_currentHabit.currentStreak} يوماً من العزة. أنت الآن تلهم / تلهمين نفسك وتثبت / تثبتين أنك أقوى من أي عادة.";
      color = Colors.green;
      icon = Icons.workspace_premium_outlined;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
          ),
          child: const Center(
            child: Text(
              '«مَنْ تَرَكَ شَيْئاً للهِ عَوَّضَهُ اللهُ خَيْراً مِنْهُ»',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ],
    );
  }
}
