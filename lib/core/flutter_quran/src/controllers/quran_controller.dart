import 'dart:async';
import 'dart:convert';

import 'package:arabic_search/arabic_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasariu/core/configurations/my_cash_keys.dart';
import 'package:wasariu/core/configurations/shared_preferences.dart';

import '../models/ayah.dart';
import '../models/highlight.dart';
import '../models/quran_page.dart';
import '../models/surah.dart';
import '../repository/quran_repository.dart';

class QuranCubit extends Cubit<List<QuranPage>> {
  QuranCubit({QuranRepository? quranRepository})
    : _quranRepository = quranRepository ?? QuranRepository(),
      super([]);

  final QuranRepository _quranRepository;

  List<QuranPage> staticPages = [];
  List<int> quranStops = [];
  List<int> surahsStart = [];
  List<Surah> surahs = [];
  final List<Ayah> ayahs = [];
  List<Highlight> highlights = [];

  final Set<int> hiddenAyahIds = {};
  int? highlightedAyahId;
  Timer? _highlightTimer;

  int lastPage = 1;
  bool hasHistory = false;
  int? initialPage;
  bool isVertical = false;
  bool isAutoScrolling = false;
  bool isTajweedEnabled = false;
  double autoScrollSpeed = 1.0;
  Timer? _scrollTimer;
  bool _isLoading = false;
  final ValueNotifier<double> loadProgress = ValueNotifier(0.0);

  Color? pageColor;

  PageController _pageController = PageController();

  Future<void> loadQuran({int quranPages = QuranRepository.hafsPagesNumber}) async {
    if (state.isNotEmpty || _isLoading) return;
    _isLoading = true;
    loadProgress.value = 0.0;

    try {
      staticPages.clear();
      quranStops.clear();
      surahsStart.clear();
      surahs.clear();
      ayahs.clear();

      try {
        final savedPage = _quranRepository.getLastPage();
        if (savedPage != null) {
          lastPage = savedPage;
          hasHistory = true;
        } else {
          lastPage = 1;
          hasHistory = false;
        }

        final colorValue = _quranRepository.getPageColor();
        if (colorValue != null) {
          pageColor = Color(colorValue);
        }

        highlights = _quranRepository.getHighlights();
      } catch (e) {
        lastPage = 1;
        hasHistory = false;
      }

      _pageController = PageController(initialPage: lastPage - 1);

      staticPages = List.generate(
        quranPages,
        (index) => QuranPage(pageNumber: index + 1, ayahs: [], lines: []),
      );

      loadProgress.value = 0.1;
      final quranJson = await _quranRepository.getQuran();
      if (quranJson.isEmpty) {
        _isLoading = false;
        return;
      }
      loadProgress.value = 0.2;

      int hizbCount = 1;
      int surahsIndex = 1;
      List<Ayah> thisSurahAyahs = [];

      int currentTajweedSurah = -1;
      Map<String, dynamic>? tajweedData;

      for (int i = 0; i < quranJson.length; i++) {
        try {
          final ayah = Ayah.fromJson(quranJson[i]);

          if (ayah.page < 1 || ayah.page > quranPages) continue;

          if (ayah.surahNumber != surahsIndex) {
            if (surahs.isNotEmpty) {
              surahs.last.endPage = ayahs.last.page;
              surahs.last.ayahs = List.from(thisSurahAyahs);
            }
            surahsIndex = ayah.surahNumber;
            thisSurahAyahs = [];
          }

          if (ayah.surahNumber != currentTajweedSurah) {
            currentTajweedSurah = ayah.surahNumber;
            try {
              String tajweedContent = await rootBundle.loadString(
                'assets/jsons/tajweed/surah_$currentTajweedSurah.json',
              );
              tajweedData = jsonDecode(tajweedContent);
            } catch (e) {
              tajweedData = null;
            }
          }

          if (tajweedData != null && tajweedData['verse'] != null) {
            var verseRules = tajweedData['verse']['verse_${ayah.ayahNumber}'];
            if (verseRules != null) {
              ayah.tajweedRules = (verseRules as List).map((e) => TajweedRule.fromJson(e)).toList();
            }
          }

          ayahs.add(ayah);
          thisSurahAyahs.add(ayah);
          staticPages[ayah.page - 1].ayahs.add(ayah);

          if (ayah.ayah.contains('۞') ||
              ayah.isQuarter ||
              (ayah.surahNumber == 1 && ayah.ayahNumber == 1)) {
            staticPages[ayah.page - 1].hizb = hizbCount++;
            quranStops.add(ayah.page);
          }

          if (ayah.ayah.contains('۩')) {
            staticPages[ayah.page - 1].hasSajda = true;
          }

          if (ayah.ayahNumber == 1) {
            ayah.ayah = ayah.ayah.replaceAll('۞', '');
            staticPages[ayah.page - 1].numberOfNewSurahs++;
            surahs.add(
              Surah(
                index: ayah.surahNumber,
                startPage: ayah.page,
                endPage: 0,
                nameEn: ayah.surahNameEn,
                nameAr: ayah.surahNameAr,
                ayahs: [],
              ),
            );
            surahsStart.add(ayah.page - 1);
          }

          if (i % 100 == 0) {
            loadProgress.value = 0.2 + (0.6 * (i / quranJson.length));
          }
        } catch (e) {
          // Error processing ayah
        }
      }

      if (surahs.isNotEmpty) {
        surahs.last.endPage = ayahs.last.page;
        surahs.last.ayahs = List.from(thisSurahAyahs);
      }

      loadProgress.value = 0.8;

      for (int pageIdx = 0; pageIdx < staticPages.length; pageIdx++) {
        QuranPage staticPage = staticPages[pageIdx];
        List<Ayah> currentLineAyahs = [];
        for (Ayah aya in staticPage.ayahs) {
          if (aya.ayah.contains('\n')) {
            final lines = aya.ayah.split('\n');
            int currentOffset = 0;
            for (int i = 0; i < lines.length; i++) {
              if (lines[i].trim().isEmpty && i == lines.length - 1) continue;

              bool centered = false;
              if ((aya.centered && i == lines.length - 2)) {
                centered = true;
              }
              final a = Ayah.fromAya(
                ayah: aya,
                aya: lines[i],
                ayaText: lines[i],
                centered: centered,
                ayahOffset: currentOffset,
              );
              currentLineAyahs.add(a);
              if (i < lines.length - 1) {
                if (currentLineAyahs.isNotEmpty) {
                  staticPage.lines.add(Line(List.from(currentLineAyahs)));
                  currentLineAyahs.clear();
                }
                currentOffset += lines[i].length + 1;
              }
            }
          } else {
            currentLineAyahs.add(aya);
          }
        }
        if (currentLineAyahs.isNotEmpty) {
          staticPage.lines.add(Line(List.from(currentLineAyahs)));
          currentLineAyahs.clear();
        }

        if (pageIdx % 50 == 0) {
          loadProgress.value = 0.8 + (0.2 * (pageIdx / staticPages.length));
        }
      }
      loadProgress.value = 1.0;
      emit(List.from(staticPages));

      CacheHelper.saveData(key: MyCashKeys.isQuranDownloaded, value: true);
    } catch (e) {
      if (staticPages.isNotEmpty) emit(List.from(staticPages));
    } finally {
      _isLoading = false;
    }
  }

  void updateController(int pageIndex) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageIndex);
    } else {
      _pageController = PageController(initialPage: pageIndex);
    }
  }

  void highlightAyah(int ayahId) {
    _highlightTimer?.cancel();
    highlightedAyahId = ayahId;
    emit(List.from(staticPages));

    _highlightTimer = Timer(const Duration(seconds: 2), () {
      highlightedAyahId = null;
      emit(List.from(staticPages));
    });
  }

  void toggleAyahVisibility(int ayahId) {
    if (hiddenAyahIds.contains(ayahId)) {
      hiddenAyahIds.remove(ayahId);
    } else {
      hiddenAyahIds.add(ayahId);
    }
    emit(List.from(staticPages));
  }

  bool isAyahHidden(int ayahId) => hiddenAyahIds.contains(ayahId);

  void clearHiddenAyahs() {
    hiddenAyahIds.clear();
    emit(List.from(staticPages));
  }

  List<Ayah> findSimilarAyahs(Ayah targetAyah) {
    if (targetAyah.ayahText.length < 15) return [];
    String startOfAyah = targetAyah.ayahText.substring(0, 15);
    return ayahs.where((a) => a.id != targetAyah.id && a.ayahText.startsWith(startOfAyah)).toList();
  }

  List<Ayah> search(String searchText) {
    if (searchText.isEmpty) return [];
    final normalizedSearch = ArabicText.normalize(searchText);
    return ayahs.where((aya) => aya.normalizedText.contains(normalizedSearch)).toList();
  }

  void toggleVerticalMode() {
    isVertical = !isVertical;
    if (!isVertical && isAutoScrolling) {
      stopAutoScroll();
    }
    emit(List.from(staticPages));
  }

  void toggleTajweed() {
    isTajweedEnabled = !isTajweedEnabled;
    emit(List.from(staticPages));
  }

  void toggleAutoScroll() {
    if (isAutoScrolling) {
      stopAutoScroll();
    } else {
      startAutoScroll();
    }
  }

  void startAutoScroll() {
    isAutoScrolling = true;
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_pageController.hasClients) {
        final currentPosition = _pageController.position.pixels;
        final maxPosition = _pageController.position.maxScrollExtent;
        if (currentPosition < maxPosition) {
          _pageController.jumpTo(currentPosition + autoScrollSpeed);
        } else {
          stopAutoScroll();
        }
      }
    });
    emit(List.from(staticPages));
  }

  void stopAutoScroll() {
    isAutoScrolling = false;
    _scrollTimer?.cancel();
    emit(List.from(staticPages));
  }

  void setAutoScrollSpeed(double speed) {
    autoScrollSpeed = speed;
    emit(List.from(staticPages));
  }

  void setPageColor(Color color) {
    pageColor = color;
    _quranRepository.savePageColor(color.toARGB32());
    emit(List.from(staticPages));
  }

  void addHighlight(Highlight highlight) {
    highlights.removeWhere(
      (h) => h.ayahId == highlight.ayahId && h.start == highlight.start && h.end == highlight.end,
    );
    highlights.add(highlight);
    _quranRepository.saveHighlights(highlights);
    emit(List.from(staticPages));
  }

  void removeHighlight(int ayahId, {int? start, int? end}) {
    highlights.removeWhere(
      (h) =>
          h.ayahId == ayahId &&
          (start == null || h.start == start) &&
          (end == null || h.end == end),
    );
    _quranRepository.saveHighlights(highlights);
    emit(List.from(staticPages));
  }

  List<Highlight> getAyahHighlights(int ayahId) {
    return highlights.where((h) => h.ayahId == ayahId).toList();
  }

  @override
  Future<void> close() {
    _scrollTimer?.cancel();
    _highlightTimer?.cancel();
    loadProgress.dispose();
    return super.close();
  }

  Future<void> saveLastPage(int lastPage) async {
    this.lastPage = lastPage;
    hasHistory = true;
    try {
      await _quranRepository.saveLastPage(lastPage);
    } catch (e) {
      // Could not save last page
    }
    emit(List.from(staticPages));
  }

  void animateToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else {
      _pageController = PageController(initialPage: page);
    }
  }

  PageController get pageController => _pageController;
}
