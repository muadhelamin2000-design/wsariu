import 'package:hive_flutter/hive_flutter.dart';
import '../models/zad_model.dart';
import '../../profile/services/user_service.dart';

class ZadService {
  static const String boxName = 'zad_deeds_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<ZadDeed> getDeeds() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .where((v) => v is Map && v.containsKey('id'))
        .map((d) => ZadDeed.fromMap(Map<dynamic, dynamic>.from(d as Map)))
        .where((d) => d.userId == currentUserId)
        .toList();
  }

  static Future<void> saveDeed(ZadDeed deed) async {
    final box = Hive.box(boxName);
    await box.put(deed.id, deed.toMap());
  }

  static Future<void> deleteDeed(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }
}
