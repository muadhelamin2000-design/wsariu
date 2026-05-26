import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../utils/preferences/preferences.dart';
import '../utils/preferences/preferences_utils.dart';

class QuranRepository {
  static const hafsPagesNumber = 604;

  Future<List<dynamic>> getQuran() async {
    try {
      String content = await rootBundle.loadString(
        'assets/json/quran_hafs.json',
      );
      final dynamic decoded = jsonDecode(content);

      List<dynamic> allAyahs = [];

      if (decoded is List) {
        allAyahs = decoded;
      } else if (decoded is Map &&
          decoded['data'] != null &&
          decoded['data']['surahs'] != null) {
        for (var surah in decoded['data']['surahs']) {
          if (surah['ayahs'] != null) {
            for (var ayah in surah['ayahs']) {
              ayah['surahNumber'] = surah['number'];
              ayah['sora_name_ar'] = surah['name'];
              ayah['sora_name_en'] = surah['englishName'];
              allAyahs.add(ayah);
            }
          }
        }
      }

      allAyahs.sort((a, b) {
        int surahCompare = (a['sora'] ?? a['surahNumber'] ?? 0).compareTo(
          b['sora'] ?? b['surahNumber'] ?? 0,
        );
        if (surahCompare != 0) return surahCompare;
        return (a['aya_no'] ?? a['numberInSurah'] ?? 0).compareTo(
          b['aya_no'] ?? b['numberInSurah'] ?? 0,
        );
      });

      for (int i = 0; i < allAyahs.length; i++) {
        allAyahs[i]['id'] = i + 1;
      }

      return allAyahs;
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveLastPage(int lastPage) async =>
      PreferencesUtils().setInt(Preferences().lastPage, lastPage);

  int? getLastPage() => PreferencesUtils().getInt(Preferences().lastPage);

  bool hasLastPage() =>
      PreferencesUtils().containsKey(Preferences().lastPage) ?? false;

  Future<bool> saveBookmarks(List<Bookmark> bookmarks) =>
      PreferencesUtils().setStringList(
        Preferences().bookmarks,
        bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList(),
      );

  List<Bookmark> getBookmarks() =>
      (PreferencesUtils().getStringList(Preferences().bookmarks) ?? [])
          .map((bookmark) => Bookmark.fromJson(json.decode(bookmark)))
          .toList();

  Future<bool> savePageColor(int colorValue) async =>
      PreferencesUtils().setInt(Preferences().pageColor, colorValue);

  int? getPageColor() => PreferencesUtils().getInt(Preferences().pageColor);

  Future<bool> saveHighlights(List<Highlight> highlights) =>
      PreferencesUtils().setStringList(
        Preferences().highlights,
        highlights.map((h) => json.encode(h.toJson())).toList(),
      );

  List<Highlight> getHighlights() =>
      (PreferencesUtils().getStringList(Preferences().highlights) ?? [])
          .map((h) => Highlight.fromJson(json.decode(h)))
          .toList();
}
