import 'package:hive_flutter/hive_flutter.dart';

class QuickLinkService {
  static const String boxName = 'quick_links_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  /// ربط صفحتين ببعضهما بشكل متبادل
  static Future<void> linkPages(String pageAId, String pageBId) async {
    final box = Hive.box(boxName);
    
    // روابط الصفحة A
    List<String> linksA = List<String>.from(box.get(pageAId) ?? []);
    if (!linksA.contains(pageBId)) {
      linksA.add(pageBId);
      await box.put(pageAId, linksA);
    }

    // روابط الصفحة B (الربط المتبادل)
    List<String> linksB = List<String>.from(box.get(pageBId) ?? []);
    if (!linksB.contains(pageAId)) {
      linksB.add(pageAId);
      await box.put(pageBId, linksB);
    }
  }

  /// فك الارتباط بين صفحتين
  static Future<void> unlinkPages(String pageAId, String pageBId) async {
    final box = Hive.box(boxName);
    
    List<String> linksA = List<String>.from(box.get(pageAId) ?? []);
    linksA.remove(pageBId);
    await box.put(pageAId, linksA);

    List<String> linksB = List<String>.from(box.get(pageBId) ?? []);
    linksB.remove(pageAId);
    await box.put(pageBId, linksB);
  }

  /// الحصول على قائمة الروابط لصفحة معينة
  static List<String> getLinksForPage(String pageId) {
    final box = Hive.box(boxName);
    return List<String>.from(box.get(pageId) ?? []);
  }
}
