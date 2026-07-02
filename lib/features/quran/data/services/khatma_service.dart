import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class KhatmaModel {
  final String id;
  final String name;
  final int targetPages;
  final int currentPage;
  final DateTime startDate;
  final bool isCompleted;

  KhatmaModel({
    required this.id,
    required this.name,
    required this.targetPages,
    this.currentPage = 0,
    required this.startDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'targetPages': targetPages,
    'currentPage': currentPage,
    'startDate': startDate.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory KhatmaModel.fromMap(Map<dynamic, dynamic> map) => KhatmaModel(
    id: map['id'],
    name: map['name'],
    targetPages: map['targetPages'],
    currentPage: map['currentPage'],
    startDate: DateTime.parse(map['startDate']),
    isCompleted: map['isCompleted'] ?? false,
  );
}

class KhatmaService {
  static const String boxName = 'khatma_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<KhatmaModel> getAllKhatmas() {
    final box = Hive.box(boxName);
    return box.values.map((e) => KhatmaModel.fromMap(Map<dynamic, dynamic>.from(e))).toList();
  }

  static Future<void> addKhatma(String name, int targetPages) async {
    final id = const Uuid().v4();
    final khatma = KhatmaModel(id: id, name: name, targetPages: targetPages, startDate: DateTime.now());
    await Hive.box(boxName).put(id, khatma.toMap());
  }

  static Future<void> updateProgress(String id, int page) async {
    final box = Hive.box(boxName);
    final map = box.get(id);
    if (map != null) {
      final khatma = KhatmaModel.fromMap(Map<dynamic, dynamic>.from(map));
      final updated = KhatmaModel(
        id: khatma.id,
        name: khatma.name,
        targetPages: khatma.targetPages,
        currentPage: page,
        startDate: khatma.startDate,
        isCompleted: page >= khatma.targetPages,
      );
      await box.put(id, updated.toMap());
    }
  }

  static Future<void> deleteKhatma(String id) async {
    await Hive.box(boxName).delete(id);
  }
}
