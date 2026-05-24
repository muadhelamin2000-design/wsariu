import 'package:hive_flutter/hive_flutter.dart';
import '../models/addiction_model.dart';
import '../../profile/services/user_service.dart';
import '../../../core/services/security_service.dart';

class AddictionService {
  static const String boxName = 'addiction_habits_box_v2';

  static Future<void> init() async {
    await SecurityService.openEncryptedBox(boxName);
  }

  static List<AddictionHabit> getHabits() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((h) => AddictionHabit.fromMap(Map<dynamic, dynamic>.from(h)))
        .where((h) => h.userId == currentUserId && h.isActive)
        .toList();
  }

  static Future<void> saveHabit(AddictionHabit habit) async {
    final box = Hive.box(boxName);
    await box.put(habit.id, habit.toMap());
  }

  static Future<void> deleteHabit(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  static Future<void> resetStreak(String id) async {
    final box = Hive.box(boxName);
    final map = box.get(id);
    if (map != null) {
      final habit = AddictionHabit.fromMap(Map<dynamic, dynamic>.from(map));
      
      int currentStreak = habit.currentStreak;
      int newBest = currentStreak > habit.bestStreak ? currentStreak : habit.bestStreak;
      
      final updated = habit.copyWith(
        currentStreak: 0,
        bestStreak: newBest,
        lastRelapse: DateTime.now(),
      );
      await box.put(id, updated.toMap());
    }
  }

  static Future<void> lapseStreak(String id) async {
    final box = Hive.box(boxName);
    final map = box.get(id);
    if (map != null) {
      final habit = AddictionHabit.fromMap(Map<dynamic, dynamic>.from(map));
      
      final updated = habit.copyWith(
        currentStreak: (habit.currentStreak > 0) ? habit.currentStreak - 1 : 0,
        // bestStreak remains the same, it won't increase until currentStreak exceeds it
        lastRelapse: DateTime.now(),
      );
      await box.put(id, updated.toMap());
    }
  }

  static Future<void> incrementStreak(String id) async {
     final box = Hive.box(boxName);
    final map = box.get(id);
    if (map != null) {
      final habit = AddictionHabit.fromMap(Map<dynamic, dynamic>.from(map));
      final newCurrent = habit.currentStreak + 1;
      // Best streak only updates if current streak exceeds it
      final newBest = newCurrent > habit.bestStreak ? newCurrent : habit.bestStreak;
      
      final updated = habit.copyWith(
        currentStreak: newCurrent,
        bestStreak: newBest,
      );
      await box.put(id, updated.toMap());
    }
  }

  static Map<String, List<String>> generateAIContent(String habitName) {
    habitName = habitName.trim().toLowerCase();
    
    Map<String, List<String>> content;
    if (habitName.contains('تدخين') || habitName.contains('smoking')) {
      content = {
        'harms': ['تلف الرئتين', 'إهدار المال', 'رائحة كريهة', 'خطر السرطان', 'ضعف اللياقة'],
        'benefits': ['تحسن التنفس', 'توفير المال', 'أسنان ناصعة', 'صحة قلب أفضل', 'طاقة يومية أعلى'],
        'alternatives': ['شرب الماء', 'لبان طبيعي', 'مشي لمدة 5 دقائق', 'تنفس عميق', 'مضغ السواك'],
      };
    } else if (habitName.contains('سكر') || habitName.contains('sugar') || habitName.contains('حلويات')) {
      content = {
        'harms': ['زيادة الوزن', 'خطر السكري', 'تسوس الأسنان', 'خمول بعد الأكل', 'التهابات الجسم'],
        'benefits': ['وزن مثالي', 'بشرة صافية', 'نشاط مستمر', 'تركيز أعلى', 'مزاج متزن'],
        'alternatives': ['أكل فاكهة', 'شرب ماء بالليمون', 'تناول مكسرات', 'شاي أخضر', 'تمارين ضغط'],
      };
    } else if (habitName.contains('سوشيال') || habitName.contains('social') || habitName.contains('تيك توك')) {
      content = {
        'harms': ['تشتت الانتباه', 'إضاعة الوقت', 'مقارنة النفس بالآخرين', 'ألم الرقبة', 'اضطراب النوم'],
        'benefits': ['إنتاجية أعلى', 'سلام نفسي', 'وقت للعائلة', 'تركيز في العمل', 'نوم عميق'],
        'alternatives': ['قراءة كتاب', 'رياضة خفيفة', 'تعلم مهارة', 'تنظيف المكان', 'ذكر الله'],
      };
    } else {
      content = {
        'harms': ['إهدار الوقت والجهد', 'تأثير سلبي على الصحة النفسية', 'عائق عن التطور الشخصي'],
        'benefits': ['زيادة الثقة بالنفس', 'تحقيق الحرية الشخصية', 'التقرب إلى الله'],
        'alternatives': ['ممارسة الرياضة', 'القراءة', 'الاستغفار والذكر', 'شرب الماء'],
      };
    }

    // إضافة الحديث الشريف لكل العادات الجديدة في قائمة الفوائد
    if (!content['benefits']!.contains('«مَنْ تَرَكَ شَيْئاً للهِ عَوَّضَهُ اللهُ خَيْراً مِنْهُ»')) {
      content['benefits']!.insert(0, '«مَنْ تَرَكَ شَيْئاً للهِ عَوَّضَهُ اللهُ خَيْراً مِنْهُ»');
    }
    
    return content;
  }
}
