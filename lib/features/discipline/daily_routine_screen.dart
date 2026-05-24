import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models/routine_model.dart';
import 'services/routine_service.dart';
import 'routine_detail_screen.dart';
import '../profile/services/user_service.dart';
import '../dashboard/services/prayer_service.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/badge_service.dart';

import '../../core/mixins/help_feature_mixin.dart';

class DailyRoutineScreen extends StatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  State<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends State<DailyRoutineScreen> with HelpFeatureMixin {
  List<Routine> _allRoutines = [];
  bool _isListView = false;

  static const List<String> fullArabicDays = [
    'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
    checkFirstTimeHelp(context, 'routine');
  }

  void _refreshData() {
    setState(() {
      _allRoutines = RoutineService.getRoutines();
    });
  }

  List<DateTime> _getThisWeekDates() {
    DateTime now = DateTime.now();
    int currentFlutterWeekday = now.weekday; // Mon=1, Sun=7
    int daysToSubtract;
    // Saturday in Flutter is 6
    if (currentFlutterWeekday == 6) {
      daysToSubtract = 0;
    } else if (currentFlutterWeekday == 7) {
      daysToSubtract = 1;
    } else {
      daysToSubtract = currentFlutterWeekday + 1;
    }
    DateTime saturday = now.subtract(Duration(days: daysToSubtract));
    return List.generate(7, (i) => saturday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('routine');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: Text('الروتين اليومي')),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح الروتين اليومي', 
            description: 'نظم يومك حول مواقيت الصلاة:\n'
            '- أضف روتينك المعتاد واربطه بصلاة معينة (قبل أو بعد).\n'
            '- حدد أوقات البداية والنهاية لكل نشاط.\n'
            '- النظام سيذكرك بالنشاط القادم بناءً على جدولك.\n'
            '- يمكنك استعراض الروتين كقائمة أو كجدول زمني.',
            pageId: 'routine',
          ),
          IconButton(
            icon: Icon(_isListView ? Icons.calendar_view_day : Icons.list),
            onPressed: () => setState(() => _isListView = !_isListView),
            tooltip: _isListView ? 'عرض المخطط' : 'عرض القائمة (للترتيب)',
          ),
          TextButton(
            onPressed: () => _showAddRoutineSheet(),
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'reset_all') _confirmResetAllRoutines();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_all',
                child: Text('تصفير الكل (بداية جديدة)', style: TextStyle(fontSize: 13, color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoutineSheet(),
        label: const Text('إضافة'),
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'routine'),
          Expanded(child: _isListView ? _buildReorderableList() : _buildWeeklyTimeline()),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    if (_allRoutines.isEmpty) return const Center(child: Text('لا يوجد روتين مضاف بعد.'));
    
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allRoutines.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _allRoutines.removeAt(oldIndex);
          _allRoutines.insert(newIndex, item);
        });
        await RoutineService.saveRoutinesOrder(_allRoutines);
      },
      itemBuilder: (context, index) {
        final r = _allRoutines[index];
        return Card(
          key: ValueKey(r.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.drag_handle, color: Color(r.colorValue)),
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(r.relatedPrayer != RelatedPrayer.none ? 'مرتبط بـ ${_getPrayerName(r.relatedPrayer)}' : 'وقت محدد'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RoutineDetailScreen(routine: r)),
              ).then((_) => _refreshData());
            },
          ),
        );
      },
    );
  }

  Widget _buildWeeklyTimeline() {
    final weekDates = _getThisWeekDates();
    final prayers = PrayerService.getPrayerTimes();
    
    final List<Map<String, dynamic>> timeSlots = [
      {'name': 'الفجر', 'time': prayers['الفجر']},
      {'name': 'الظهر', 'time': prayers['الظهر']},
      {'name': 'العصر', 'time': prayers['العصر']},
      {'name': 'المغرب', 'time': prayers['المغرب']},
      {'name': 'العشاء', 'time': prayers['العشاء']},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 80), 
                  ...weekDates.map((date) => Container(
                    width: 120,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: date.day == DateTime.now().day ? const Color(0xFF0F3D2E).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fullArabicDays[_getArabicDayIndex(date)],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: date.day == DateTime.now().day 
                            ? (ThemeService.isDarkMode ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E))
                            : (ThemeService.isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(24, (hour) {
                return _buildTimeRow(hour, weekDates, timeSlots);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(int hour, List<DateTime> weekDates, List<Map<String, dynamic>> timeSlots) {
    String? prayerName;
    for (var slot in timeSlots) {
      if (slot['time']!.hour == hour) {
        prayerName = slot['name'];
      }
    }

    return Row(
      children: [
        Container(
          width: 80,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey.shade100)),
            color: prayerName != null ? const Color(0xFFC8A24A).withOpacity(0.1) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat.jm('ar').format(DateTime(2024, 1, 1, hour)),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (prayerName != null)
                Text(prayerName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
            ],
          ),
        ),
        ...weekDates.map((date) {
          final instances = RoutineService.getInstancesForDate(date).where((inst) => 
            _isRoutineInHour(inst['routine'], hour, date, timeSlots)
          ).toList();

          return Container(
            width: 120,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade50),
              color: instances.isNotEmpty ? Color(instances.first['routine'].colorValue).withOpacity(0.2) : Colors.transparent,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: instances.map((inst) {
                  final r = inst['routine'] as Routine;
                  final d = inst['date'] as DateTime;
                  final isCarry = inst['isCarryOver'] as bool;
                  
                  final isOverdue = !r.isDoneOn(d) && r.isOverdue() && d.day == DateTime.now().day;
                  
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoutineDetailScreen(routine: r)),
                      ).then((_) => _refreshData());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isCarry ? '${r.title} (فائت)' : (isOverdue ? '${r.title} (متأخر)' : r.title),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 8, 
                              fontWeight: FontWeight.bold, 
                              color: (isCarry || isOverdue) ? Colors.red.shade800 : Color(r.colorValue),
                              decoration: r.isDoneOn(d) ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (r.isDoneOn(d))
                            const Icon(Icons.check, size: 8, color: Colors.green),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _isRoutineInHour(Routine r, int hour, DateTime date, List<Map<String, dynamic>> timeSlots) {
    if (r.reminderTime != null) {
      return r.reminderTime!.hour == hour;
    }
    if (r.startTime != null && r.endTime != null) {
      return hour >= r.startTime!.hour && hour < r.endTime!.hour;
    }
    
    if (r.relatedPrayer != RelatedPrayer.none) {
      int prayerHour = _getPrayerHour(r.relatedPrayer, timeSlots);
      int nextPrayerHour = _getNextPrayerHour(r.relatedPrayer, timeSlots);
      
      if (r.afterPrayer) {
         return hour >= prayerHour && hour < nextPrayerHour;
      } else {
         return hour == (prayerHour - 1 < 0 ? 23 : prayerHour - 1);
      }
    }

    return false;
  }

  int _getPrayerHour(RelatedPrayer p, List<Map<String, dynamic>> slots) {
    String name = _getPrayerName(p);
    return slots.firstWhere((s) => s['name'] == name)['time'].hour;
  }

  int _getNextPrayerHour(RelatedPrayer p, List<Map<String, dynamic>> slots) {
    int currentIdx = 0;
    String name = _getPrayerName(p);
    for(int i=0; i<slots.length; i++) { if(slots[i]['name'] == name) currentIdx = i; }
    
    if (currentIdx < slots.length - 1) {
      return slots[currentIdx + 1]['time'].hour;
    }
    return 24; 
  }

  String _getPrayerName(RelatedPrayer p) {
    switch (p) {
      case RelatedPrayer.fajr: return 'الفجر';
      case RelatedPrayer.dhuhr: return 'الظهر';
      case RelatedPrayer.asr: return 'العصر';
      case RelatedPrayer.maghrib: return 'المغرب';
      case RelatedPrayer.isha: return 'العشاء';
      default: return '';
    }
  }

  void _showAddRoutineSheet({Routine? routine}) {
    final isEdit = routine != null;
    final titleController = TextEditingController(text: routine?.title ?? '');
    
    RoutineType selectedType = routine?.type ?? RoutineType.major;
    RoutineRecurrence selectedRecurrence = routine?.recurrence ?? RoutineRecurrence.daily;
    List<int> selectedDays = List<int>.from(routine?.specificDays ?? []);
    TimeOfDay? startTime = routine?.startTime;
    TimeOfDay? endTime = routine?.endTime;
    TimeOfDay? reminderTime = routine?.reminderTime;
    RelatedPrayer selectedPrayer = routine?.relatedPrayer ?? RelatedPrayer.none;
    bool afterPrayer = routine?.afterPrayer ?? true;
    Color selectedColor = Color(routine?.colorValue ?? 0xFF0F3D2E);

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل الروتين' : 'تدوين روتين جديد',
      accentColor: const Color(0xFFC8A24A),
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController, 
                decoration: InputDecoration(
                  labelText: 'اسم الروتين',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoutineType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'تصنيف الروتين'),
                items: const [
                  DropdownMenuItem(value: RoutineType.major, child: Text('روتين أساسي (يستمر معك)')),
                  DropdownMenuItem(value: RoutineType.minor, child: Text('روتين فرعي (لليوم فقط)')),
                ],
                onChanged: (v) => setSheetState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoutineRecurrence>(
                value: selectedRecurrence,
                decoration: const InputDecoration(labelText: 'نظام التكرار'),
                items: const [
                  DropdownMenuItem(value: RoutineRecurrence.daily, child: Text('يومياً')),
                  DropdownMenuItem(value: RoutineRecurrence.everyOtherDay, child: Text('يوم ويوم')),
                  DropdownMenuItem(value: RoutineRecurrence.specificDays, child: Text('أيام محددة')),
                  DropdownMenuItem(value: RoutineRecurrence.interval, child: Text('كل عدد من الأيام')),
                ],
                onChanged: (v) => setSheetState(() => selectedRecurrence = v!),
              ),
              if (selectedRecurrence == RoutineRecurrence.specificDays) ...[
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
              const SizedBox(height: 16),
              const Text('توقيت الروتين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RelatedPrayer>(
                      value: selectedPrayer,
                      decoration: const InputDecoration(labelText: 'صلاة'),
                      items: const [
                        DropdownMenuItem(value: RelatedPrayer.none, child: Text('لا يوجد')),
                        DropdownMenuItem(value: RelatedPrayer.fajr, child: Text('الفجر')),
                        DropdownMenuItem(value: RelatedPrayer.dhuhr, child: Text('الظهر')),
                        DropdownMenuItem(value: RelatedPrayer.asr, child: Text('العصر')),
                        DropdownMenuItem(value: RelatedPrayer.maghrib, child: Text('المغرب')),
                        DropdownMenuItem(value: RelatedPrayer.isha, child: Text('العشاء')),
                      ],
                      onChanged: (v) => setSheetState(() => selectedPrayer = v!),
                    ),
                  ),
                  if (selectedPrayer != RelatedPrayer.none) ...[
                    const SizedBox(width: 8),
                    DropdownButton<bool>(
                      value: afterPrayer,
                      items: const [
                        DropdownMenuItem(value: false, child: Text('قبل')),
                        DropdownMenuItem(value: true, child: Text('بعد')),
                      ],
                      onChanged: (v) => setSheetState(() => afterPrayer = v!),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('وقت البداية', style: TextStyle(fontSize: 12)),
                      subtitle: Text(startTime?.format(context) ?? '--:--'),
                      onTap: () async {
                        final p = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                        if (p != null) setSheetState(() => startTime = p);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('وقت النهاية', style: TextStyle(fontSize: 12)),
                      subtitle: Text(endTime?.format(context) ?? '--:--'),
                      onTap: () async {
                        final p = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                        if (p != null) setSheetState(() => endTime = p);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: Color(0xFFC8A24A)),
                title: Text(reminderTime == null ? 'وقت التذكير' : 'موعد: ${reminderTime!.format(context)}'),
                trailing: reminderTime != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setSheetState(() => reminderTime = null)) : const Icon(Icons.keyboard_arrow_left, size: 14),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: reminderTime ?? TimeOfDay.now());
                  if (p != null) setSheetState(() => reminderTime = p);
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          onPressed: () async {
            if (titleController.text.isEmpty || UserService.currentUser == null) return;
            final newRoutine = Routine(
              id: routine?.id ?? const Uuid().v4(),
              userId: UserService.currentUser!.id,
              title: titleController.text,
              type: selectedType,
              recurrence: selectedRecurrence,
              specificDays: selectedDays,
              startTime: startTime,
              endTime: endTime,
              reminderTime: reminderTime,
              relatedPrayer: selectedPrayer,
              afterPrayer: afterPrayer,
              createdAt: routine?.createdAt ?? DateTime.now(),
              colorValue: selectedColor.value,
              executionLog: routine?.executionLog ?? {},
            );
            await RoutineService.saveRoutine(newRoutine);
            if (mounted) {
              Navigator.pop(context);
              _refreshData();
            }
          },
          child: const Text('حفظ الروتين'),
        ),
      ],
    );
  }

  void _showRoutineOptions(Routine routine, DateTime date) {
    bool isDone = routine.isDoneOn(date);
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(isDone ? Icons.undo : Icons.check_circle_outline, color: isDone ? Colors.orange : Colors.green),
            title: Text(isDone ? 'إلغاء الإنجاز' : 'إتمام الروتين'),
            onTap: () async {
              await RoutineService.toggleRoutineCompletion(routine.id, date);
              Navigator.pop(context);
              _refreshData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.redAccent),
            title: const Text('بداية جديدة (تصفير التقدم)'),
            onTap: () async {
              Navigator.pop(context);
              _confirmResetRoutine(routine);
            },
          ),
          ListTile(leading: const Icon(Icons.edit_note), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showAddRoutineSheet(routine: routine); }),
          ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('حذف'), onTap: () async {
            await RoutineService.deleteRoutine(routine.id);
            Navigator.pop(context);
            _refreshData();
          }),
        ],
      ),
    );
  }

  void _confirmResetAllRoutines() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير كل الروتين',
      message: 'هل أنت متأكد من مسح جميع سجلات الإنجاز واعتبار اليوم هو أول يوم؟ (سيعيد حساب الالتزام ليكون 100%)',
      confirmLabel: 'تصفير الكل',
      isDestructive: true,
    );
    if (result == true) {
      await RoutineService.resetAllRoutinesCompletion();
      _refreshData();
    }
  }

  void _confirmResetRoutine(Routine routine) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير السجل',
      message: 'هل تريد تصفير سجل "${routine.title}" والبدء من اليوم كبداية جديدة؟',
      confirmLabel: 'تصفير الآن',
    );
    if (result == true) {
      final updated = routine.copyWith(executionLog: {}, createdAt: DateTime.now());
      await RoutineService.saveRoutine(updated);
      _refreshData();
    }
  }

  int _getArabicDayIndex(DateTime date) {
    int f = date.weekday;
    if (f == 6) return 0; if (f == 7) return 1; return f + 1;
  }
}
