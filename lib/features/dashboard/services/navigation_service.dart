import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

class NavTab {
  final String id;
  final String label;
  final int? iconCode; // Store as int
  final String? emoji; 
  final String route;
  final String sectionKey;

  NavTab({
    required this.id,
    required this.label,
    this.iconCode,
    this.emoji,
    required this.route,
    required this.sectionKey,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'icon': iconCode,
    'emoji': emoji,
    'route': route,
    'sectionKey': sectionKey,
  };

  factory NavTab.fromMap(Map<dynamic, dynamic> map) {
    return NavTab(
      id: map['id'],
      label: map['label'],
      iconCode: map['icon'],
      emoji: map['emoji'],
      route: map['route'],
      sectionKey: map['sectionKey'],
    );
  }
}

class NavigationService {
  static const String boxName = 'navigation_settings_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<NavTab> getTabs() {
    final box = Hive.box(boxName);
    final data = box.get('nav_tabs');
    List<NavTab> list;
    
    // فحص إذا كان الشريط يحتوي على الأقسام القديمة (مثل الصلاة أو الصحة) ومسحها
    bool isOldStructure = false;
    if (data != null) {
      list = (data as List).map((t) => NavTab.fromMap(Map<dynamic, dynamic>.from(t))).toList();
      isOldStructure = list.any((t) => t.id == 'discipline' || t.id == 'worship' || t.id == 'health');
    } else {
      isOldStructure = true;
    }

    if (isOldStructure) {
      list = _saveAndReturnDefaults(box);
    } else {
      list = (data as List).map((t) => NavTab.fromMap(Map<dynamic, dynamic>.from(t))).toList();
    }

    // مزامنة الأسماء والأيقونات مع الأقسام الفعلية بشكل فوري لضمان التطابق
    final sectionsBox = Hive.box('sections_management_box');
    if (sectionsBox.isNotEmpty) {
      bool changed = false;
      for (int i = 0; i < list.length; i++) {
        final tab = list[i];
        final sectionData = sectionsBox.get(tab.sectionKey);
        if (sectionData != null) {
          final sName = sectionData['name'];
          final sEmoji = sectionData['icon'];
          
          if (tab.label != sName || tab.emoji != sEmoji) {
            list[i] = NavTab(
              id: tab.id,
              label: sName,
              iconCode: tab.iconCode,
              emoji: sEmoji,
              route: tab.route,
              sectionKey: tab.sectionKey,
            );
            changed = true;
          }
        }
      }
      if (changed) {
        saveTabs(list);
      }
    }

    return list;
  }

  static Future<void> syncTabsWithSections() async {
    final box = Hive.box(boxName);
    final data = box.get('nav_tabs');
    if (data == null) return;

    List<NavTab> currentTabs = (data as List).map((t) => NavTab.fromMap(Map<dynamic, dynamic>.from(t))).toList();
    final sectionsBox = Hive.box('sections_management_box');
    
    bool changed = false;
    for (int i = 0; i < currentTabs.length; i++) {
      final tab = currentTabs[i];
      final sectionData = sectionsBox.get(tab.sectionKey);
      
      if (sectionData != null) {
        final sName = sectionData['name'];
        final sEmoji = sectionData['icon'];
        
        if (tab.label != sName || tab.emoji != sEmoji) {
          currentTabs[i] = NavTab(
            id: tab.id,
            label: sName,
            iconCode: tab.iconCode,
            emoji: sEmoji,
            route: tab.route,
            sectionKey: tab.sectionKey,
          );
          changed = true;
        }
      }
    }

    if (changed) {
      await saveTabs(currentTabs);
    }
  }

  static List<NavTab> _saveAndReturnDefaults(Box box) {
    final defaults = [
      NavTab(id: 'browser', label: 'المتصفح', iconCode: Icons.language_outlined.codePoint, route: '/browser', sectionKey: 'browser'),
      NavTab(id: 'spiritual', label: 'الجانب الروحي', iconCode: Icons.mosque_outlined.codePoint, emoji: '🕌', route: '/worship', sectionKey: 'spiritual'),
      NavTab(id: 'psychological', label: 'الجانب النفسي', iconCode: Icons.spa_outlined.codePoint, emoji: '🌿', route: '/learning', sectionKey: 'psychological'),
      NavTab(id: 'physical', label: 'شفاء', iconCode: Icons.healing_outlined.codePoint, emoji: '🛡️', route: '/health', sectionKey: 'physical'),
      NavTab(id: 'mental', label: 'الجانب العقلي', iconCode: Icons.psychology_outlined.codePoint, emoji: '🧠', route: '/discipline', sectionKey: 'mental'),
    ];
    box.put('nav_tabs', defaults.map((t) => t.toMap()).toList());
    return defaults;
  }

  static Future<void> saveTabs(List<NavTab> tabs) async {
    final box = Hive.box(boxName);
    await box.put('nav_tabs', tabs.map((t) => t.toMap()).toList());
  }
}
