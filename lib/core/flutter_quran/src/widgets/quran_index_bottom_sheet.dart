import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/utils/app_colors.dart';

import '../app_bloc.dart';
import '../models/surah.dart';
import '../utils/flutter_quran_utils.dart';

class QuranIndexBottomSheet extends StatefulWidget {
  const QuranIndexBottomSheet({super.key});

  @override
  State<QuranIndexBottomSheet> createState() => _QuranIndexBottomSheetState();
}

class _QuranIndexBottomSheetState extends State<QuranIndexBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScrollController? _scrollController;
  int _currentSurahIndex = -1;
  int _currentJuzIndex = -1;
  int _currentQuarterIndex = -1;
  int _currentPageIndex = -1;
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateCurrentIndices();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _scrollToCurrent();
      }
    });
  }

  void _calculateCurrentIndices() {
    final int currentPage = AppBloc.quranCubit.lastPage;
    _currentPageIndex = currentPage - 1;
    final surahs = AppBloc.quranCubit.surahs;
    _currentSurahIndex = surahs.indexWhere(
      (s) => currentPage >= s.startPage && (s.endPage == 0 || currentPage <= s.endPage),
    );

    final ayahs = AppBloc.quranCubit.ayahs;
    if (ayahs.isNotEmpty) {
      final currentAyah = ayahs.firstWhere((a) => a.page == currentPage, orElse: () => ayahs.first);
      _currentJuzIndex = currentAyah.jozz - 1;

      final allQuarters = ayahs
          .where((a) => a.isQuarter || (a.surahNumber == 1 && a.ayahNumber == 1))
          .toList();
      allQuarters.sort((a, b) => a.id.compareTo(b.id));
      _currentQuarterIndex = allQuarters.lastIndexWhere((q) => q.page <= currentPage);
    }
  }

  void _scrollToCurrent() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    double offset = 0;
    if (_tabController.index == 0) {
      if (_currentSurahIndex != -1) {
        offset = _currentSurahIndex * 77.h;
      }
    } else if (_tabController.index == 1) {
      if (_currentJuzIndex != -1) {
        const double juzHeaderHeight = 54.0;
        const double quarterHeight = 82.0;
        double totalJuzHeight = (juzHeaderHeight.h + (8 * quarterHeight.h));

        double juzOffset = _currentJuzIndex * totalJuzHeight;
        double quarterInJuzOffset = 0;

        if (_currentQuarterIndex != -1) {
          int quarterIndexInThisJuz = _currentQuarterIndex % 8;
          quarterInJuzOffset = juzHeaderHeight.h + (quarterIndexInThisJuz * quarterHeight.h);
        }

        offset = juzOffset + quarterInJuzOffset;
      }
    } else {
      if (_currentPageIndex != -1) {
        offset = _currentPageIndex * 60.h;
      }
    }

    if (offset > 0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollController!.hasClients) {
          _scrollController!.animateTo(
            offset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = AppColors.getMainColor(context);
    final Color bgColor = AppColors.getBackground(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        _scrollController = scrollController;
        if (!_hasScrolled) {
          _hasScrolled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
        }

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Text(
                  "فهرس القرآن",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                    fontFamily: 'ReemKufi',
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: mainColor,
                unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
                indicatorColor: mainColor,
                labelStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ReemKufi',
                ),
                tabs: const [
                  Tab(text: 'فهرس السور'),
                  Tab(text: 'فهرس الأجزاء'),
                  Tab(text: 'فهرس الصفحات'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSurahList(context, isDark, mainColor, scrollController),
                    _buildJuzList(scrollController, isDark, mainColor),
                    _buildPageList(context, scrollController, isDark, mainColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurahList(
    BuildContext context,
    bool isDark,
    Color mainColor,
    ScrollController scrollController,
  ) {
    final List<Surah> surahs = AppBloc.quranCubit.surahs;
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: surahs.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 60.w,
        endIndent: 16.w,
        color: mainColor.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        final Surah surah = surahs[index];
        final bool isCurrentSurah = index == _currentSurahIndex;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: isCurrentSurah ? mainColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isCurrentSurah
                ? Border.all(color: mainColor.withValues(alpha: 0.1), width: 1)
                : null,
          ),
          child: Stack(
            children: [
              ListTile(
                onTap: () {
                  if (surah.ayahs.isNotEmpty) {
                    FlutterQuran().navigateToAyah(surah.ayahs.first);
                    Navigator.pop(context);
                  }
                },
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isCurrentSurah ? mainColor : mainColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    surah.index.toString().toArabic(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isCurrentSurah ? Colors.white : mainColor,
                      fontFamily: 'ReemKufi',
                    ),
                  ),
                ),
                title: Text(
                  'سورة ${surah.nameAr}',
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 18.sp,
                    fontWeight: isCurrentSurah ? FontWeight.bold : FontWeight.normal,
                    color: mainColor,
                  ),
                ),
                subtitle: Text(
                  'عدد آياتها: ${surah.ayahs.length.toString().toArabic()} • ص ${surah.startPage.toString().toArabic()}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isCurrentSurah
                        ? mainColor.withValues(alpha: 0.7)
                        : (isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12.sp,
                  color: mainColor.withValues(alpha: isCurrentSurah ? 0.6 : 0.3),
                ),
              ),
              if (isCurrentSurah)
                Positioned(
                  right: 0,
                  top: 15.h,
                  bottom: 15.h,
                  child: Container(
                    width: 4.w,
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4.r)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageList(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    Color mainColor,
  ) {
    final pages = AppBloc.quranCubit.state;
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: pages.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 60.w,
        endIndent: 16.w,
        color: mainColor.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        final page = pages[index];
        final int pageNumber = page.pageNumber;
        final bool isCurrentPage = index == _currentPageIndex;

        final firstAyah = page.ayahs.isNotEmpty ? page.ayahs.first : null;
        final surahName = firstAyah?.surahNameAr ?? "";

        String previewText = "";
        if (page.lines.isNotEmpty) {
          previewText = page.lines[0].ayahs.map((a) => a.ayahText).join(" ");
          if (page.lines.length > 1) {
            previewText += " ${page.lines[1].ayahs.map((a) => a.ayahText).join(" ")}";
          }
        }
        if (previewText.length > 100) {
          previewText = "${previewText.substring(0, 100)}...";
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: isCurrentPage ? mainColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isCurrentPage
                ? Border.all(color: mainColor.withValues(alpha: 0.1), width: 1)
                : null,
          ),
          child: ListTile(
            onTap: () {
              AppBloc.quranCubit.animateToPage(index);
              Navigator.pop(context);
            },
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: isCurrentPage ? mainColor : mainColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                pageNumber.toString().toArabic(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isCurrentPage ? Colors.white : mainColor,
                  fontFamily: 'ReemKufi',
                ),
              ),
            ),
            title: Text(
              "صفحة $pageNumber - سورة $surahName".toArabic(),
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 16.sp,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                color: mainColor,
              ),
            ),
            subtitle: Text(
              previewText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: 'AmiriQuran',
                color: isCurrentPage
                    ? mainColor.withValues(alpha: 0.7)
                    : (isDark ? Colors.white60 : Colors.grey[600]),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12.sp,
              color: mainColor.withValues(alpha: 0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJuzList(ScrollController scrollController, bool isDark, Color mainColor) {
    final ayahs = AppBloc.quranCubit.ayahs;

    final allQuarters = ayahs
        .where((a) => a.isQuarter || (a.surahNumber == 1 && a.ayahNumber == 1))
        .toList();
    allQuarters.sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: 30,
      itemBuilder: (context, index) {
        int juzNumber = index + 1;
        int startIndex = (juzNumber - 1) * 8;
        int endIndex = juzNumber * 8;
        List<Ayah> juzQuarters = allQuarters.sublist(
          startIndex,
          endIndex > allQuarters.length ? allQuarters.length : endIndex,
        );

        final bool isCurrentJuz = index == _currentJuzIndex;
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: isCurrentJuz
                    ? mainColor.withValues(alpha: 0.15)
                    : mainColor.withValues(alpha: 0.08),
              ),
              alignment: Alignment.center,
              child: Text(
                "الجزء ${juzNumber.toString().toArabic()}",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                  fontFamily: 'ReemKufi',
                ),
              ),
            ),
            ...juzQuarters.map((ayah) {
              int globalIndex = allQuarters.indexOf(ayah);
              int hizb = (globalIndex ~/ 4) + 1;
              int quarter = (globalIndex % 4) + 1;
              final bool isCurrentQuarter = globalIndex == _currentQuarterIndex;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isCurrentQuarter ? mainColor.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        ListTile(
                          onTap: () {
                            FlutterQuran().navigateToAyah(ayah);
                            Navigator.pop(context);
                          },
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                          leading: SizedBox(
                            width: 50.w,
                            height: 50.h,
                            child: CustomPaint(
                              painter: HizbProgressPainter(
                                progress: quarter / 4,
                                color: isCurrentQuarter ? mainColor : mainColor,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "الحزب",
                                      style: TextStyle(
                                        color: quarter >= 3
                                            ? (isDark ? Colors.black : Colors.white)
                                            : mainColor,
                                        fontSize: 8.sp,
                                      ),
                                    ),
                                    Text(
                                      hizb.toString().toArabic(),
                                      style: TextStyle(
                                        color: quarter >= 3
                                            ? (isDark ? Colors.black : Colors.white)
                                            : mainColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            "${ayah.ayah.replaceAll('۞', '').trim().split(' ').take(8).join(' ')}...",
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 17.sp,
                              fontWeight: isCurrentQuarter ? FontWeight.bold : FontWeight.normal,
                              color: mainColor,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            "سورة ${ayah.surahNameAr} • آية ${ayah.ayahNumber.toString().toArabic()} • ص ${ayah.page.toString().toArabic()}",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isCurrentQuarter
                                  ? mainColor.withValues(alpha: 0.7)
                                  : (isDark ? Colors.white60 : Colors.grey[600]),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12.sp,
                            color: mainColor.withValues(alpha: 0.3),
                          ),
                        ),
                        if (!isCurrentQuarter)
                          Divider(
                            height: 1,
                            indent: 75.w,
                            endIndent: 16.w,
                            color: mainColor.withValues(alpha: 0.05),
                          ),
                      ],
                    ),
                    if (isCurrentQuarter)
                      Positioned(
                        right: 0,
                        top: 10.h,
                        bottom: 10.h,
                        child: Container(
                          width: 3.5.w,
                          decoration: BoxDecoration(
                            color: mainColor,
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(4.r)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class HizbProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  HizbProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.1));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      true,
      Paint()..color = color,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
