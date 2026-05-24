import 'package:flutter/material.dart';
import 'prayer_service.dart';
import 'smart_report_service.dart';
import '../../discipline/services/habit_service.dart';
import '../../discipline/services/routine_service.dart';
import '../../discipline/services/task_service.dart';
import '../../worship/services/worship_service.dart';
import '../../discipline/models/habit_model.dart';
import '../../health/services/sleep_service.dart';

enum MessageType { guide, motivation, warning, suggestion }

class SmartMessage {
  final String text;
  final MessageType type;
  final String? subText;
  SmartMessage(this.text, this.type, {this.subText});
}

class ActionSuggestion {
  final String title;
  final IconData icon;
  final String route;
  final Color? color;
  final String description;
  ActionSuggestion(this.title, this.icon, this.route, {this.color, this.description = ''});
}

class ProactiveAssistantService {
  
  static String get assistantName => "مساعدك الشخصي"; 

  static SmartMessage getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12 && hour > 4) return SmartMessage("صباح الخير يا بطل / بطلة.. يوم جديد مليء بالفرص ☀️", MessageType.guide);
    if (hour >= 12 && hour < 17) return SmartMessage("طاب يومكَ / يومكِ.. أنا معكَ / معكِ لتنظيم وقتكَ / وقتكِ ✨", MessageType.guide);
    if (hour >= 17 && hour < 21) return SmartMessage("مساء الهمة.. لنراجع إنجازاتنا 🌙", MessageType.guide);
    return SmartMessage("وقت الهدوء.. استعد / استعدي لنوم عميق ومريح 😴", MessageType.guide);
  }

  static Future<Map<String, dynamic>> analyzeUserStatus() async {
    final habits = HabitService.getHabits();
    final worships = WorshipService.getItems();
    final today = PrayerService.getIslamicDayDate();
    final report = SmartReportService.generateDailyReport(today);
    
    List<String> positives = [];
    List<String> negatives = [];
    List<String> recommendations = [];

    // 1. تحليل الإيجابيات
    if (report['progress'] > 0.5) positives.add("أداؤكَ / أداؤكِ اليوم ممتاز، استمر / استمري في هذا المسار.");
    
    // 2. تحليل التنبيهات
    final badHabitDone = habits.where((h) => h.goal == HabitGoal.bad && h.completionLog.containsKey(PrayerService.getIslamicDayKey())).toList();
    if (badHabitDone.isNotEmpty) negatives.add("انتبه / انتبهي! العادات السيئة قد تعطل مسيرتكَ / مسيرتكِ.");
    
    if (DateTime.now().hour > 22) negatives.add("السهر عدو الإنتاجية، النوم الآن هو القرار الصحيح.");

    // 3. الاقتراحات
    recommendations.add("خصص / خصصي وقتاً للذكر أو القراءة الآن لتجدد / تجددي طاقتكَ / طاقتكِ الذهنية.");

    return {
      'positives': positives,
      'negatives': negatives,
      'recommendations': recommendations,
      'summary': report['insight'] ?? "يومكَ / يومكِ يسير بشكل جيد، حافظ / حافظي على تركيزكَ / تركيزكِ."
    };
  }

  static Future<String> getPersonalizedResponse(String userMessage) async {
    final query = userMessage.toLowerCase();
    
    if (query.contains('متعصب') || query.contains('مضغوط') || query.contains('توتر')) {
      return "أتفهم تماماً شعوركَ / شعوركِ بالضغط. 🌿 خذ / خذي نفساً عميقاً. تذكر / تذكري أهدافكَ / أهدافكِ ولا تدع / تدعي شعوراً عابراً يحبطكِ. أنصحك بالوضوء أو المشي قليلاً بعيداً عن الشاشات.";
    }

    if (query.contains('أعمل إيه') || query.contains('افعل') || query.contains('خطة')) {
      final suggestions = await getWhatToDoNow();
      return "بناءً على تحليلي ليومك، أفضل شيء تفعله / تفعلينه الآن هو: ${suggestions.first.title}. ${suggestions.first.description}";
    }

    final status = await analyzeUserStatus();
    String resp = "أهلاً بكَ / بكِ، إليك تحليلي السريع للوضع الحالي:\n\n";
    if ((status['positives'] as List).isNotEmpty) resp += "✅ الإيجابيات: ${status['positives'][0]}\n";
    if ((status['negatives'] as List).isNotEmpty) resp += "⚠️ تنبيه: ${status['negatives'][0]}\n";
    if ((status['recommendations'] as List).isNotEmpty) resp += "💡 اقتراح: ${status['recommendations'][0]}\n";
    return resp;
  }

  static Future<List<ActionSuggestion>> getWhatToDoNow({int? minutes}) async {
    final now = DateTime.now();
    final today = PrayerService.getIslamicDayDate();
    final habits = HabitService.getHabits();
    final routines = RoutineService.getRoutines();
    
    List<ActionSuggestion> list = [];

    if (now.hour >= 22 || now.hour <= 3) {
      list.add(ActionSuggestion("النوم", Icons.bedtime_outlined, "/health/sleep", color: Colors.indigo, description: "الاستعداد للنوم الآن سيجعلكَ / سيجعلكِ أكثر نشاطاً لصلاة الفجر."));
    }

    final pendingRoutine = routines.where((r) => r.isRequiredToday(today) && !r.isDoneOn(today)).firstOrNull;
    if (pendingRoutine != null) {
      list.add(ActionSuggestion(pendingRoutine.title, Icons.repeat, "/discipline/daily-routine", color: Colors.blue, description: "الالتزام بالروتين يعيد لكَ / لكِ السيطرة على يومكَ / يومكِ."));
    }

    final pendingHabit = habits.where((h) => h.goal == HabitGoal.good && !h.isCompletedToday()).firstOrNull;
    if (pendingHabit != null) {
      list.add(ActionSuggestion(pendingHabit.name, Icons.check_circle_outline, "/discipline/habits", color: Colors.green, description: "إنجاز عادة صغيرة يعطيكَ / يعطيكِ دفعة معنوية قوية."));
    }

    if (list.isEmpty) {
      list.add(ActionSuggestion("قراءة ورد القرآن", Icons.auto_stories, "/worship/prayers", color: Colors.amber, description: "استغل / استغلي هذا الوقت في القراءة والتدبر لتجد / تجددي البركة في يومكَ / يومكِ."));
    }

    return list;
  }

  static SmartMessage getSmartMessage() {
     final hour = DateTime.now().hour;
     if (hour >= 21 || hour <= 2) return SmartMessage("حان وقت ترك الهاتف والاستعداد لنوم هادئ ومريح.", MessageType.guide);
     if (hour >= 5 && hour <= 8) return SmartMessage("ابدأ / ابدئي يومكَ / يومكِ بذكر الله لتجد / تجددي البركة والتوفيق في كل خطوة.", MessageType.guide);
     return SmartMessage("أنا هنا معكَ / معكِ، دعنا نجعل هذا اليوم مليئاً بالإنجاز والتميز بطل / بطلة! 🚀", MessageType.guide);
  }
}
