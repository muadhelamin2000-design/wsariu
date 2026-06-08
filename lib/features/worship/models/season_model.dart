import 'package:uuid/uuid.dart';

class WorshipSeason {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> worshipIds;
  final bool isActive;

  WorshipSeason({
    String? id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.worshipIds = const [],
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'worshipIds': worshipIds,
    'isActive': isActive,
  };

  factory WorshipSeason.fromMap(Map<dynamic, dynamic> map) => WorshipSeason(
    id: map['id'],
    name: map['name'],
    startDate: DateTime.parse(map['startDate']),
    endDate: DateTime.parse(map['endDate']),
    worshipIds: List<String>.from(map['worshipIds'] ?? []),
    isActive: map['isActive'] ?? true,
  );
}
