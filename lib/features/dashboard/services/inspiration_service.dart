class InspirationService {
  static const List<Map<String, String>> _inspirations = [
    {
      'text': 'نِعْمَ الْعَبْدُ ۖ إِنَّهُ أَوَّابٌ',
      'source': 'سورة ص - 30',
    },
    {
      'text': 'وَتَزَوَّدُوا فَإِنَّ خَيْرَ الزَّادِ التَّقْوَىٰ',
      'source': 'سورة البقرة - 197',
    },
    {
      'text': 'إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ',
      'source': 'سورة التوبة - 120',
    },
    {
      'text': 'وَسَارِعُوا إِلَىٰ مَغْفِرَةٍ مِّن رَّبِّكُمْ',
      'source': 'سورة آل عمران - 133',
    },
    {
      'text': 'أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
      'source': 'حديث شريف',
    },
    {
      'text': 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ طَرِيقًا إِلَى الْجَنَّةِ',
      'source': 'حديث شريف',
    },
    {
      'text': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
      'source': 'حديث شريف',
    },
    {
      'text': 'فَإِذَا عَزَمْتَ فَتَوَكَّلْ عَلَى اللَّهِ',
      'source': 'سورة آل عمران - 159',
    },
    {
      'text': 'وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ',
      'source': 'سورة النجم - 39',
    },
    {
      'text': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
      'source': 'سورة الطلاق - 2',
    },
  ];

  static Map<String, String> getDailyInspiration() {
    int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    int index = dayOfYear % _inspirations.length;
    return _inspirations[index];
  }
}
