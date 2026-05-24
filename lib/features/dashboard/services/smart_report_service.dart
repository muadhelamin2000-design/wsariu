import '../../discipline/services/habit_service.dart';
import '../../discipline/services/task_service.dart';
import '../../discipline/services/routine_service.dart';
import '../../discipline/models/habit_model.dart';
import '../../worship/services/worship_service.dart';
import '../../worship/models/worship_model.dart';
import '../../worship/services/journal_service.dart';
import '../../health/services/health_service.dart';
import '../../discipline/services/incremental_habit_service.dart';
import '../../worship/services/addiction_service.dart';
import '../../learning/services/study_session_service.dart';
import '../../learning/services/memo_service.dart';
import '../../learning/models/memo_model.dart';
import '../../profile/services/life_link_service.dart';
import '../../profile/models/life_link_model.dart';
import '../../library/services/library_service.dart';
import '../../library/models/library_models.dart';
import 'prayer_service.dart';

class SmartReportService {
  static Map<String, dynamic> generateDailyReport([DateTime? targetDate]) {
    // استخدام تاريخ اليوم الإسلامي إذا لم يتم تمرير تاريخ محدد
    final DateTime date = targetDate ?? PrayerService.getIslamicDayDate();
    final String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final habits = HabitService.getHabits();
    final tasks = TaskService.getTasks();
    final routines = RoutineService.getRoutines();
    final worshipItems = WorshipService.getItems();
    final journal = JournalService.getEntryForDate(date);
    final exercises = HealthService.getExercises(null);
    final nutrition = HealthService.getFoodEntries(date);
    final incrementalHabits = IncrementalHabitService.getHabits();
    final addictionHabits = AddictionService.getHabits();
    final studySessions = StudySessionService.getAllSessions().where((s) => _isSameDay(s.date, date)).toList();
    final pdfFiles = LibraryService.getFiles(type: LibraryType.pdf);
    final videoFiles = LibraryService.getFiles(type: LibraryType.video);

    List<String> positives = [];
    List<String> negatives = [];
    List<String> advice = [];

    double earnedPoints = 0;
    double maxPossiblePoints = 0;

    // --- 1. العادات ---
    int goodHabitsDone = 0;
    for (var h in habits) {
      if (h.goal == HabitGoal.good) {
        maxPossiblePoints += h.basePoints;
        if (h.completionLog.containsKey(dateKey)) {
          earnedPoints += (h.completionLog[dateKey]! * h.basePoints);
          goodHabitsDone++;
        }
      } else {
        if (h.completionLog.containsKey(dateKey)) {
          earnedPoints -= (h.completionLog[dateKey]! * h.basePoints);
          negatives.add("قمت بممارسة عادة سيئة: ${h.name}");
        }
      }
    }
    if (goodHabitsDone > 0) positives.add("أنجزت $goodHabitsDone من عاداتك الحسنة.");
    if (goodHabitsDone == 0 && habits.any((h) => h.goal == HabitGoal.good)) {
      negatives.add("لم تنجز أي عادة حسنة اليوم.");
      advice.add("حاول البدء بأصغر عادة لديك لكسر الجمود.");
    }

    // --- 2. المهام ---
    final todaysTasks = tasks.where((t) => _isSameDay(t.date, date)).toList();
    int tasksDone = 0;
    for (var t in todaysTasks) {
      maxPossiblePoints += 50;
      if (t.isCompleted) {
        earnedPoints += 50;
        tasksDone++;
      }
    }
    if (tasksDone > 0) positives.add("أتممت $tasksDone من مهامك المجدولة.");
    if (todaysTasks.isNotEmpty && tasksDone == 0) negatives.add("لديك مهام معلقة لم تكتمل بعد.");

    // --- 3. الروتين ---
    final todaysRoutines = routines.where((r) => r.isRequiredToday(date)).toList();
    int routinesDone = 0;
    for (var r in todaysRoutines) {
      maxPossiblePoints += 30;
      if (r.isDoneOn(date)) {
        earnedPoints += 30;
        routinesDone++;
      }
    }
    if (routinesDone == todaysRoutines.length && todaysRoutines.isNotEmpty) positives.add("التزام كامل بالروتين اليومي، أحسنت!");
    else if (routinesDone < todaysRoutines.length && todaysRoutines.isNotEmpty) negatives.add("فاتك جزء من روتينك اليومي.");

    // --- 4. العبادات ---
    int worshipDone = 0;
    for (var w in worshipItems) {
      maxPossiblePoints += w.basePoints;
      if (w.completionLog.containsKey(dateKey)) {
        earnedPoints += (w.completionLog[dateKey]! * w.basePoints);
        worshipDone++;
      }
    }
    if (worshipDone > 3) positives.add("رصيدك الإيماني اليوم في حالة جيدة.");

    // --- 5. وتزودوا (العادات التصاعدية) ---
    int incrementalDone = 0;
    for (var ih in incrementalHabits) {
      maxPossiblePoints += ih.getTargetForDate(date);
      double achieved = ih.getAchievedOn(date);
      earnedPoints += achieved;
      if (ih.isCompletedOn(date)) incrementalDone++;
    }
    if (incrementalDone > 0) positives.add("أنجزت $incrementalDone من تحديات 'وتزودوا'.");

    // --- 6. عوضه الله (الإدمان) ---
    int relapses = 0;
    for (var ah in addictionHabits) {
      if (_isSameDay(ah.lastRelapse ?? DateTime(2000), date)) {
        relapses++;
        negatives.add("حدث تعثر في تحدي: ${ah.title}");
        advice.add("السقوط ليس نهاية الطريق، قم الآن وجدد العزم في 'عوضه الله'.");
      }
    }
    if (relapses == 0 && addictionHabits.isNotEmpty) positives.add("يوم جديد من الصمود والحرية، بطل!");

    // --- 7. الصحة (الرياضة والتغذية) ---
    bool exercised = false;
    for (var ex in exercises) {
      if (ex.completionLog[dateKey] == true) {
        exercised = true;
        break;
      }
    }
    if (exercised) positives.add("حافظت على نشاطك البدني اليوم.");
    else {
      negatives.add("لم تسجل أي نشاط رياضي اليوم.");
      advice.add("الرياضة تزيد من تركيزك، جرب المشي لمدة 15 دقيقة فقط.");
    }

    if (nutrition.isNotEmpty) {
      positives.add("قمت بتسجيل وجباتك الغذائية، وعي جيد بالصحة.");
    } else {
      advice.add("تسجيل الوجبات يساعدك على مراقبة سعراتك بشكل أدق.");
    }

    // --- 8. جلسات الدراسة ---
    int totalStudyMinutes = studySessions.fold(0, (sum, s) => sum + s.actualMinutes);
    if (totalStudyMinutes > 0) {
      positives.add("خصصت $totalStudyMinutes دقيقة للمذاكرة والتركيز.");
    } else {
      advice.add("جلسة دراسة واحدة (25 دقيقة) قد تفتح لك آفاقاً جديدة اليوم.");
    }

    // --- 9. المكتبة ---
    int activeBooks = pdfFiles.where((f) => f.lastOpenedAt != null && _isSameDay(f.lastOpenedAt!, date)).length;
    int activeVideos = videoFiles.where((f) => f.lastOpenedAt != null && _isSameDay(f.lastOpenedAt!, date)).length;
    
    if (activeBooks > 0) positives.add("استمريت / استمريتي في القراءة واطلعت / اطلعتِ على $activeBooks كتاب / ملف اليوم.");
    if (activeVideos > 0) positives.add("شاهدت / شاهدتِ $activeVideos من المحتوى المرئي المفيد.");
    if (activeBooks == 0 && activeVideos == 0 && (pdfFiles.isNotEmpty || videoFiles.isNotEmpty)) {
      advice.add("لا تنسَ / تنسي نصيبك من القراءة أو المشاهدة النافعة اليوم، المكتبة تنتظرك.");
    }

    // --- 10. الصحيفة والذنوب ---
    if (journal != null) {
      if (journal.mistakesWithEffects.isNotEmpty) {
        negatives.add("هناك تقصير أو ذنوب مسجلة في صحيفتك.");
        advice.add("باب التوبة مفتوح، استغفر الآن واجعل نيتك خيراً.");
      }
      if (journal.blessings.isNotEmpty) positives.add("شكرت الله على ${journal.blessings.length} نعم، الحمد لله.");
    }

    // --- 11. البيانات (القرارات والمكافآت) ---
    final todaysData = MemoService.getAllMemos().where((m) => m.type == MemoType.data && _isSameDay(m.date, date)).toList();
    for (var d in todaysData) {
      if (d.dataCategory == 'قرارات') positives.add("سجلت قراراً جديداً: ${d.content}");
      if (d.dataCategory == 'مكافآت') positives.add("حددت لنفسك مكافأة: ${d.content}");
    }

    // --- 12. العلاقات والربط الذكي ---
    final links = LifeLinkService.getLinks();
    for (var link in links) {
      if (link.isNegativeImpact) {
        // إذا كان هناك تأثير سلبي، نبه المستخدم
        // مثال: لو المستخدم فعل عادة سيئة مرتبطة بعبادة
        final habit = habits.where((h) => h.id == link.sourceId).firstOrNull;
        if (habit != null && habit.completionLog.containsKey(dateKey)) {
          negatives.add("تحذير: ${link.sourceName} قد يعيقك عن ${link.targetName} كما سجلت في الروابط.");
        }
      }
    }

    double progress = 0;
    if (maxPossiblePoints > 0) {
      progress = (earnedPoints / maxPossiblePoints).clamp(0.0, 1.0);
    }

    return {
      'progress': progress,
      'earnedPoints': earnedPoints,
      'completedHabits': goodHabitsDone,
      'totalHabits': habits.where((h) => h.goal == HabitGoal.good).length,
      'completedTasks': tasksDone,
      'totalTasks': todaysTasks.length,
      'completedRoutine': routinesDone,
      'totalRoutine': todaysRoutines.length,
      'activeLibraryItems': activeBooks + activeVideos,
      'sinsCount': journal?.mistakesWithEffects.length ?? 0,
      'positives': positives,
      'negatives': negatives,
      'advice': advice,
      'insight': _generateInsight(progress, earnedPoints, journal, activeBooks + activeVideos),
    };
  }

  static String _generateInsight(double progress, double points, dynamic journal, int libActivity) {
    if (journal != null && journal.mistakesWithEffects.isNotEmpty) {
      return "انتبه / انتبهي! هناك ذنوب مسجلة اليوم 🌙. باب التوبة مفتوح، استغفر / استغفري الآن وجدد / جددي عهدك مع الله.";
    }
    if (progress >= 0.8 && libActivity > 0) return "أداء مذهل! أنت اليوم في قمة انضباطك وثقافتك 🌙. استمر / استمري على هذا المنوال.";
    if (progress >= 0.8) return "أداء مذهل! أنت اليوم في قمة انضباطك 🌙. استمر / استمري على هذا المنوال.";
    if (progress >= 0.5) return "عمل طيب، لقد أنجزت / أنجزتِ قدراً جيداً من أهدافك 🌙. حاول / حاولي تحسين الأداء غداً.";
    if (points < 0) return "تحذير: العادات السيئة طغت على إنجازاتك اليوم 🌙. استعن / استعيني بالله لتركها.";
    if (progress > 0) return "بداية لا بأس بها، لكنك تستطيع / تستطيعين تقديم الأفضل 🌙. الهمة الهمة!";
    return "يومك لا يزال في بدايته أو أنك لم تسجل / تسجلي إنجازاتك بعد 🌙. ابدأ / ابدئي الآن ولو بعمل بسيط.";
  }

  static String getAssistantResponse(String query) {
    final report = generateDailyReport();
    final q = query.toLowerCase();

    if (q.contains('تقييم') || q.contains('أدائي')) {
      int perc = (report['progress'] * 100).toInt();
      return "تقييمك الحالي هو $perc% 🌙. ${report['insight']}";
    }
    if (q.contains('ذنوب') || q.contains('استغفار')) {
      if (report['sinsCount'] > 0) return "لديك ${report['sinsCount']} ذنوب مسجلة 🌙. 'إن الله يغفر الذنوب جميعاً'، لا تنسَ الاستغفار.";
      return "الحمد لله، لم تسجل ذنوباً اليوم 🌙. حافظ على طهر صحيفتك.";
    }
    if (q.contains('عادات')) {
      return "أنجزت ${report['completedHabits']} عادات جيدة 🌙. حافظ على استمراريتك.";
    }
    if (q.contains('مكتبة') || q.contains('قراءة') || q.contains('فيديو')) {
      if (report['activeLibraryItems'] > 0) return "أحسنت! لقد اطلعت على ${report['activeLibraryItems']} من محتويات المكتبة اليوم 🌙. العلم نور.";
      return "لم تفتح المكتبة اليوم 🌙. خصص ولو 10 دقائق للقراءة أو المشاهدة النافعة لترتقي بعقلك.";
    }
    if (q.contains('نصيحة')) {
      if (report['progress'] < 0.4) return "نصيحتي لك 🌙: ابدأ بالمهام الصغيرة السهلة أولاً لترفع من روحك المعنوية.";
      if (report['activeLibraryItems'] == 0) return "نصيحتي لك 🌙: القراءة تغذي الروح وتفتح الآفاق، جرب تصفح كتابك المفضل لعدة دقائق.";
      return "نصيحتي لك 🌙: 'أحب الأعمال إلى الله أدومها وإن قل'. ركز على الاستمرار.";
    }

    // --- جمع البيانات من المذكرات والحوارات ---
    if (q.contains('مكافآت') || q.contains('مكافأة')) {
      final data = MemoService.getAllMemos().where((m) => m.type == MemoType.data && m.dataCategory == 'مكافآت').toList();
      if (data.isEmpty) return "لم تسجل أي مكافآت لنفسك بعد في قسم البيانات 🌙.";
      return "إليك المكافآت التي سجلتها 🌙: \n" + data.map((m) => "- ${m.content}").join('\n');
    }
    if (q.contains('عواقب') || q.contains('عقوبات')) {
      final data = MemoService.getAllMemos().where((m) => m.type == MemoType.data && m.dataCategory == 'عواقب').toList();
      if (data.isEmpty) return "لم تسجل أي عواقب في قسم البيانات 🌙.";
      return "العواقب التي حددتها 🌙: \n" + data.map((m) => "- ${m.content}").join('\n');
    }
    if (q.contains('قرارات') || q.contains('قرار')) {
      final data = MemoService.getAllMemos().where((m) => m.type == MemoType.data && m.dataCategory == 'قرارات').toList();
      if (data.isEmpty) return "لم تسجل أي قرارات حاسمة بعد 🌙.";
      return "قراراتك المسجلة 🌙: \n" + data.map((m) => "- ${m.content}").join('\n');
    }
    if (q.contains('مفضلات') || q.contains('أحب')) {
      final data = MemoService.getAllMemos().where((m) => m.type == MemoType.data && m.dataCategory == 'مفضلات').toList();
      if (data.isEmpty) return "لا يوجد مفضلات مسجلة 🌙.";
      return "الأشياء التي تحبها 🌙: \n" + data.map((m) => "- ${m.content}").join('\n');
    }
    if (q.contains('صعوبات') || q.contains('تحديات')) {
      final data = MemoService.getAllMemos().where((m) => m.type == MemoType.data && m.dataCategory == 'صعوبات').toList();
      if (data.isEmpty) return "الحمد لله، لم تسجل أي صعوبات مؤخراً 🌙.";
      return "التحديات والصعوبات التي واجهتها 🌙: \n" + data.map((m) => "- ${m.content}").join('\n');
    }

    if (q.contains('تفاعل') || q.contains('روابط') || q.contains('تأثير')) {
      final links = LifeLinkService.getLinks();
      if (links.isEmpty) return "لم تقم بإنشاء أي روابط تفاعلية بين الصفحات بعد 🌙.";
      return "إليك ملخص تفاعلات حياتك المسجلة 🌙: \n" + 
             links.map((l) => "- ${l.sourceName} ${l.isNegativeImpact ? 'يؤثر سلباً على' : 'يدعم'} ${l.targetName} (${l.relationDescription})").join('\n');
    }
    
    return "أنا هنا لمساعدتك في تحليل أدائك 🌙. يمكنك سؤالي عن (تقييمي، العادات، المكتبة، نصيحة، الذنوب، المكافآت، العواقب، أو القرارات).";
  }

  static bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
