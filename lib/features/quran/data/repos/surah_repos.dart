import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah_item_model.dart';

class SurahRepo {
  static List<SurahItemModel>? _cachedSurahs;

  static Future<List<SurahItemModel>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    
    try {
      final String response = await rootBundle.loadString('assets/json/surahs_name.json');
      final data = await json.decode(response);
      final List<dynamic> surahsJson = data['data']['surahs'];
      _cachedSurahs = surahsJson.map((json) => SurahItemModel.fromJson(json)).toList();
      return _cachedSurahs!;
    } catch (e) {
      return [];
    }
  }
}
