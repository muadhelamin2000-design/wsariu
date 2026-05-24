import 'package:hive_flutter/hive_flutter.dart';
import '../models/entertainment_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class EntertainmentService {
  static const String boxName = 'entertainment_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
    if (Hive.box(boxName).isEmpty) {
      await _seedInitialActivities();
    }
  }

  static List<EntertainmentActivity> getActivities() {
    final box = Hive.box(boxName);
    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((e) => EntertainmentActivity.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveActivity(EntertainmentActivity activity) async {
    await Hive.box(boxName).put(activity.id, activity.toMap());
  }

  static Future<void> deleteActivity(String id) async {
    await Hive.box(boxName).delete(id);
  }

  static Future<void> toggleFavorite(String id) async {
    final activities = getActivities();
    final idx = activities.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final updated = activities[idx].copyWith(isFavorite: !activities[idx].isFavorite);
      await saveActivity(updated);
    }
  }

  static Future<void> incrementExecution(String id) async {
    final activities = getActivities();
    final idx = activities.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final updated = activities[idx].copyWith(executionCount: activities[idx].executionCount + 1);
      await saveActivity(updated);
    }
  }

  static Future<void> _seedInitialActivities() async {
    final List<EntertainmentActivity> initial = [
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "مشي سريع 20 دقيقة",
        description: "تحسين الدورة الدموية وتجديد النشاط البدني.",
        icon: Icons.directions_walk,
        type: EntertainmentType.sports,
        durationMinutes: 20,
      ),
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "قراءة كتاب خفيف",
        description: "قضاء وقت ممتع في تنمية العقل بعيداً عن الشاشات.",
        icon: Icons.book,
        type: EntertainmentType.educational,
        durationMinutes: 30,
      ),
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "جلسة استرخاء وتنفس",
        description: "هدوء للأعصاب وتفريغ للضغط النفسي.",
        icon: Icons.self_improvement,
        type: EntertainmentType.psychology,
        durationMinutes: 10,
      ),
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "مكالمة صديق مقرب",
        description: "صلة الرحم وتقوية الروابط الاجتماعية.",
        icon: Icons.call,
        type: EntertainmentType.social,
        durationMinutes: 15,
      ),
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "مشاهدة فيديو مفيد",
        description: "تعلم مهارة جديدة أو استماع لدرس ملهم.",
        icon: Icons.play_circle_outline,
        type: EntertainmentType.educational,
        durationMinutes: 10,
      ),
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "تجربة وصفة صحية",
        description: "تعلم فن الطبخ الصحي والاستمتاع بوجبة لذيذة.",
        icon: Icons.restaurant,
        type: EntertainmentType.psychology,
        durationMinutes: 45,
      ),
      EntertainmentActivity(
        id: const Uuid().v4(),
        title: "جلسة ذكر وتأمل",
        description: "سكينة للروح واتصال عميق بالله.",
        icon: Icons.wb_sunny_outlined,
        type: EntertainmentType.lightReligious,
        durationMinutes: 10,
      ),
    ];

    final box = Hive.box(boxName);
    for (var a in initial) {
      await box.put(a.id, a.toMap());
    }
  }
}
