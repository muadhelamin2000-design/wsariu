import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  static const String boxName = 'theme_box';
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static Future<void> init() async {
    await Hive.openBox(boxName);
    final isDark = Hive.box(boxName).get('isDarkMode', defaultValue: false);
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggleTheme() {
    if (themeNotifier.value == ThemeMode.light) {
      themeNotifier.value = ThemeMode.dark;
      Hive.box(boxName).put('isDarkMode', true);
    } else {
      themeNotifier.value = ThemeMode.light;
      Hive.box(boxName).put('isDarkMode', false);
    }
  }

  static bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
}
