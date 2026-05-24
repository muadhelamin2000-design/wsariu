import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/memo_model.dart';
import 'services/memo_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../discipline/models/habit_model.dart';
import '../discipline/services/habit_service.dart';
import 'package:intl/intl.dart';

import '../../core/mixins/help_feature_mixin.dart';

class DialoguesScreen extends StatefulWidget {
  const DialoguesScreen({super.key});

  @override
  State<DialoguesScreen> createState() => _DialoguesScreenState();
}

class _DialoguesScreenState extends State<DialoguesScreen> with SingleTickerProviderStateMixin, HelpFeatureMixin {
  late TabController _tabController;
  List<Memo> _allMemos = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMemos();
    checkFirstTimeHelp(context, 'dialogues');
  }

  void _loadMemos() {
    setState(() {
      _allMemos = MemoService.getAllMemos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('dialogues');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('حوارات ومذكرات'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح حوارات ومذكرات', 
            description: 'دون أفكارك وحاور نفسك للوصول للحقيقة:\n'
            '- سجل المذكرات اليومية (دوافع، نتائج، تأملات).\n'
            '- ابدأ حوارات مع جوانب شخصيتك (العقل، القلب، النفس).\n'
            '- استخدم الفئات المختلفة لتنظيم أفكارك.',
            pageId: 'dialogues',
          ),
          TextButton(
            onPressed: () => _showAddMemoDialog(MemoType.values[_tabController.index]),
            child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'مذكرات'),
            Tab(text: 'حوارات'),
            Tab(text: 'أفكار'),
            Tab(text: 'بيانات'),
          ],
        ),
      ),
      body: Column(
        children: [
          const QuickLinkNavigator(currentPageId: 'dialogues'),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMemoList(MemoType.memo),
                _buildMemoList(MemoType.dialogue),
                _buildMemoList(MemoType.idea),
                _buildMemoList(MemoType.data),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemoDialog(MemoType.values[_tabController.index]),
        backgroundColor: AppTheme.primaryGreen,
        label: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildMemoList(MemoType type) {
    final filtered = _allMemos.where((m) => m.type == type).toList();
    
    if (filtered.isEmpty) {
      return Center(child: Text('لا توجد عناصر مسجلة بعد', style: TextStyle(color: Colors.grey.shade400)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final memo = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(memo.content, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (memo.type == MemoType.data)
                   Text('التصنيف: ${memo.dataCategory}', style: const TextStyle(color: Colors.blue, fontSize: 11)),
                Text(DateFormat('yyyy/MM/dd').format(memo.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (memo.type == MemoType.idea)
                  IconButton(icon: const Icon(Icons.bolt, color: Colors.amber), onPressed: () => _convertToHabit(memo), tooltip: 'تحويل لعادة'),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(memo.id)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMemoDialog(MemoType type) {
    final contentController = TextEditingController();
    String selectedDataCat = 'مكافآت';
    final List<String> dataCats = ['مكافآت', 'عواقب', 'قرارات', 'مفضلات', 'صعوبات'];

    ModernDialog.show(
      context: context,
      title: 'إضافة جديد',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == MemoType.data)
              DropdownButtonFormField<String>(
                value: selectedDataCat,
                items: dataCats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => selectedDataCat = val!),
                decoration: const InputDecoration(labelText: 'نوع البيانات'),
              ),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'اكتب هنا...', border: OutlineInputBorder()),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (contentController.text.isNotEmpty && UserService.currentUser != null) {
              final memo = Memo(
                id: const Uuid().v4(),
                userId: UserService.currentUser!.id,
                content: contentController.text,
                date: DateTime.now(),
                type: type,
                dataCategory: type == MemoType.data ? selectedDataCat : null,
              );
              await MemoService.saveMemo(memo);
              _loadMemos();
              Navigator.pop(context);
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _confirmDelete(String id) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'هل تريد حذف هذا العنصر؟', isDestructive: true);
    if (res == true) {
      await MemoService.deleteMemo(id);
      _loadMemos();
    }
  }

  void _convertToHabit(Memo memo) {
    final titleController = TextEditingController(text: memo.content);
    final pointsController = TextEditingController(text: '10');
    final unitController = TextEditingController(text: 'مرة');
    
    HabitGoal selectedGoal = HabitGoal.good;
    HabitType selectedType = HabitType.fixed;
    RecurrenceType selectedRecurrence = RecurrenceType.daily;
    TimeOfDay? selectedTime;

    ModernDialog.show(
      context: context,
      title: 'تحويل إلى عادة',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController, 
                decoration: const InputDecoration(labelText: 'اسم العادة'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitGoal>(
                value: selectedGoal,
                items: const [DropdownMenuItem(value: HabitGoal.good, child: Text('عادة جيدة')), DropdownMenuItem(value: HabitGoal.bad, child: Text('عادة سيئة'))],
                onChanged: (val) => setDialogState(() => selectedGoal = val!),
                decoration: const InputDecoration(labelText: 'النوع'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitType>(
                value: selectedType,
                items: const [DropdownMenuItem(value: HabitType.fixed, child: Text('نقاط ثابتة')), DropdownMenuItem(value: HabitType.variable, child: Text('قيمة متغيرة'))],
                onChanged: (val) => setDialogState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: 'طريقة الحساب'),
              ),
              const SizedBox(height: 12),
              TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'النقاط'), keyboardType: TextInputType.number),
              if (selectedType == HabitType.variable)
                 TextField(controller: unitController, decoration: const InputDecoration(labelText: 'اسم الوحدة (دقيقة، صفحة...)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrenceType>(
                value: selectedRecurrence,
                items: const [DropdownMenuItem(value: RecurrenceType.daily, child: Text('يومياً')), DropdownMenuItem(value: RecurrenceType.specificDays, child: Text('أيام محددة'))],
                onChanged: (val) => setDialogState(() => selectedRecurrence = val!),
                decoration: const InputDecoration(labelText: 'التكرار'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(selectedTime == null ? 'ضبط وقت (اختياري)' : 'الوقت: ${selectedTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) setDialogState(() => selectedTime = picked);
                },
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
            if (titleController.text.isNotEmpty && UserService.currentUser != null) {
               final habit = Habit(
                 id: const Uuid().v4(),
                 userId: UserService.currentUser!.id,
                 name: titleController.text,
                 type: selectedType,
                 goal: selectedGoal,
                 basePoints: int.tryParse(pointsController.text) ?? 10,
                 unitName: selectedType == HabitType.variable ? unitController.text : null,
                 recurrence: selectedRecurrence,
                 createdAt: DateTime.now(),
                 reminderHour: selectedTime?.hour,
                 reminderMinute: selectedTime?.minute,
               );
               await HabitService.saveHabit(habit);
               if (mounted) {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل الفكرة إلى عادة بنجاح!')));
               }
            }
          },
          child: const Text('إنشاء العادة الآن'),
        ),
      ],
    );
  }
}
