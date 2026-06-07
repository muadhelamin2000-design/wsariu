import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'models/zad_model.dart';
import 'services/zad_service.dart';
import '../discipline/services/habit_service.dart';
import '../discipline/models/habit_model.dart';
import 'services/worship_service.dart';
import 'models/worship_model.dart';
import '../discipline/services/task_service.dart';
import '../discipline/models/task_model.dart';
import '../discipline/services/routine_service.dart';
import '../discipline/models/routine_model.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';

import '../../core/widgets/modern_link_picker.dart';
import '../../core/mixins/help_feature_mixin.dart';

class ZadMaadScreen extends StatefulWidget {
  const ZadMaadScreen({super.key});

  @override
  State<ZadMaadScreen> createState() => _ZadMaadScreenState();
}

class _ZadMaadScreenState extends State<ZadMaadScreen> with HelpFeatureMixin {
  List<ZadDeed> _deeds = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
    checkFirstTimeHelp(context, 'zad_maad');
  }

  void _refreshData() {
    setState(() {
      _deeds = ZadService.getDeeds();
    });
  }

  double _calculateDailyProgress(ZadDeed deed, DateTime date) {
    int total = deed.facilitators.length + deed.hindrances.length;
    if (total == 0) return 0;
    
    int successCount = 0;
    for (var f in deed.facilitators) {
      if (_isItemCompleted(f, date)) successCount++;
    }
    for (var h in deed.hindrances) {
      if (!_isItemCompleted(h, date)) successCount++;
    }
    
    return (successCount / total) * 100;
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

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('zad');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('البنيان'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح البنيان', 
            description: 'ابنِ قصرك في الجنة ورمم نقصك:\n'
            '- تابع السنن والرواتب والأذكار المقيدة.\n'
            '- اربط الأعمال ببعضها لخلق نظام عبادة متكامل.\n'
            '- تتبع تقدمك في البناء الروحي يوماً بعد يوم.',
            pageId: 'zad',
          ),
          TextButton(
            onPressed: () => _showAddEditDeedDialog(),
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'zad'),
          _buildStickyQuote(),
          Expanded(
            child: _deeds.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: _deeds.length,
                    itemBuilder: (context, index) => _buildDeedCard(_deeds[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyQuote() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8A24A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          'كالبنيان يشد بعضه بعضاً',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3D2E),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stairs, size: 80, color: AppTheme.primaryGreen.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('ابدأ ببناء زادك للمعاد..', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text('أضف أول طاعة تلتزم بتطويرها الآن.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeedCard(ZadDeed deed) {
    double proximity = _calculateDailyProgress(deed, DateTime.now());
    final color = Color(deed.colorValue);
    final isDark = ThemeService.isDarkMode;

    return Hero(
      tag: 'deed_${deed.id}',
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DeedDetailScreen(deed: deed))).then((_) => _refreshData()),
        onLongPress: () => _showAddEditDeedDialog(deed: deed),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A38) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(deed.iconEmoji, style: const TextStyle(fontSize: 22)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${proximity.toInt()}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(deed.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: Text(deed.quote, 
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis, 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 11, color: Colors.grey, height: 1.3)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                proximity > 70 ? "ثبات ممتاز" : (proximity > 35 ? "في طريق التحسن" : "تحتاج مجاهدة"),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDeedDialog({ZadDeed? deed}) {
    final isEdit = deed != null;
    final nameController = TextEditingController(text: deed?.name ?? '');
    final emojiController = TextEditingController(text: deed?.iconEmoji ?? '🌟');
    final quoteController = TextEditingController(text: deed?.quote ?? '');
    ZadCategory selectedCategory = deed?.category ?? ZadCategory.balanced;
    Color selectedColor = Color(deed?.colorValue ?? AppTheme.primaryGreen.value);

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل البناء' : 'إضافة بناء روحي',
      accentColor: AppTheme.primaryGreen,
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(width: 60, child: TextField(controller: emojiController, decoration: const InputDecoration(labelText: 'أيقونة'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العمل/البناء'))),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ZadCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'نوع البناء'),
                items: const [
                  DropdownMenuItem(value: ZadCategory.balanced, child: Text('بناء متوازن (أسباب وعوائق)')),
                  DropdownMenuItem(value: ZadCategory.independent, child: Text('بناء مستقل (خيار جديد)')),
                ],
                onChanged: (v) => setSheetState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              const Text('اللون المميز:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: AppTheme.expandedColors.length,
                  itemBuilder: (context, idx) {
                    final c = AppTheme.expandedColors[idx];
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = c),
                      child: CircleAvatar(radius: 15, backgroundColor: c, child: selectedColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); }, child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        if (isEdit) 
          TextButton(onPressed: () async {
            final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف؟', message: 'سيتم حذف هذا البناء نهائياً.', isDestructive: true);
            if (confirm == true) {
              await ZadService.deleteDeed(deed.id);
              if (mounted) { Navigator.of(context, rootNavigator: true).pop(); _refreshData(); }
            }
          }, child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          onPressed: () async {
            if (nameController.text.isNotEmpty && UserService.currentUser != null) {
              final newDeed = ZadDeed(
                id: deed?.id ?? const Uuid().v4(),
                userId: UserService.currentUser!.id,
                name: nameController.text,
                description: '', // Required field
                iconEmoji: emojiController.text,
                quote: quoteController.text,
                colorValue: selectedColor.value,
                category: selectedCategory,
                facilitators: deed?.facilitators ?? [],
                hindrances: deed?.hindrances ?? [],
                createdAt: deed?.createdAt ?? DateTime.now(),
              );
              await ZadService.saveDeed(newDeed);
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                _refreshData();
              }
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class DeedDetailScreen extends StatefulWidget {
  final ZadDeed deed;
  const DeedDetailScreen({super.key, required this.deed});

  @override
  State<DeedDetailScreen> createState() => _DeedDetailScreenState();
}

class _DeedDetailScreenState extends State<DeedDetailScreen> {
  late ZadDeed _currentDeed;
  final Map<String, TextEditingController> _inputControllers = {};

  @override
  void initState() {
    super.initState();
    _currentDeed = widget.deed;
  }

  void _refresh() {
    final updated = ZadService.getDeeds().where((d) => d.id == _currentDeed.id).firstOrNull;
    if (updated != null) setState(() => _currentDeed = updated);
  }

  double _getDailyBalance(DateTime date) {
    int total = _currentDeed.facilitators.length + _currentDeed.hindrances.length;
    if (total == 0) return 0;
    
    int facilitatorsChecked = _currentDeed.facilitators.where((it) => _isItemCompleted(it, date)).length;
    int hindrancesChecked = _currentDeed.hindrances.where((it) => _isItemCompleted(it, date)).length;
    
    return (facilitatorsChecked - hindrancesChecked) / total;
  }

  String _getMizanMessage(double balance) {
    if (balance > 0.6) return "بناء قوي جداً! أنت تسيطر على البناء ببراعة 💪";
    if (balance > 0.2) return "خطوات ثابتة في طريق التحسن، استمر 🌟";
    if (balance > -0.2) return "المجاهدة مستمرة، غلّب جانب الإعانة ليرتفع البناء";
    if (balance > -0.6) return "انتبه! العوائق بدأت تؤثر على ثباتك، جاهد نفسك ⚠️";
    return "تحذير: البناء مهدد بالتصدع، عد إلى طريق الاستقامة فوراً 🛑";
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

  double _getItemValue(ZadItem item, DateTime date) {
    if (item.type == ZadItemType.internal) {
      return item.getValueOn(date);
    } else if (item.type == ZadItemType.habit) {
      final h = HabitService.getHabits().where((it) => it.id == item.linkedId).firstOrNull;
      if (h == null) return 0;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return h.completionLog[key] ?? 0;
    } else if (item.type == ZadItemType.worship) {
      final w = WorshipService.getItems().where((it) => it.id == item.linkedId).firstOrNull;
      if (w == null) return 0;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return w.completionLog[key] ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final balance = _getDailyBalance(DateTime.now());
    final mizanColor = balance >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(_currentDeed.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'deed_${_currentDeed.id}', child: _buildHeaderCard(balance, mizanColor)),
            const SizedBox(height: 24),
            _buildWeeklyGraph(),
            const SizedBox(height: 24),
            _buildDualSection('⚠️ عوائق تمنعني', _currentDeed.hindrances, Colors.red, 'hindrance'),
            const SizedBox(height: 24),
            _buildDualSection('💪 أسباب تعينني', _currentDeed.facilitators, Colors.green, 'facilitator'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(double balance, Color mizanColor) {
    final isDark = ThemeService.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_currentDeed.iconEmoji, style: const TextStyle(fontSize: 40)),
              IconButton(
                icon: const Icon(Icons.history, color: Color(0xFFC8A24A)),
                onPressed: _showManualLogDialog,
                tooltip: 'سجل تاريخي',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_currentDeed.name, 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(_currentDeed.quote, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Color(0xFFC8A24A), height: 1.4),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          
          if (_currentDeed.category == ZadCategory.balanced) ...[
            // ميزان البناء
            Text('ميزان البناء اليومي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mizanColor)),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: balance.abs().clamp(0.0, 1.0),
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    color: mizanColor,
                    minHeight: 12,
                  ),
                ),
                Text('${(balance * 100).toInt().abs()}%', 
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
              ],
            ),
            const SizedBox(height: 8),
            Text(_getMizanMessage(balance), 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: mizanColor, fontWeight: FontWeight.w600)),
          ] else
            Text('بناء مستقل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(_currentDeed.colorValue))),
        ],
      ),
    );
  }

  void _showManualLogDialog() {
    DateTime selectedDate = DateTime.now();
    
    ModernDialog.show(
      context: context,
      title: 'تعديل السجل التاريخي',
      content: StatefulBuilder(
        builder: (context, setModalState) {
          double dayBalance = _getDailyBalance(selectedDate);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('اختر اليوم'),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
              ),
              const Divider(),
              const Text('حالة البناء في هذا اليوم:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Text('${(dayBalance * 100).toInt()}%', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: dayBalance >= 0 ? Colors.green : Colors.red)),
              const SizedBox(height: 16),
              const Text('يمكنك تعديل بنود هذا اليوم من الأقسام بالأسفل بعد اختيار التاريخ من هنا.', 
                textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); }, child: const Text('إغلاق')),
      ],
    );
  }

  Widget _buildWeeklyGraph() {
    List<DateTime> weekDates = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), (_getDailyBalance(weekDates[i]) + 1) * 50)); // Normalize graph to 0-100%
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.isDarkMode ? Colors.white10 : Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        children: [
          const Text('تطور الأداء الأسبوعي (الميزان)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0, maxY: 100,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFC8A24A),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFFC8A24A).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
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
                  child: Text(
                    'إضافة أكثر من سبب',
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showAddItemOptions(type),
                  child: Text(
                    'ربط بند',
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('لا يوجد بنود مضافة بعد', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
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
            hintText: 'مثال:\nالوضوء\nالذكر\nترك الهاتف',
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); }, child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final names = nameController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
                
                List<ZadItem> currentList = listType == 'hindrance' 
                    ? List.from(_currentDeed.hindrances) 
                    : List.from(_currentDeed.facilitators);
                
                for (var name in names) {
                  currentList.add(ZadItem(id: const Uuid().v4(), name: name.trim(), type: ZadItemType.internal));
                }

                final updatedDeed = listType == 'hindrance' 
                    ? _currentDeed.copyWith(hindrances: currentList)
                    : _currentDeed.copyWith(facilitators: currentList);
                
                await ZadService.saveDeed(updatedDeed);
                _refresh();
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              }
            },
            child: const Text('إضافة الكل'),
          ),
        ],
      ),
    );
  }

  Widget _buildZadItemCard(ZadItem item, Color color, String listType) {
    final today = DateTime.now();
    bool isCompleted = _isItemCompleted(item, today);
    double value = _getItemValue(item, today);
    
    bool isVariable = false;
    String unit = "";
    if (item.type == ZadItemType.habit) {
      final h = HabitService.getHabits().where((it) => it.id == item.linkedId).firstOrNull;
      if (h != null && h.type == HabitType.variable) { isVariable = true; unit = h.unitName ?? ""; }
    } else if (item.type == ZadItemType.worship) {
      final w = WorshipService.getItems().where((it) => it.id == item.linkedId).firstOrNull;
      if (w != null && w.type == WorshipItemType.variable) { isVariable = true; unit = w.unitName ?? ""; }
    }

    final controller = _inputControllers.putIfAbsent(item.id, () => TextEditingController());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              activeColor: color,
              onChanged: (val) => _toggleItem(item, val ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(fontSize: 14, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
                  if (item.type != ZadItemType.internal)
                    Text(item.type == ZadItemType.habit ? 'عادة مرتبطة' : 'عبادة مرتبطة', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
            if (isVariable) ...[
               SizedBox(
                  width: 50,
                  height: 30,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: value > 0 ? '${value.toInt()}' : '0',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (val) {
                      double? v = double.tryParse(val);
                      if (v != null) _updateItemValue(item, v);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: () => _removeItem(listType, item.id),
            ),
          ],
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
    List<ZadItem> list = listType == 'hindrance' ? List.from(_currentDeed.hindrances) : List.from(_currentDeed.facilitators);
    list.add(item);
    final updated = listType == 'hindrance' 
        ? _currentDeed.copyWith(hindrances: list)
        : _currentDeed.copyWith(facilitators: list);
    await ZadService.saveDeed(updated);
    _refresh();
  }

  void _removeItem(String listType, String id) async {
    List<ZadItem> list = listType == 'hindrance' ? List.from(_currentDeed.hindrances) : List.from(_currentDeed.facilitators);
    list.removeWhere((it) => it.id == id);
    final updated = listType == 'hindrance' 
        ? _currentDeed.copyWith(hindrances: list)
        : _currentDeed.copyWith(facilitators: list);
    await ZadService.saveDeed(updated);
    _refresh();
  }

  void _toggleItem(ZadItem item, bool val) async {
    final date = DateTime.now();
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    if (item.type == ZadItemType.internal) {
      final newLog = Map<String, double>.from(item.log);
      newLog[dateKey] = val ? 1.0 : 0.0;
      final newItem = item.copyWith(log: newLog);
      _updateItemInDeed(newItem);
    } else if (item.type == ZadItemType.habit) {
      await HabitService.toggleHabitCompletion(item.linkedId!, date, val ? 1.0 : 0.0);
      _refresh();
    } else if (item.type == ZadItemType.worship) {
      await WorshipService.updateItemValue(item.linkedId!, date, val ? 1.0 : 0.0, increment: false);
      _refresh();
    }
  }

  void _updateItemValue(ZadItem item, double val) async {
    final date = DateTime.now();
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    if (item.type == ZadItemType.internal) {
      final newLog = Map<String, double>.from(item.log);
      newLog[dateKey] = val;
      final newItem = item.copyWith(log: newLog);
      _updateItemInDeed(newItem);
    } else if (item.type == ZadItemType.habit) {
      await HabitService.updateHabitValue(item.linkedId!, date, val);
      _refresh();
    } else if (item.type == ZadItemType.worship) {
      await WorshipService.updateItemValue(item.linkedId!, date, val, increment: false);
      _refresh();
    }
  }

  void _updateItemInDeed(ZadItem newItem) async {
    List<ZadItem> h = List.from(_currentDeed.hindrances);
    List<ZadItem> f = List.from(_currentDeed.facilitators);
    
    int hIdx = h.indexWhere((it) => it.id == newItem.id);
    if (hIdx != -1) h[hIdx] = newItem;
    
    int fIdx = f.indexWhere((it) => it.id == newItem.id);
    if (fIdx != -1) f[fIdx] = newItem;
    
    final updated = _currentDeed.copyWith(hindrances: h, facilitators: f);
    await ZadService.saveDeed(updated);
    _refresh();
  }
}
