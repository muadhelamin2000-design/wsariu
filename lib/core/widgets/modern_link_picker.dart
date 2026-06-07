import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../features/worship/models/zad_model.dart';
import '../../features/worship/models/worship_model.dart';
import '../../features/discipline/models/habit_model.dart';
import '../../features/discipline/models/task_model.dart';
import '../../features/discipline/models/routine_model.dart';
import '../../features/worship/services/worship_service.dart';
import '../../features/discipline/services/habit_service.dart';
import '../../features/discipline/services/task_service.dart';
import '../../features/discipline/services/routine_service.dart';
import '../services/theme_service.dart';
import 'modern_dialog.dart';

class ModernLinkPicker extends StatefulWidget {
  final Function(ZadItem) onItemPicked;
  const ModernLinkPicker({super.key, required this.onItemPicked});

  @override
  State<ModernLinkPicker> createState() => _ModernLinkPickerState();
}

class _ModernLinkPickerState extends State<ModernLinkPicker> {
  String? selectedPage;
  String? selectedSection;
  String? selectedItemId;

  final List<String> pages = ['العبادات', 'العادات', 'المهام السريعة', 'الروتين', 'بند نصي'];

  List<String> _getSections() {
    if (selectedPage == 'العبادات') return WorshipService.getSections().map((e) => e.name).toList();
    if (selectedPage == 'العادات') return ['عادات جيدة', 'عادات سيئة'];
    return [];
  }

  List<dynamic> _getItems() {
    if (selectedPage == 'العبادات') {
      return WorshipService.getItems().where((it) {
        if (selectedSection == null) return true;
        final sec = WorshipService.getSections().where((s) => s.id == it.sectionId).firstOrNull;
        return sec?.name == selectedSection;
      }).toList();
    }
    if (selectedPage == 'العادات') {
      final goal = selectedSection == 'عادات جيدة' ? HabitGoal.good : HabitGoal.bad;
      return HabitService.getHabits().where((h) => h.goal == goal).toList();
    }
    if (selectedPage == 'المهام السريعة') return TaskService.getTasks();
    if (selectedPage == 'الروتين') return RoutineService.getRoutines();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final themeAccent = const Color(0xFFC8A24A);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 20)),
          Text('إضافة بند جديد', style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
          const SizedBox(height: 24),
          
          _buildDropdown('اختر النوع', selectedPage, pages, (val) {
            setState(() {
              selectedPage = val;
              selectedSection = null;
              selectedItemId = null;
            });
            if (val == 'بند نصي') _showTextInput();
          }),

          if (_getSections().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDropdown('اختر القسم', selectedSection, _getSections(), (val) {
              setState(() {
                selectedSection = val;
                selectedItemId = null;
              });
            }),
          ],

          if (selectedPage != null && selectedPage != 'بند نصي') ...[
            const SizedBox(height: 16),
            _buildItemDropdown(),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: selectedItemId == null ? null : () {
                final items = _getItems();
                final selectedItem = items.where((it) {
                   if (it is WorshipItem || it is Habit) return it.id == selectedItemId;
                   if (it is Task || it is Routine) return it.id == selectedItemId;
                   return false;
                }).firstOrNull;

                if (selectedItem == null) return;

                ZadItem item;
                if (selectedItem is WorshipItem) {
                  item = ZadItem(id: const Uuid().v4(), name: selectedItem.name, type: ZadItemType.worship, linkedId: selectedItem.id);
                } else if (selectedItem is Habit) {
                  item = ZadItem(id: const Uuid().v4(), name: selectedItem.name, type: ZadItemType.habit, linkedId: selectedItem.id);
                } else if (selectedItem is Task) {
                  item = ZadItem(id: const Uuid().v4(), name: selectedItem.title, type: ZadItemType.task, linkedId: selectedItem.id);
                } else {
                  item = ZadItem(id: const Uuid().v4(), name: selectedItem.title, type: ZadItemType.routine, linkedId: selectedItem.id);
                }
                widget.onItemPicked(item);
                Navigator.pop(context);
              },
              child: const Text('إضافة البند', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showTextInput() async {
    final res = await ModernDialog.showInput(context: context, title: 'إضافة بند نصي', hint: 'اكتب البند هنا...');
    if (res != null && res.isNotEmpty) {
      widget.onItemPicked(ZadItem(id: const Uuid().v4(), name: res, type: ZadItemType.internal));
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildItemDropdown() {
    final items = _getItems();
    return DropdownButtonFormField<String>(
      value: selectedItemId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'اختر العنصر',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((e) {
        String name = (e is Task || e is Routine) ? e.title : e.name;
        String id = (e is Task || e is Routine || e is Habit || e is WorshipItem) ? e.id : "";
        return DropdownMenuItem(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (val) => setState(() => selectedItemId = val),
    );
  }
}
