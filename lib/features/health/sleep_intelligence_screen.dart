import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/mixins/date_formatting_mixin.dart';
import '../../core/mixins/ui_helpers_mixin.dart';
import '../../core/mixins/help_feature_mixin.dart';
import 'services/sleep_service.dart';
import 'models/sleep_model.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';
import 'package:uuid/uuid.dart';
import '../profile/services/user_service.dart';

import '../discipline/services/notification_service.dart';
import '../discipline/services/habit_service.dart';
import '../discipline/models/habit_model.dart';
import '../library/models/library_models.dart';
import '../library/services/library_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/widgets/modern_audio_player.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/page_info.dart';

import '../discipline/services/routine_service.dart';
import '../discipline/models/routine_model.dart';

class SleepIntelligenceScreen extends StatefulWidget {
  const SleepIntelligenceScreen({super.key});

  @override
  State<SleepIntelligenceScreen> createState() => _SleepIntelligenceScreenState();
}

class _SleepIntelligenceScreenState extends State<SleepIntelligenceScreen> with DateFormattingMixin, UIHelpersMixin, HelpFeatureMixin {
  int _waitMinutes = 14; 
  SleepEntry? _activeEntry;
  DateTime? _plannedSleepTime;
  int _snoozeMinutes = 10;
  String _selectedTone = 'Default';
  String? _customTonePath;
  String? _customToneName;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> _habits = [
    {'name': 'ترك الهاتف قبل النوم بساعة', 'isGood': true, 'selected': false},
    {'name': 'إغلاق الإضاءة القوية', 'isGood': true, 'selected': false},
    {'name': 'الوضوء قبل النوم', 'isGood': true, 'selected': false},
    {'name': 'أذكار النوم', 'isGood': true, 'selected': false},
    {'name': 'صلاة الوتر', 'isGood': true, 'selected': false},
    {'name': 'استخدام الهاتف في السرير', 'isGood': false, 'selected': false},
    {'name': 'الكافيين بعد المغرب', 'isGood': false, 'selected': false},
    {'name': 'الأكل الثقيل ليلًا', 'isGood': false, 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    _activeEntry = SleepService.getActiveEntry();
    _loadSettings();
    checkFirstTimeHelp(context, 'sleep');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settings = SleepService.getSettings();
    setState(() {
      _waitMinutes = settings['waitMinutes'] ?? 14;
      _snoozeMinutes = settings['snoozeMinutes'] ?? 10;
      _selectedTone = settings['selectedTone'] ?? 'Default';
      _customTonePath = settings['customTonePath'];
      _customToneName = settings['customToneName'];
      
      final savedHabitList = settings['allHabits'] as List?;
      if (savedHabitList != null) {
        _habits.clear();
        _habits.addAll(savedHabitList.map((e) => Map<String, dynamic>.from(e)).toList());
      } else {
        // Fallback for old users who only have selectedHabits
        final savedSelectedNames = settings['selectedHabits'] as List?;
        if (savedSelectedNames != null) {
          for (var habit in _habits) {
            habit['selected'] = savedSelectedNames.contains(habit['name']);
          }
        }
      }
    });
  }

  void _saveSettings() async {
    await SleepService.saveSettings({
      'waitMinutes': _waitMinutes,
      'snoozeMinutes': _snoozeMinutes,
      'selectedTone': _selectedTone,
      'customTonePath': _customTonePath,
      'customToneName': _customToneName,
      'allHabits': _habits, // Save the entire list with isGood and selection state
    });
  }

  void _testSound() async {
    if (_selectedTone == 'Custom' && _customTonePath != null) {
      try {
        await _audioPlayer.setFilePath(_customTonePath!);
        _audioPlayer.play();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('جاري تجربة النغمة المختارة... 🎵'),
          duration: Duration(seconds: 3),
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تشغيل الملف: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('النغمات المدمجة ستتوفر قريباً، جرب نغمة من هاتفك.')));
    }
  }

  Future<int?> _showWaitMinutesDialog() async {
    int temp = _waitMinutes;
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مدة الدخول في النوم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('كم دقيقة تحتاج عادةً لتغفو بعد الاستلقاء؟', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setDialogState(() => temp = (temp + 1).clamp(0, 60)), icon: const Icon(Icons.add_circle_outline)),
                  Text('$temp دقيقة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setDialogState(() => temp = (temp - 1).clamp(0, 60)), icon: const Icon(Icons.remove_circle_outline)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, temp), child: const Text('حفظ')),
        ],
      ),
    );
  }

  void _addHabit({bool isGood = true, Map<String, dynamic>? habitToEdit}) async {
    final isEdit = habitToEdit != null;
    final nameController = TextEditingController(text: habitToEdit?['name']);
    final messageController = TextEditingController(text: habitToEdit?['message']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل البند' : 'إضافة بنود متعددة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              maxLines: isEdit ? 1 : 5,
              decoration: InputDecoration(
                labelText: isEdit ? 'اسم العادة' : 'أسماء العادات (ضع كل واحدة في سطر)',
                hintText: isEdit ? '' : 'مثال:\nترك الهاتف\nالوضوء\nأذكار النوم',
              ),
            ),
            if (isEdit) TextField(controller: messageController, decoration: const InputDecoration(labelText: 'رسالة التذكير (اختياري)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  if (isEdit) {
                    habitToEdit['name'] = nameController.text;
                    habitToEdit['message'] = messageController.text;
                  } else {
                    final names = nameController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
                    for (var name in names) {
                      _habits.add({
                        'name': name.trim(), 
                        'isGood': isGood, 
                        'selected': false
                      });
                    }
                  }
                });
                Navigator.pop(context);
                _saveSettings();
              }
            },
            child: Text(isEdit ? 'حفظ' : 'إضافة الكل'),
          ),
        ],
      ),
    );
  }

  void _pickSleepTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (dt.isBefore(now.subtract(const Duration(hours: 1)))) {
        dt = dt.add(const Duration(days: 1));
      }
      setState(() {
        _plannedSleepTime = dt;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E);
    final customBg = getPageBackgroundColor('sleep');

    return Scaffold(
      backgroundColor: customBg ?? (isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC)),
      appBar: AppBar(
        title: const Text('النوم الذكي 💤', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح مساعد النوم الذكي', 
            description: 'هذه الصفحة تساعدكَ / تساعدكِ على تنظيم نومكَ / نومكِ:\n'
            '- اضغط / اضغطي "أنام الآن" لتسجيل وقت بداية نومكَ / نومكِ.\n'
            '- عند الاستيقاظ، سجل / سجلي شعوركَ / شعوركِ لنعطيك إحصائيات دقيقة.\n'
            '- استخدم / استخدمي القيلولة الذكية بمددها المختلفة.\n'
            '- تتبع / تتبعي عاداتكَ / عاداتكِ قبل النوم لمعرفة مدى تأثيرها على جودة نومكَ / نومكِ.\n'
            '- استمع / استمعي للصوتيات الهادئة من قائمة الهدوء.',
            pageId: 'sleep',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const QuickLinkNavigator(currentPageId: 'sleep'),
            const PageInfo(
              title: 'مساعد النوم الذكي 💤',
              description: 'حسّن / حسّني جودة حياتكَ / حياتكِ من خلال تنظيم دورات النوم، وتتبع العادات المؤثرة، والاستيقاظ في الوقت المثالي لنشاطكَ / نشاطكِ الذهني.',
              icon: Icons.airline_seat_individual_suite_rounded,
            ),
            const SizedBox(height: 16),
            _buildSleepProgramCard(primaryColor, isDark),
            const SizedBox(height: 24),
            _buildPlanningCard(primaryColor, isDark),
            const SizedBox(height: 24),
            _buildSmartNapSection(primaryColor, isDark),
            const SizedBox(height: 24),
            _buildHabitsSection(isDark, true),
            const SizedBox(height: 16),
            _buildHabitsSection(isDark, false),
            const SizedBox(height: 24),
            _buildQuietList(context, isDark),
            const SizedBox(height: 24),
            _buildQualityBar(isDark),
            const SizedBox(height: 24),
            _buildSleepLogTable(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepProgramCard(Color primary, bool isDark) {
    // التحقق إذا كان الروتين موجوداً أصلاً
    final routines = RoutineService.getRoutines();
    final sleepRoutine = routines.where((r) => r.title == 'النوم المبكر والقيام').firstOrNull;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💤 برنامج النوم الذكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (sleepRoutine != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                  onPressed: () => _editSleepProgram(sleepRoutine),
                  tooltip: 'تعديل المواعيد',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _deleteSleepProgram(sleepRoutine.id),
                  tooltip: 'حذف البرنامج',
                ),
              ]
            ],
          ),
          const SizedBox(height: 8),
          if (sleepRoutine == null)
            ElevatedButton.icon(
              onPressed: _setupSleepHabitProgram,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('تفعيل البرنامج (10م - 3ص)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else 
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'الموعد الحالي: ${sleepRoutine.startTime?.format(context)} - ${sleepRoutine.endTime?.format(context)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _deleteSleepProgram(String routineId) async {
    final confirm = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف البرنامج',
      message: 'هل أنت متأكد من حذف روتين النوم والتنبيهات المرتبطة به؟',
      isDestructive: true,
    );
    if (confirm ?? false) {
      await RoutineService.deleteRoutine(routineId);
      // حذف التنبيهات المحددة للبرنامج
      await NotificationService.cancelNotification(9001);
      await NotificationService.cancelNotification(9002);
      await NotificationService.cancelNotification(9003);
      setState(() {});
      showSuccessMessage(context, 'تم حذف البرنامج بنجاح');
    }
  }

  void _editSleepProgram(Routine routine) async {
    TimeOfDay? start = routine.startTime;
    TimeOfDay? end = routine.endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل مواعيد النوم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('وقت النوم'),
                trailing: Text(start?.format(context) ?? '--:--'),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: start ?? const TimeOfDay(hour: 22, minute: 0));
                  if (picked != null) setDialogState(() => start = picked);
                },
              ),
              ListTile(
                title: const Text('وقت الاستيقاظ'),
                trailing: Text(end?.format(context) ?? '--:--'),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: end ?? const TimeOfDay(hour: 3, minute: 0));
                  if (picked != null) setDialogState(() => end = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final updated = Routine(
                  id: routine.id,
                  userId: routine.userId,
                  title: routine.title,
                  type: routine.type,
                  recurrence: routine.recurrence,
                  startTime: start,
                  endTime: end,
                  reminderTime: TimeOfDay(hour: (start!.hour - 1 + 24) % 24, minute: 30), // تذكير قبلها بـ 30 دقيقة
                  createdAt: routine.createdAt,
                  colorValue: routine.colorValue,
                );
                await RoutineService.saveRoutine(updated);
                Navigator.pop(context);
                setState(() {});
                showSuccessMessage(context, 'تم تحديث المواعيد بنجاح');
              },
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningCard(Color primary, bool isDark) {
    final startTime = _activeEntry?.bedTime ?? _plannedSleepTime ?? DateTime.now();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF0F3D2E), const Color(0xFF1B4D3E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.nights_stay_outlined, color: Color(0xFFC8A24A), size: 42),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () async {
                      final val = await _showWaitMinutesDialog();
                      if (val != null) {
                        setState(() => _waitMinutes = val);
                        _saveSettings();
                      }
                    },
                    child: Text('معدل الدخول في النوم: $_waitMinutes دقيقة', style: const TextStyle(color: Colors.white60, fontSize: 10, decoration: TextDecoration.underline)),
                  ),
                  if (_plannedSleepTime != null)
                    Text(
                      'موعد النوم المخطط: ${DateFormat.jm('ar').format(_plannedSleepTime!)}',
                      style: const TextStyle(color: Color(0xFFC8A24A), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_activeEntry == null) ...[
            _buildWakeUpSuggestions(startTime),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startSleep,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('أنام الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8A24A),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickSleepTime,
                  icon: const Icon(Icons.access_time_rounded),
                  label: const Text('تحديد موعد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text('بدأت النوم في: ${DateFormat.jm('ar').format(_activeEntry!.bedTime)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildWakeUpSuggestions(_activeEntry!.bedTime),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _stopSleep(DateTime.now()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('⏰ استيقظت الآن', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickWakeTime,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('🕒 استيقظت سابقاً', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _pickWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (dt.isAfter(now)) {
        dt = dt.subtract(const Duration(days: 1));
      }
      _stopSleep(dt);
    }
  }

  void _startSleep() async {
    if (UserService.currentUser == null) {
      showErrorMessage(context, 'يجب تسجيل الدخول أولاً');
      return;
    }

    final entry = SleepEntry(
      id: const Uuid().v4(),
      userId: UserService.currentUser!.id,
      bedTime: DateTime.now(), // Always use exact time when pressing "Sleep Now"
    );
    await SleepService.saveEntry(entry);
    setState(() {
      _activeEntry = entry;
      _plannedSleepTime = null;
    });
  }

  void _stopSleep(DateTime wakeTime) async {
    if (_activeEntry == null) return;
    
    final expectedQuality = _calculateExpectedQuality();
    int? userQuality;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('كيف تشعر بعد الاستيقاظ؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('قيم جودة نومك الفعلية:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _qualityEmojiBtn(1, '😴', 'سيء', (v) => userQuality = v),
                _qualityEmojiBtn(2, '😐', 'متوسط', (v) => userQuality = v),
                _qualityEmojiBtn(3, '🙂', 'جيد', (v) => userQuality = v),
                _qualityEmojiBtn(4, '⚡', 'ممتاز', (v) => userQuality = v),
              ],
            ),
          ],
        ),
      ),
    );

    if (userQuality == null) return; 

    final updated = SleepEntry(
      id: _activeEntry!.id,
      userId: _activeEntry!.userId,
      bedTime: _activeEntry!.bedTime,
      wakeTime: wakeTime,
      positiveHabits: _habits.where((h) => h['isGood'] && h['selected']).map((h) => h['name'] as String).toList(),
      negativeHabits: _habits.where((h) => !h['isGood'] && h['selected']).map((h) => h['name'] as String).toList(),
      quality: expectedQuality.toInt(),
      notes: userQuality.toString(), 
    );
    await SleepService.saveEntry(updated);
    if (!context.mounted) return;
    setState(() => _activeEntry = null);
    showSuccessMessage(context, 'تم تسجيل بيانات النوم بنجاح ✅');
  }

  void _showAddManualEntryDialog() async {
    DateTime? bed;
    DateTime? wake;
    int quality = 3;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة سجل يدوي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('وقت النوم'),
                subtitle: Text(bed == null ? 'اختر' : DateFormat('yyyy/MM/dd HH:mm').format(bed!)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setDialogState(() => bed = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }
                },
              ),
              ListTile(
                title: const Text('وقت الاستيقاظ'),
                subtitle: Text(wake == null ? 'اختر' : DateFormat('yyyy/MM/dd HH:mm').format(wake!)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setDialogState(() => wake = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }
                },
              ),
              const Text('الشعور بعد الاستيقاظ:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: () => setDialogState(() => quality = 1), icon: Text('😴', style: TextStyle(fontSize: quality == 1 ? 30 : 20))),
                  IconButton(onPressed: () => setDialogState(() => quality = 2), icon: Text('😐', style: TextStyle(fontSize: quality == 2 ? 30 : 20))),
                  IconButton(onPressed: () => setDialogState(() => quality = 3), icon: Text('🙂', style: TextStyle(fontSize: quality == 3 ? 30 : 20))),
                  IconButton(onPressed: () => setDialogState(() => quality = 4), icon: Text('⚡', style: TextStyle(fontSize: quality == 4 ? 30 : 20))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: (bed != null && wake != null) ? () {
                final entry = SleepEntry(
                  id: const Uuid().v4(),
                  userId: UserService.currentUser!.id,
                  bedTime: bed!,
                  wakeTime: wake!,
                  notes: quality.toString(),
                  quality: 70, // Default for manual
                );
                SleepService.saveEntry(entry);
                Navigator.pop(context);
                setState(() {});
              } : null,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEntryDialog(SleepEntry entry) async {
    DateTime bed = entry.bedTime;
    DateTime wake = entry.wakeTime ?? DateTime.now();
    int quality = int.tryParse(entry.notes) ?? 3;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل السجل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('وقت النوم'),
                subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(bed)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: bed, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(bed));
                    if (t != null) setDialogState(() => bed = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }
                },
              ),
              ListTile(
                title: const Text('وقت الاستيقاظ'),
                subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(wake)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: wake, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(wake));
                    if (t != null) setDialogState(() => wake = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }
                },
              ),
              const Text('الشعور بعد الاستيقاظ:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: () => setDialogState(() => quality = 1), icon: Text('😴', style: TextStyle(fontSize: quality == 1 ? 30 : 20))),
                  IconButton(onPressed: () => setDialogState(() => quality = 2), icon: Text('😐', style: TextStyle(fontSize: quality == 2 ? 30 : 20))),
                  IconButton(onPressed: () => setDialogState(() => quality = 3), icon: Text('🙂', style: TextStyle(fontSize: quality == 3 ? 30 : 20))),
                  IconButton(onPressed: () => setDialogState(() => quality = 4), icon: Text('⚡', style: TextStyle(fontSize: quality == 4 ? 30 : 20))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'هل تريد حذف هذا السجل؟', isDestructive: true);
                if (confirm ?? false) {
                  await SleepService.deleteEntry(entry.id);
                  Navigator.pop(context);
                  setState(() {});
                }
              }, 
              child: const Text('حذف', style: TextStyle(color: Colors.red))
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final updated = SleepEntry(
                  id: entry.id,
                  userId: entry.userId,
                  bedTime: bed,
                  wakeTime: wake,
                  notes: quality.toString(),
                  quality: entry.quality,
                  positiveHabits: entry.positiveHabits,
                  negativeHabits: entry.negativeHabits,
                );
                SleepService.saveEntry(updated);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearLog() async {
    final confirm = await ModernDialog.showConfirm(
      context: context, 
      title: 'تصفير السجل', 
      message: 'هل أنت متأكد من مسح جميع بيانات النوم؟ لا يمكن التراجع عن هذه الخطوة.',
      isDestructive: true,
    );
    if (confirm ?? false) {
      await SleepService.clearLog();
      setState(() {});
      showSuccessMessage(context, 'تم تصفير السجل بنجاح');
    }
  }

  Widget _qualityEmojiBtn(int val, String emoji, String label, Function(int) onSelect) {
    return InkWell(
      onTap: () {
        onSelect(val);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  double _calculateExpectedQuality() {
    if (_habits.isEmpty) return 50;
    
    int totalHabits = _habits.length;
    int goodSelected = _habits.where((h) => h['isGood'] && h['selected']).length;
    int badNotSelected = _habits.where((h) => !h['isGood'] && !h['selected']).length;
    
    // Quality is the percentage of good things done and bad things avoided
    double score = ((goodSelected + badNotSelected) / totalHabits) * 100;
    return score.clamp(0, 100);
  }

  Widget _buildWakeUpSuggestions(DateTime bedTime) {
    final suggestions = SleepService.calculateWakeUpTimes(bedTime, _waitMinutes);
    return Column(
      children: [
        const Text('أوقات الاستيقاظ المثالية (دورات 90 دقيقة):', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: suggestions.asMap().entries.map((e) {
            int cycles = e.key + 2; 
            return InkWell(
              onTap: () => _setAlarm(e.value, cycles),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        Text('$cycles دورات', style: const TextStyle(color: Color(0xFFC8A24A), fontSize: 9, fontWeight: FontWeight.bold)),
                        Text(DateFormat.jm('ar').format(e.value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _pickCustomTone() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _customTonePath = result.files.single.path;
        _customToneName = result.files.single.name;
        _selectedTone = 'Custom';
      });
      _saveSettings();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم اختيار نغمة: $_customToneName 🎵'),
        backgroundColor: Colors.blue,
      ));
    }
  }

  void _setAlarm(DateTime time, int cycles) async {
    // Open system alarm clock instead of setting an internal alarm
    const channel = MethodChannel('com.wasariu.app/alarm');
    try {
      await channel.invokeMethod('setSystemAlarm', {
        'hour': time.hour,
        'minutes': time.minute,
        'message': 'استيقاظ ذكي ($cycles دورات)',
      });
    } catch (e) {
      debugPrint("Failed to open alarm clock: $e");
    }
  }

  void _setupSleepHabitProgram() async {
    TimeOfDay sleepTime = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 3, minute: 0);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تفعيل برنامج النوم الذكي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سيتم إنشاء روتين يومي لمساعدتك على النوم والقيام بنشاط.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('موعد النوم المخطط', style: TextStyle(fontSize: 13)),
                trailing: Text(sleepTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: sleepTime);
                  if (picked != null) setDialogState(() => sleepTime = picked);
                },
              ),
              ListTile(
                title: const Text('موعد الاستيقاظ المخطط', style: TextStyle(fontSize: 13)),
                trailing: Text(wakeTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: wakeTime);
                  if (picked != null) setDialogState(() => wakeTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تفعيل الآن')),
          ],
        ),
      ),
    );
    
    if (confirm ?? false) {
      final userId = UserService.currentUser?.id ?? '';
      
      // 1. إضافة روتين النوم بدون تنبيهات تلقائية بناءً على رغبة المستخدم
      final sleepRoutine = Routine(
        id: const Uuid().v4(),
        userId: userId,
        title: 'النوم المبكر والقيام',
        type: RoutineType.major,
        recurrence: RoutineRecurrence.daily,
        startTime: sleepTime,
        endTime: wakeTime,
        reminderTime: null, // تم إيقاف التنبيهات التلقائية
        createdAt: DateTime.now(),
        colorValue: Colors.indigo.value,
      );
      await RoutineService.saveRoutine(sleepRoutine);

      if (mounted) {
        showSuccessMessage(context, 'تم تفعيل برنامج النوم والروتين بنجاح ✅');
        setState(() {});
      }
    }
  }

  Widget _buildSmartNapSection(Color primary, bool isDark) {
    final naps = [
      {'title': 'تنشيط سريع', 'time': '10', 'icon': '⚡', 'desc': 'تخلص من الخمول فوراً'},
      {'title': 'تحسين التركيز', 'time': '20', 'icon': '🧠', 'desc': 'تعزيز القدرات العقلية'},
      {'title': 'راحة متوسطة', 'time': '30', 'icon': '🔥', 'desc': 'تجديد الطاقة الجسدية'},
      {'title': 'دورة كاملة', 'time': '90', 'icon': '🚀', 'desc': 'إصلاح شامل للدماغ'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('القيلولة الذكية ☁️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, mainAxisSpacing: 12, crossAxisSpacing: 12),
          itemCount: naps.length,
          itemBuilder: (context, index) => InkWell(
            onTap: () {
              final minutes = int.parse(naps[index]['time']!);
              _setTimer(minutes, naps[index]['title']!);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(naps[index]['icon']!, style: const TextStyle(fontSize: 20)),
                      Text('${naps[index]['time']} د', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text(naps[index]['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setTimer(int minutes, String title) async {
    const channel = MethodChannel('com.wasariu.app/alarm');
    try {
      await channel.invokeMethod('setSystemAlarm', {
        'isTimer': true,
        'durationMinutes': minutes,
        'message': 'قيلولة ذكية: $title',
      });
    } catch (e) {
      debugPrint("Failed to set timer: $e");
    }
  }

  void _importHabits(bool targetIsGood) {
    final allHabits = HabitService.getHabits();
    if (allHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد عادات عامة لاستيرادها')));
      return;
    }

    final worshipHabits = allHabits.where((h) => h.name.contains('صلاة') || h.name.contains('ذكر') || h.name.contains('قرآن')).toList();
    final healthHabits = allHabits.where((h) => h.name.contains('ماء') || h.name.contains('أكل') || h.name.contains('رياضة')).toList();
    final otherHabits = allHabits.where((h) => !worshipHabits.contains(h) && !healthHabits.contains(h)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('استيراد عادات ذكية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('اختر من عاداتك الحالية لربطها بنظام النوم', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (worshipHabits.isNotEmpty) _buildImportCategory('🕋 عادات إيمانية', worshipHabits, targetIsGood),
                    if (healthHabits.isNotEmpty) _buildImportCategory('💪 عادات صحية', healthHabits, targetIsGood),
                    if (otherHabits.isNotEmpty) _buildImportCategory('🎯 عادات أخرى', otherHabits, targetIsGood),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCategory(String title, List<Habit> items, bool targetIsGood) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        ),
        ...items.map((h) => ListTile(
          title: Text(h.name, style: const TextStyle(fontSize: 13)),
          trailing: TextButton(
            onPressed: () {
              setState(() {
                if (!_habits.any((element) => element['name'] == h.name)) {
                  _habits.add({
                    'name': h.name, 
                    'isGood': targetIsGood, 
                    'selected': false
                  });
                }
              });
              Navigator.pop(context);
              _saveSettings();
            },
            child: Text('إضافة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
          ),
        )),
        const Divider(),
      ],
    );
  }

  Widget _buildHabitsSection(bool isDark, bool isGood) {
    final filtered = _habits.where((h) => h['isGood'] == isGood).toList();
    final color = isGood ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isGood ? 'عادات تحسين النوم ✅' : 'عادات تُضعف جودة النوم ❌', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
              ),
              TextButton(
                onPressed: () => _addHabit(isGood: isGood),
                style: TextButton.styleFrom(foregroundColor: color),
                child: const Text('إضافة أكثر من سبب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 20), 
                onPressed: () => _importHabits(isGood), 
                tooltip: 'استيراد',
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('لا توجد عادات مضافة', style: TextStyle(color: Colors.grey, fontSize: 11))),
            )
          else
            ...filtered.map((h) => CheckboxListTile(
              value: h['selected'],
              onChanged: (val) {
                setState(() => h['selected'] = val);
                _saveSettings();
              },
              activeColor: color,
              contentPadding: EdgeInsets.zero,
              title: Text(h['name'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
              secondary: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    onPressed: () => _addHabit(habitToEdit: h),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _habits.remove(h)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildQuietList(BuildContext context, bool isDark) {
    final categories = LibraryService.getCategories(type: LibraryType.audio);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.spa_outlined, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('قائمة الهدوء 🧘', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push('/audio-library'),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('إدارة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const Text('أضف أقسام وصوتيات من مكتبة الصوتيات لتظهر هنا بشكل منظم', style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            ...categories.map((cat) {
              final files = LibraryService.getFiles(categoryId: cat.id, type: LibraryType.audio);
              if (files.isEmpty) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('${cat.emoji} ${cat.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ModernAudioPlayer(
                                audioPaths: files.map((f) => f.path).toList(),
                                titles: files.map((f) => f.name).toList(),
                                initialIndex: index,
                              ),
                            );
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(left: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                  child: const Icon(Icons.play_arrow, color: Colors.teal, size: 20),
                                ),
                                const SizedBox(height: 6),
                                Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24, thickness: 0.5),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQualityBar(bool isDark) {
    if (_habits.isEmpty) return const SizedBox.shrink();
    
    double score = _calculateExpectedQuality();
    bool anySelected = _habits.any((h) => h['selected']);
    
    String status = "😴 لم يتم التقييم";
    if (anySelected) {
      if (score > 85) {
        status = "⚡ طاقة عالية";
      } else if (score > 70) {
        status = "🔥 ممتاز";
      } else if (score > 50) {
        status = "🙂 جيد";
      } else if (score > 30) {
        status = "😐 متوسط";
      } else {
        status = "😴 مضطرب";
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('جودة النوم المتوقعة', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: anySelected ? (score / 100) : 0, 
            minHeight: 10, 
            borderRadius: BorderRadius.circular(5), 
            color: const Color(0xFFC8A24A), 
            backgroundColor: Colors.grey.withValues(alpha: 0.1)
          ),
          if (!anySelected)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('قم بتحديد العادات التي مارستها اليوم لتقييم جودتك', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildSleepLogTable(bool isDark) {
    final entries = SleepService.getEntries().where((e) => e.wakeTime != null).take(7).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text('سجل النوم الأخير', style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: _showAddManualEntryDialog,
                child: const Text('إضافة يوم فاتني', style: TextStyle(fontSize: 11)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _confirmClearLog,
                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                label: const Text('مسح السجل', style: TextStyle(fontSize: 11, color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 0,
              columns: const [
                DataColumn(label: Text('اليوم', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('المدة', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('دورات', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('التوقع', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('الشعور', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('تعديل', style: TextStyle(fontSize: 11))),
              ],
              rows: entries.map((e) {
                final dateStr = DateFormat('E, d MMM', 'ar_SA').format(e.wakeTime!);
                final durationStr = "${e.duration.inHours}س ${e.duration.inMinutes % 60}د";
                final cycles = (e.duration.inMinutes / 90).toStringAsFixed(1);
                
                String expected = "😐";
                if (e.quality > 70) {
                  expected = "✅";
                } else if (e.quality < 40) {
                  expected = "⚠️";
                }

                String felt = "❓";
                int feltVal = int.tryParse(e.notes) ?? 0;
                if (feltVal == 1) {
                  felt = "😴";
                } else if (feltVal == 2) {
                  felt = "😐";
                } else if (feltVal == 3) {
                  felt = "🙂";
                } else if (feltVal == 4) {
                  felt = "⚡";
                }

                return DataRow(cells: [
                  DataCell(Text(dateStr, style: const TextStyle(fontSize: 10))),
                  DataCell(Text(durationStr, style: const TextStyle(fontSize: 10))),
                  DataCell(Text(cycles, style: const TextStyle(fontSize: 10))),
                  DataCell(
                  InkWell(
                    onTap: () {
                      String label = "متوسط 😐";
                      if (e.quality > 70) label = "ممتاز ✅";
                      else if (e.quality < 40) label = "مضطرب ⚠️";
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('التوقع بناءً على العادات: $label'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        width: 250,
                      ));
                    },
                    child: Center(child: Text(expected)),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () {
                      String label = "غير معروف";
                      if (feltVal == 1) label = "سيء 😴";
                      else if (feltVal == 2) label = "متوسط 😐";
                      else if (feltVal == 3) label = "جيد 🙂";
                      else if (feltVal == 4) label = "ممتاز ⚡";
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('جودة الاستيقاظ الفعلية: $label'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        width: 250,
                      ));
                    },
                    child: Center(child: Text(felt)),
                  ),
                ),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                    onPressed: () => _showEditEntryDialog(e),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
