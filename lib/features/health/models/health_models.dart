import 'package:flutter/material.dart';

// --- Chronic Conditions & Lab Tests (New) ---

enum MedicineStatus { taken, pending, missed }

class ChronicCondition {
  final String id;
  final String personName; // لنفسي أو اسم فرد العائلة
  final String conditionName; // اسم المرض (مثلاً: صدفية)
  final double? weight;
  final double? height;
  final List<Medicine> medicines;
  final List<String> sideEffects; // الأعراض الجانبية الواجب مراقبتها
  final String notes;

  ChronicCondition({
    required this.id,
    required this.personName,
    required this.conditionName,
    this.weight,
    this.height,
    this.medicines = const [],
    this.sideEffects = const [],
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'personName': personName,
    'conditionName': conditionName,
    'weight': weight,
    'height': height,
    'medicines': medicines.map((m) => m.toMap()).toList(),
    'sideEffects': sideEffects,
    'notes': notes,
  };

  factory ChronicCondition.fromMap(Map<dynamic, dynamic> map) => ChronicCondition(
    id: map['id'],
    personName: map['personName'],
    conditionName: map['conditionName'],
    weight: (map['weight'] as num?)?.toDouble(),
    height: (map['height'] as num?)?.toDouble(),
    medicines: (map['medicines'] as List?)?.map((m) => Medicine.fromMap(m)).toList() ?? [],
    sideEffects: List<String>.from(map['sideEffects'] ?? []),
    notes: map['notes'] ?? '',
  );
}

class Medicine {
  final String id;
  final String name;
  final String dose;
  final String instruction; // (قبل الأكل، بعد الأكل، دهان...)
  final int hour;
  final int minute;
  MedicineStatus status;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    this.instruction = '',
    required this.hour,
    required this.minute,
    this.status = MedicineStatus.pending,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dose': dose,
    'instruction': instruction,
    'hour': hour,
    'minute': minute,
    'status': status.index,
  };

  factory Medicine.fromMap(Map<dynamic, dynamic> map) => Medicine(
    id: map['id'],
    name: map['name'],
    dose: map['dose'],
    instruction: map['instruction'] ?? '',
    hour: map['hour'],
    minute: map['minute'],
    status: MedicineStatus.values[map['status'] ?? 1],
  );
}

class LabResult {
  final DateTime date;
  final double value;
  final String? unit;

  LabResult({required this.date, required this.value, this.unit});

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'value': value,
    'unit': unit,
  };

  factory LabResult.fromMap(Map<dynamic, dynamic> map) => LabResult(
    date: DateTime.parse(map['date']),
    value: (map['value'] as num).toDouble(),
    unit: map['unit'],
  );
}

class GradualLabTest {
  final String id;
  final String conditionId; // ربط التحليل بحالة مرضية
  final String testName;
  final DateTime startDate;
  final List<int> intervalsInDays; 
  int currentIntervalIndex;
  final String reason;
  final List<LabResult> results;

  GradualLabTest({
    required this.id,
    required this.conditionId,
    required this.testName,
    required this.startDate,
    this.intervalsInDays = const [3, 7, 14, 30, 90, 180],
    this.currentIntervalIndex = 0,
    this.reason = '',
    this.results = const [],
  });

  DateTime get nextTestDate {
    int days = intervalsInDays[currentIntervalIndex % intervalsInDays.length];
    return startDate.add(Duration(days: days));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'conditionId': conditionId,
    'testName': testName,
    'startDate': startDate.toIso8601String(),
    'intervalsInDays': intervalsInDays,
    'currentIntervalIndex': currentIntervalIndex,
    'reason': reason,
    'results': results.map((r) => r.toMap()).toList(),
  };

  factory GradualLabTest.fromMap(Map<dynamic, dynamic> map) => GradualLabTest(
    id: map['id'],
    conditionId: map['conditionId'] ?? '',
    testName: map['testName'],
    startDate: DateTime.parse(map['startDate']),
    intervalsInDays: List<int>.from(map['intervalsInDays'] ?? []),
    currentIntervalIndex: map['currentIntervalIndex'] ?? 0,
    reason: map['reason'] ?? '',
    results: (map['results'] as List?)?.map((r) => LabResult.fromMap(r)).toList() ?? [],
  );
}

// --- Nutrition & Workout Models (Old, Keep for Compatibility) ---

enum Gender { male, female }
enum ActivityLevel { low, medium, high }
enum HealthGoal { loseFat, gainMuscle, recomposition, maintain }

class UserHealthProfile {
  final String userId;
  final Gender gender;
  final int age;
  final double height;
  final double weight;
  final ActivityLevel activityLevel;
  final HealthGoal goal;

  UserHealthProfile({
    required this.userId,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'gender': gender.index,
    'age': age,
    'height': height,
    'weight': weight,
    'activityLevel': activityLevel.index,
    'goal': goal.index,
  };

  factory UserHealthProfile.fromMap(Map<dynamic, dynamic> map) => UserHealthProfile(
    userId: map['userId'],
    gender: Gender.values[map['gender'] ?? 0],
    age: map['age'] ?? 0,
    height: (map['height'] as num?)?.toDouble() ?? 0,
    weight: (map['weight'] as num?)?.toDouble() ?? 0,
    activityLevel: ActivityLevel.values[map['activityLevel'] ?? 1],
    goal: HealthGoal.values[map['goal'] ?? 0],
  );
}

class FoodEntry {
  final String id;
  final String userId;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime date;

  FoodEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'date': date.toIso8601String(),
  };

  factory FoodEntry.fromMap(Map<dynamic, dynamic> map) => FoodEntry(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    calories: (map['calories'] as num).toDouble(),
    protein: (map['protein'] as num).toDouble(),
    carbs: (map['carbs'] as num).toDouble(),
    fats: (map['fats'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );
}

enum WorkoutType { cardio, home, gym }

class WorkoutExercise {
  final String id;
  final String userId;
  final String name;
  final WorkoutType type;
  final int? sets;
  final int? reps;
  final double? weight;
  final double? caloriesBurned;
  final int? durationMinutes;
  final DateTime date;
  final Map<String, bool> completionLog;

  WorkoutExercise({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.sets,
    this.reps,
    this.weight,
    this.caloriesBurned,
    this.durationMinutes,
    required this.date,
    this.completionLog = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type.index,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'caloriesBurned': caloriesBurned,
    'durationMinutes': durationMinutes,
    'date': date.toIso8601String(),
    'completionLog': completionLog,
  };

  factory WorkoutExercise.fromMap(Map<dynamic, dynamic> map) => WorkoutExercise(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    type: WorkoutType.values[map['type'] ?? 0],
    sets: map['sets'],
    reps: map['reps'],
    weight: (map['weight'] as num?)?.toDouble(),
    caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
    durationMinutes: map['durationMinutes'],
    date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    completionLog: Map<String, bool>.from(map['completionLog'] ?? {}),
  );

  WorkoutExercise copyWith({Map<String, bool>? completionLog}) {
    return WorkoutExercise(
      id: id,
      userId: userId,
      name: name,
      type: type,
      sets: sets,
      reps: reps,
      weight: weight,
      caloriesBurned: caloriesBurned,
      durationMinutes: durationMinutes,
      date: date,
      completionLog: completionLog ?? this.completionLog,
    );
  }
}
