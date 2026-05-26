class ReaderInfo {
  final int index;
  final String name;
  final String readerNamePath;
  final String url;

  const ReaderInfo({
    required this.index,
    required this.name,
    required this.readerNamePath,
    required this.url,
  });
}

class ReadersConstants {
  ReadersConstants._();

  static const ayahs1stSource = "https://cdn.islamic.network/quran/audio/";
  static const ayahs2ndSource = "https://everyayah.com/data/";
  static const surahUrl1 = "https://download.quranicaudio.com/quran/";
  static const surahUrl2 = "https://server16.mp3quran.net/";
  static const surahUrl3 = "https://server12.mp3quran.net/";
  static const surahUrl4 = "https://server6.mp3quran.net/";
  static const surahUrl5 = "https://server11.mp3quran.net/";

  static List<ReaderInfo>? customAyahReaders;
  static List<ReaderInfo>? customSurahReaders;

  static List<ReaderInfo> get activeAyahReaders => customAyahReaders ?? ayahReaderInfo;

  static List<ReaderInfo> get activeSurahReaders => customSurahReaders ?? surahReaderInfo;

  static final List<ReaderInfo> ayahReaderInfo = [
    const ReaderInfo(
      index: 0,
      name: 'مشاري العفاسي',
      readerNamePath: '128/ar.alafasy',
      url: ayahs1stSource,
    ),
    const ReaderInfo(
      index: 1,
      name: 'عبد الباسط عبد الصمد',
      readerNamePath: 'Abdul_Basit_Murattal_192kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 2,
      name: 'محمد صديق المنشاوي',
      readerNamePath: 'Minshawy_Murattal_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 3,
      name: 'محمود خليل الحصري',
      readerNamePath: 'Husary_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 4,
      name: 'أحمد العجمي',
      readerNamePath: '128/ar.ahmedajamy',
      url: ayahs1stSource,
    ),
    const ReaderInfo(
      index: 5,
      name: 'ماهر المعيقلي',
      readerNamePath: 'MaherAlMuaiqly128kbps',
      url: ayahs2ndSource,
    ),
  ];

  static final List<ReaderInfo> surahReaderInfo = [
    const ReaderInfo(
      index: 0,
      name: 'عبد الباسط',
      readerNamePath: 'abdul_basit_murattal/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 1,
      name: 'محمد المنشاوي',
      readerNamePath: 'muhammad_siddeeq_al-minshaawee/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 2,
      name: 'محمود الحصري',
      readerNamePath: 'mahmood_khaleel_al-husaree_iza3a/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 3,
      name: 'أحمد العجمي',
      readerNamePath: 'ahmed_ibn_3ali_al-3ajamy/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 4,
      name: 'ماهر المعيقلي',
      readerNamePath: 'maher_almu3aiqly/year1440/',
      url: surahUrl1,
    ),
  ];
}
