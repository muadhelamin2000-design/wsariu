import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/incremental_habit_model.dart';
import 'services/incremental_habit_service.dart';
import '../profile/services/user_service.dart';
import '../dashboard/services/prayer_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';

import '../../core/mixins/help_feature_mixin.dart';

class IncrementalHabitsScreen extends StatefulWidget {
  const IncrementalHabitsScreen({super.key});

  @override
  State<IncrementalHabitsScreen> createState() => _IncrementalHabitsScreenState();
}

class _IncrementalHabitsScreenState extends State<IncrementalHabitsScreen> with HelpFeatureMixin {
  List<IncrementalHabit> _habits = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadHabits();
    checkFirstTimeHelp(context, 'incremental');
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadHabits() {
    setState(() {
      _habits = IncrementalHabitService.getHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('incremental');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('وتزودوا (عادات تصاعدية)'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح قسم وتزودوا', 
            description: 'هذا القسم مخصص لبناء العادات بالتدرج:\n'
            '- أضف تحدياً جديداً (مثل: قيام الليل، قراءة القرآن).\n'
            '- حدد البداية، الهدف النهائي، ومقدار الزيادة الدورية.\n'
            '- النظام سيقوم بزيادة المستهدف تلقائياً بناءً على جدولك.\n'
            '- اضغط (+) عند الإنجاز لرفع نقاطك.',
            pageId: 'incremental',
          ),
          TextButton(
            onPressed: () => _showAddHabitSheet(),
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'incremental'),
          Expanded(
            child: _habits.isEmpty
                ? const Center(child: Text('ابدأ بإضافة عادة تصاعدية جديدة'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _habits.length,
                    onReorder: (oldIndex, newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _habits.removeAt(oldIndex);
                        _habits.insert(newIndex, item);
                      });
                      await IncrementalHabitService.saveHabitsOrder(_habits);
                    },
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
                      return _buildHabitCard(habit, key: ValueKey(habit.id));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(IncrementalHabit habit, {Key? key}) {
    final today = PrayerService.getIslamicDayDate();
    final target = habit.getTargetForDate(today);
    final achieved = habit.getAchievedOn(today);
    final progress = achieved / (target > 0 ? target : 1);
    final TextEditingController inputController = _controllers.putIfAbsent(habit.id, () => TextEditingController());
    final isDark = ThemeService.isDarkMode;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('الهدف اليومي: ${target.toInt()} ${habit.unit}', 
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue, size: 20),
                      onPressed: () => _showAddHabitSheet(habit: habit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(habit.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(habit.color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${achieved.toInt()} / ${target.toInt()} ${habit.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 35,
                      child: TextField(
                        controller: inputController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: habit.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 35),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final val = double.tryParse(inputController.text);
                        if (val != null && val > 0) {
                          _updateProgress(habit.id, val);
                          inputController.clear();
                        }
                      },
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('يزداد كل ${habit.daysBetweenIncrements} أيام بمقدار ${habit.incrementValue.toInt()}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            if (habit.reminderTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('التنبيه: ${habit.reminderTime!.format(context)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateProgress(String id, double delta) async {
    await IncrementalHabitService.updateProgress(id, DateTime.now(), delta);
    _loadHabits();
  }

  void _showCustomUpdateDialog(IncrementalHabit habit) async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إضافة إلى ${habit.title}',
      hint: 'المقدار بالـ ${habit.unit}',
    );
    if (result != null) {
      final val = double.tryParse(result);
      if (val != null) {
        _updateProgress(habit.id, val);
      }
    }
  }

  void _showAddHabitSheet({IncrementalHabit? habit}) {
    final isEdit = habit != null;
    final titleController = TextEditingController(text: habit?.title ?? '');
    final startController = TextEditingController(text: habit?.startValue.toInt().toString() ?? '');
    final targetController = TextEditingController(text: habit?.targetValue.toInt().toString() ?? '');
    final incrementController = TextEditingController(text: habit?.incrementValue.toInt().toString() ?? '');
    final daysController = TextEditingController(text: habit?.daysBetweenIncrements.toString() ?? '1');
    final unitController = TextEditingController(text: habit?.unit ?? '');
    int selectedColor = habit?.colorValue ?? 0xFF0F3D2E;
    TimeOfDay? selectedTime = habit?.reminderTime;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل التحدي' : 'بدء تحدي تصاعدي',
      accentColor: const Color(0xFFC8A24A),
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController, 
                decoration: InputDecoration(
                  labelText: 'اسم العادة (مثلاً: قيام الليل)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController, 
                decoration: InputDecoration(
                  labelText: 'الوحدة (مثلاً: دقائق، ذكر)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: startController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'البداية من'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الهدف النهائي'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: incrementController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الزيادة'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: daysController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كل كم يوم؟'))),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: Color(0xFFC8A24A)),
                title: Text(selectedTime == null ? 'ضبط منبه للتذكير' : 'وقت التذكير: ${selectedTime!.format(context)}'),
                trailing: selectedTime != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setSheetState(() => selectedTime = null)) : const Icon(Icons.keyboard_arrow_left, size: 14),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
                  if (p != null) setSheetState(() => selectedTime = p);
                },
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
                      onTap: () => setSheetState(() => selectedColor = c.value),
                      child: CircleAvatar(radius: 15, backgroundColor: c, child: selectedColor == c.value ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
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
            if (titleController.text.isEmpty || UserService.currentUser == null) return;
            final newHabit = IncrementalHabit(
              id: habit?.id ?? const Uuid().v4(),
              userId: UserService.currentUser!.id,
              title: titleController.text,
              startValue: double.tryParse(startController.text) ?? 0,
              targetValue: double.tryParse(targetController.text) ?? 100,
              incrementValue: double.tryParse(incrementController.text) ?? 1,
              daysBetweenIncrements: int.tryParse(daysController.text) ?? 1,
              unit: unitController.text,
              createdAt: habit?.createdAt ?? DateTime.now(),
              executionLog: habit?.executionLog ?? {},
              colorValue: selectedColor,
              reminderHour: selectedTime?.hour,
              reminderMinute: selectedTime?.minute,
            );
            await IncrementalHabitService.saveHabit(newHabit);
            if (mounted) {
              Navigator.pop(context);
              _loadHabits();
            }
          },
          child: Text(isEdit ? 'حفظ التعديلات' : 'بدء التحدي الآن'),
        ),
      ],
    );
  }

  void _confirmDelete(String id) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف التحدي',
      message: 'هل أنت متأكد من حذف هذه العادة التصاعدية؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await IncrementalHabitService.deleteHabit(id);
      _loadHabits();
    }
  }
}
