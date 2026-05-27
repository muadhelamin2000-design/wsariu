import 'package:flutter/material.dart';

// --- Chronic Conditions & Lab Tests (New) ---

enum MedicineStatus { taken, pending, missed }
enum MedicineRemindType { fixed, interval }

class ChronicCondition {
  final String id;
  final String? patientId; // ربط الحالة بمريض محدد
  final String personName; 
  final String conditionName; // اسم المرض (مثلاً: صدفية)
  final double? weight;
  final double? height;
  final List<Medicine> medicines;
  final List<String> sideEffects; // الأعراض الجانبية الواجب مراقبتها
  final String notes;

  ChronicCondition({
    required this.id,
    this.patientId,
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
    'patientId': patientId,
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
    patientId: map['patientId'],
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
  final String instruction; 
  final int hour;
  final int minute;
  final int frequencyPerDay;
  final MedicineRemindType remindType;
  final DateTime? lastTakenAt;
  MedicineStatus status;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    this.instruction = '',
    required this.hour,
    required this.minute,
    this.frequencyPerDay = 1,
    this.remindType = MedicineRemindType.fixed,
    this.lastTakenAt,
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
    'frequencyPerDay': frequencyPerDay,
    'remindType': remindType.index,
    'lastTakenAt': lastTakenAt?.toIso8601String(),
    'status': status.index,
  };

  factory Medicine.fromMap(Map<dynamic, dynamic> map) => Medicine(
    id: map['id'],
    name: map['name'],
    dose: map['dose'],
    instruction: map['instruction'] ?? '',
    hour: map['hour'],
    minute: map['minute'],
    frequencyPerDay: map['frequencyPerDay'] ?? 1,
    remindType: MedicineRemindType.values[map['remindType'] ?? 0],
    lastTakenAt: map['lastTakenAt'] != null ? DateTime.parse(map['lastTakenAt']) : null,
    status: MedicineStatus.values[map['status'] ?? 1],
  );

  Medicine copyWith({
    MedicineStatus? status,
    DateTime? lastTakenAt,
  }) {
    return Medicine(
      id: id,
      name: name,
      dose: dose,
      instruction: instruction,
      hour: hour,
      minute: minute,
      frequencyPerDay: frequencyPerDay,
      remindType: remindType,
      lastTakenAt: lastTakenAt ?? this.lastTakenAt,
      status: status ?? this.status,
    );
  }
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
enum ActivityLevel { sedentary, light, moderate, active, veryActive }
enum HealthGoal { loseFat, cleanBulk, recomposition, maintain }

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
    userId: map['userId'] ?? '',
    gender: Gender.values[map['gender'] ?? 0],
    age: map['age'] ?? 25,
    height: (map['height'] as num?)?.toDouble() ?? 170,
    weight: (map['weight'] as num?)?.toDouble() ?? 70,
    activityLevel: ActivityLevel.values[map['activityLevel'] ?? 0],
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

class FoodTemplate {
  final String id;
  final String userId;
  final String name;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double caloriesPer100g;

  FoodTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.caloriesPer100g,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatsPer100g': fatsPer100g,
    'caloriesPer100g': caloriesPer100g,
  };

  factory FoodTemplate.fromMap(Map<dynamic, dynamic> map) => FoodTemplate(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    proteinPer100g: (map['proteinPer100g'] as num).toDouble(),
    carbsPer100g: (map['carbsPer100g'] as num).toDouble(),
    fatsPer100g: (map['fatsPer100g'] as num).toDouble(),
    caloriesPer100g: (map['caloriesPer100g'] as num).toDouble(),
  );
}

class PatientProfile {
  final String id;
  final String userId;
  final String name;
  final int? age;
  final double? weight;
  final double? height;
  final String? notes;
  final String? imagePath;

  PatientProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.age,
    this.weight,
    this.height,
    this.notes,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'age': age,
    'weight': weight,
    'height': height,
    'notes': notes,
    'imagePath': imagePath,
  };

  factory PatientProfile.fromMap(Map<dynamic, dynamic> map) => PatientProfile(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    age: map['age'],
    weight: (map['weight'] as num?)?.toDouble(),
    height: (map['height'] as num?)?.toDouble(),
    notes: map['notes'],
    imagePath: map['imagePath'],
  );
}

enum WorkoutType { cardio, home, gym }

class WorkoutExercise {
  final String id;
  final String userId;
  final String name;
  final WorkoutType type;
  final String? muscleGroup; // New: Chest, Back, etc.
  final String? subCategory; // New: Upper Chest, etc.
  final int? sets;
  final int? reps;
  final double? weight;
  final double? caloriesBurned;
  final int? durationMinutes;
  final String? videoPath; // New
  final String? imagePath; // New
  final String notes; // New
  final bool isRecurring; // New: Acts like a habit
  final DateTime date;
  final Map<String, bool> completionLog;

  WorkoutExercise({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.muscleGroup,
    this.subCategory,
    this.sets,
    this.reps,
    this.weight,
    this.caloriesBurned,
    this.durationMinutes,
    this.videoPath,
    this.imagePath,
    this.notes = '',
    this.isRecurring = false,
    required this.date,
    this.completionLog = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type.index,
    'muscleGroup': muscleGroup,
    'subCategory': subCategory,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'caloriesBurned': caloriesBurned,
    'durationMinutes': durationMinutes,
    'videoPath': videoPath,
    'imagePath': imagePath,
    'notes': notes,
    'isRecurring': isRecurring,
    'date': date.toIso8601String(),
    'completionLog': completionLog,
  };

  factory WorkoutExercise.fromMap(Map<dynamic, dynamic> map) => WorkoutExercise(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    type: WorkoutType.values[map['type'] ?? 0],
    muscleGroup: map['muscleGroup'],
    subCategory: map['subCategory'],
    sets: map['sets'],
    reps: map['reps'],
    weight: (map['weight'] as num?)?.toDouble(),
    caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
    durationMinutes: map['durationMinutes'],
    videoPath: map['videoPath'],
    imagePath: map['imagePath'],
    notes: map['notes'] ?? '',
    isRecurring: map['isRecurring'] ?? false,
    date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    completionLog: Map<String, bool>.from(map['completionLog'] ?? {}),
  );

  WorkoutExercise copyWith({
    String? name,
    WorkoutType? type,
    String? muscleGroup,
    String? subCategory,
    int? sets,
    int? reps,
    double? weight,
    double? caloriesBurned,
    int? durationMinutes,
    String? videoPath,
    String? imagePath,
    String? notes,
    bool? isRecurring,
    Map<String, bool>? completionLog,
    DateTime? date,
  }) {
    return WorkoutExercise(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      subCategory: subCategory ?? this.subCategory,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      videoPath: videoPath ?? this.videoPath,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      date: date ?? this.date,
      completionLog: completionLog ?? this.completionLog,
    );
  }
}
