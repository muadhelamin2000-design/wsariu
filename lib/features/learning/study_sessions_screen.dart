import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/study_session_model.dart';
import 'services/study_session_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/widgets/page_info.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/study_timer_service.dart';
import 'package:intl/intl.dart';

import '../../core/mixins/help_feature_mixin.dart';

class StudySessionsScreen extends StatefulWidget {
  const StudySessionsScreen({super.key});

  @override
  State<StudySessionsScreen> createState() => _StudySessionsScreenState();
}

class _StudySessionsScreenState extends State<StudySessionsScreen> with HelpFeatureMixin {
  // Timer State subscription
  StreamSubscription? _timerSub;
  
  // Settings Controllers
  late TextEditingController _studyController;
  late TextEditingController _breakController;
  
  String _selectedCategory = 'عام';
  
  List<StudySession> _sessions = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _studyController = TextEditingController(text: studyTimerService.studyMinutes.toString());
    _breakController = TextEditingController(text: studyTimerService.breakMinutes.toString());
    _loadData();
    _timerSub = studyTimerService.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _loadData() {
    setState(() {
      _sessions = StudySessionService.getAllSessions();
      _categories = StudySessionService.getCategories();
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : 'عام';
      }
    });
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    _studyController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    studyTimerService.toggleTimer(onComplete: _onPhaseComplete);
  }

  void _onPhaseComplete() {
    if (studyTimerService.isStudyPhase) {
      _saveSession(studyTimerService.studyMinutes); // Full session
      studyTimerService.startBreak();
      _showNotification('انتهى وقت المذاكرة! خذ قسطاً من الراحة.');
    } else {
      studyTimerService.startStudy();
      _showNotification('انتهى البريك! حان وقت العودة للعمل.');
    }
  }

  void _resetTimer() {
    studyTimerService.reset();
  }

  void _finishEarly() {
    if (studyTimerService.isStudyPhase && studyTimerService.isActive) {
      int elapsedSeconds = (studyTimerService.studyMinutes * 60) - studyTimerService.secondsRemaining;
      int elapsedMinutes = elapsedSeconds ~/ 60;
      if (elapsedMinutes > 0) {
        _saveSession(elapsedMinutes);
      }
    }
    _resetTimer();
  }

  Future<void> _saveSession(int actualMinutes) async {
    if (UserService.currentUser == null) return;
    
    final session = StudySession(
      id: const Uuid().v4(),
      userId: UserService.currentUser!.id,
      category: _selectedCategory,
      plannedMinutes: studyTimerService.studyMinutes,
      actualMinutes: actualMinutes,
      breakMinutes: studyTimerService.breakMinutes,
      date: DateTime.now(),
    );
    
    await StudySessionService.saveSession(session);
    _loadData();
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('study_sessions');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('جلسات الدراسة'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح جلسات الدراسة', 
            description: 'تعلم بذكاء ولا تكتفِ بالمجهود:\n'
            '- ابدأ مؤقت التركيز للمذاكرة.\n'
            '- سجل مستويات تركيزك ووعيك أثناء الجلسة.\n'
            '- حدد المهام المطلوبة قبل البدء.',
            pageId: 'study_sessions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            QuickLinkNavigator(currentPageId: 'sessions'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: PageInfo(
                title: 'جلسات التركيز (بومودورو)',
                description: 'استخدم تقنية بومودورو لزيادة إنتاجيتك. حدد وقت المذاكرة ووقت الراحة، وسجل جلساتك لمتابعة أدائك الدراسي.',
                icon: Icons.timer,
              ),
            ),
            _buildStatsHeader(),
            _buildTimerCard(),
            _buildSettingsSection(),
            _buildHistorySection(),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.blueGrey,
        label: const Text('إضافة قسم', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildStatsHeader() {
    int todayMinutes = _sessions
        .where((s) => s.date.day == DateTime.now().day)
        .fold(0, (sum, s) => sum + s.actualMinutes);
        
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('اليوم', '$todayMinutes د'),
          _statCol('الجلسات', '${_sessions.length}'),
          _statCol('الأسبوع', '${_getWeeklyMinutes()} د'),
        ],
      ),
    );
  }

  int _getWeeklyMinutes() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _sessions
        .where((s) => s.date.isAfter(weekAgo))
        .fold(0, (sum, s) => sum + s.actualMinutes);
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTimerCard() {
    double total = ((studyTimerService.isStudyPhase ? studyTimerService.studyMinutes : studyTimerService.breakMinutes) * 60).toDouble();
    if (total == 0) total = 1;
    double progress = studyTimerService.secondsRemaining / total;
    Color color = studyTimerService.isStudyPhase ? Colors.green : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(studyTimerService.isStudyPhase ? 'وقت المذاكرة' : 'استراحة', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(_formatTime(studyTimerService.secondsRemaining), 
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: studyTimerService.isActive ? Colors.orange : color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: Icon(studyTimerService.isActive ? Icons.pause : Icons.play_arrow),
                    label: Text(studyTimerService.isActive ? 'إيقاف مؤقت' : 'ابدأ الآن'),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _finishEarly,
                    icon: const Icon(Icons.stop),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات الجلسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _studyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المذاكرة (د)', border: OutlineInputBorder()),
                  onChanged: (val) {
                    studyTimerService.setSettings(
                      int.tryParse(val) ?? 25,
                      studyTimerService.breakMinutes,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _breakController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'البريك (د)', border: OutlineInputBorder()),
                  onChanged: (val) {
                    studyTimerService.setSettings(
                      studyTimerService.studyMinutes,
                      int.tryParse(val) ?? 5,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _showAddCategoryDialog,
                child: const Text('إضافة', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إضافة قسم جديد',
      hint: 'اسم القسم (مثلاً: رياضيات)',
    );
    if (result != null && result.isNotEmpty) {
      await StudySessionService.addCategory(result);
      _loadData();
      setState(() => _selectedCategory = result);
    }
  }

  Widget _buildHistorySection() {
    if (_sessions.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('سجل الجلسات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sessions.length > 5 ? 5 : _sessions.length,
          itemBuilder: (context, index) {
            final s = _sessions[index];
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(s.category),
              subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(s.date)),
              trailing: Text('${s.actualMinutes} دقيقة', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }
}
