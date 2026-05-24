class UserModel {
  final String id;
  final String name;
  final String avatar;
  final String email;
  final String? photoPath;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.avatar = '👤',
    this.email = '',
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'email': email,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      avatar: map['avatar'] ?? '👤',
      email: map['email'] ?? '',
      photoPath: map['photoPath'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}
