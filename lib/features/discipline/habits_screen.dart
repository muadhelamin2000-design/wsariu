import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit_model.dart';
import 'habit_detail_screen.dart';
import 'habit_section_screen.dart';
import 'services/habit_service.dart';
import 'services/notification_service.dart';
import '../profile/services/user_service.dart';
import '../dashboard/services/prayer_service.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/services/page_management_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/badge_service.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/widgets/page_info.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with HelpFeatureMixin {
  List<Habit> _habits = [];
  List<HabitGoal> _sectionsOrder = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  final Map<HabitGoal, bool> _isSectionExpanded = {
    HabitGoal.good: false,
    HabitGoal.bad: false,
  };

  static const List<String> fullArabicDays = [
    'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
    checkFirstTimeHelp(context, 'habits');
  }

  void _loadHabits() {
    setState(() {
      _habits = HabitService.getHabits();
      _sectionsOrder = HabitService.getSectionsOrder();
    });
  }

  double _getNetScoreForDate(DateTime date) {
    double good = 0;
    double bad = 0;
    for (var h in _habits) {
      double p = h.calculatePoints(date);
      if (h.goal == HabitGoal.good) {
        good += p;
      } else {
        bad += p;
      }
    }
    return good - bad;
  }

  List<DateTime> _getCurrentWeekDates() {
    DateTime now = DateTime.now();
    int currentFlutterWeekday = now.weekday;
    int daysToSubtract;
    if (currentFlutterWeekday == 6) daysToSubtract = 0;
    else if (currentFlutterWeekday == 7) daysToSubtract = 1;
    else daysToSubtract = currentFlutterWeekday + 1;
    DateTime saturday = now.subtract(Duration(days: daysToSubtract));
    return List.generate(7, (i) => saturday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = PageManagementService.getAllPages();
    final page = pages.firstWhere((p) => p.id == 'habits', orElse: () => PageItem(id: 'habits', name: 'نظام العادات', route: '', iconData: '✅', sectionKey: 'discipline'));

    final customBg = getPageBackgroundColor('habits');
    return Scaffold(
      backgroundColor: customBg,
      appBar: (_isSelectionMode || _selectedIds.isNotEmpty)
        ? AppBar(
            backgroundColor: AppTheme.primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white), 
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              })
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown, 
              child: Text(
                _selectedIds.isEmpty ? 'تحديد العناصر' : '${_selectedIds.length} محدد', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              )
            ),
            actions: [
              if (_selectedIds.isNotEmpty) ...[
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white), onPressed: _showBulkEditPoints, tooltip: 'تعديل النقاط'),
                IconButton(icon: const Icon(Icons.swap_horiz, color: Colors.white), onPressed: _showBulkChangeCategory, tooltip: 'تغيير القسم'),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _bulkDelete, tooltip: 'حذف المحدد'),
              ],
            ],
          )
        : AppBar(
            title: InkWell(
              onTap: _showEditPageNameDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(page.name, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                ],
              ),
            ),
            centerTitle: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              buildHelpButton(
                context, 
                title: 'شرح نظام العادات', 
                description: 'بناء الشخصية يبدأ من العادة:\n'
                '- اضغط "إضافة عادة" لتدوين هدف جديد.\n'
                '- حدد نوع العادة (ثابتة أو متغيرة) ونظام التكرار.\n'
                '- العادات الحسنة تزيد نقاطك، والسيئة تنقصها.\n'
                '- استخدم "وضع التحديد" لتعديل أو حذف مجموعة عادات معاً.\n'
                '- اضغط مطولاً على العادة لترتيبها.',
                pageId: 'habits',
              ),
              TextButton(
                onPressed: () => _showAddEditHabitSheet(),
                child: const Text('إضافة عادة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'select') setState(() => _isSelectionMode = true);
                  if (val == 'home') GoRouter.of(context).go('/');
                  if (val == 'reset') _confirmResetAllHabits();
                  if (val == 'bulk') _showBulkAddDialog();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.checklist_rtl, size: 20), SizedBox(width: 8), Text('وضع التحديد', style: TextStyle(fontSize: 13))])),
                  const PopupMenuItem(value: 'bulk', child: Row(children: [Icon(Icons.format_list_bulleted, size: 20), SizedBox(width: 8), Text('إضافة متعددة', style: TextStyle(fontSize: 13))])),
                  const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.refresh_outlined, size: 20, color: Colors.red), SizedBox(width: 8), Text('تصفير الكل', style: TextStyle(fontSize: 13, color: Colors.red))])),
                  const PopupMenuItem(value: 'home', child: Row(children: [Icon(Icons.home_outlined, size: 20), SizedBox(width: 8), Text('الرئيسية', style: TextStyle(fontSize: 13))])),
                ],
              ),
            ],
          ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                QuickLinkNavigator(currentPageId: 'habits'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: PageInfo(
                    title: 'نظام العادات المتكامل',
                    description: 'قم ببناء شخصيتك من خلال الالتزام بالعادات الحسنة ومجاهدة العادات السيئة. راقب تقدمك وارتفاع نقاطك مع كل إنجاز.',
                    icon: Icons.track_changes,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildWeeklyAnalysis()),
          SliverToBoxAdapter(child: _buildOverallStats()),
          if (_habits.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('ابدأ بتدوين أول عاداتك اليوم!')),
            )
          else
            SliverToBoxAdapter(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _sectionsOrder.removeAt(oldIndex);
                    _sectionsOrder.insert(newIndex, item);
                  });
                  await HabitService.saveSectionsOrder(_sectionsOrder);
                },
                children: _sectionsOrder.map((goal) {
                  final sectionHabits = _habits.where((h) => h.goal == goal).toList();
                  if (sectionHabits.isEmpty) return SizedBox(key: ValueKey('empty_${goal.index}'));
                  return _buildHabitSection(
                    key: ValueKey('section_${goal.index}'),
                    title: HabitService.getSectionMetadata(goal)['title'],
                    habits: sectionHabits,
                    goal: goal,
                  );
                }).toList(),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildWeeklyAnalysis() {
    List<DateTime> weekDates = _getCurrentWeekDates();
    List<double> scores = weekDates.map((d) => _getNetScoreForDate(d)).toList();
    final isDark = ThemeService.isDarkMode;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تتبع الأداء الأسبوعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                double score = scores[i];
                double heightFactor = (score.abs() / 200).clamp(0.1, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 25,
                        height: 80 * heightFactor,
                        decoration: BoxDecoration(
                          color: score >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(fullArabicDays[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    double goodPoints = 0;
    double badPoints = 0;
    DateTime today = PrayerService.getIslamicDayDate();

    for (var h in _habits) {
      double p = h.calculatePoints(today);
      if (h.goal == HabitGoal.good) {
        goodPoints += p;
      } else {
        badPoints += p;
      }
    }
    double netScore = goodPoints - badPoints;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D2E), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('إيجابي', '${goodPoints.toInt()}', Colors.greenAccent),
          Column(
            children: [
              Text(netScore.toInt().toString(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const Text('صافي اليوم', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
          _statItem('سلبي', '${badPoints.toInt()}', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildHabitCard(Habit habit, int index, {Key? key}) {
    bool isBad = habit.goal == HabitGoal.bad;
    DateTime today = PrayerService.getIslamicDayDate();
    String dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    double currentValue = habit.completionLog[dateKey] ?? 0;
    bool isCompletedToday = currentValue > 0;

    final isSelected = _selectedIds.contains(habit.id);

    return ReorderableDelayedDragStartListener(
      key: key,
      index: index,
      enabled: true,
      child: InkWell(
        onLongPress: null, // Reserved for dragging
        onTap: (_isSelectionMode || _selectedIds.isNotEmpty)
          ? () => setState(() => isSelected ? _selectedIds.remove(habit.id) : _selectedIds.add(habit.id))
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HabitDetailScreen(habit: habit)),
              ).then((_) => _loadHabits());
            },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected ? const BorderSide(color: AppTheme.primaryGreen, width: 2) : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_isSelectionMode || _selectedIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: AppTheme.primaryGreen, size: 20),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.drag_handle, size: 20, color: Colors.grey),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text('Streak: ${habit.currentStreak} 🔥', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode && _selectedIds.isEmpty) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_note_outlined, size: 18), 
                        onPressed: () => _showAddEditHabitSheet(habit: habit)
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.history, size: 16, color: Colors.orange),
                        onPressed: () => _showBackfillHabit(habit),
                        tooltip: 'استدراك',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.redAccent),
                        onPressed: () => _confirmResetHabit(habit),
                        tooltip: 'تصفير السجل',
                      ),
                    ],
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (habit.type == HabitType.fixed)
                      Row(
                        children: [
                          SizedBox(
                            height: 24, width: 24,
                            child: Checkbox(
                              value: isCompletedToday,
                              activeColor: Color(habit.colorValue),
                              onChanged: (_isSelectionMode || _selectedIds.isNotEmpty) ? null : (val) async {
                                await HabitService.toggleHabitCompletion(habit.id, DateTime.now(), 1.0);
                                _loadHabits();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(isCompletedToday ? 'تم' : 'لم يتم', style: TextStyle(color: isCompletedToday ? Color(habit.colorValue) : Colors.grey, fontSize: 12)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 30,
                            child: TextField(
                              enabled: !_isSelectionMode && _selectedIds.isEmpty,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                hintText: currentValue > 0 ? '${currentValue.toInt()}' : '0',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onSubmitted: (val) async {
                                double? newValue = double.tryParse(val);
                                if (newValue != null) {
                                  await HabitService.updateHabitValue(habit.id, DateTime.now(), newValue);
                                  _loadHabits();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(habit.unitName ?? "", style: TextStyle(fontSize: 11, color: Color(habit.colorValue))),
                        ],
                      ),
                    Text('${habit.calculatePoints(PrayerService.getIslamicDayDate()).toInt().abs()}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isBad ? Colors.red : const Color(0xFFC8A24A))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditHabitSheet({Habit? habit}) {
    final isEdit = habit != null;
    final nameController = TextEditingController(text: habit?.name ?? '');
    final pointsController = TextEditingController(text: habit?.basePoints.toString() ?? '10');
    final unitController = TextEditingController(text: habit?.unitName ?? '');
    final intervalController = TextEditingController(text: habit?.intervalValue.toString() ?? '1');
    final targetController = TextEditingController(text: habit?.dailyTarget?.toInt().toString() ?? '');
    final flexCountController = TextEditingController(text: habit?.flexibleCount?.toString() ?? '3');
    final messageController = TextEditingController(text: habit?.customReminderMessage ?? '');
    
    HabitType selectedType = habit?.type ?? HabitType.fixed;
    HabitGoal selectedGoal = habit?.goal ?? HabitGoal.good;
    RecurrenceType selectedRecurrence = habit?.recurrence ?? RecurrenceType.daily;
    ReminderType selectedReminderType = habit?.reminderType ?? ReminderType.fixed;
    
    List<int> selectedDays = List<int>.from(habit?.specificDays ?? []);
    TimeOfDay? selectedTime = habit?.reminderTime;
    TimeOfDay? flexStartTime = habit?.flexibleStartTime ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? flexEndTime = habit?.flexibleEndTime ?? const TimeOfDay(hour: 22, minute: 0);
    String? selectedPrayer = habit?.linkedPrayer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int selectedColorValue = habit?.colorValue ?? 0xFF0F3D2E;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل عادة' : 'تدوين عادة جديدة',
      accentColor: const Color(0xFFC8A24A),
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'اسم العادة',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<HabitType>(
                      value: selectedType,
                      dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(labelText: 'النوع', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                      items: const [DropdownMenuItem(value: HabitType.fixed, child: Text('ثابتة')), DropdownMenuItem(value: HabitType.variable, child: Text('متغيرة'))],
                      onChanged: (v) => setSheetState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<HabitGoal>(
                      value: selectedGoal,
                      dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(labelText: 'التصنيف', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                      items: const [DropdownMenuItem(value: HabitGoal.good, child: Text('جيدة')), DropdownMenuItem(value: HabitGoal.bad, child: Text('سيئة'))],
                      onChanged: (v) => setSheetState(() => selectedGoal = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController, 
                keyboardType: TextInputType.number, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'الهدف اليومي (مثلاً: 3 لتر)',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RecurrenceType>(
                value: selectedRecurrence,
                dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'نظام التكرار', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                items: const [
                  DropdownMenuItem(value: RecurrenceType.daily, child: Text('يومياً')),
                  DropdownMenuItem(value: RecurrenceType.everyOtherDay, child: Text('يوم آه ويوم لا')),
                  DropdownMenuItem(value: RecurrenceType.specificDays, child: Text('أيام محددة')),
                  DropdownMenuItem(value: RecurrenceType.interval, child: Text('كل عدد من الأيام')),
                ],
                onChanged: (v) => setSheetState(() => selectedRecurrence = v!),
              ),
              if (selectedRecurrence == RecurrenceType.specificDays) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    bool isSelected = selectedDays.contains(index);
                    return FilterChip(
                      label: Text(fullArabicDays[index], style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) selectedDays.add(index);
                          else selectedDays.remove(index);
                        });
                      },
                    );
                  }),
                ),
              ],
              if (selectedRecurrence == RecurrenceType.interval)
                TextField(
                  controller: intervalController, 
                  keyboardType: TextInputType.number, 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'كل كم يوم؟',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  ),
                ),
              
              const Divider(height: 32),
              Text('نظام التذكير الذكي', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E))),
              const SizedBox(height: 10),
              DropdownButtonFormField<ReminderType>(
                value: selectedReminderType,
                dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'نوع التذكير', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                items: const [
                  DropdownMenuItem(value: ReminderType.fixed, child: Text('تذكير ثابت (موعد محدد)')),
                  DropdownMenuItem(value: ReminderType.prayer, child: Text('مرتبط بموعد الصلاة 🕋')),
                  DropdownMenuItem(value: ReminderType.flexible, child: Text('تذكير مرن (موزع)')),
                ],
                onChanged: (v) => setSheetState(() => selectedReminderType = v!),
              ),

              if (selectedReminderType == ReminderType.fixed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFFC8A24A)),
                  title: Text(selectedTime == null ? 'ضبط وقت التذكير' : 'موعد: ${selectedTime!.format(context)}', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  trailing: const Icon(Icons.keyboard_arrow_left, size: 14),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
                    if (picked != null) setSheetState(() => selectedTime = picked);
                  },
                )
              else if (selectedReminderType == ReminderType.prayer)
                DropdownButtonFormField<String>(
                  value: selectedPrayer,
                  dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: 'اختر الصلاة', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                  items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSheetState(() => selectedPrayer = v!),
                )
              else ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('البداية', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey)),
                        subtitle: Text(flexStartTime?.format(context) ?? '--:--', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: flexStartTime ?? TimeOfDay.now());
                          if (p != null) setSheetState(() => flexStartTime = p);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('النهاية', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey)),
                        subtitle: Text(flexEndTime?.format(context) ?? '--:--', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: flexEndTime ?? TimeOfDay.now());
                          if (p != null) setSheetState(() => flexEndTime = p);
                        },
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: flexCountController, 
                  keyboardType: TextInputType.number, 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'عدد مرات التذكير',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'رسالة التذكير المخصصة (اختياري)',
                  hintText: 'اتركها فارغة للنظام الذكي',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pointsController, 
                      keyboardType: TextInputType.number, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(labelText: 'النقاط', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                    ),
                  ),
                  if (selectedType == HabitType.variable) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController, 
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(labelText: 'اسم الوحدة', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const Text('اختر لون العادة:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: AppTheme.expandedColors.length,
                  itemBuilder: (context, idx) {
                    final color = AppTheme.expandedColors[idx];
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColorValue = color.value),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: color,
                        child: selectedColorValue == color.value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          onPressed: () async {
            if (nameController.text.isEmpty || UserService.currentUser == null) return;
            final String habitId = habit?.id ?? const Uuid().v4();
            
            final newHabit = Habit(
              id: habitId,
              userId: UserService.currentUser!.id,
              name: nameController.text,
              type: selectedType,
              goal: selectedGoal,
              basePoints: int.tryParse(pointsController.text) ?? 10,
              unitName: selectedType == HabitType.variable ? unitController.text : null,
              recurrence: selectedRecurrence,
              specificDays: selectedDays,
              intervalValue: int.tryParse(intervalController.text) ?? 1,
              createdAt: habit?.createdAt ?? DateTime.now(),
              completionLog: habit?.completionLog ?? {},
              colorValue: selectedColorValue,
              
              reminderType: selectedReminderType,
              reminderHour: selectedTime?.hour,
              reminderMinute: selectedTime?.minute,
              flexibleStartHour: flexStartTime?.hour,
              flexibleStartMinute: flexStartTime?.minute,
              flexibleEndHour: flexEndTime?.hour,
              flexibleEndMinute: flexEndTime?.minute,
              flexibleCount: int.tryParse(flexCountController.text),
              dailyTarget: double.tryParse(targetController.text),
              customReminderMessage: messageController.text.isNotEmpty ? messageController.text : null,
              linkedPrayer: selectedPrayer,
            );
            
            await HabitService.saveHabit(newHabit);
            if (mounted) {
              Navigator.pop(context);
              _loadHabits();
            }
          },
          child: const Text('حفظ العادة'),
        ),
      ],
    );
  }

  void _confirmDelete(String id) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف العادة',
      message: 'هل أنت متأكد من حذف هذه العادة نهائياً؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await HabitService.deleteHabit(id);
      _loadHabits();
    }
  }

  void _confirmResetHabit(Habit habit) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير العادة',
      message: 'هل أنت متأكد من مسح سجل الإنجاز لعادة "${habit.name}"؟',
      confirmLabel: 'تصفير الآن',
    );
    if (result == true) {
      await HabitService.resetHabitCompletion(habit.id);
      if (mounted) _loadHabits();
    }
  }

  void _confirmResetAllHabits() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير كل العادات',
      message: 'هل أنت متأكد من مسح جميع سجلات الإنجاز لكل العادات؟ لا يمكن التراجع عن هذا الفعل.',
      confirmLabel: 'تصفير الكل',
      isDestructive: true,
    );
    if (result == true) {
      await HabitService.resetAllHabitsCompletion();
      if (mounted) _loadHabits();
    }
  }

  void _showBulkEditPoints() async {
    final res = await ModernDialog.showInput(context: context, title: 'تعديل النقاط', hint: 'أدخل النقاط الجديدة لـ ${_selectedIds.length} عنصر');
    if (res != null) {
      final points = int.tryParse(res);
      if (points != null) {
        for (var id in _selectedIds) {
          final habit = _habits.firstWhere((h) => h.id == id);
          await HabitService.saveHabit(habit.copyWith(basePoints: points));
        }
        setState(() => _selectedIds.clear());
        _loadHabits();
      }
    }
  }

  void _showBulkChangeCategory() async {
    ModernDialog.show(
      context: context,
      title: 'تغيير القسم',
      content: const Text('إلى أي قسم تريد نقل العناصر المحددة؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(
          onPressed: () async {
            for (var id in _selectedIds) {
              final habit = _habits.firstWhere((h) => h.id == id);
              await HabitService.saveHabit(habit.copyWith(goal: HabitGoal.good));
            }
            Navigator.pop(context);
            setState(() => _selectedIds.clear());
            _loadHabits();
          },
          child: const Text('عادات جيدة'),
        ),
        TextButton(
          onPressed: () async {
            for (var id in _selectedIds) {
              final habit = _habits.firstWhere((h) => h.id == id);
              await HabitService.saveHabit(habit.copyWith(goal: HabitGoal.bad));
            }
            Navigator.pop(context);
            setState(() => _selectedIds.clear());
            _loadHabits();
          },
          child: const Text('عادات سيئة', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _bulkDelete() async {
    final res = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف محدد',
      message: 'هل تريد حذف ${_selectedIds.length} عنصر بشكل نهائي؟',
      isDestructive: true,
    );
    if (res == true) {
      for (var id in _selectedIds) {
        await HabitService.deleteHabit(id);
      }
      setState(() => _selectedIds.clear());
      _loadHabits();
    }
  }

  void _showBackfillHabit(Habit habit) {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));
    final controller = TextEditingController(text: habit.type == HabitType.fixed ? '1' : '');

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
                  firstDate: habit.createdAt,
                  lastDate: DateTime.now(),
                );
                if (p != null) setDialogState(() => selectedDate = p);
              },
            ),
            if (habit.type == HabitType.variable)
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'القيمة (${habit.unitName})',
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
            await _saveHabitCompletionSpecificDate(habit.id, selectedDate, val);
            if (mounted) {
              Navigator.pop(context);
              _loadHabits();
            }
          },
          child: const Text('حفظ الإنجاز'),
        ),
      ],
    );
  }

  Future<void> _saveHabitCompletionSpecificDate(String id, DateTime date, double value) async {
    final box = Hive.box(HabitService.boxName);
    final habitMap = box.get(id);
    if (habitMap != null) {
      final habit = Habit.fromMap(Map<dynamic, dynamic>.from(habitMap));
      final String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final newLog = Map<String, double>.from(habit.completionLog);
      newLog[dateKey] = value;
      await box.put(id, habit.copyWith(completionLog: newLog).toMap());
    }
  }

  Widget _buildHabitSection({required String title, required List<Habit> habits, required HabitGoal goal, Key? key}) {
    final metadata = HabitService.getSectionMetadata(goal);
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HabitSectionScreen(goal: goal))).then((_) => _loadHabits()),
        leading: Text(metadata['emoji'] ?? '', style: const TextStyle(fontSize: 24)),
        title: Text(
          metadata['title'] ?? title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(metadata['color'] ?? 0xFF000000),
          ),
        ),
        subtitle: Text('عدد العادات: ${habits.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              onSelected: (val) {
                if (val == 'edit') _showEditSectionDialog(goal);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('تعديل القسم', style: TextStyle(fontSize: 12))])),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showEditPageNameDialog() async {
    // Find the page item for habits
    final pages = PageManagementService.getAllPages();
    final page = pages.firstWhere((p) => p.id == 'habits', orElse: () => PageItem(id: 'habits', name: 'العادات', route: '', iconData: '✅', sectionKey: 'discipline'));

    final nameController = TextEditingController(text: page.name);
    final iconController = TextEditingController(text: page.iconData);

    ModernDialog.show(
      context: context,
      title: 'تعديل اسم الصفحة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصفحة')),
          const SizedBox(height: 12),
          TextField(controller: iconController, decoration: const InputDecoration(labelText: 'الأيقونة (إيموجي)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              page.name = nameController.text;
              page.iconData = iconController.text;
              await PageManagementService.savePage(page);
              if (mounted) Navigator.pop(context);
              setState(() {});
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _showEditSectionDialog(HabitGoal goal) {
    final metadata = HabitService.getSectionMetadata(goal);
    final titleController = TextEditingController(text: metadata['title']);
    final emojiController = TextEditingController(text: metadata['emoji']);
    int selectedColor = metadata['color'];

    ModernDialog.show(
      context: context,
      title: 'تعديل القسم',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'اسم القسم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: 'إيموجي القسم'),
              ),
              const SizedBox(height: 16),
              const Text('اختر اللون:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Color(0xFF0F3D2E),
                  Colors.green,
                  Colors.red,
                  Colors.blue,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.brown,
                  Colors.pink,
                  Colors.amber,
                  Colors.cyan,
                  Colors.indigo,
                  Colors.lime,
                  Colors.deepOrange,
                  Colors.deepPurple,
                  Colors.lightBlue,
                  Colors.lightGreen,
                  Colors.blueGrey,
                  const Color(0xFFC8A24A),
                  Colors.grey,
                  Colors.black,
                ].map((color) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color.value),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: color,
                    child: selectedColor == color.value
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          onPressed: () async {
            await HabitService.saveSectionMetadata(goal, {
              'title': titleController.text,
              'emoji': emojiController.text,
              'color': selectedColor,
            });
            Navigator.pop(context);
            setState(() {});
          },
          child: const Text('حفظ التغييرات'),
        ),
      ],
    );
  }

  void _showBulkAddDialog() {
    final textController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    HabitGoal selectedGoal = HabitGoal.good;

    ModernDialog.show(
      context: context,
      title: 'إضافة متعددة للعادات',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل العادات (واحدة في كل سطر). يمكنك استخدام الصيغة: "اسم العادة - نقاط"',
                  style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'شرب الماء - 15\nقراءة سورة الملك\nمذاكرة ساعة - 50',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: ThemeService.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'نقاط افتراضية', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<HabitGoal>(
                      value: selectedGoal,
                      decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: HabitGoal.good, child: Text('جيدة')),
                        DropdownMenuItem(value: HabitGoal.bad, child: Text('سيئة')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedGoal = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F3D2E), foregroundColor: Colors.white),
          onPressed: () async {
            final lines = textController.text.split('\n');
            int defaultPoints = int.tryParse(pointsController.text) ?? 10;
            int count = 0;
            final userId = UserService.currentUser?.id;
            if (userId == null) return;

            for (var line in lines) {
              final clean = line.trim();
              if (clean.isEmpty) continue;

              String name = clean;
              int points = defaultPoints;

              if (clean.contains('-')) {
                final parts = clean.split('-');
                name = parts[0].trim();
                points = int.tryParse(parts[parts.length - 1].trim()) ?? defaultPoints;
              }

              final habit = Habit(
                id: const Uuid().v4(),
                userId: userId,
                name: name,
                type: HabitType.fixed,
                goal: selectedGoal,
                basePoints: points,
                recurrence: RecurrenceType.daily,
                createdAt: DateTime.now(),
                orderIndex: _habits.length + count,
              );
              await HabitService.saveHabit(habit);
              count++;
            }

            if (mounted) {
              Navigator.pop(context);
              _loadHabits();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة $count عادة بنجاح')));
            }
          },
          child: const Text('إضافة الكل'),
        ),
      ],
    );
  }
}
