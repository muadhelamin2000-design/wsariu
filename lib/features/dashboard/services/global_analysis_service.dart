import '../../discipline/services/habit_service.dart';
import '../../discipline/models/habit_model.dart';
import '../../worship/services/worship_service.dart';
import '../../health/services/sleep_service.dart';
import '../../discipline/services/task_service.dart';

class GlobalAnalysisReport {
  final String summary;
  final double overallScore;
  final List<String> suggestions;
  final List<String> rebukes;

  GlobalAnalysisReport({
    required this.summary,
    required this.overallScore,
    required this.suggestions,
    required this.rebukes,
  });
}

class GlobalAnalysisService {
  static GlobalAnalysisReport generateGlobalAnalysis() {
    final habits = HabitService.getHabits();
    final worshipItems = WorshipService.getItems();
    final sleepEntries = SleepService.getEntries();
    final tasks = TaskService.getTasks();
    
    List<String> rebukes = [];
    List<String> suggestions = [];
    double totalPoints = 0;
    
    DateTime? firstDate;
    if (sleepEntries.isNotEmpty) firstDate = sleepEntries.last.bedTime;
    
    final now = DateTime.now();
    if (firstDate == null) {
      return GlobalAnalysisReport(
        summary: "بانتظار بياناتكِ الأولى لنبدأ رحلة التحسين معاً 🌸.",
        overallScore: 0,
        suggestions: ["ابدئي بتسجيل أولى عاداتكِ اليوم."],
        rebukes: [],
      );
    }
    
    int totalDays = now.difference(firstDate).inDays + 1;
    
    // 1. العادات
    for (var h in habits) {
      totalPoints += h.commitmentRate;
      if (h.commitmentRate < 30 && totalDays > 3) {
        rebukes.add("تراجع بسيط في التزامكِ بـ '${h.name}'، أنتِ قادرة على العودة لمساركِ.");
      }
    }

    // 2. العبادات
    int worshipDoneCount = worshipItems.where((w) => w.completionLog.isNotEmpty).length;
    if (worshipDoneCount < worshipItems.length * 0.3 && totalDays > 2) {
      rebukes.add("هناك فجوات في جانب العبادات، الصلاة والذكر هما مصدر طاقتكِ.");
    }

    // 3. النوم (منع تشجيع السهر)
    final badHabits = habits.where((h) => h.goal == HabitGoal.bad).map((h) => h.name.toLowerCase());
    bool considersSaharBad = badHabits.any((name) => name.contains('سهر') || name.contains('نوم متاخر'));

    if (sleepEntries.isNotEmpty) {
      final lastSleep = sleepEntries.first;
      // إذا كان ينام بعد الساعة 11 مساءً (23)
      if (lastSleep.bedTime.hour >= 23 || lastSleep.bedTime.hour < 4) {
        if (considersSaharBad) {
           rebukes.add("نومكِ كان متأخراً بالأمس رغم أنكِ تجاهدين لترك السهر. دعينا نحاول اليوم النوم قبل الـ 11 🌙.");
        } else {
           suggestions.add("النوم المبكر (قبل الـ 11) سيعطيكِ تركيزاً أفضل بكثير في الغد.");
        }
      } else {
        suggestions.add("أحسنتِ بالنوم في وقت مثالي بالأمس! حافظي على هذا النظام.");
      }
    }
    
    int pendingTasks = tasks.where((t) => !t.isCompleted).length;
    if (pendingTasks > 3) {
      suggestions.add("لديكِ مهام بسيطة متراكمة، إنجازها الآن سيريّح ذهنكِ.");
    }

    double score = (totalPoints / (habits.isEmpty ? 1 : habits.length)).clamp(0, 100);
    
    String summary = "تحليل مسيرتكِ يا غالية:\n";
    if (score > 80) {
      summary += "أداؤكِ متميز جداً وملهم. استمري بهذا الرقي.";
    } else if (score > 50) {
      summary += "أداؤكِ متوازن، لكن طموحكِ يستحق جهداً أكبر للوصول للقمة.";
    } else {
      summary += "نحتاج لوقفة هادئة لنعيد ترتيب الأولويات، البداية الجديدة ممكنة دائماً.";
    }

    return GlobalAnalysisReport(
      summary: summary,
      overallScore: score,
      suggestions: suggestions,
      rebukes: rebukes,
    );
  }
}
