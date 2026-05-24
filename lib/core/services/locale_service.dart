import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleService {
  static const String boxName = 'locale_settings_box';
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar', 'SA'));

  static Future<void> init() async {
    await Hive.openBox(boxName);
    final box = Hive.box(boxName);
    final String langCode = box.get('language_code', defaultValue: 'ar');
    final String countryCode = box.get('country_code', defaultValue: 'SA');
    localeNotifier.value = Locale(langCode, countryCode);
  }

  static Future<void> setLocale(String langCode, String countryCode) async {
    final box = Hive.box(boxName);
    await box.put('language_code', langCode);
    await box.put('country_code', countryCode);
    localeNotifier.value = Locale(langCode, countryCode);
  }

  static bool get isArabic => localeNotifier.value.languageCode == 'ar';
}
