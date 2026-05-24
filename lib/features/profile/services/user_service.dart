import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class UserService {
  static const String boxName = 'users_box';
  static UserModel? currentUser;

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<UserModel> getUsers() {
    final box = Hive.box(boxName);
    return box.values.map((u) => UserModel.fromMap(Map<dynamic, dynamic>.from(u))).toList();
  }

  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box(boxName);
    await box.put(user.id, user.toMap());
  }

  static Future<void> deleteUser(String id) async {
    await Hive.box(boxName).delete(id);
  }
}
