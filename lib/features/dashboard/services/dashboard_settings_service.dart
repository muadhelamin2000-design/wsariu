import 'package:hive_flutter/hive_flutter.dart';

class DashboardSettings {
  final Map<String, bool> visibleSections;
  final List<String> order;

  DashboardSettings({
    required this.visibleSections, 
    required this.order,
  });

  Map<String, dynamic> toMap() => {
    'visibleSections': visibleSections,
    'order': order,
  };

  factory DashboardSettings.fromMap(Map<dynamic, dynamic> map) {
    return DashboardSettings(
      visibleSections: Map<String, bool>.from(map['visibleSections'] ?? {}),
      order: List<String>.from(map['order'] ?? []),
    );
  }
}

class DashboardSettingsService {
  static const String boxName = 'dashboard_settings_box';
  
  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static DashboardSettings getSettings() {
    final box = Hive.box(boxName);
    final data = box.get('current_settings');
    DashboardSettings settings;
    
    if (data != null) {
      settings = DashboardSettings.fromMap(Map<dynamic, dynamic>.from(data));
    } else {
      settings = _getDefaultSettings();
    }

    // Ensure all required keys are present
    final defaultKeys = _getDefaultSettings().visibleSections.keys;
    for (var key in defaultKeys) {
      if (!settings.visibleSections.containsKey(key)) {
        settings.visibleSections[key] = true;
      }
    }
    
    return settings;
  }

  static DashboardSettings _getDefaultSettings() {
    return DashboardSettings(
      visibleSections: {
        'assistant': true,
        'routine_summary': true,
        'habits_summary': true,
        'worship_summary': true,
        'bunyan_summary': true,
        'study_summary': true,
        'usage': true,
      },
      order: [
        'assistant',
        'routine_summary',
        'habits_summary',
        'worship_summary',
        'bunyan_summary',
        'study_summary',
        'usage',
      ],
    );
  }

  static Future<void> saveSettings(DashboardSettings settings) async {
    final box = Hive.box(boxName);
    await box.put('current_settings', settings.toMap());
  }

  static Future<void> toggleSection(String key, bool visible) async {
    final settings = getSettings();
    settings.visibleSections[key] = visible;
    await saveSettings(settings);
  }
}
