import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_bloc.dart';
import '../models/ayah.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/quran_constants.dart';
import '../models/surah.dart';
import 'preferences/preferences_utils.dart';

class FlutterQuran {
  Future<void> init({List<Bookmark>? userBookmarks, bool overwriteBookmarks = false}) async {
    PreferencesUtils().preferences = await SharedPreferences.getInstance();
    AppBloc.init();
    await AppBloc.quranCubit.loadQuran();
    AppBloc.bookmarksCubit.initBookmarks(
      userBookmarks: userBookmarks,
      overwrite: overwriteBookmarks,
    );
  }

  int getCurrentPageNumber() => AppBloc.quranCubit.lastPage;

  List<Ayah> search(String text) => AppBloc.quranCubit.search(text);

  void navigateToAyah(Ayah ayah) {
    AppBloc.quranCubit.animateToPage(ayah.page - 1);

    AppBloc.audioCubit.setSelectedAyah(ayah.id);

    Future.delayed(const Duration(seconds: 5)).then((value) => AppBloc.audioCubit.clearSelection());
  }

  void navigateToPage(int page) => AppBloc.quranCubit.animateToPage(page - 1);

  void navigateToJozz(int jozz) =>
      navigateToPage(jozz == 1 ? 0 : (AppBloc.quranCubit.quranStops[(jozz - 1) * 8 - 1]));

  void navigateToHizb(int hizb) =>
      navigateToPage(hizb == 1 ? 0 : (AppBloc.quranCubit.quranStops[(hizb - 1) * 4 - 1]));

  void navigateToBookmark(Bookmark bookmark) {
    if (bookmark.page > 0 && bookmark.page <= 604) {
      navigateToPage(bookmark.page);
    } else {
      throw Exception("Page number must be between 1 and 604");
    }
  }

  void navigateToSurah(int surah) => navigateToPage(AppBloc.quranCubit.surahsStart[surah - 1] + 1);

  List<String> getAllJozzs() =>
      QuranConstants.quranHizbs.sublist(0, 30).map((jozz) => "الجزء $jozz").toList();

  List<String> getAllHizbs() => QuranConstants.quranHizbs.map((jozz) => "الحزب $jozz").toList();

  Surah getSurah(int surah) => AppBloc.quranCubit.surahs[surah - 1];

  List<String> getAllSurahs({bool isArabic = true}) => AppBloc.quranCubit.surahs
      .map((surah) => "سورة ${isArabic ? surah.nameAr : surah.nameEn}")
      .toList();

  TextStyle getHafsStyle(BuildContext context) {
    final isThemeDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor =
        AppBloc.quranCubit.pageColor ?? (isThemeDark ? Colors.black : const Color(0xFFFFF9E7));

    final isDarkColor = ThemeData.estimateBrightnessForColor(pageColor) == Brightness.dark;

    return TextStyle(
      color: isDarkColor ? Colors.white : Colors.black,
      fontSize: 23.55,
      fontFamily: 'Hafs',
    );
  }

  TextStyle get hafsStyle =>
      const TextStyle(color: Colors.black, fontSize: 23.55, fontFamily: 'Hafs');

  Map<String, Color> getTajweedColors(bool isDark) => {
    "ghunnah": const Color(0xFF2E7D32),
    "ikhfa": const Color(0xFF4CAF50),
    "idghaam_ghunnah": const Color(0xFF8BC34A),
    "idgham_ghunnah": const Color(0xFF8BC34A),
    "iqlab": const Color(0xFFF57C00),

    "ikhfa_shafawi": const Color(0xFF00897B),
    "idghaam_shafawi": const Color(0xFF00ACC1),
    "idghaam_mutajanisayn": const Color(0xFFAFB42B),

    "qalqalah": const Color(0xFFC2185B),

    "madd_munfasil": isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
    "madd_muttasil": isDark ? const Color(0xFF7986CB) : const Color(0xFF303F9F),
    "madd_6": isDark ? const Color(0xFF9575CD) : const Color(0xFF512DA8),
    "madd_4": isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
    "madd_5": isDark ? const Color(0xFF7986CB) : const Color(0xFF303F9F),
    "madd_246": isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),

    "idghaam_no_ghunnah": isDark ? const Color(0xFF9E9E9E) : const Color(0xFF616161),
    "hamzat_wasl": isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
    "lam_shamsiyyah": isDark ? const Color(0xFFD7D7D7) : const Color(0xFF9E9E9E),
    "silent": isDark ? const Color(0xFFE0E0E0) : const Color(0xFFBDBDBD),
    "madd_2": isDark ? Colors.white : Colors.black,
  };

  TextSpan getTajweedColoredText(Ayah ayah, TextStyle baseStyle, {bool showTajweed = true}) {
    final List<Highlight> highlights = AppBloc.quranCubit.getAyahHighlights(ayah.id);

    final holyRegex = RegExp(r'\S*(?:ٱللَّه|لِلَّه)\S*');

    if ((ayah.tajweedRules == null || ayah.tajweedRules!.isEmpty) &&
        highlights.isEmpty &&
        showTajweed) {
      return getAllahColoredText(ayah.ayah, baseStyle);
    }

    final List<TajweedRule> effectiveRules = showTajweed ? (ayah.tajweedRules ?? []) : [];
    final bool isDark = baseStyle.color == Colors.white;
    final Map<String, Color> tajweedColors = getTajweedColors(isDark);

    List<TextSpan> spans = [];
    String text = ayah.ayah;
    int offset = ayah.ayahOffset;

    Set<int> splitPoints = {0, text.length};

    final holyMatches = holyRegex.allMatches(text).toList();
    for (var m in holyMatches) {
      splitPoints.add(m.start);
      splitPoints.add(m.end);
    }

    for (var rule in effectiveRules) {
      if (rule.start < offset + text.length && rule.end > offset) {
        splitPoints.add((rule.start - offset).clamp(0, text.length));
        splitPoints.add((rule.end - offset).clamp(0, text.length));
      }
    }

    List<Highlight> currentHighlights = highlights
        .where(
          (h) =>
              h.start != null &&
              h.end != null &&
              h.start! < offset + text.length &&
              h.end! > offset,
        )
        .toList();
    for (var h in currentHighlights) {
      splitPoints.add((h.start! - offset).clamp(0, text.length));
      splitPoints.add((h.end! - offset).clamp(0, text.length));
    }

    List<int> sortedPoints = splitPoints.toList()..sort();

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      int start = sortedPoints[i];
      int end = sortedPoints[i + 1];
      if (start == end) continue;

      String chunk = text.substring(start, end);

      Color? textColor;
      var activeRule = effectiveRules.firstWhere(
        (r) => (r.start - offset) <= start && (r.end - offset) >= end,
        orElse: () => TajweedRule(start: -1, end: -1, rule: ""),
      );
      if (activeRule.start != -1) {
        textColor = tajweedColors[activeRule.rule];
      }

      Color? bgColor;
      var activeHighlight = currentHighlights.firstWhere(
        (h) => (h.start! - offset) <= start && (h.end! - offset) >= end,
        orElse: () => Highlight(ayahId: -1, colorCode: 0),
      );
      if (activeHighlight.ayahId != -1) {
        bgColor = Color(activeHighlight.colorCode).withValues(alpha: 0.5);
      }

      if (start > 0 &&
          text[start - 1].trim().isNotEmpty &&
          chunk.isNotEmpty &&
          chunk[0].trim().isNotEmpty) {
        chunk = '\u200D' + chunk;
      }
      if (end < text.length && text[end - 1].trim().isNotEmpty && text[end].trim().isNotEmpty) {
        chunk = chunk + '\u200D';
      }

      TextStyle chunkStyle = baseStyle.copyWith(color: textColor, backgroundColor: bgColor);

      bool isHoly = holyMatches.any((m) => start >= m.start && end <= m.end);

      if (isHoly && activeRule.rule != "madd_munfasil") {
        spans.add(
          TextSpan(
            text: chunk,
            style: chunkStyle.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.add(TextSpan(text: chunk, style: chunkStyle));
      }
    }

    if (spans.isEmpty && text.isNotEmpty) {
      return getAllahColoredText(text, baseStyle);
    }

    return TextSpan(children: spans);
  }

  TextSpan getAllahColoredText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final finalRegex = RegExp(r'\S*(?:ٱللَّه|لِلَّه)\S*');

    int lastEnd = 0;
    for (final match in finalRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        String nonMatch = text.substring(lastEnd, match.start);
        if (match.start < text.length &&
            text[match.start].trim().isNotEmpty &&
            nonMatch.isNotEmpty &&
            nonMatch[nonMatch.length - 1].trim().isNotEmpty) {
          nonMatch += '\u200D';
        }
        spans.add(TextSpan(text: nonMatch, style: baseStyle));
      }

      String matchText = match.group(0)!;
      if (match.start > 0 &&
          text[match.start - 1].trim().isNotEmpty &&
          matchText.isNotEmpty &&
          matchText[0].trim().isNotEmpty) {
        matchText = '\u200D' + matchText;
      }
      if (match.end < text.length &&
          text[match.end].trim().isNotEmpty &&
          matchText.isNotEmpty &&
          matchText[matchText.length - 1].trim().isNotEmpty) {
        matchText = matchText + '\u200D';
      }

      spans.add(
        TextSpan(
          text: matchText,
          style: baseStyle.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      String remaining = text.substring(lastEnd);
      if (lastEnd > 0 &&
          text[lastEnd - 1].trim().isNotEmpty &&
          remaining.isNotEmpty &&
          remaining[0].trim().isNotEmpty) {
        remaining = '\u200D' + remaining;
      }
      spans.add(TextSpan(text: remaining, style: baseStyle));
    }

    return spans.isEmpty ? TextSpan(text: text, style: baseStyle) : TextSpan(children: spans);
  }

  void showTransitionPopup(BuildContext context, String text) {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: 60.w,
        right: 60.w,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withValues(alpha: 0.9)
                  : const Color(0xFFE0E0E0).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF424242),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'ReemKufi',
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 1500)).then((_) => overlayEntry.remove());
  }

  static final FlutterQuran _instance = FlutterQuran._internal();

  factory FlutterQuran() {
    return _instance;
  }

  FlutterQuran._internal();
}
