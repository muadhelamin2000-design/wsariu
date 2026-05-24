import 'package:hive_flutter/hive_flutter.dart';
import '../models/life_link_model.dart';
import 'user_service.dart';

class LifeLinkService {
  static const String boxName = 'life_links_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<LifeLink> getLinks() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((l) => LifeLink.fromMap(Map<dynamic, dynamic>.from(l)))
        .where((l) => l.userId == currentUserId)
        .toList();
  }

  static Future<void> saveLink(LifeLink link) async {
    final box = Hive.box(boxName);
    await box.put(link.id, link.toMap());
  }

  static Future<void> deleteLink(String id) async {
    await Hive.box(boxName).delete(id);
  }
}
