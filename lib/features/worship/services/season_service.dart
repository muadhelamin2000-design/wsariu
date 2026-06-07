import 'package:hive_flutter/hive_flutter.dart';
import '../models/season_model.dart';

class SeasonService {
  static const String boxName = 'worship_seasons_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<WorshipSeason> getSeasons() {
    final box = Hive.box(boxName);
    return box.values
        .map((e) => WorshipSeason.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static Future<void> saveSeason(WorshipSeason season) async {
    await Hive.box(boxName).put(season.id, season.toMap());
  }

  static Future<void> deleteSeason(String id) async {
    await Hive.box(boxName).delete(id);
  }
}
