import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/addiction_model.dart';
import 'services/addiction_service.dart';
import '../discipline/services/progress_service.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';

class EmergencyModeScreen extends StatefulWidget {
  final AddictionHabit habit;
  const EmergencyModeScreen({super.key, required this.habit});

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen> {
  int _secondsRemaining = 900; // Default 15 minutes
  Timer? _timer;
  bool _canExit = false;
  int _selectedDuration = 15;
  int _inspirationIndex = 0;

  final List<Map<String, String>> _inspirations = [
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى الْخَاشِعِينَ ﴾',
      'source': '[البقرة: 45]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ ﴾',
      'source': '[البقرة: 153]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَلَنَبْلُوَنَّكُمْ بِشَيْءٍ مِنَ الْخَوْفِ وَالْجُوعِ وَنَقْصٍ مِنَ الْأَمْوالِ وَالْأَنْفُسِ وَالثَّمَرَاتِ وَبَشِّرِ الصَّابِرِينَ * الَّذِينَ إِذَا أَصَابَتْهُمْ مُصِيبَةٌ قَالُوا إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ ﴾',
      'source': '[البقرة: 155، 156]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَالصَّابِرِينَ فِي الْبَأْسَاءِ وَالضَّرَّاءِ وَحِينَ الْبَأْسِ أُولَئِكَ الَّذِينَ صَدَقُوا وَأُولَئِكَ هُمُ الْمُتَّقُونَ ﴾',
      'source': '[البقرة: 177]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ أَمْ حَسِبْتُمْ أَنْ تَدْخُلُوا الْجَنَّةَ وَلَمَّا يَعْلَمِ اللَّهُ الَّذِينَ جَاهَدُوا مِنْكُمْ وَيَعْلَمَ الصَّابِرِينَ ﴾',
      'source': '[آل عمران: 142]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَاللَّهُ يُحِبُّ الصَّابِرِينَ ﴾',
      'source': '[آل عمران: 146]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ يَا أَيُّهَا الَّذِينَ آمَنُوا اصْبِرُوا وَصَابِرُوا وَرَابِطُوا وَاتَّقُوا اللَّهَ لَعَلَّكُمْ تُفْلِحُونَ ﴾',
      'source': '[آل عمران: 200]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ إِلَّا الَّذِينَ صَبَرُوا وَعَمِلُوا الصَّالِحَاتِ أُولَئِكَ لَهُمْ مَغْفِرَةٌ وَأَجْرٌ كَبِيرٌ ﴾',
      'source': '[هود: 11]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَاصْبِرْ فَإِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ ﴾',
      'source': '[هود: 115]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ إِنَّهُ مَنْ يَتَّقِ وَيَصْبِرْ فَإِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ ﴾',
      'source': '[يوسف: 90]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ سَلَامٌ عَلَيْكُمْ بِمَا صَبَرْتُمْ فَنِعْمَ عُقْبَى الدَّارِ ﴾',
      'source': '[الرعد: 24]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ مَا عِنْدَكُمْ يَنْفَدُ وَمَا عِنْدَ اللَّهِ بَاقٍ وَلَنَجْزِيَنَّ الَّذِينَ صَبَرُوا أَجْرَهُمْ بِأَحْسَنِ مَا كَانُوا يَعْمَلُونَ ﴾',
      'source': '[النحل: 96]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَاصْبِرْ نَفْسَكَ مَعَ الَّذِينَ يَدْعُونَ رَبَّهُمْ بِالْغَدَاةِ وَالْعَشِيِّ يُرِيدُونَ وَجْهَهُ وَلَا تَعْدُ عَيْنَاكَ عَنْهُمْ تُرِيدُ زِينَةَ الْحَيَاةِ الدُّنْيَا وَلَا تُطِعْ مَنْ أَغْفَلْنَا قَلْبَهُ عَنْ ذِكْرِنَا وَاتَّبَعَ هَوَاهُ وَكانَ أَمْرُهُ فُرُطاً ﴾',
      'source': '[الكهف: 28]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ إِنِّي جَزَيْتُهُمُ الْيَوْمَ بِمَا صَبَرُوا أَنَّهُمْ هُمُ الْفَائِزُونَ ﴾',
      'source': '[المؤمنون: 111]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ أُولَئِكَ يُجزَوْنَ الْغُرْفَةَ بِمَا صَبَرُوا وَيُلَقَّوْنَ فِيهَا تَحِيَّةً وَسَلَامًا ﴾',
      'source': '[الفرقان: 75]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ أُولَئِكَ يُؤْتَوْنَ أَجْرَهُمْ مَرَّتَيْنِ بِمَا صَبَرُوا وَيَدْرَؤُونَ بِالْحَسَنَةِ السَّيئَةَ وَمِمَّا رَزَقْنَاهُمْ يُنْفِقُونَ ﴾',
      'source': '[القصص: 54]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَمَا يُلَقَّاهَا إِلَّا الَّذِينَ صَبَرُوا وَمَا يُلَقَّاهَا إِلَّا ذُو حظٍّ عَظِيمٍ ﴾',
      'source': '[فصلت: 35]'
    },
    {
      'type': 'آية قرآنية',
      'text': '﴿ وَلَمَنْ صَبَرَ وَغَفَرَ إِنَّ ذَلِكَ لَمِنْ عَزْمِ الْأُمُورِ ﴾',
      'source': '[الشورى: 43]'
    },
    {
      'type': 'حديث شريف',
      'text': '"ما رُزقَ عبدٌ خيرًا له ولا أَوسعَ من الصبرِ"',
      'source': 'أبي هريرة رضي الله عنه'
    },
    {
      'type': 'حديث شريف',
      'text': '"... ومن يستعفف يعفه الله، ومن يستغن يغنه الله، ومن يتصبر يصبره الله، وما أُعطي أحدٌ عطاءً خيرًا وأوسع من الصبر"',
      'source': 'أبي سعيد الخدري رضي الله عنه'
    },
    {
      'type': 'حديث شريف',
      'text': '"الطهور شطر الإيمان، والحمد لله تملأ الميزان، وسبحان الله والحمد لله تملآن - أو تملأ - ما بين السماء والأرض، الصلاة نور، والصدقة برهان، والصبر ضياءٌ، والقرآن حجة لك أو عليك..."',
      'source': 'أبي مالك الأشعري رضي الله عنه'
    },
    {
      'type': 'حديث شريف',
      'text': '"إن السعيد لمن جُنِّبَ الفتن، ولمن ابتُلِيَ فصبر"',
      'source': 'المقداد رضي الله عنه'
    },
    {
      'type': 'حكمة',
      'text': 'الصبر مثل اسمه مُرٌّ مذاقته\nلكن عواقبه أحلى من العسل',
      'source': 'مدارج السالكين'
    },
    {
      'type': 'حكمة',
      'text': 'إن الأمور إذا انسدت مسالكها\nفالصبر يفتح منها كل ما ارتتجا\nلا تيئَسن وإن طالت مطالبه\nإذا استعنت بصبر أن ترى فرجا',
      'source': 'محمد بن يسير'
    },
    {
      'type': 'حكمة',
      'text': 'أخلق بذي الصبر أن يحظى بحاجته\nومدمن القرع للأبواب أن يلجا\nوقل من جدَّ في أمر يحاوله\nواستصحب الصبر إلا فاز بالظفر',
      'source': 'أدب الدنيا والدين'
    }
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    setState(() {
      _secondsRemaining = minutes * 60;
      _selectedDuration = minutes;
      _inspirationIndex = 0;
    });
    
    int intervalSeconds = ((minutes * 60) / _inspirations.length).floor();
    if (intervalSeconds < 10) intervalSeconds = 10;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          int elapsed = (minutes * 60) - _secondsRemaining;
          _inspirationIndex = (elapsed ~/ intervalSeconds) % _inspirations.length;
        });
      } else {
        setState(() {
          _canExit = true;
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_canExit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ وضع الصمود مفعل.. جاهد نفسك ولا تخرج الآن. استعن بالله!', textAlign: TextAlign.center),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: _timer == null ? _buildDurationPicker(isDark) : _buildActiveEmergency(isDark),
        ),
      ),
    );
  }

  Widget _buildDurationPicker(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 80, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            Text(
              'لحظة ثبات واحتساب',
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'اختر مدة الصمود الآن (15-30 دقيقة)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [15, 20, 30].map((m) => _durationChip(m)).toList(),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _startTimer(_selectedDuration),
              child: const Text('أعاهد الله على الصمود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(int minutes) {
    bool isSelected = _selectedDuration == minutes;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
        ),
        child: Text(
          '$minutes د',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveEmergency(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTimerDisplay(),
          const SizedBox(height: 32),
          _buildInspirationCard(isDark),
          const SizedBox(height: 24),
          _buildInfoCards(isDark),
          const SizedBox(height: 40),
          if (_canExit) _buildCompletionButtons(),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Column(
      children: [
        Text(
          _formatTime(_secondsRemaining),
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const Text('اصمد، اللحظة الصعبة ستمر بإذن الله', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: 1 - (_secondsRemaining / (_selectedDuration * 60)),
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildInspirationCard(bool isDark) {
    final insp = _inspirations[_inspirationIndex % _inspirations.length];
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_inspirationIndex),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(insp['type']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
            const SizedBox(height: 12),
            Text(
              insp['text']!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, height: 1.8),
            ),
            const SizedBox(height: 12),
            Text(insp['source']!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(bool isDark) {
    return Column(
      children: [
        if (widget.habit.facilitators.isNotEmpty || widget.habit.benefits.isNotEmpty)
          _buildCard(
            'أسباب تعينك على النصر والفوائد 💪',
            [
              ...widget.habit.facilitators.map((e) => e.name),
              ...widget.habit.benefits,
            ].take(5).toList(),
            Colors.green,
            isDark,
          ),
        const SizedBox(height: 16),
        if (widget.habit.hindrances.isNotEmpty || widget.habit.harms.isNotEmpty)
          _buildCard(
            'تذكر السلبيات والعواقب ⚠️',
            [
              ...widget.habit.hindrances.map((e) => e.name),
              ...widget.habit.harms,
            ].take(5).toList(),
            Colors.red,
            isDark,
          ),
        const SizedBox(height: 16),
        if (widget.habit.alternatives.isNotEmpty)
          _buildCard(
            'بدائل مقترحة الآن ⚡',
            widget.habit.alternatives.take(5).toList(),
            Colors.blue,
            isDark,
          ),
      ],
    );
  }

  Widget _buildCard(String title, List<String> items, Color color, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCompletionButtons() {
    return Column(
      children: [
        const Text('انتهى الوقت الإجباري.. هل نجحت؟', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _finishEmergency(true),
                child: const Text('انتصرت بفضل الله', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _finishEmergency(false),
              child: const Text('للأسف وقعت', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _finishEmergency(bool triumphed) async {
    if (triumphed) {
      await AddictionService.incrementStreak(widget.habit.id);
      
      await ProgressService.unlockBadge(
        'emergency_victory_${widget.habit.id}',
        'وسام الصمود: ${widget.habit.title}',
        'انتصرت في معركة الإرادة لمرة واحدة. استمر!',
        '🛡️',
      );
    } else {
      await AddictionService.resetStreak(widget.habit.id);
    }
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(triumphed ? 'تم تسجيل النصر! أنت بطل 💪' : 'لا بأس، استعن بالله وابدأ من جديد الآن'),
          backgroundColor: triumphed ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
