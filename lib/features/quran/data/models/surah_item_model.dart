class SurahItemModel {
  final int surahNumber;
  final String surahName;
  final String type;
  final int ayahNumbers;
  final String? surahInfo;
  final String? surahNames;

  SurahItemModel({
    required this.surahNumber,
    required this.surahName,
    required this.type,
    required this.ayahNumbers,
    this.surahInfo,
    this.surahNames,
  });

  factory SurahItemModel.fromJson(Map<String, dynamic> json) {
    return SurahItemModel(
      surahNumber: json['number'],
      surahName: json['name'],
      type: json['revelationType'],
      ayahNumbers: json['ayahsNumber'],
      surahInfo: json['surahInfo'],
      surahNames: json['surahNames'],
    );
  }
}
