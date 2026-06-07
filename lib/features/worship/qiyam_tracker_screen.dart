import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/qiyam_model.dart';
import 'services/qiyam_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;

import 'services/qiyam_content_service.dart';

class QiyamTrackerScreen extends StatefulWidget {
  const QiyamTrackerScreen({super.key});

  @override
  State<QiyamTrackerScreen> createState() => _QiyamTrackerScreenState();
}

class _QiyamTrackerScreenState extends State<QiyamTrackerScreen> {
  bool _isPraying = false;
  bool _isOnBreak = false;
  DateTime? _segmentStart;
  List<QiyamSegment> _currentSegments = [];
  Timer? _timer;
  int _elapsedSeconds = 0;
  List<QiyamSession> _history = [];

  final List<Map<String, dynamic>> _propheticGuidance = [
    {
      'id': 'qg1', 
      'name': 'نية قيام الليل عند النوم', 
      'evidence': 'عن عائشة رضي الله عنها، أن رسول الله صلى الله عليه وسلم قال: "ما من امرئ تكون له صلاة بليل، يغلبه عليها نوم، إلا كتب له أجر صلاته، وكان نومه عليه صدقة" (صحيح أبي داود)', 
      'selected': false
    },
    {
      'id': 'qg2', 
      'name': 'السواك عند القيام', 
      'evidence': 'عن حذيفة رضي الله عنه، قال: "كان النبي صلى الله عليه وسلم إذا قام من الليل يشوص فاه بالسواك" (صحيح البخاري)', 
      'selected': false
    },
    {
      'id': 'qg3', 
      'name': 'افتتاح القيام بركعتين خفيفتين', 
      'evidence': 'عن عائشة رضي الله عنها، قالت: "كان رسول الله صلى الله عليه وسلم إذا قام من الليل ليصلي، افتتح صلاته بركعتين خفيفتين" (صحيح مسلم)', 
      'selected': false
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadGuidanceSettings();
  }

  void _loadGuidanceSettings() {
    final box = Hive.box(QiyamContentService.boxName);
    final saved = box.get('prophetic_guidance_selection');
    if (saved != null) {
      final List savedList = saved;
      for (var item in _propheticGuidance) {
        if (savedList.contains(item['id'])) {
          item['selected'] = true;
        }
      }
    }
  }

  void _saveGuidanceSettings() {
    final box = Hive.box(QiyamContentService.boxName);
    final selectedIds = _propheticGuidance.where((i) => i['selected']).map((i) => i['id']).toList();
    box.put('prophetic_guidance_selection', selectedIds);
  }

  void _loadHistory() {
    setState(() => _history = QiyamService.getSessions());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _startNow() {
    setState(() {
      _isPraying = true;
      _isOnBreak = false;
      _segmentStart = DateTime.now();
      _elapsedSeconds = 0;
    });
    _startTimer();
  }

  void _startPrevious() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now(), helpText: 'متى بدأت الصلاة؟');
    if (picked != null) {
      final now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (dt.isAfter(now)) dt = dt.subtract(const Duration(days: 1));
      setState(() {
        _isPraying = true;
        _segmentStart = dt;
        _elapsedSeconds = DateTime.now().difference(dt).inSeconds;
      });
      _startTimer();
    }
  }

  void _takeBreak() {
    if (_segmentStart == null) return;
    final now = DateTime.now();
    _currentSegments.add(QiyamSegment(start: _segmentStart!, end: now, type: SegmentType.prayer));
    setState(() {
      _isPraying = false;
      _isOnBreak = true;
      _segmentStart = now;
      _elapsedSeconds = 0;
    });
  }

  void _resumePraying() {
    if (_segmentStart == null) return;
    final now = DateTime.now();
    _currentSegments.add(QiyamSegment(start: _segmentStart!, end: now, type: SegmentType.rest));
    setState(() {
      _isPraying = true;
      _isOnBreak = false;
      _segmentStart = now;
      _elapsedSeconds = 0;
    });
  }

  void _finishNow() async {
    _recordSession(DateTime.now());
  }

  void _finishPrevious() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now(), helpText: 'متى انتهيت؟');
    if (picked != null) {
      final now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _recordSession(dt);
    }
  }

  void _recordSession(DateTime end) async {
    if (_segmentStart != null) {
      if (_isPraying) _currentSegments.add(QiyamSegment(start: _segmentStart!, end: end, type: SegmentType.prayer));
      else if (_isOnBreak) _currentSegments.add(QiyamSegment(start: _segmentStart!, end: end, type: SegmentType.rest));
    }

    int prayerMins = _currentSegments.where((s) => s.type == SegmentType.prayer).fold(0, (sum, s) => sum + s.durationMinutes);
    int breakMins = _currentSegments.where((s) => s.type == SegmentType.rest).fold(0, (sum, s) => sum + s.durationMinutes);

    final session = QiyamSession(
      id: const Uuid().v4(),
      userId: UserService.currentUser!.id,
      date: DateTime.now(),
      totalPrayerMinutes: prayerMins,
      totalBreakMinutes: breakMins,
      segments: List.from(_currentSegments),
    );

    await QiyamService.saveSession(session);
    _timer?.cancel();
    _loadHistory();
    setState(() {
      _isPraying = false;
      _isOnBreak = false;
      _elapsedSeconds = 0;
      _currentSegments = [];
      _segmentStart = null;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الجلسة بنجاح ✅')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قيام الليل 🌙')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildInspirationCard(),
            const SizedBox(height: 24),
            _buildPropheticGuidanceSection(),
            const SizedBox(height: 24),
            _buildTimerDisplay(),
            const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 32),
            _buildChartSection(),
            const SizedBox(height: 32),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPropheticGuidanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('هدي النبي ﷺ في قيام الليل 🕌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
          const SizedBox(height: 12),
          ..._propheticGuidance.map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Checkbox(
              value: item['selected'],
              onChanged: (val) {
                setState(() => item['selected'] = val);
                _saveGuidanceSettings();
              },
              activeColor: AppTheme.primaryGreen,
            ),
            title: Text(item['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryGreen),
              onPressed: () => ModernDialog.showInfo(context: context, title: item['name'], message: item['evidence']),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInspirationCard() {
    final inspirations = QiyamContentService.getDailyInspirationTriple();
    final verse = inspirations['verse']!;
    final hadith = inspirations['hadith']!;
    final saying = inspirations['saying']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC8A24A).withOpacity(0.1), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3))
      ),
      child: Column(
        children: [
          _buildInspirationItem('📖 آية', verse['text']!, verse['source']!),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFC8A24A), thickness: 0.2)),
          _buildInspirationItem('💬 حديث', hadith['text']!, hadith['source']!),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFC8A24A), thickness: 0.2)),
          _buildInspirationItem('📜 من أقوال السلف', saying['text']!, saying['source']!),
        ],
      ),
    );
  }

  Widget _buildInspirationItem(String title, String text, String source) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
        const SizedBox(height: 8),
        Text(
          text, 
          textAlign: TextAlign.center, 
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 15, fontWeight: FontWeight.bold, height: 1.5)
        ),
        const SizedBox(height: 4),
        Text(source, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChartSection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    // تجميع البيانات لآخر 7 أيام
    Map<String, int> dailyTotals = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = intl.DateFormat('MM/dd').format(date);
      dailyTotals[dateKey] = 0;
    }

    for (var session in _history) {
      final dateKey = intl.DateFormat('MM/dd').format(session.date);
      if (dailyTotals.containsKey(dateKey)) {
        dailyTotals[dateKey] = dailyTotals[dateKey]! + session.totalPrayerMinutes;
      }
    }

    final entries = dailyTotals.entries.toList();
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تطور وقت القيام (آخر 7 أيام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.only(right: 16, top: 16, left: 0),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      int index = val.toInt();
                      if (index < 0 || index >= entries.length) return const Text('');
                      return Text(entries[index].key, style: const TextStyle(fontSize: 9, color: Colors.grey));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryGreen,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: AppTheme.primaryGreen.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
        const Center(child: Text('الوقت بالدقائق', style: TextStyle(fontSize: 10, color: Colors.grey))),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    final duration = Duration(seconds: _elapsedSeconds);
    String timeStr = "${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    return Column(
      children: [
        Text(_isPraying ? 'في رحاب الصلاة...' : (_isOnBreak ? 'استراحة محارب...' : 'جاهز للقيام؟'), style: const TextStyle(color: Colors.grey)),
        Text(timeStr, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildControls() {
    if (!_isPraying && !_isOnBreak) {
      return Column(
        children: [
          ElevatedButton.icon(onPressed: _startNow, icon: const Icon(Icons.play_arrow), label: const Text('بدأت الآن'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55))),
          const SizedBox(height: 12),
          TextButton(onPressed: _startPrevious, child: const Text('بدأت مسبقاً', style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            if (_isPraying) Expanded(child: ElevatedButton.icon(onPressed: _takeBreak, icon: const Icon(Icons.pause), label: const Text('استراحة'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange))),
            if (_isOnBreak) Expanded(child: ElevatedButton.icon(onPressed: _resumePraying, icon: const Icon(Icons.play_arrow), label: const Text('استئناف'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _finishNow, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('خلصت الآن')),
            const SizedBox(width: 12),
            TextButton(onPressed: _finishPrevious, child: const Text('خلصت مسبقاً', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('سجل القيام', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () async {
            if (await ModernDialog.showConfirm(context: context, title: 'تصفير السجل', message: 'هل تريد حذف كافة جلسات الصلاة؟', isDestructive: true) == true) {
              await Hive.box(QiyamService.boxName).clear();
              _loadHistory();
            }
          }, child: const Text('مسح الكل', style: TextStyle(color: Colors.red, fontSize: 12))),
        ]),
        ..._history.map((s) => Card(
          child: ListTile(
            title: Text(intl.DateFormat('EEEE, d MMMM', 'ar').format(s.date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('صلاة: ${s.totalPrayerMinutes}د • استراحة: ${s.totalBreakMinutes}د', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () async {
              if (await ModernDialog.showConfirm(context: context, title: 'حذف السجل', message: 'هل تريد حذف سجل هذا اليوم؟') == true) {
                await QiyamService.deleteSessionByDate(s.date);
                _loadHistory();
              }
            }),
          ),
        )),
      ],
    );
  }
}
