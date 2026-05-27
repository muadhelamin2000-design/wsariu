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

  final List<Map<String, String>> _inspirations = [
    {'text': '«عَلَيْكُمْ بِقِيَامِ اللَّيْلِ، فَإِنَّهُ دَأْبُ الصَّالِحِينَ قَبْلَكُمْ»', 'source': 'حديث شريف'},
    {'text': '«أَفْضَلُ الصَّلَاةِ بَعْدَ الْفَرِيضَةِ صَلَاةُ اللَّيْلِ»', 'source': 'حديث شريف'},
    {'text': '«كان النبي ﷺ يقوم من الليل حتى تتفطر قدماه»', 'source': 'هدي نبوي'},
    {'text': 'قيام الليل مدرسة الإخلاص ومحراب الصادقين.', 'source': 'قلم'},
    {'text': '﴿تَتَجافىٰ جُنوبُهُم عَنِ المَضاجِعِ يَدعونَ رَبَّهُم خَوفًا وَطَمَعًا﴾', 'source': 'السجدة: ١٦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
            _buildTimerDisplay(),
            const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 32),
            _buildChartSection(), // إضافة الرسم البياني هنا
            const SizedBox(height: 32),
            _buildHistorySection(),
          ],
        ),
      ),
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

  Widget _buildInspirationCard() {
    final ins = (_inspirations..shuffle()).first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFC8A24A).withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3))),
      child: Column(
        children: [
          Text(ins['text']!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
          const SizedBox(height: 8),
          Text(ins['source']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
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
              await Hive.box(QiyamService.boxName).delete(s.id);
              _loadHistory();
            }),
          ),
        )),
      ],
    );
  }
}
