import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models/worship_model.dart';
import 'services/worship_service.dart';
import '../dashboard/services/prayer_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../discipline/models/habit_model.dart';
import 'worship_item_detail_screen.dart';

enum WorshipSortType { manual, alphabetical, consistency }

class WorshipSectionItemsScreen extends StatefulWidget {
  final WorshipSection section;
  const WorshipSectionItemsScreen({super.key, required this.section});

  @override
  State<WorshipSectionItemsScreen> createState() => _WorshipSectionItemsScreenState();
}

class _WorshipSectionItemsScreenState extends State<WorshipSectionItemsScreen> {
  List<WorshipItem> _items = [];
  WorshipSortType _sortType = WorshipSortType.manual;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    var all = WorshipService.getItems().where((i) => i.sectionId == widget.section.id).toList();
    
    switch (_sortType) {
      case WorshipSortType.alphabetical:
        all.sort((a, b) => a.name.compareTo(b.name));
        break;
      case WorshipSortType.consistency:
        all.sort((a, b) => b.commitmentRate.compareTo(a.commitmentRate));
        break;
      case WorshipSortType.manual:
        all.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        break;
    }
    
    setState(() => _items = all);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.section.emoji} ${widget.section.name}'),
        actions: [
          TextButton(
            onPressed: () => _showAddEditItemSheet(),
            child: const Text('إضافة عمل', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          PopupMenuButton<WorshipSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (val) {
              setState(() => _sortType = val);
              _loadItems();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: WorshipSortType.manual, child: Text('ترتيب يدوي')),
              const PopupMenuItem(value: WorshipSortType.alphabetical, child: Text('ترتيب أبجدي')),
              const PopupMenuItem(value: WorshipSortType.consistency, child: Text('حسب المواظبة')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: _confirmResetSection,
            tooltip: 'تصفير القسم',
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('لا توجد أعمال في هذا القسم'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              onReorder: (oldIndex, newIndex) async {
                if (_sortType != WorshipSortType.manual) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب اختيار "ترتيب يدوي" لتغيير الترتيب بسحب العناصر')));
                  return;
                }
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
                
                final allItems = WorshipService.getItems();
                for (var item in _items) {
                  final idx = allItems.indexWhere((it) => it.id == item.id);
                  if (idx != -1) {
                    allItems[idx] = item.copyWith(orderIndex: _items.indexOf(item));
                  }
                }
                await WorshipService.saveItemsOrder(allItems);
              },
              itemBuilder: (context, index) => _buildItemCard(_items[index], index),
            ),
    );
  }

  Widget _buildItemCard(WorshipItem item, int index) {
    DateTime today = PrayerService.getIslamicDayDate();
    String dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    double currentValue = item.completionLog[dateKey] ?? 0;
    bool isSoulAtPeace = widget.section.category == WorshipCategory.soulAtPeace;

    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WorshipItemDetailScreen(item: item, isGood: isSoulAtPeace))).then((_) => _loadItems()),
          leading: item.type == WorshipItemType.fixed
              ? Checkbox(
                  value: currentValue > 0,
                  activeColor: Color(item.colorValue),
                  onChanged: (val) async {
                    await WorshipService.updateItemValue(item.id, DateTime.now(), val == true ? 1.0 : 0.0, increment: false);
                    _loadItems();
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
                        await WorshipService.updateItemValue(item.id, DateTime.now(), newValue, increment: false);
                        _loadItems();
                      }
                    },
                  ),
                ),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الالتزام: ${item.commitmentRate.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text('النقاط: ${item.calculatePoints(today).toInt()}', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(item.colorValue))),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (val) {
              if (val == 'edit') _showAddEditItemSheet(item: item);
              if (val == 'delete') _confirmDeleteItem(item.id);
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

  void _showAddEditItemSheet({WorshipItem? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final pointsController = TextEditingController(text: item?.basePoints.toInt().toString() ?? '10');
    final emojiController = TextEditingController(text: item?.emoji ?? '📍');
    final unitController = TextEditingController(text: item?.unitName ?? '');
    final messageController = TextEditingController(text: item?.customReminderMessage ?? '');
    final intervalController = TextEditingController(text: item?.intervalValue.toString() ?? '1');

    WorshipItemType type = item?.type ?? WorshipItemType.fixed;
    WorshipRecurrence recurrence = item?.recurrence ?? WorshipRecurrence.daily;
    ReminderType reminderType = item?.reminderType ?? ReminderType.fixed;
    
    List<int> selectedDays = List<int>.from(item?.specificDays ?? []);
    TimeOfDay? selectedTime = item?.reminderTime;
    TimeOfDay? flexStartTime = (item?.flexibleStartHour != null) ? TimeOfDay(hour: item!.flexibleStartHour!, minute: item.flexibleStartMinute ?? 0) : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? flexEndTime = (item?.flexibleEndHour != null) ? TimeOfDay(hour: item!.flexibleEndHour!, minute: item.flexibleEndMinute ?? 0) : const TimeOfDay(hour: 22, minute: 0);
    final flexCountController = TextEditingController(text: item?.flexibleCount?.toString() ?? '3');
    String? selectedPrayer = item?.linkedPrayer;
    
    final isDark = ThemeService.isDarkMode;
    Color selectedColor = Color(item?.colorValue ?? widget.section.colorValue);

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل عمل' : 'تدوين عمل جديد',
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم العمل',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<WorshipItemType>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'النوع'),
                      items: const [
                        DropdownMenuItem(value: WorshipItemType.fixed, child: Text('ثابتة')),
                        DropdownMenuItem(value: WorshipItemType.variable, child: Text('متغيرة')),
                      ],
                      onChanged: (v) => setSheetState(() => type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: emojiController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'أيقونة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WorshipRecurrence>(
                value: recurrence,
                decoration: const InputDecoration(labelText: 'نظام التكرار'),
                items: const [
                  DropdownMenuItem(value: WorshipRecurrence.daily, child: Text('يومياً')),
                  DropdownMenuItem(value: WorshipRecurrence.everyOtherDay, child: Text('يوم ويوم')),
                  DropdownMenuItem(value: WorshipRecurrence.specificDays, child: Text('أيام محددة')),
                  DropdownMenuItem(value: WorshipRecurrence.interval, child: Text('كل فترة')),
                ],
                onChanged: (v) => setSheetState(() => recurrence = v!),
              ),
              if (recurrence == WorshipRecurrence.specificDays) ...[
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
                value: reminderType,
                decoration: const InputDecoration(labelText: 'نوع التذكير'),
                items: const [
                  DropdownMenuItem(value: ReminderType.fixed, child: Text('تذكير ثابت (موعد محدد)')),
                  DropdownMenuItem(value: ReminderType.prayer, child: Text('مرتبط بموعد الصلاة 🕋')),
                  DropdownMenuItem(value: ReminderType.flexible, child: Text('تذكير مرن (موزع)')),
                ],
                onChanged: (v) => setSheetState(() => reminderType = v!),
              ),

              if (reminderType == ReminderType.fixed)
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
              else if (reminderType == ReminderType.prayer)
                DropdownButtonFormField<String>(
                  value: selectedPrayer,
                  decoration: const InputDecoration(labelText: 'اختر الصلاة'),
                  items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSheetState(() => selectedPrayer = v!),
                )
              else if (reminderType == ReminderType.flexible) ...[
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'النقاط'),
                    ),
                  ),
                  if (type == WorshipItemType.variable) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'الوحدة'),
                      ),
                    ),
                  ],
                ],
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
                      onTap: () => setSheetState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColor.value == color.value ? Border.all(color: Colors.white, width: 2) : null),
                        child: selectedColor.value == color.value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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
            final newItem = WorshipItem(
              id: item?.id ?? const Uuid().v4(),
              userId: UserService.currentUser!.id,
              sectionId: widget.section.id,
              name: nameController.text,
              type: type,
              basePoints: double.tryParse(pointsController.text) ?? 10,
              unitName: unitController.text,
              recurrence: recurrence,
              specificDays: selectedDays,
              intervalValue: int.tryParse(intervalController.text) ?? 1,
              createdAt: item?.createdAt ?? DateTime.now(),
              emoji: emojiController.text,
              colorValue: selectedColor.value,
              reminderType: reminderType,
              reminderHour: selectedTime?.hour,
              reminderMinute: selectedTime?.minute,
              flexibleStartHour: flexStartTime?.hour,
              flexibleStartMinute: flexStartTime?.minute,
              flexibleEndHour: flexEndTime?.hour,
              flexibleEndMinute: flexEndTime?.minute,
              flexibleCount: int.tryParse(flexCountController.text),
              linkedPrayer: selectedPrayer,
              customReminderMessage: messageController.text.isNotEmpty ? messageController.text : null,
              completionLog: item?.completionLog ?? {},
              orderIndex: item?.orderIndex ?? _items.length,
            );
            await WorshipService.saveItem(newItem);
            Navigator.pop(context);
            _loadItems();
          },
          child: const Text('حفظ العمل'),
        ),
      ],
    );
  }

  void _confirmDeleteItem(String id) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف العمل',
      message: 'هل أنت متأكد من حذف هذا العمل نهائياً؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await WorshipService.deleteItem(id);
      _loadItems();
    }
  }

  void _confirmResetSection() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير القسم',
      message: 'هل أنت متأكد من مسح سجل الإنجاز لجميع الأعمال في هذا القسم فقط؟',
      confirmLabel: 'تصفير الآن',
      isDestructive: true,
    );
    if (result == true) {
      for (var item in _items) {
        await WorshipService.resetWorshipCompletion(item.id);
      }
      _loadItems();
    }
  }
}
