import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'services/prayer_service.dart';
import 'services/sunan_service.dart';
import 'services/daily_wird_service.dart';
import 'services/navigation_service.dart';
import 'services/screen_time_service.dart';
import 'services/proactive_assistant_service.dart';
import 'services/smart_report_service.dart';
import '../discipline/services/notification_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/app_theme.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/mixins/ui_helpers_mixin.dart';
import '../discipline/services/habit_service.dart';
import '../worship/services/worship_service.dart';
import '../worship/services/qiyam_service.dart';
import '../../core/services/page_management_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/widgets/smart_summary_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with HelpFeatureMixin, UIHelpersMixin {
  int _currentIndex = 0;
  late List<NavTab> _navTabs;
  List<SectionItem> _sections = [];
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    checkFirstTimeHelp(context, 'dashboard');

    Hive.box('sections_management_box').listenable().addListener(_onDataChanged);
    Hive.box('navigation_settings_box').listenable().addListener(_onDataChanged);
    Hive.box('pages_management_box').listenable().addListener(_onDataChanged);

    _startUiTimer();
  }

  void _startUiTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI and update the countdown string
        });
      }
    });
  }

  void _loadAllData() {
    _navTabs = NavigationService.getTabs();
    _sections = PageManagementService.getSections();
  }

  @override
  void dispose() {
    Hive.box('sections_management_box').listenable().removeListener(_onDataChanged);
    Hive.box('navigation_settings_box').listenable().removeListener(_onDataChanged);
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _loadAllData();
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() { _currentIndex = index; });
    final tab = _navTabs[index];
    if (tab.id == 'browser') {
      context.push(tab.route);
      setState(() => _currentIndex = 0);
    } else if (tab.id != 'home') {
      context.push(tab.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F0E6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildMainContent(isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainContent(bool isDark) {
    final hijri = HijriCalendar.now();
    final arabicHijriMonths = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    final hijriDateStr = "${hijri.hDay} ${arabicHijriMonths[hijri.hMonth - 1]} ${hijri.hYear}";

    final bundle = DailyWirdService.getDailyWirdBundle();
    final prayerTimes = PrayerService.getPrayerTimes();
    final nextPrayerStr = PrayerService.getNextPrayerCountdown();
    final nightTimes = PrayerService.getNightTimes();

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildSeasonalAlert(isDark),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('وَسَارِعُواُ', 
                  style: TextStyle(
                    fontFamily: 'Amiri', 
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF0F3D2E)
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.grey, size: 24),
                      onPressed: () {
                        ThemeService.toggleTheme();
                        _onDataChanged();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.library_books_outlined, color: Colors.grey, size: 24), 
                      tooltip: 'المكتبة',
                      onPressed: () => context.push('/library-choice')
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_outlined, color: Colors.grey, size: 24), 
                      onPressed: _showGlobalSearch
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFC8A24A)),
                const SizedBox(width: 8),
                Text('${DateFormat('EEEE, d MMMM', 'ar').format(DateTime.now())} • $hijriDateStr', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildWirdSection(bundle, isDark),
            const SizedBox(height: 32),
            _buildPrayerSection(prayerTimes, nextPrayerStr, isDark),
            const SizedBox(height: 24),
            _buildNightSection(nightTimes, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalAlert(bool isDark) {
    final hijri = HijriCalendar.now();
    String? title;
    String? message;
    IconData icon = Icons.wb_sunny_outlined;

    if (hijri.hMonth == 9) {
      title = "رمضان مبارك 🌙";
      message = "نفحات الرحمة تغمرنا، اجعل / اجعلي هذا اليوم يفيض بالذكر والدعاء.";
      icon = Icons.nightlight_round;
    } else if (hijri.hMonth == 12 && hijri.hDay <= 10) {
      title = "عشر ذي الحجة 🕋";
      message = "خير أيام الدنيا، أكثر / أكثري من التكبير والتهليل والتحميد.";
      icon = Icons.mosque_outlined;
    } else if (DateTime.now().weekday == DateTime.friday) {
      title = "جمعة مباركة 🌙";
      message = "لا تنسَ / تنسي سورة الكهف والصلاة على النبي ﷺ.";
      icon = Icons.auto_awesome;
    }

    if (title == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8A24A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC8A24A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFC8A24A))),
                Text(message!, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWirdSection(Map<String, DailyWird> bundle, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBF5), 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories_outlined, color: Color(0xFFC8A24A), size: 22),
              SizedBox(width: 12),
              Text('الورد اليومي الجامع', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (bundle['verse'] != null) _buildVerseItem(bundle['verse']!, isDark),
          if (bundle['hadith'] != null) _buildHadithItem(bundle['hadith']!, isDark),
          if (bundle['wisdom'] != null) _buildWisdomItem(bundle['wisdom']!, isDark),
        ],
      ),
    );
  }

  Widget _buildVerseItem(DailyWird wird, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('قال تعالى:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
          const SizedBox(height: 8),
          Text(wird.text, 
            style: TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.6, color: isDark ? Colors.white : Colors.black87)
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('[ ${wird.source} ]', style: const TextStyle(fontSize: 10, color: Colors.grey))
          ),
          const Divider(height: 32, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildHadithItem(DailyWird wird, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('عن ${wird.narrator} رضي الله عنه:', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
          const SizedBox(height: 6),
          const Text('قال رسول الله صلى الله عليه وسلم:', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(wird.text, 
            style: TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.6, color: isDark ? Colors.white : Colors.black87)
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('[ ${wird.source} ]', style: const TextStyle(fontSize: 10, color: Colors.grey))
          ),
          const Divider(height: 32, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildWisdomItem(DailyWird wird, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('من أقوال ${wird.source}:', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
          const SizedBox(height: 8),
          Text(wird.text, 
            style: TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.6, color: isDark ? Colors.white : Colors.black87)
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSection(Map<String, DateTime> times, String countdown, bool isDark) {
    final next = PrayerService.getNextPrayerName();
    final sunanProgress = SunanService.getTodayProgress();
    final totalRakaat = SunanService.getTotalRakaatToday();
    final targetRakaat = SunanService.getTargetRakaat();
    final totalHouses = SunanService.getTotalHousesBuilt();
    final isHouseBuilt = SunanService.isHouseBuiltToday();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          // Row 1: Prayer Names
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: times.keys.map((name) {
              bool isNext = name == next;
              return Expanded(
                child: Center(
                  child: Text(name, 
                    style: TextStyle(fontSize: 9, color: isNext ? const Color(0xFFC8A24A) : Colors.grey.withOpacity(0.7), fontWeight: isNext ? FontWeight.bold : FontWeight.normal)
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Row 2: Prayer Times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: times.entries.map((e) {
              bool isNext = e.key == next;
              return Expanded(
                child: Center(
                  child: Text(DateFormat.jm('ar').format(e.value).replaceAll('ص', 'ص').replaceAll('م', 'م'), 
                    style: TextStyle(fontSize: 10, fontWeight: isNext ? FontWeight.bold : FontWeight.w500, color: isNext ? const Color(0xFFC8A24A) : (isDark ? Colors.white70 : Colors.black87))
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Row 3: Sunan Bricks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: times.keys.map((name) {
              var prayerSunan = SunanService.getSunanForPrayer(name);
              
              return Expanded(
                child: Center(
                  child: prayerSunan.isEmpty 
                    ? const SizedBox(height: 18)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: prayerSunan.entries.map((s) {
                          final key = '${name}_${s.key}';
                          final currentCount = sunanProgress[key] ?? 0;
                          final targetCount = s.value;
                          bool isDone = currentCount >= targetCount;
                          
                          return GestureDetector(
                            onTap: () async {
                              await SunanService.updateProgress(name, s.key, isDone ? 0 : targetCount);
                              _onDataChanged();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.0),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDone ? const Color(0xFFC8A24A) : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3), width: 0.5),
                              ),
                              child: Text('${s.value}', style: TextStyle(fontSize: 8, color: isDone ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          );
                        }).toList(),
                      ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          
          // House in Paradise Section
          _buildHouseWidget(totalRakaat, targetRakaat, totalHouses, isHouseBuilt, isDark),
          
          const SizedBox(height: 16),
          
          // Qiyam al-Layl Card
          _buildQiyamCard(isDark),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFC8A24A).withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Text(countdown, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiyamCard(bool isDark) {
    final int todayMinutes = QiyamService.getTodayTotalPrayerMinutes();
    final hours = todayMinutes ~/ 60;
    final minutes = todayMinutes % 60;

    return InkWell(
      onTap: () => context.push('/worship/qiyam'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFC8A24A).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFC8A24A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.nights_stay, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('قيام الليل 🌙', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    todayMinutes > 0 
                      ? 'صليت اليوم: $hours ساعة و $minutes دقيقة' 
                      : 'لم يتم تسجيل صلاة لليوم بعد',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFC8A24A)),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseWidget(int current, int target, int totalHouses, bool isBuilt, bool isDark) {
    double progress = (current / target).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D2E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بناء بيت في الجنة 🕋', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('أتممت $current من $target ركعة سنة راتبة', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  final res = await ModernDialog.showInput(
                    context: context,
                    title: 'تعديل إجمالي البيوت',
                    hint: 'أدخل عدد البيوت الإجمالي',
                    initialValue: totalHouses.toString(),
                  );
                  if (res != null) {
                    final count = int.tryParse(res);
                    if (count != null) {
                      await SunanService.setTotalHouses(count);
                      _onDataChanged();
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFC8A24A), borderRadius: BorderRadius.circular(10)),
                  child: Text('إجمالي البيوت: $totalHouses', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // House Animation / Visual
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // House Frame
                  Icon(Icons.home_outlined, size: 60, color: isDark ? Colors.white10 : Colors.grey.shade200),
                  // Progress Fill (House Building)
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [progress, progress],
                      colors: [const Color(0xFFC8A24A), Colors.transparent],
                    ).createShader(rect),
                    child: const Icon(Icons.home_rounded, size: 60, color: Colors.white),
                  ),
                  if (isBuilt)
                    const Positioned(
                      top: 0, right: 0,
                      child: Icon(Icons.stars, color: Colors.amber, size: 20),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'قَالَ رَسُولُ اللهِ ﷺ:',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(
            target == 12 
              ? '«مَنْ صَلَّى لِلَّهِ فِي يَوْمٍ وَلَيْلَةٍ اثْنَتَيْ عَشْرَةَ رَكْعَةً بَنَى اللَّهُ لَهُ بَيْتًا فِي الْجَنَّةِ»'
              : '«مَنْ صَلَّى لِلَّهِ فِي يَوْمِ الْجُمُعَةِ عَشْرَ رَكَعَاتٍ بَنَى اللَّهُ لَهُ بَيْتًا فِي الْجَنَّةِ»',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 13, color: Color(0xFFC8A24A), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'رواه مسلم عن أم حبيبة رضي الله عنها',
            style: TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildNightSection(Map<String, DateTime> night, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مواقيت الليل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _nightItem('نصف الليل', night['midnightSharia']!),
                  _nightItem('الثلث الأخير', night['lastThirdSharia']!),
                  _nightItem('السدس الأخير', night['lastSixthSharia']!),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F3D2E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nightlight_round, color: Color(0xFFC8A24A), size: 18),
                  SizedBox(width: 8),
                  Text('نظام قيام داود عليه السلام', 
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'يبدأ من: ${DateFormat.jm('ar').format(night['startDawud']!)} • إلى: ${DateFormat.jm('ar').format(night['endDawud']!)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '«أحب الصلاة إلى الله صلاة داود، كان ينام نصف الليل ويقوم ثلثه وينام سدسه»',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nightItem(String label, DateTime time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(DateFormat.jm('ar').format(time), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomNav() {
    final isDark = ThemeService.isDarkMode;
    return Container(
      height: 75, margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white, 
        borderRadius: BorderRadius.circular(35), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, 
          onTap: _onTabTapped, 
          type: BottomNavigationBarType.fixed, 
          backgroundColor: Colors.transparent, 
          elevation: 0,
          selectedItemColor: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2E7D32), 
          unselectedItemColor: Colors.grey.shade400, 
          showSelectedLabels: true, 
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: _navTabs.map((tab) => BottomNavigationBarItem(
            icon: tab.emoji != null ? Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(tab.emoji!, style: const TextStyle(fontSize: 18)),
            ) : Icon(tab.icon), 
            label: tab.label
          )).toList(),
        ),
      ),
    );
  }

  void _showGlobalSearch() {
    final TextEditingController searchController = TextEditingController();
    bool isSearching = false;
    List<Map<String, dynamic>> allItems = [];
    for (var p in PageManagementService.getAllPages()) {
      allItems.add({'name': p.name, 'icon': p.iconData, 'type': 'صفحة', 'route': p.route, 'category': p.sectionKey});
    }
    for (var h in HabitService.getHabits()) {
      allItems.add({'name': h.name, 'icon': '✅', 'type': 'عادة', 'route': '/discipline/habits', 'category': 'الجانب البدني'});
    }
    for (var i in WorshipService.getItems()) {
      allItems.add({'name': i.name, 'icon': '🕌', 'type': 'عبادة', 'route': '/worship/prayers', 'category': 'العبادة والروح'});
    }

    List<Map<String, dynamic>> filteredItems = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: ThemeService.isDarkMode ? const Color(0xFF131C2B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'ابحث عن عادة، عبادة، أو صفحة...', border: InputBorder.none, icon: Icon(Icons.search)),
                        onChanged: (val) {
                          setModalState(() {
                            isSearching = val.isNotEmpty;
                            filteredItems = allItems.where((p) => p['name'].toString().toLowerCase().contains(val.toLowerCase())).toList();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: filteredItems.isEmpty && isSearching
                  ? const Center(child: Text('لا توجد نتائج لمطابقة بحثك'))
                  : ListView.builder(
                      itemCount: isSearching ? filteredItems.length : allItems.length,
                      itemBuilder: (context, index) {
                        final item = isSearching ? filteredItems[index] : allItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: Text(item['icon'], style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['type']} • ${item['category']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () { Navigator.pop(context); context.push(item['route']); },
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showEditSectionDialog(SectionItem section) async {
    final nameController = TextEditingController(text: section.name);
    final iconController = TextEditingController(text: section.icon);
    ModernDialog.show(context: context, title: 'تعديل القسم', content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم القسم')), const SizedBox(height: 12), TextField(controller: iconController, decoration: const InputDecoration(labelText: 'الأيقونة (إيموجي)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { if (nameController.text.isNotEmpty) { section.name = nameController.text; section.icon = iconController.text; await PageManagementService.saveSection(section); if (mounted) Navigator.pop(context); } }, child: const Text('حفظ'))]);
  }

  void _setPrayerAlarm(String name, DateTime time) async {
    final confirm = await ModernDialog.showConfirm(
      context: context,
      title: 'ضبط منبه الصلاة',
      message: 'هل تريد ضبط منبه الهاتف لوقت $name (${DateFormat.jm('ar').format(time)})؟',
    );
    if (confirm == true) {
      await NotificationService.setSystemAlarm(hour: time.hour, minutes: time.minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم ضبط المنبه لـ $name بنجاح')));
      }
    }
  }
}
