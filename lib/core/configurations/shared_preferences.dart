import 'package:hive_flutter/hive_flutter.dart';

class CacheHelper {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('cache_helper_box');
  }

  static Future<void> saveData({required String key, required dynamic value}) async {
    await _box.put(key, value);
  }

  static dynamic getData({required String key}) {
    return _box.get(key);
  }

  static Future<void> removeData({required String key}) async {
    await _box.delete(key);
  }
}
