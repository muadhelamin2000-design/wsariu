import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models/task_model.dart';
import 'services/task_service.dart';
import '../profile/services/user_service.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/widgets/modern_dialog.dart';

class QuickTasksScreen extends StatefulWidget {
  const QuickTasksScreen({super.key});

  @override
  State<QuickTasksScreen> createState() => _QuickTasksScreenState();
}

class _QuickTasksScreenState extends State<QuickTasksScreen> with HelpFeatureMixin {
  List<Task> _tasks = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    checkFirstTimeHelp(context, 'tasks');
  }

  void _loadTasks() {
    setState(() {
      _tasks = TaskService.getTasks();
    });
  }

  void _showAddTaskSheet({Task? task}) {
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
    DateTime selectedDate = task?.date ?? DateTime.now();
    List<DateTime> reminders = List.from(task?.reminderTimes ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernDialog(
        title: isEdit ? 'تعديل مهمة' : 'تدوين مهمة سريعة',
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
                    labelText: 'عنوان المهمة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController, 
                  decoration: InputDecoration(
                    labelText: 'وصف إضافي (اختياري)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('الأولوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _priorityChip(setSheetState, TaskPriority.urgent, 'عاجل', Colors.red, selectedPriority, (p) => selectedPriority = p),
                    _priorityChip(setSheetState, TaskPriority.medium, 'متوسط', Colors.amber, selectedPriority, (p) => selectedPriority = p),
                    _priorityChip(setSheetState, TaskPriority.low, 'منخفض', Colors.green, selectedPriority, (p) => selectedPriority = p),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 18),
                  title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setSheetState(() => selectedDate = picked);
                  },
                ),
                const Text('التذكيرات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ...reminders.map((r) => Chip(
                      label: Text(DateFormat('HH:mm').format(r)),
                      onDeleted: () => setSheetState(() => reminders.remove(r)),
                    )),
                    ActionChip(
                      avatar: const Icon(Icons.alarm, size: 14),
                      label: const Text('إضافة تذكير'),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) {
                          setSheetState(() {
                            reminders.add(DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute));
                          });
                        }
                      },
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            onPressed: () async {
              if (titleController.text.isEmpty || UserService.currentUser == null) return;
              final newTask = Task(
                id: task?.id ?? const Uuid().v4(),
                userId: UserService.currentUser!.id,
                title: titleController.text,
                description: descController.text,
                priority: selectedPriority,
                date: selectedDate,
                reminderTimes: reminders,
                isCompleted: task?.isCompleted ?? false,
              );
              await TaskService.saveTask(newTask);
              if (mounted) {
                Navigator.pop(context);
                _loadTasks();
              }
            },
            child: const Text('حفظ المهمة'),
          ),
        ],
      ),
    );
  }

  void _showBulkChangePriority() async {
    TaskPriority? selected;
    ModernDialog.show(
      context: context,
      title: 'تغيير الأولوية',
      content: StatefulBuilder(
        builder: (context, setModalState) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _priorityChip(setModalState, TaskPriority.urgent, 'عاجل', Colors.red, selected ?? TaskPriority.medium, (p) => selected = p),
            _priorityChip(setModalState, TaskPriority.medium, 'متوسط', Colors.amber, selected ?? TaskPriority.medium, (p) => selected = p),
            _priorityChip(setModalState, TaskPriority.low, 'منخفض', Colors.green, selected ?? TaskPriority.medium, (p) => selected = p),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (selected != null) {
              for (var id in _selectedIds) {
                final task = _tasks.firstWhere((t) => t.id == id);
                await TaskService.saveTask(task.copyWith(priority: selected));
              }
              Navigator.pop(context);
              setState(() => _selectedIds.clear());
              _loadTasks();
            }
          },
          child: const Text('تغيير'),
        ),
      ],
    );
  }

  void _showBulkChangeDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      for (var id in _selectedIds) {
        final task = _tasks.firstWhere((t) => t.id == id);
        await TaskService.saveTask(task.copyWith(date: picked));
      }
      setState(() => _selectedIds.clear());
      _loadTasks();
    }
  }

  void _bulkDelete() async {
    final res = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف محدد',
      message: 'هل تريد حذف ${_selectedIds.length} مهمة بشكل نهائي؟',
      isDestructive: true,
    );
    if (res == true) {
      for (var id in _selectedIds) {
        await TaskService.deleteTask(id);
      }
      setState(() => _selectedIds.clear());
      _loadTasks();
    }
  }

  Widget _priorityChip(StateSetter setSheetState, TaskPriority p, String label, Color color, TaskPriority selected, Function(TaskPriority) onSelected) {
    bool isSelected = selected == p;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      onSelected: (val) { if (val) setSheetState(() => onSelected(p)); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_isSelectionMode || _selectedIds.isNotEmpty)
        ? AppBar(
            backgroundColor: const Color(0xFFC8A24A),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white), 
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              })
            ),
            title: FittedBox(fit: BoxFit.scaleDown, child: Text(_selectedIds.isEmpty ? 'تحديد المهام' : '${_selectedIds.length} محدد', style: const TextStyle(color: Colors.white))),
            actions: [
              if (_selectedIds.isNotEmpty) ...[
                IconButton(icon: const Icon(Icons.priority_high, color: Colors.white), onPressed: _showBulkChangePriority, tooltip: 'تغيير الأولوية'),
                IconButton(icon: const Icon(Icons.calendar_today, color: Colors.white), onPressed: _showBulkChangeDate, tooltip: 'تغيير التاريخ'),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _bulkDelete, tooltip: 'حذف المحدد'),
              ],
            ],
          )
        : AppBar(
            title: const Text('المهام السريعة', style: TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
            centerTitle: false,
            titleSpacing: 0,
            actions: [
              buildHelpButton(
                context, 
                title: 'شرح المهام السريعة', 
                description: 'أفضل طريقة لإنجاز مهامك اليومية:\n'
                '- أضف مهاماً بضغطة زر.\n'
                '- حدد أولوية المهمة (منخفضة، متوسطة، عالية).\n'
                '- يمكنك إضافة تذكيرات للمهمة.\n'
                '- المهمة تكتمل بالضغط على الدائرة بجانبها.'
              ),
              IconButton(
                icon: const Icon(Icons.checklist_rtl),
                onPressed: () => setState(() => _isSelectionMode = true),
                tooltip: 'وضع التحديد',
              ),
              TextButton(
                onPressed: () => _showAddTaskSheet(),
                child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(),
        label: const Text('إضافة'),
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'tasks'),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('لا يوجد مهام حالياً'))
                : ReorderableListView(
                    padding: const EdgeInsets.all(16),
                    onReorder: (oldIndex, newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _tasks.removeAt(oldIndex);
                        _tasks.insert(newIndex, item);
                      });
                      await TaskService.saveTasksOrder(_tasks);
                    },
                    children: _tasks.map((task) => _buildTaskCard(task, key: ValueKey(task.id))).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, TaskPriority p) {
    final sectionTasks = _tasks.where((t) => t.priority == p).toList();
    if (sectionTasks.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...sectionTasks.map((task) => _buildTaskCard(task)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskCard(Task task, {Key? key}) {
    final isSelected = _selectedIds.contains(task.id);
    return ReorderableDelayedDragStartListener(
      key: key,
      index: _tasks.indexOf(task),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        color: isSelected ? const Color(0xFFC8A24A).withValues(alpha: 0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(color: isSelected ? const Color(0xFFC8A24A) : Colors.grey.shade200, width: isSelected ? 2 : 1)
        ),
        child: InkWell(
          onLongPress: null, // Reserved for dragging
          onTap: (_isSelectionMode || _selectedIds.isNotEmpty)
            ? () => setState(() => isSelected ? _selectedIds.remove(task.id) : _selectedIds.add(task.id))
            : null,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            leading: (_isSelectionMode || _selectedIds.isNotEmpty)
              ? Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: const Color(0xFFC8A24A))
              : Checkbox(
                  value: task.isCompleted,
                  activeColor: task.priorityColor,
                  onChanged: (val) async {
                    await TaskService.toggleTaskStatus(task.id);
                    _loadTasks();
                  },
                ),
            title: Text(task.title, style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold,
            )),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(task.date)),
            trailing: (_isSelectionMode || _selectedIds.isNotEmpty) ? null : IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(leading: const Icon(Icons.edit_note), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showAddTaskSheet(task: task); }),
                      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('حذف'), onTap: () async {
                        await TaskService.deleteTask(task.id);
                        Navigator.pop(context);
                        _loadTasks();
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
