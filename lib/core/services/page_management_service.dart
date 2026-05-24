import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

import '../../features/dashboard/services/navigation_service.dart';

class PageItem {
  final String id;
  String name;
  String route;
  String iconData; 
  String sectionKey;
  int colorValue;
  int? backgroundColorValue; // New field for page background
  bool isLocked; // New field for selective lock

  PageItem({
    required this.id,
    required this.name,
    required this.route,
    required this.iconData,
    required this.sectionKey,
    this.colorValue = 0xFF0F3D2E,
    this.backgroundColorValue,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'route': route,
    'iconData': iconData,
    'sectionKey': sectionKey,
    'colorValue': colorValue,
    'backgroundColorValue': backgroundColorValue,
    'isLocked': isLocked,
  };

  factory PageItem.fromMap(Map<dynamic, dynamic> map) {
    return PageItem(
      id: map['id'],
      name: map['name'],
      route: map['route'],
      iconData: map['iconData']?.toString() ?? '🎯',
      sectionKey: map['sectionKey'],
      colorValue: map['colorValue'] ?? 0xFF0F3D2E,
      backgroundColorValue: map['backgroundColorValue'],
      isLocked: map['isLocked'] ?? false,
    );
  }

  static const List<int> availableColors = [
    0xFF0F3D2E, 0xFF1B4D3E, 0xFFB71C1C, 0xFF0D47A1, 0xFF4A148C, 
    0xFFE65100, 0xFFC8A24A, 0xFF263238, 0xFF006064, 0xFF827717,
    0xFFD32F2F, 0xFFC2185B, 0xFF7B1FA2, 0xFF512DA8, 0xFF303F9F,
    0xFF1976D2, 0xFF0288D1, 0xFF0097A7, 0xFF00796B, 0xFF388E3C,
    0xFF689F38, 0xFFAF1212, 0xFFFBC02D, 0xFFFFA000, 0xFFF57C00,
    0xFFE64A19, 0xFF5D4037, 0xFF616161, 0xFF455A64, 0xFF121212,
  ];

  static const List<IconData> availableIcons = [
    Icons.check_circle_outline,
    Icons.repeat,
    Icons.bolt,
    Icons.trending_up,
    Icons.analytics_outlined,
    Icons.mosque_outlined,
    Icons.stairs,
    Icons.book_outlined,
    Icons.favorite_border,
    Icons.volunteer_activism_outlined,
    Icons.library_books_outlined,
    Icons.restaurant_menu,
    Icons.fitness_center,
    Icons.nights_stay_outlined,
    Icons.hub_outlined,
    Icons.timer_outlined,
    Icons.chat_bubble_outline,
    Icons.mood_outlined,
    Icons.people_outline,
    Icons.star_outline,
    Icons.shield_outlined,
    Icons.lightbulb_outline,
  ];
}

class SectionItem {
  final String key;
  String name;
  String icon;

  SectionItem({required this.key, required this.name, required this.icon});

  Map<String, dynamic> toMap() => {'key': key, 'name': name, 'icon': icon};
  factory SectionItem.fromMap(Map<dynamic, dynamic> map) => SectionItem(key: map['key'], name: map['name'], icon: map['icon']);
}

class PageManagementService {
  static const String boxName = 'pages_management_box';
  static const String sectionBoxName = 'sections_management_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
    await Hive.openBox(sectionBoxName);
    
    // فحص الإصدار لتطبيق الهيكلة الجديدة (الجوانب الأربعة)
    final settingsBox = await Hive.openBox('settings_box');
    final currentVersion = settingsBox.get('pages_structure_version', defaultValue: 0);
    
    if (currentVersion < 9) {
      await Hive.box(boxName).clear();
      await Hive.box(sectionBoxName).clear();
      // فتح صندوق شريط التنقل قبل مسحه لتجنب خطأ Box not found
      final navBox = await Hive.openBox(NavigationService.boxName);
      await navBox.clear();
      await _seedDefaultSections();
      await _seedDefaultPages();
      await settingsBox.put('pages_structure_version', 9);
    }
  }

  static List<SectionItem> getSections() {
    final box = Hive.box(sectionBoxName);
    return box.values.map((s) => SectionItem.fromMap(Map<dynamic, dynamic>.from(s))).toList();
  }

  static Future<void> saveSection(SectionItem section) async {
    final box = Hive.box(sectionBoxName);
    await box.put(section.key, section.toMap());
  }

  static Future<void> _seedDefaultSections() async {
    final defaults = [
      SectionItem(key: 'spiritual', name: 'الجانب الروحي', icon: '🕌'),
      SectionItem(key: 'psychological', name: 'الجانب النفسي', icon: '🌿'),
      SectionItem(key: 'physical', name: 'الجانب البدني', icon: '💪'),
      SectionItem(key: 'mental', name: 'الجانب العقلي', icon: '🧠'),
    ];
    for (var s in defaults) {
      await saveSection(s);
    }
  }

  static List<PageItem> getPagesForSection(String sectionKey) {
    final box = Hive.box(boxName);
    return box.values.map((p) => PageItem.fromMap(Map<dynamic, dynamic>.from(p))).where((p) => p.sectionKey == sectionKey).toList();
  }

  static List<PageItem> getAllPages() {
    final box = Hive.box(boxName);
    return box.values.map((p) => PageItem.fromMap(Map<dynamic, dynamic>.from(p))).toList();
  }

  static Future<void> savePage(PageItem page) async {
    final box = Hive.box(boxName);
    await box.put(page.id, page.toMap());
  }

  static Future<void> deletePage(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  static Future<void> _seedDefaultPages() async {
    final defaults = [
      // 1. الجانب الروحي (spiritual)
      PageItem(id: 'quran', name: 'القرآن الكريم', route: '/worship/quran', iconData: '📖', sectionKey: 'spiritual'),
      PageItem(id: 'addiction', name: 'عوضه الله', route: '/worship/awadho-allah', iconData: '🤝', sectionKey: 'spiritual'),
      PageItem(id: 'knowledge', name: 'حُجَّة لي', route: '/worship/hujja-li', iconData: '📚', sectionKey: 'spiritual'),
      PageItem(id: 'prayers', name: 'العبادات', route: '/worship/prayers', iconData: '🕌', sectionKey: 'spiritual'),
      PageItem(id: 'secret', name: 'سر مع الله', route: '/worship/sir-ma3-allah', iconData: '🤍', sectionKey: 'spiritual'),
      PageItem(id: 'zad', name: 'البنيان', route: '/worship/zad-maad', iconData: '🪜', sectionKey: 'spiritual'),
      
      // 2. الجانب العقلي (mental)
      PageItem(id: 'linked', name: 'المذاكرة المترابطة', route: '/learning/linked-studies', iconData: '🕸️', sectionKey: 'mental'),
      PageItem(id: 'habits', name: 'العادات', route: '/discipline/habits', iconData: '✅', sectionKey: 'mental'),
      PageItem(id: 'incremental', name: 'وتزودوا', route: '/discipline/incremental-habits', iconData: '📈', sectionKey: 'mental'),
      PageItem(id: 'progress', name: 'متابعة التقدم', route: '/discipline/progress', iconData: '📊', sectionKey: 'mental'),
      PageItem(id: 'routine', name: 'الروتين اليومي', route: '/discipline/daily-routine', iconData: '🔄', sectionKey: 'mental'),
      PageItem(id: 'tasks', name: 'المهام السريعة', route: '/discipline/quick-tasks', iconData: '⚡', sectionKey: 'mental'),
      PageItem(id: 'sessions', name: 'جلسات الدراسة', route: '/learning/study-sessions', iconData: '⏲️', sectionKey: 'mental'),

      // 3. الجانب البدني (physical)
      PageItem(id: 'healthcare', name: 'لبدنك عليك حق ولاهلك عليك حق', route: '/health/care', iconData: '🩺', sectionKey: 'physical'),
      PageItem(id: 'nutrition', name: 'التغذية', route: '/health/nutrition', iconData: '🥗', sectionKey: 'physical'),
      PageItem(id: 'sports', name: 'الرياضة', route: '/health/sports', iconData: '🏋️', sectionKey: 'physical'),
      PageItem(id: 'sleep', name: 'النوم الذكي', iconData: '🌙', route: '/health/sleep', sectionKey: 'physical'),
      
      // 4. الجانب النفسي (psychological)
      PageItem(id: 'dialogues', name: 'حوارات ومذكرات', route: '/learning/dialogues', iconData: '💬', sectionKey: 'psychological'),
      PageItem(id: 'entertainment', name: 'الترفيه الذكي', route: '/discipline/entertainment', iconData: '🎭', sectionKey: 'psychological'),
      PageItem(id: 'wissal', name: 'وِصال', route: '/discipline/wissal', iconData: '👥', sectionKey: 'psychological'),
      PageItem(id: 'khaznati', name: 'خزنتي', route: '/discipline/khaznati', iconData: '💰', sectionKey: 'psychological'),
      PageItem(id: 'journal', name: 'صحيفتي', route: '/worship/journal', iconData: '📖', sectionKey: 'psychological'),
    ];
    
    for (var p in defaults) {
      await savePage(p);
    }
  }
}
