import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/sleep_service.dart';
import 'models/sleep_model.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';
import 'package:uuid/uuid.dart';
import '../profile/services/user_service.dart';
import '../library/models/library_models.dart';
import '../library/services/library_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/widgets/modern_audio_player.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../discipline/services/routine_service.dart';
import '../discipline/models/routine_model.dart';

class SleepIntelligenceScreen extends StatefulWidget {
  const SleepIntelligenceScreen({super.key});

  @override
  State<SleepIntelligenceScreen> createState() => _SleepIntelligenceScreenState();
}

class _SleepIntelligenceScreenState extends State<SleepIntelligenceScreen> {
  int _waitMinutes = 14; 
  SleepEntry? _activeEntry;
  String? _selectedLibraryCategoryId; 

  final List<Map<String, dynamic>> _habits = [
    {'id': '1', 'name': 'ترك الهاتف قبل النوم بساعة', 'isGood': true, 'selected': false},
    {'id': '2', 'name': 'إغلاق الإضاءة القوية', 'isGood': true, 'selected': false},
    {'id': '3', 'name': 'الوضوء قبل النوم', 'isGood': true, 'selected': false},
    {'id': '4', 'name': 'أذكار النوم', 'isGood': true, 'selected': false},
    {'id': '5', 'name': 'صلاة الوتر', 'isGood': true, 'selected': false},
    {'id': '6', 'name': 'استخدام الهاتف في السرير', 'isGood': false, 'selected': false},
    {'id': '7', 'name': 'الكافيين بعد المغرب', 'isGood': false, 'selected': false},
    {'id': '8', 'name': 'الأكل الثقيل ليلًا', 'isGood': false, 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    _activeEntry = SleepService.getActiveEntry();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = SleepService.getSettings();
    setState(() {
      _waitMinutes = settings['waitMinutes'] ?? 14;
      _selectedLibraryCategoryId = settings['selectedLibraryCategoryId']; 
      final savedHabitList = settings['allHabits'] as List?;
      if (savedHabitList != null) {
        _habits.clear();
        _habits.addAll(savedHabitList.map((e) => Map<String, dynamic>.from(e)).toList());
      }
    });
  }

  void _saveSettings() async {
    await SleepService.saveSettings({
      'waitMinutes': _waitMinutes,
      'selectedLibraryCategoryId': _selectedLibraryCategoryId,
      'allHabits': _habits,
    });
  }

  void _openAlarmClock(int hour, int minute) async {
    const channel = MethodChannel('com.wasariu.app/alarm');
    try {
      await channel.invokeMethod('setSystemAlarm', {
        'hour': hour,
        'minutes': minute,
        'message': 'استيقاظ ذكي من وسارعوا',
      });
    } catch (e) {
      debugPrint("Failed to open alarm: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق المنبه تلقائياً')));
    }
  }

  void _openTimer(int minutes) async {
    const channel = MethodChannel('com.wasariu.app/alarm');
    try {
      await channel.invokeMethod('setSystemAlarm', {
        'isTimer': true,
        'durationMinutes': minutes,
        'message': 'قيلولة ذكية من وسارعوا',
      });
    } catch (e) {
      debugPrint("Failed to open timer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E);

    return Scaffold(
      appBar: AppBar(title: const Text('النوم الذكي 💤'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const QuickLinkNavigator(currentPageId: 'sleep'),
            _buildSleepProgramCard(isDark),
            const SizedBox(height: 24),
            _buildPlanningCard(isDark),
            const SizedBox(height: 24),
            _buildNapsSection(primaryColor, isDark),
            const SizedBox(height: 24),
            _buildHabitsSection(isDark, true),
            const SizedBox(height: 16),
            _buildHabitsSection(isDark, false),
            const SizedBox(height: 24),
            _buildQualityBar(isDark),
            const SizedBox(height: 24),
            _buildQuietList(context, isDark),
            const SizedBox(height: 24),
            _buildSleepLogTable(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepProgramCard(bool isDark) {
    final routines = RoutineService.getRoutines();
    final sleepRoutine = routines.where((r) => r.title == 'روتين النوم المخصص').firstOrNull;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('💤 برنامج النوم والقيام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            if (sleepRoutine != null) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteSleepProgram(sleepRoutine.id))
          ]),
          if (sleepRoutine == null)
            ElevatedButton(onPressed: _setupSleepHabitProgram, child: const Text('تفعيل برنامج النوم المخصص'))
          else 
            Text('الموعد المخطط: ${sleepRoutine.startTime?.format(context)} - ${sleepRoutine.endTime?.format(context)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _setupSleepHabitProgram() async {
    TimeOfDay? start = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0), helpText: 'اختر وقت النوم المفضل');
    if (start == null) return;
    TimeOfDay? end = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 3, minute: 0), helpText: 'اختر وقت الاستيقاظ المفضل');
    if (end == null) return;

    final routine = Routine(
      id: const Uuid().v4(),
      userId: UserService.currentUser?.id ?? '',
      title: 'روتين النوم المخصص',
      type: RoutineType.major,
      recurrence: RoutineRecurrence.daily,
      startTime: start,
      endTime: end,
      createdAt: DateTime.now(),
      colorValue: Colors.indigo.value,
    );
    await RoutineService.saveRoutine(routine);
    setState(() {});
  }

  void _deleteSleepProgram(String id) async {
    await RoutineService.deleteRoutine(id);
    setState(() {});
  }

  Widget _buildPlanningCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF0F3D2E), const Color(0xFF1B4D3E)]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة دورات النوم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () async {
                  final res = await ModernDialog.showInput(context: context, title: 'مدة الدخول في النوم', hint: 'عدد الدقائق (مثلاً 14)', initialValue: _waitMinutes.toString());
                  if (res != null) { setState(() => _waitMinutes = int.tryParse(res) ?? 14); _saveSettings(); }
                },
                child: Text('الغفوة: $_waitMinutes دقيقة', style: const TextStyle(color: Color(0xFFC8A24A), fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 10),
          const Column(
            children: [
              Text('الدورة الواحدة = 90 دقيقة', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('اختر عدد الدورات لضبط المنبه تلقائياً:', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 20),
          if (_activeEntry == null) ...[
            _buildWakeUpSuggestions(isDark),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startSleepNow, 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                    child: const Text('أنام الآن'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickSleepTime, 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                    child: const Text('بدأت مسبقاً'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text('بدأت النوم في: ${DateFormat.jm('ar').format(_activeEntry!.bedTime)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _stopSleep(DateTime.now()), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('استيقظت الآن'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _pickWakeTime, style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent), child: const Text('استيقظت مسبقاً'))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWakeUpSuggestions(bool isDark) {
    final suggestions = SleepService.calculateWakeUpTimes(DateTime.now(), _waitMinutes);
    final chipColor = isDark ? Colors.white10 : Colors.blueGrey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.asMap().entries.map((e) {
        int cycleCount = e.key + 2; 
        return InkWell(
          onTap: () => _openAlarmClock(e.value.hour, e.value.minute),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm, size: 12, color: Color(0xFFC8A24A)),
                    const SizedBox(width: 4),
                    Text('$cycleCount دورات', style: const TextStyle(color: Color(0xFFC8A24A), fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(DateFormat.jm('ar').format(e.value), style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _startSleepNow() async {
    final entry = SleepEntry(id: const Uuid().v4(), userId: UserService.currentUser!.id, bedTime: DateTime.now());
    await SleepService.saveEntry(entry);
    setState(() => _activeEntry = entry);
  }

  void _pickSleepTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (dt.isAfter(now)) dt = dt.subtract(const Duration(days: 1));
      final entry = SleepEntry(id: const Uuid().v4(), userId: UserService.currentUser!.id, bedTime: dt);
      await SleepService.saveEntry(entry);
      setState(() => _activeEntry = entry);
    }
  }

  void _pickWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _stopSleep(dt);
    }
  }

  void _stopSleep(DateTime wakeTime) async {
    if (_activeEntry == null) return;
    int? quality;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('كيف تشعر الآن؟'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _qualityBtn(1, '😴', () => quality = 1),
            _qualityBtn(2, '😐', () => quality = 2),
            _qualityBtn(3, '🙂', () => quality = 3),
            _qualityBtn(4, '⚡', () => quality = 4),
          ],
        ),
      ),
    );
    if (quality == null) return;

    final updated = SleepEntry(
      id: _activeEntry!.id,
      userId: _activeEntry!.userId,
      bedTime: _activeEntry!.bedTime,
      wakeTime: wakeTime,
      quality: _calculateExpectedQuality().toInt(),
      notes: quality.toString(),
    );
    await SleepService.saveEntry(updated);
    setState(() {
      for (var h in _habits) h['selected'] = false;
      _activeEntry = null;
    });
    _saveSettings();
  }

  Widget _qualityBtn(int val, String emoji, VoidCallback onSelect) {
    return InkWell(onTap: () { onSelect(); Navigator.pop(context); }, child: Text(emoji, style: const TextStyle(fontSize: 32)));
  }

  double _calculateExpectedQuality() {
    int good = _habits.where((h) => h['isGood'] && h['selected']).length;
    int bad = _habits.where((h) => !h['isGood'] && h['selected']).length;
    if (good == 0 && bad == 0) return 0.0;
    double result = (50.0 + (good * 10) - (bad * 10));
    return result.clamp(0.0, 100.0);
  }

  Widget _buildNapsSection(Color primary, bool isDark) {
    final naps = [
      {'min': 10, 'label': 'قيلولة النانو', 'tip': '10 دقائق: كافية للتخلص من النعاس المؤقت.'},
      {'min': 20, 'label': 'قيلولة الطاقة', 'tip': '20 دقيقة: مثالية لتجديد النشاط السريع دون خمول.'},
      {'min': 30, 'label': 'قيلولة متوسطة', 'tip': '30 دقيقة: تحسن الذاكرة والتركيز بشكل ملحوظ.'},
      {'min': 45, 'label': 'قيلولة الإبداع', 'tip': '45 دقيقة: توازن بين النشاط والراحة العميقة.'},
      {'min': 60, 'label': 'إعادة تشغيل', 'tip': '60 دقيقة: مفيدة جداً بعد ليلة سهر.'},
      {'min': 90, 'label': 'دورة كاملة', 'tip': '90 دقيقة: تمنحك فوائد النوم العميق وتمنع الخمول.'},
    ];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('القيلولة الذكية ☁️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
              const Spacer(),
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          ...naps.map((nap) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _openTimer(nap['min'] as int),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                      child: Text('${nap['min']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nap['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(nap['tip'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHabitsSection(bool isDark, bool isGood) {
    final filtered = _habits.where((h) => h['isGood'] == isGood).toList();
    final color = isGood ? Colors.green : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isGood ? 'عادات تحسن النوم ✅' : 'عادات تُضعف النوم ❌', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  TextButton(onPressed: () => _addHabit(isGood, false), child: const Text('عادة', style: TextStyle(fontSize: 11))),
                  TextButton(onPressed: () => _addHabit(isGood, true), child: const Text('متعدد', style: TextStyle(fontSize: 11))),
                ],
              ),
            ],
          ),
          ...filtered.map((h) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Checkbox(
              value: h['selected'],
              onChanged: (val) { setState(() => h['selected'] = val); _saveSettings(); },
              activeColor: color,
            ),
            title: Text(h['name'], style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () => _editHabit(h)),
                IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.red), onPressed: () => _deleteHabit(h)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _addHabit(bool isGood, bool isMultiple) async {
    if (isMultiple) {
      final res = await ModernDialog.showInput(context: context, title: 'إضافة عادات متعددة', hint: 'اكتب كل عادة في سطر منفصل');
      if (res != null) {
        final names = res.split('\n').where((s) => s.trim().isNotEmpty);
        setState(() {
          for (var n in names) _habits.add({'id': const Uuid().v4(), 'name': n.trim(), 'isGood': isGood, 'selected': false});
        });
        _saveSettings();
      }
    } else {
      final res = await ModernDialog.showInput(context: context, title: 'إضافة عادة', hint: 'اسم العادة');
      if (res != null && res.isNotEmpty) {
        setState(() => _habits.add({'id': const Uuid().v4(), 'name': res.trim(), 'isGood': isGood, 'selected': false}));
        _saveSettings();
      }
    }
  }

  void _editHabit(Map<String, dynamic> habit) async {
    final res = await ModernDialog.showInput(context: context, title: 'تعديل العادة', hint: 'الاسم الجديد', initialValue: habit['name']);
    if (res != null && res.isNotEmpty) {
      setState(() => habit['name'] = res.trim());
      _saveSettings();
    }
  }

  void _deleteHabit(Map<String, dynamic> habit) {
    setState(() => _habits.removeWhere((h) => h['id'] == habit['id']));
    _saveSettings();
  }

  Widget _buildQualityBar(bool isDark) {
    double score = _calculateExpectedQuality();
    bool anySelected = _habits.any((h) => h['selected']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('جودة النوم المتوقعة'),
            Text(anySelected ? "${score.toInt()}%" : "0%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: anySelected ? (score / 100) : 0, color: const Color(0xFFC8A24A), backgroundColor: Colors.grey.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildQuietList(BuildContext context, bool isDark) {
    final allCategories = LibraryService.getCategories(type: LibraryType.audio);
    LibraryCategory? selectedCategory;
    if (_selectedLibraryCategoryId != null) {
      selectedCategory = allCategories.where((c) => c.id == _selectedLibraryCategoryId).firstOrNull;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('قائمة الهدوء 🧘', style: TextStyle(fontWeight: FontWeight.bold)),
              if (selectedCategory != null)
                TextButton(onPressed: () => _addAudioToQuietList(selectedCategory!.id), child: const Text('إضافة ملف', style: TextStyle(fontSize: 12))),
              TextButton(onPressed: () => _showCategoryPicker(allCategories), child: Text(selectedCategory == null ? 'اختر قسماً' : 'تغيير القسم')),
            ],
          ),
          if (selectedCategory != null) _buildCategoryContent(selectedCategory, isDark)
          else const Text('اختر قسماً واحداً من المكتبة ليظهر هنا', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showCategoryPicker(List<LibraryCategory> categories) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(categories[index].name),
          onTap: () { setState(() => _selectedLibraryCategoryId = categories[index].id); _saveSettings(); Navigator.pop(context); },
        ),
      ),
    );
  }

  void _addAudioToQuietList(String categoryId) async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = LibraryFile(
        id: const Uuid().v4(),
        userId: UserService.currentUser!.id,
        name: result.files.single.name,
        path: result.files.single.path!,
        categoryId: categoryId,
        addedAt: DateTime.now(),
        type: LibraryType.audio,
      );
      await LibraryService.saveFile(file);
      setState(() {});
    }
  }

  Widget _buildCategoryContent(LibraryCategory cat, bool isDark) {
    final files = LibraryService.getFiles(categoryId: cat.id, type: LibraryType.audio);
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () => showModalBottomSheet(context: context, builder: (context) => ModernAudioPlayer(audioPaths: [files[index].path], titles: [files[index].name])),
          child: Container(
            width: 80, 
            margin: const EdgeInsets.only(right: 10), 
            child: Column(
              children: [
                const Icon(Icons.music_note, color: Colors.teal), 
                Text(
                  files[index].name, 
                  style: TextStyle(fontSize: 8, color: textColor), 
                  maxLines: 2, 
                  textAlign: TextAlign.center
                )
              ]
            )
          ),
        ),
      ),
    );
  }

  Widget _buildSleepLogTable(bool isDark) {
    final entries = SleepService.getEntries().where((e) => e.wakeTime != null).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل النوم التفصيلي', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(onPressed: _clearLog, child: const Text('حذف السجل بالكامل', style: TextStyle(color: Colors.red, fontSize: 10))),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            columns: const [
              DataColumn(label: Text('التاريخ', style: TextStyle(fontSize: 10))),
              DataColumn(label: Text('ساعات', style: TextStyle(fontSize: 10))),
              DataColumn(label: Text('متوقع', style: TextStyle(fontSize: 10))),
              DataColumn(label: Text('الفعلي', style: TextStyle(fontSize: 10))),
              DataColumn(label: Text('إجراءات', style: TextStyle(fontSize: 10))),
            ],
            rows: entries.map((e) {
              final hours = e.duration.inHours;
              final mins = e.duration.inMinutes % 60;
              final sentiment = e.notes == '1' ? 'سيء' : e.notes == '2' ? 'متوسط' : e.notes == '3' ? 'جيد' : 'ممتاز';
              final emoji = e.notes == '1' ? '😴' : e.notes == '2' ? '😐' : e.notes == '3' ? '🙂' : '⚡';

              return DataRow(cells: [
                DataCell(Text(DateFormat('MM/dd').format(e.bedTime), style: const TextStyle(fontSize: 9))),
                DataCell(Text('$hours:$mins', style: const TextStyle(fontSize: 9))),
                DataCell(Text('${e.quality}%', style: const TextStyle(fontSize: 9))),
                DataCell(
                  InkWell(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الحالة: $sentiment'), duration: const Duration(seconds: 1))),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(sentiment, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                      ],
                    ),
                  )
                ),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 14), onPressed: () => _editEntry(e)),
                    IconButton(icon: const Icon(Icons.delete, size: 14, color: Colors.red), onPressed: () => _deleteEntry(e)),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _clearLog() async {
    final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف السجل', message: 'هل أنت متأكد من حذف سجل النوم بالكامل؟');
    if (confirm == true) {
      await SleepService.clearLog();
      setState(() {});
    }
  }

  void _deleteEntry(SleepEntry e) async {
    await SleepService.deleteEntry(e.id);
    setState(() {});
  }

  void _editEntry(SleepEntry e) async {
    final TimeOfDay? start = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(e.bedTime), helpText: 'وقت النوم');
    if (start == null) return;
    final TimeOfDay? end = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(e.wakeTime!), helpText: 'وقت الاستيقاظ');
    if (end == null) return;

    final updated = SleepEntry(
      id: e.id,
      userId: e.userId,
      bedTime: DateTime(e.bedTime.year, e.bedTime.month, e.bedTime.day, start.hour, start.minute),
      wakeTime: DateTime(e.wakeTime!.year, e.wakeTime!.month, e.wakeTime!.day, end.hour, end.minute),
      quality: e.quality,
      notes: e.notes,
    );
    await SleepService.saveEntry(updated);
    setState(() {});
  }
}
