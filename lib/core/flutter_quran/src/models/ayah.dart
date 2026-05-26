import 'package:arabic_search/arabic_search.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';

class TajweedRule {
  final int start;
  final int end;
  final String rule;

  TajweedRule({required this.start, required this.end, required this.rule});

  factory TajweedRule.fromJson(Map<String, dynamic> json) {
    return TajweedRule(start: json['start'], end: json['end'], rule: json['rule']);
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end, 'rule': rule};
}

class Ayah {
  final int id, jozz, surahNumber, page, lineStart, lineEnd, ayahNumber, quarter, hizb;
  final String surahNameEn, surahNameAr, ayahText;
  late final String normalizedText;
  String ayah;
  final bool sajda;
  bool centered;
  final String? audio;
  final bool isQuarter;
  List<TajweedRule>? tajweedRules;
  final List<Ayah>? similarAyahs;
  final int ayahOffset;

  Ayah({
    required this.id,
    required this.jozz,
    required this.surahNumber,
    required this.page,
    required this.lineStart,
    required this.lineEnd,
    required this.ayahNumber,
    required this.quarter,
    required this.hizb,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.ayah,
    required this.ayahText,
    required this.sajda,
    required this.centered,
    this.audio,
    this.isQuarter = false,
    this.tajweedRules,
    this.similarAyahs,
    this.ayahOffset = 0,
  }) {
    normalizedText = ArabicText.normalize(ayahText);
  }

  factory Ayah.fromJson(Map<String, dynamic> json) {
    String ayahText = json['aya_text'] ?? json['text'] ?? '';
    if (ayahText.isNotEmpty) {
      if (ayahText[ayahText.length - 1] == '\n') {
        ayahText = ayahText.replaceRange(ayahText.length - 1, ayahText.length - 1, ' ');
      } else {
        ayahText = '$ayahText ';
      }
    }

    return Ayah(
      id: json['id'] ?? json['number'] ?? 0,
      jozz: json['jozz'] ?? json['juz'] ?? 0,
      surahNumber: json['sora'] ?? json['surahNumber'] ?? 0,
      page: json['page'] ?? 0,
      lineStart: json['line_start'] ?? 0,
      lineEnd: json['line_end'] ?? 0,
      ayahNumber: json['aya_no'] ?? json['numberInSurah'] ?? 0,
      quarter: json['hizbQuarter'] ?? -1,
      hizb: json['hizb'] ?? -1,
      surahNameEn: json['sora_name_en'] ?? json['surahNameEn'] ?? '',
      surahNameAr: json['sora_name_ar'] ?? json['surahNameAr'] ?? '',
      ayah: ayahText,
      ayahText: json['aya_text_emlaey'] ?? json['text'] ?? '',
      sajda: json['sajda'] ?? false,
      centered: json['centered'] ?? false,
      audio: json['audio'],
      isQuarter: json['is_quarter'] ?? false,
      tajweedRules: json['tajweed_rules'] != null
          ? (json['tajweed_rules'] as List).map((i) => TajweedRule.fromJson(i)).toList()
          : null,
      similarAyahs: json['similar_ayahs'] != null
          ? (json['similar_ayahs'] as List).map((i) => Ayah.fromJson(i)).toList()
          : null,
      ayahOffset: json['ayah_offset'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jozz': jozz,
    'sora': surahNumber,
    'page': page,
    'line_start': lineStart,
    'line_end': lineEnd,
    'aya_no': ayahNumber,
    'sora_name_en': surahNameEn,
    'sora_name_ar': surahNameAr,
    'aya_text': ayah,
    'aya_text_emlaey': ayahText,
    'centered': centered,
    'audio': audio,
    'is_quarter': isQuarter,
    'tajweed_rules': tajweedRules?.map((e) => e.toJson()).toList(),
    'ayah_offset': ayahOffset,
  };

  factory Ayah.fromAya({
    required Ayah ayah,
    required String aya,
    required String ayaText,
    bool centered = false,
    int ayahOffset = 0,
  }) {
    return Ayah(
      id: ayah.id,
      jozz: ayah.jozz,
      surahNumber: ayah.surahNumber,
      page: ayah.page,
      lineStart: ayah.lineStart,
      lineEnd: ayah.lineEnd,
      ayahNumber: ayah.ayahNumber,
      quarter: ayah.quarter,
      hizb: ayah.hizb,
      surahNameEn: ayah.surahNameEn,
      surahNameAr: ayah.surahNameAr,
      ayah: aya,
      ayahText: ayaText,
      sajda: ayah.sajda,
      centered: centered,
      audio: ayah.audio,
      isQuarter: ayah.isQuarter,
      tajweedRules: ayah.tajweedRules,
      similarAyahs: ayah.similarAyahs,
      ayahOffset: ayahOffset,
    );
  }
}
