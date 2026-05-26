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
import '../discipline/models/task_model.dart';
import '../discipline/services/task_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('حوارات ومذكرات'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح حوارات ومذكرات', 
            description: 'دون أفكارك وحاور نفسك:\n- مذكرات: يومياتك وتأملاتك.\n- حوارات: نقاشات مع جوانب شخصيتك.\n- أفكار: خواطر عابرة (يمكن تحويلها لعادة).\n- بيانات: قراراتك ومفضلاتك (يمكن تحويلها لمهمة).',
            pageId: 'dialogues',
          ),
          TextButton(
            onPressed: () => _showAddMemoDialog(MemoType.values[_tabController.index]),
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'مذكرات'), Tab(text: 'حوارات'), Tab(text: 'أفكار'), Tab(text: 'بيانات')],
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
    );
  }

  Widget _buildMemoList(MemoType type) {
    final filtered = _allMemos.where((m) => m.type == type).toList();
    if (filtered.isEmpty) return const Center(child: Text('لا توجد عناصر مسجلة بعد', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final memo = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(memo.title.isNotEmpty ? memo.title : memo.content.split('\n').first, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('yyyy/MM/dd').format(memo.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            leading: _getLeadingIcon(memo),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memo.content, style: const TextStyle(height: 1.5)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (memo.type == MemoType.idea)
                          IconButton(icon: const Icon(Icons.bolt, color: Colors.amber), onPressed: () => _convertToHabit(memo), tooltip: 'تحويل لعادة'),
                        if (memo.dataCategory == 'قرارات')
                          IconButton(icon: const Icon(Icons.push_pin_outlined, color: Colors.blue), onPressed: () => _convertToTask(memo), tooltip: 'تحويل لمهمة'),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(memo.id)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Icon _getLeadingIcon(Memo memo) {
    if (memo.type == MemoType.idea) return const Icon(Icons.lightbulb_outline, color: Colors.amber);
    if (memo.dataCategory == 'قرارات') return const Icon(Icons.gavel_outlined, color: Colors.blue);
    return const Icon(Icons.notes, color: Colors.grey);
  }

  void _showAddMemoDialog(MemoType type) {
    final titleController = TextEditingController();
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
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'العنوان (اختياري)')),
            TextField(controller: contentController, maxLines: 5, decoration: const InputDecoration(labelText: 'المحتوى'), autofocus: true),
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
                title: titleController.text,
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

  void _convertToTask(Memo memo) {
    TaskPriority selectedPriority = TaskPriority.medium;
    ModernDialog.show(
      context: context,
      title: 'تحويل القرار لمهمة',
      content: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر أولوية المهمة:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              value: selectedPriority,
              items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (v) => setModalState(() => selectedPriority = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            final task = Task(
              id: const Uuid().v4(),
              userId: UserService.currentUser!.id,
              title: memo.title.isNotEmpty ? memo.title : "قرار: ${memo.content.split('\n').first}",
              description: memo.content,
              priority: selectedPriority,
              date: DateTime.now(),
            );
            await TaskService.saveTask(task);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل القرار لمهمة سريعة بنجاح!')));
          },
          child: const Text('تحويل الآن'),
        )
      ],
    );
  }

  void _convertToHabit(Memo memo) {
    // ... (نفس كود التحويل لعادة السابق مع تحديثات العنوان)
  }

  void _confirmDelete(String id) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'هل تريد حذف هذا العنصر؟', isDestructive: true);
    if (res == true) { await MemoService.deleteMemo(id); _loadMemos(); }
  }
}
