import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/bookmarks_controller.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/bookmark.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_constants.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';
import 'package:wasariu/core/flutter_quran/src/utils/flutter_quran_utils.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/bsmallah_widget.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_line.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_page_bottom_info.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/surah_header_widget.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/utils/font_style.dart';

class QuranPageView extends StatefulWidget {
  final int? initialSurah;
  final int? initialPage;
  final bool showBottomWidget;
  final Widget? bottomWidget;
  final Function(int)? onPageChanged;
  final bool isSinglePageMode;
  final List<int>? pageRange;

  const QuranPageView({
    super.key,
    this.initialSurah,
    this.initialPage,
    this.showBottomWidget = true,
    this.bottomWidget,
    this.onPageChanged,
    this.isSinglePageMode = false,
    this.pageRange,
  });

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _prepareInitialPage();
  }

  void _prepareInitialPage() {
    final cubit = AppBloc.quranCubit;
    if (cubit.state.isEmpty) return;

    int? targetPage;
    if (widget.initialSurah != null) {
      if (widget.initialSurah! > 0 && widget.initialSurah! <= cubit.surahsStart.length) {
        targetPage = cubit.surahsStart[widget.initialSurah! - 1];
      }
    } else if (widget.initialPage != null) {
      targetPage = widget.initialPage! - 1;
    } else {
      targetPage = cubit.lastPage - 1;
    }

    if (targetPage != null && targetPage >= 0) {
      if (widget.pageRange != null) {
        final pageInRange = targetPage - widget.pageRange![0] + 1;
        cubit.updateController(pageInRange >= 0 ? pageInRange : 0);
      } else {
        cubit.updateController(targetPage);
      }
      cubit.saveLastPage(targetPage + 1);
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final currentOrientation = MediaQuery.of(context).orientation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<QuranCubit, List<QuranPage>>(
      bloc: AppBloc.quranCubit,
      listener: (context, pages) {
        if (pages.isNotEmpty && !_isInitialized) {
          _prepareInitialPage();
        }
      },
      builder: (ctx, pages) {
        final pageColor =
            AppBloc.quranCubit.pageColor ?? (isDark ? Colors.black : const Color(0xFFFFF9E7));

        if (pages.isEmpty) {
          return Container(
            color: pageColor,
            child: Center(
              child: ValueListenableBuilder<double>(
                valueListenable: AppBloc.quranCubit.loadProgress,
                builder: (context, progress, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150.w,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.gray.withValues(alpha: 0.2),
                          color: AppColors.getMainColor(context),
                          borderRadius: BorderRadius.circular(10.r),
                          minHeight: 8.h,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "جاري تحميل المصحف الشريف... ${(progress * 100).toInt()}%",
                        style: AppFontStyle.fontCairo18w700black(context).copyWith(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white70 : AppColors.getMainColor(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        if (!_isInitialized) {
          _prepareInitialPage();
        }

        return Container(
          color: pageColor,
          child: PageView.builder(
            itemCount: widget.pageRange != null
                ? (widget.pageRange![1] - widget.pageRange![0] + 1)
                : pages.length,
            controller: AppBloc.quranCubit.pageController,
            scrollDirection: AppBloc.quranCubit.isVertical ? Axis.vertical : Axis.horizontal,
            physics: widget.isSinglePageMode
                ? const NeverScrollableScrollPhysics()
                : (AppBloc.quranCubit.isVertical ? null : const PageScrollPhysics()),
            pageSnapping: !AppBloc.quranCubit.isVertical,
            onPageChanged: (page) {
              final actualPage = widget.pageRange != null
                  ? (page + widget.pageRange![0] - 1)
                  : page;
              _handlePageChanged(context, pages, actualPage);
            },
            itemBuilder: (ctx, index) {
              final actualIndex = widget.pageRange != null
                  ? (index + widget.pageRange![0] - 1)
                  : index;
              return _buildPage(
                context,
                pages[actualIndex],
                actualIndex,
                deviceSize,
                currentOrientation,
              );
            },
          ),
        );
      },
    );
  }

  void _handlePageChanged(BuildContext context, List<QuranPage> pages, int page) {
    final pageNumber = page + 1;
    if (widget.onPageChanged != null) widget.onPageChanged!(pageNumber);
    AppBloc.quranCubit.saveLastPage(pageNumber);

    final currentPage = pages[page];
    if (currentPage.hizb != null && currentPage.ayahs.isNotEmpty) {
      final firstAyah = currentPage.ayahs.first;
      if (firstAyah.isQuarter || (firstAyah.surahNumber == 1 && firstAyah.ayahNumber == 1)) {
        final hizb = currentPage.hizb!;
        final partText = _mapNumberToHizbPart(hizb);
        final hizbName = QuranConstants.quranHizbs[(hizb / 4).floor()];
        final juzNumber = ((hizb - 1) ~/ 8) + 1;

        String msg = "";
        if ((hizb - 1) % 8 == 0) {
          msg = "الجزء ${juzNumber.toString().toArabic()}\nالحزب $hizbName";
        } else {
          msg = "$partText الحزب $hizbName";
        }
        if (firstAyah.ayahNumber == 1) {
          msg += "\nبداية سورة ${firstAyah.surahNameAr}";
        }
        FlutterQuran().showTransitionPopup(context, msg.trim());
      }
    }
  }

  Widget _buildPage(
    BuildContext context,
    QuranPage page,
    int index,
    Size deviceSize,
    Orientation orientation,
  ) {
    if (page.ayahs.isEmpty && page.lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final isRightPage = index % 2 == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: isRightPage ? 25.w : 15.w,
            right: isRightPage ? 15.w : 25.w,
            top: 10.h,
            bottom: 0,
          ),
          child: Column(
            children: [
              Expanded(
                child: index == 0 || index == 1
                    ? _buildOpeningPage(context, page, index, deviceSize)
                    : _buildStandardPage(context, page, deviceSize, orientation),
              ),
              if (widget.showBottomWidget) ...[
                widget.bottomWidget ??
                    QuranPageBottomInfoWidget(
                      page: index + 1,
                      hizb: page.hizb,
                      surahName: page.ayahs.isNotEmpty ? page.ayahs.last.surahNameAr : "",
                    ),
                SizedBox(height: 5.h),
              ],
            ],
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: isRightPage ? 0 : null,
          right: isRightPage ? null : 0,
          child: Container(
            width: 20.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: isRightPage ? Alignment.centerLeft : Alignment.centerRight,
                end: isRightPage ? Alignment.centerRight : Alignment.centerLeft,
              ),
            ),
          ),
        ),
        Positioned(
          top: 30.h,
          bottom: 30.h,
          left: isRightPage ? 0 : null,
          right: isRightPage ? null : 0,
          child: Container(width: 1, color: isDark ? Colors.white10 : Colors.black12),
        ),
        BlocBuilder<BookmarksCubit, List<Bookmark>>(
          bloc: AppBloc.bookmarksCubit,
          builder: (context, bookmarks) {
            final isPageBookmarked = bookmarks.any((b) => b.page == index + 1 && b.ayahId == -1);
            return isPageBookmarked
                ? _BookmarkRibbon(isRightPage: isRightPage)
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildOpeningPage(BuildContext context, QuranPage page, int index, Size deviceSize) {
    if (page.ayahs.isEmpty) return const SizedBox.shrink();
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SurahHeaderWidget(
              surahName: page.ayahs[0].surahNameAr,
              surahNumber: page.ayahs[0].surahNumber,
            ),
            if (index == 1) BasmallahWidget(surahNumber: page.ayahs[0].surahNumber),
            ...page.lines.map(
              (line) =>
                  _LineWithBookmarks(line: line, deviceSize: deviceSize, boxFit: BoxFit.scaleDown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardPage(
    BuildContext context,
    QuranPage page,
    Size deviceSize,
    Orientation orientation,
  ) {
    final List<int> surahsShowedInPage = [];
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: EdgeInsets.only(top: 5.h),
          physics: orientation == Orientation.portrait
              ? const NeverScrollableScrollPhysics()
              : null,
          children: page.lines.map((line) {
            Widget? header;
            final firstAyahInLine = line.ayahs.firstWhere(
              (a) => a.ayahNumber == 1,
              orElse: () => line.ayahs.first,
            );

            if (firstAyahInLine.ayahNumber == 1 &&
                !surahsShowedInPage.contains(firstAyahInLine.surahNumber)) {
              surahsShowedInPage.add(firstAyahInLine.surahNumber);
              header = Column(
                children: [
                  SurahHeaderWidget(
                    surahName: firstAyahInLine.surahNameAr,
                    surahNumber: firstAyahInLine.surahNumber,
                  ),
                  if (firstAyahInLine.surahNumber != 9)
                    BasmallahWidget(surahNumber: firstAyahInLine.surahNumber),
                ],
              );
            }

            return Column(
              children: [
                if (header != null) header,
                SizedBox(
                  width: deviceSize.width - 30,
                  height:
                      ((orientation == Orientation.portrait
                              ? constraints.maxHeight
                              : deviceSize.width) -
                          (page.numberOfNewSurahs *
                              (line.ayahs.isNotEmpty && line.ayahs[0].surahNumber != 9
                                  ? 110
                                  : 80))) *
                      0.98 /
                      (page.lines.isEmpty ? 1 : page.lines.length),
                  child: _LineWithBookmarks(
                    line: line,
                    deviceSize: deviceSize,
                    boxFit: line.ayahs.isNotEmpty && line.ayahs.last.centered
                        ? BoxFit.scaleDown
                        : BoxFit.fill,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  String _mapNumberToHizbPart(int number) {
    final reminder = (number / 4) % 1;
    if (number / 4 == 0) return '';
    if (reminder == 0.25) return 'ربع';
    if (reminder == 0.5) return 'نصف';
    if (reminder == 0.75) return 'ثلاثة أرباع';
    return 'بداية';
  }
}

class _LineWithBookmarks extends StatelessWidget {
  final Line line;
  final Size deviceSize;
  final BoxFit boxFit;

  const _LineWithBookmarks({required this.line, required this.deviceSize, required this.boxFit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarksCubit, List<Bookmark>>(
      bloc: AppBloc.bookmarksCubit,
      builder: (context, bookmarks) {
        final bookmarksAyahs = bookmarks.map((bookmark) => bookmark.ayahId).toList();
        return SizedBox(
          width: deviceSize.width - 32,
          child: QuranLine(line, bookmarksAyahs, bookmarks, boxFit: boxFit),
        );
      },
    );
  }
}

class _BookmarkRibbon extends StatelessWidget {
  final bool isRightPage;

  const _BookmarkRibbon({required this.isRightPage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isRightPage ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: isRightPage ? EdgeInsets.only(right: 25.w) : EdgeInsets.only(left: 25.w),
        child: CustomPaint(size: Size(35.w, 100.h), painter: _RibbonPainter()),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xAAF36077)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width / 2, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
