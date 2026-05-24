import 'package:uuid/uuid.dart';
import '../../profile/models/user_model.dart';
import '../../profile/services/user_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  static const String authBoxName = 'local_auth_box';
  
  static Future<void> init() async {
    await Hive.openBox(authBoxName);
    final userId = loggedInUserId;
    if (userId != null) {
      final users = UserService.getUsers();
      try {
        UserService.currentUser = users.firstWhere((u) => u.id == userId);
      } catch (e) {
        // User not found
      }
    }
  }

  static String? get loggedInUserId {
    final box = Hive.box(authBoxName);
    return box.get('current_user_id');
  }

  static Future<UserModel?> login(String name, String pin) async {
    final users = UserService.getUsers();
    try {
      // البحث عن مستخدم بنفس الاسم والـ PIN
      final user = users.firstWhere(
        (u) => u.name == name && u.avatar == pin, // نستخدم avatar مؤقتاً لتخزين الـ PIN لتبسيط الكود
      );
      
      final authBox = Hive.box(authBoxName);
      await authBox.put('current_user_id', user.id);
      UserService.currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel?> register(String name, String pin) async {
    final id = const Uuid().v4();
    final newUser = UserModel(
      id: id,
      name: name,
      avatar: pin, // تخزين الـ PIN محلياً
      createdAt: DateTime.now(),
    );

    await UserService.saveUser(newUser);
    final authBox = Hive.box(authBoxName);
    await authBox.put('current_user_id', id);
    UserService.currentUser = newUser;
    return newUser;
  }

  static Future<void> logout() async {
    final authBox = Hive.box(authBoxName);
    await authBox.delete('current_user_id');
    UserService.currentUser = null;
  }
}
