class AppBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt.toIso8601String(),
    };
  }

  factory AppBadge.fromMap(Map<dynamic, dynamic> map) {
    return AppBadge(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      unlockedAt: DateTime.parse(map['unlockedAt']),
    );
  }
}
