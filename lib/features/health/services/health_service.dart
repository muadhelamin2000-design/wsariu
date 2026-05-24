import 'package:hive_flutter/hive_flutter.dart';
import '../models/health_models.dart';
import '../../profile/services/user_service.dart';

class HealthService {
  static const String profileBox = 'health_profile_box';
  static const String foodBox = 'food_entries_box';
  static const String exercisesBox = 'workout_exercises_box';
  static const String conditionsBox = 'chronic_conditions_box';
  static const String testsBox = 'lab_tests_box';

  static Future<void> init() async {
    await Hive.openBox(profileBox);
    await Hive.openBox(foodBox);
    await Hive.openBox(exercisesBox);
    await Hive.openBox(conditionsBox);
    await Hive.openBox(testsBox);
  }

  // --- Chronic Conditions ---
  static List<ChronicCondition> getConditions() {
    final box = Hive.box(conditionsBox);
    return box.values.map((e) => ChronicCondition.fromMap(Map<dynamic, dynamic>.from(e))).toList();
  }

  static Future<void> saveCondition(ChronicCondition condition) async {
    await Hive.box(conditionsBox).put(condition.id, condition.toMap());
  }

  static Future<void> deleteCondition(String id) async {
    await Hive.box(conditionsBox).delete(id);
    // Delete linked tests? Maybe later.
  }

  // --- Lab Tests ---
  static List<GradualLabTest> getLabTests(String? conditionId) {
    final box = Hive.box(testsBox);
    var tests = box.values.map((e) => GradualLabTest.fromMap(Map<dynamic, dynamic>.from(e)));
    if (conditionId != null) {
      tests = tests.where((t) => t.conditionId == conditionId);
    }
    return tests.toList();
  }

  static Future<void> saveLabTest(GradualLabTest test) async {
    await Hive.box(testsBox).put(test.id, test.toMap());
  }

  static Future<void> deleteLabTest(String id) async {
    await Hive.box(testsBox).delete(id);
  }

  // --- Profile ---
  static UserHealthProfile? getProfile() {
    final box = Hive.box(profileBox);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return null;
    final data = box.get(currentUserId);
    if (data == null) return null;
    return UserHealthProfile.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static Future<void> saveProfile(UserHealthProfile profile) async {
    await Hive.box(profileBox).put(profile.userId, profile.toMap());
  }

  // --- Food ---
  static List<FoodEntry> getFoodEntries(DateTime date) {
    final box = Hive.box(foodBox);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return [];
    final dateKey = "${date.year}-${date.month}-${date.day}";
    return box.values
        .map((e) => FoodEntry.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId && "${e.date.year}-${e.date.month}-${e.date.day}" == dateKey)
        .toList();
  }

  static Future<void> addFood(FoodEntry entry) async => await Hive.box(foodBox).put(entry.id, entry.toMap());
  static Future<void> deleteFood(String id) async => await Hive.box(foodBox).delete(id);

  // --- Workout Exercises ---
  static List<WorkoutExercise> getExercises(WorkoutType? type) {
    final box = Hive.box(exercisesBox);
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return [];

    var entries = box.values
        .map((e) => WorkoutExercise.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == userId);

    if (type != null) {
      entries = entries.where((e) => e.type == type);
    }

    return entries.toList();
  }

  static Future<void> saveExercise(WorkoutExercise exercise) async {
    await Hive.box(exercisesBox).put(exercise.id, exercise.toMap());
  }

  static Future<void> deleteExercise(String id) async {
    await Hive.box(exercisesBox).delete(id);
  }

  static Future<void> toggleCompletion(String id, DateTime date) async {
    final box = Hive.box(exercisesBox);
    final map = box.get(id);
    if (map != null) {
      final exercise = WorkoutExercise.fromMap(Map<dynamic, dynamic>.from(map));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final newLog = Map<String, bool>.from(exercise.completionLog);
      newLog[dateKey] = !(newLog[dateKey] ?? false);
      if (newLog[dateKey] == false) newLog.remove(dateKey);

      final updated = exercise.copyWith(completionLog: newLog);
      await box.put(id, updated.toMap());
    }
  }

  static double calculateDailyBurn(DateTime date) {
    final all = getExercises(null);
    double total = 0;
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    for (var ex in all) {
      if (ex.completionLog[dateKey] == true) {
        if (ex.type == WorkoutType.cardio) {
          total += ex.caloriesBurned ?? 0;
        } else {
          // حرق تقريبي لتمارين المقاومة: 5 سعرات لكل مجموعة
          total += (ex.sets ?? 0) * 5;
        }
      }
    }
    return total;
  }
}
