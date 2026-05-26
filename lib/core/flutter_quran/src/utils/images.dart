class Images {
  final surahHeader = 'lib/core/flutter_quran/assets/images/surah_header.png';

  static final Images _instance = Images._internal();

  factory Images() {
    return _instance;
  }

  Images._internal();
}
