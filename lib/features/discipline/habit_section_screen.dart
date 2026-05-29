import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models/habit_model.dart';
import 'services/habit_service.dart';
import '../dashboard/services/prayer_service.dart';
import '../profile/services/user_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import 'habit_detail_screen.dart';
import '../../core/app_theme.dart';

enum HabitSortType { manual, alphabetical, consistency }

class HabitSectionScreen extends StatefulWidget {
  final HabitGoal goal;
  const HabitSectionScreen({super.key, required this.goal});

  @override
  State<HabitSectionScreen> createState() => _HabitSectionScreenState();
}

class _HabitSectionScreenState extends State<HabitSectionScreen> {
  List<Habit> _habits = [];
  HabitSortType _sortType = HabitSortType.manual;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() {
    var all = HabitService.getHabits().where((h) => h.goal == widget.goal).toList();
    
    switch (_sortType) {
      case HabitSortType.alphabetical:
        all.sort((a, b) => a.name.compareTo(b.name));
        break;
      case HabitSortType.consistency:
        all.sort((a, b) => b.commitmentRate.compareTo(a.commitmentRate));
        break;
      case HabitSortType.manual:
        all.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        break;
    }
    
    setState(() => _habits = all);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final metadata = HabitService.getSectionMetadata(widget.goal);

    return Scaffold(
      appBar: AppBar(
        title: Text('${metadata['emoji']} ${metadata['title']}'),
        actions: [
          TextButton(
            onPressed: () => _showAddEditHabitSheet(),
            child: const Text('إضافة عادة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          PopupMenuButton<HabitSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (val) {
              setState(() => _sortType = val);
              _loadHabits();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: HabitSortType.manual, child: Text('ترتيب يدوي')),
              const PopupMenuItem(value: HabitSortType.alphabetical, child: Text('ترتيب أبجدي')),
              const PopupMenuItem(value: HabitSortType.consistency, child: Text('حسب المواظبة')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: _confirmResetSection,
            tooltip: 'تصفير القسم',
          ),
        ],
      ),
      body: _habits.isEmpty
          ? const Center(child: Text('لا توجد عادات في هذا القسم'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _habits.length,
              onReorder: (oldIndex, newIndex) async {
                if (_sortType != HabitSortType.manual) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب اختيار "ترتيب يدوي" لتغيير الترتيب بسحب العناصر')));
                  return;
                }
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _habits.removeAt(oldIndex);
                  _habits.insert(newIndex, item);
                });
                // Save global order
                final allHabits = HabitService.getHabits();
                for (var h in _habits) {
                  final idx = allHabits.indexWhere((it) => it.id == h.id);
                  if (idx != -1) {
                    allHabits[idx] = h.copyWith(orderIndex: _habits.indexOf(h));
                  }
                }
                await HabitService.saveHabitsOrder(allHabits);
              },
              itemBuilder: (context, index) => _buildHabitCard(_habits[index], index),
            ),
    );
  }

  Widget _buildHabitCard(Habit habit, int index) {
    DateTime today = PrayerService.getIslamicDayDate();
    String dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    double currentValue = habit.completionLog[dateKey] ?? 0;
    bool isCompletedToday = currentValue > 0;
    bool isBad = habit.goal == HabitGoal.bad;

    return Card(
      key: ValueKey(habit.id),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HabitDetailScreen(habit: habit))).then((_) => _loadHabits()),
          leading: habit.type == HabitType.fixed
              ? Checkbox(
                  value: isCompletedToday,
                  activeColor: Color(habit.colorValue),
                  onChanged: (val) async {
                    await HabitService.toggleHabitCompletion(habit.id, DateTime.now(), 1.0);
                    _loadHabits();
                  },
                )
              : SizedBox(
                  width: 50,
                  height: 35,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: currentValue > 0 ? '${currentValue.toInt()}' : '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الالتزام: ${habit.commitmentRate.toInt()}% | Streak: ${habit.currentStreak} 🔥', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text('النقاط: ${habit.calculatePoints(today).toInt().abs()}', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isBad ? Colors.red : const Color(0xFFC8A24A))),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (val) {
              if (val == 'edit') _showAddEditHabitSheet(habit: habit);
              if (val == 'delete') _confirmDelete(habit.id);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('تعديل', style: TextStyle(fontSize: 12))])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('حذف', style: TextStyle(fontSize: 12, color: Colors.red))])),
            ],
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
    final targetController = TextEditingController(text: habit?.dailyTarget?.toInt().toString() ?? '');
    final messageController = TextEditingController(text: habit?.customReminderMessage ?? '');
    final flexCountController = TextEditingController(text: habit?.flexibleCount?.toString() ?? '3');
    final intervalController = TextEditingController(text: habit?.intervalValue.toString() ?? '1');

    HabitType selectedType = habit?.type ?? HabitType.fixed;
    HabitGoal selectedGoal = habit?.goal ?? widget.goal;
    RecurrenceType selectedRecurrence = habit?.recurrence ?? RecurrenceType.daily;
    ReminderType selectedReminderType = habit?.reminderType ?? ReminderType.fixed;
    
    List<int> selectedDays = List<int>.from(habit?.specificDays ?? []);
    TimeOfDay? selectedTime = habit?.reminderTime;
    TimeOfDay? flexStartTime = habit?.flexibleStartTime ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? flexEndTime = habit?.flexibleEndTime ?? const TimeOfDay(hour: 22, minute: 0);
    String? selectedPrayer = habit?.linkedPrayer;
    
    int selectedColorValue = habit?.colorValue ?? 0xFF0F3D2E;
    final isDark = ThemeService.isDarkMode;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل عادة' : 'تدوين عادة جديدة',
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم العادة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<HabitType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'النوع'),
                      items: const [
                        DropdownMenuItem(value: HabitType.fixed, child: Text('ثابتة')),
                        DropdownMenuItem(value: HabitType.variable, child: Text('متغيرة')),
                      ],
                      onChanged: (v) => setSheetState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<HabitGoal>(
                      value: selectedGoal,
                      decoration: const InputDecoration(labelText: 'التصنيف'),
                      items: const [
                        DropdownMenuItem(value: HabitGoal.good, child: Text('جيدة')),
                        DropdownMenuItem(value: HabitGoal.bad, child: Text('سيئة')),
                      ],
                      onChanged: (v) => setSheetState(() => selectedGoal = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الهدف اليومي (مثلاً: 3 لتر)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RecurrenceType>(
                value: selectedRecurrence,
                decoration: const InputDecoration(labelText: 'نظام التكرار'),
                items: const [
                  DropdownMenuItem(value: RecurrenceType.daily, child: Text('يومياً')),
                  DropdownMenuItem(value: RecurrenceType.everyOtherDay, child: Text('يوم ويوم')),
                  DropdownMenuItem(value: RecurrenceType.specificDays, child: Text('أيام محددة')),
                  DropdownMenuItem(value: RecurrenceType.interval, child: Text('كل عدد من الأيام')),
                ],
                onChanged: (v) => setSheetState(() => selectedRecurrence = v!),
              ),
              if (selectedRecurrence == RecurrenceType.specificDays) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: List.generate(7, (index) {
                    final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
                    bool isSelected = selectedDays.contains(index);
                    return ChoiceChip(
                      label: Text(days[index], style: const TextStyle(fontSize: 10)),
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
              
              const SizedBox(height: 24),
              const Text('نظام التذكير الذكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderType>(
                value: selectedReminderType,
                decoration: const InputDecoration(labelText: 'نوع التذكير'),
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
                  title: Text(selectedTime == null ? 'ضبط وقت التذكير' : 'موعد: ${selectedTime!.format(context)}'),
                  trailing: const Icon(Icons.keyboard_arrow_left, size: 14),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
                    if (picked != null) setSheetState(() => selectedTime = picked);
                  },
                )
              else if (selectedReminderType == ReminderType.prayer)
                DropdownButtonFormField<String>(
                  value: selectedPrayer,
                  decoration: const InputDecoration(labelText: 'اختر الصلاة'),
                  items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSheetState(() => selectedPrayer = v!),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('البداية', style: TextStyle(fontSize: 10)),
                        subtitle: Text(flexStartTime?.format(context) ?? '--:--'),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: flexStartTime ?? TimeOfDay.now());
                          if (p != null) setSheetState(() => flexStartTime = p);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('النهاية', style: TextStyle(fontSize: 10)),
                        subtitle: Text(flexEndTime?.format(context) ?? '--:--'),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: flexEndTime ?? TimeOfDay.now());
                          if (p != null) setSheetState(() => flexEndTime = p);
                        },
                      ),
                    ),
                  ],
                ),
                TextField(controller: flexCountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد مرات التذكير')),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'رسالة التذكير المخصصة (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'النقاط'),
              ),
              const SizedBox(height: 20),
              const Text('اختر اللون:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.expandedColors.length,
                  itemBuilder: (context, idx) {
                    final color = AppTheme.expandedColors[idx];
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColorValue = color.value),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColorValue == color.value ? Border.all(color: Colors.white, width: 2) : null),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          onPressed: () async {
            if (nameController.text.isEmpty || UserService.currentUser == null) return;
            final newHabit = Habit(
              id: habit?.id ?? const Uuid().v4(),
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
              orderIndex: habit?.orderIndex ?? _habits.length,
            );
            await HabitService.saveHabit(newHabit);
            Navigator.pop(context);
            _loadHabits();
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

  void _confirmResetSection() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير القسم',
      message: 'هل أنت متأكد من مسح سجل الإنجاز لجميع العادات في هذا القسم فقط؟',
      confirmLabel: 'تصفير الآن',
      isDestructive: true,
    );
    if (result == true) {
      for (var h in _habits) {
        await HabitService.resetHabitCompletion(h.id);
      }
      _loadHabits();
    }
  }
}
