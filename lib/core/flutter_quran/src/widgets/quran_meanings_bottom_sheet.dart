import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/widgets/custom_loading_indicator.dart';
import 'package:wasariu/gen/assets.gen.dart';

import '../app_bloc.dart';
import '../models/surah.dart';

class QuranMeaningsScreen extends StatefulWidget {
  const QuranMeaningsScreen({super.key});

  @override
  State<QuranMeaningsScreen> createState() => _QuranMeaningsScreenState();
}

class _QuranMeaningsScreenState extends State<QuranMeaningsScreen> {
  List<dynamic> _allMeanings = [];
  bool _isLoading = true;
  int _selectedSurahIndex = 1;
  int _selectedAyahIndex = 1;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadMeanings();
  }

  Future<void> _loadMeanings() async {
    try {
      final String content = await rootBundle.loadString('assets/jsons/tafseer/ar_ma3any.json');
      final List<dynamic> jsonList = json.decode(content);

      final firstAyahWithMeaning = jsonList.firstWhere(
        (m) => m['sura'] == _selectedSurahIndex && m['text'].toString().trim().isNotEmpty,
        orElse: () => null,
      );

      setState(() {
        _allMeanings = jsonList;
        if (firstAyahWithMeaning != null) {
          _selectedAyahIndex = firstAyahWithMeaning['aya'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToAyah(int ayahNumber, List<dynamic> surahMeanings) {
    if (!_scrollController.hasClients) return;

    final key = _itemKeys[ayahNumber];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, alignment: 0.0);
    } else {
      int index = surahMeanings.indexWhere((m) => m['aya'] == ayahNumber);
      if (index != -1) {
        double targetOffset = index * 250.h;
        _scrollController.jumpTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final retryKey = _itemKeys[ayahNumber];
          if (retryKey != null && retryKey.currentContext != null) {
            Scrollable.ensureVisible(retryKey.currentContext!, alignment: 0.0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    final Color goldColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFD4AF37);
    final Color ayahTextColor = isDark ? const Color(0xFFD2B48C) : const Color(0xFF8B4513);
    final Color bgColor = isDark
        ? Colors.black.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);
    final Color textColor = isDark ? Colors.white70 : Colors.black87;

    final surahs = AppBloc.quranCubit.surahs;
    final currentSurah = surahs.firstWhere(
      (s) => s.index == _selectedSurahIndex,
      orElse: () => surahs.first,
    );

    final surahMeanings = _allMeanings
        .where((m) => m['sura'] == _selectedSurahIndex && m['text'].toString().trim().isNotEmpty)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFFBF9F4),
        body: Stack(
          children: [
            Positioned.fill(child: Assets.images.backgroundImage.image(fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: bgColor)),
            Column(
              children: [
                _buildAppBar(context, mainColor),
                _buildSelectionBar(currentSurah, surahMeanings, mainColor, goldColor, isDark),
                Expanded(
                  child: _isLoading
                      ? Center(child: CustomLoadingIndicator(color: mainColor))
                      : surahMeanings.isEmpty
                      ? Center(
                          child: Text(
                            "لا توجد معاني كلمات مسجلة لهذه السورة",
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          children: surahMeanings.map((item) {
                            final ayahNum = item['aya'] as int;
                            final isSelected = ayahNum == _selectedAyahIndex;

                            final ayah = AppBloc.quranCubit.ayahs.firstWhere(
                              (a) =>
                                  a.surahNumber == _selectedSurahIndex && a.ayahNumber == ayahNum,
                              orElse: () => AppBloc.quranCubit.ayahs.first,
                            );
                            final meanings = item['text'].toString().split('<br>');

                            return InkWell(
                              onTap: () {
                                setState(() => _selectedAyahIndex = ayahNum);
                              },
                              child: Container(
                                key: _itemKeys[ayahNum] ??= GlobalKey(),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? goldColor.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  border: Border(
                                    right: BorderSide(
                                      color: isSelected ? goldColor : Colors.transparent,
                                      width: 4.w,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${ayah.ayah.replaceAll('\n', ' ').trim()} ﴿${ayahNum.toString().toArabic()}﴾",
                                      style: TextStyle(
                                        fontFamily: 'AmiriQuran',
                                        fontSize: 19.sp,
                                        color: isSelected ? mainColor : ayahTextColor,
                                        height: 1.8,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    SizedBox(height: 12.h),
                                    ...meanings.map((m) {
                                      final parts = m.split(':');
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 8.h),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${parts[0].trim()}: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: mainColor,
                                                  fontSize: 15.sp,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              TextSpan(
                                                text: parts.length > 1 ? parts[1].trim() : "",
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 15.sp,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    if (!isSelected)
                                      Divider(height: 32, color: isDark ? Colors.white10 : null),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color mainColor) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "معاني الكلمات",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: mainColor,
                fontFamily: 'ReemKufi',
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Assets.images.icons.backIcon.svg(
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(mainColor, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    Surah currentSurah,
    List<dynamic> surahMeanings,
    Color mainColor,
    Color goldColor,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorButton(
              label: "سورة ${currentSurah.nameAr}",
              mainColor: mainColor,
              isDark: isDark,
              onTap: () => _showSurahPicker(context, mainColor, goldColor, isDark),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSelectorButton(
              label: "الآية ${_selectedAyahIndex.toString().toArabic()}",
              mainColor: mainColor,
              isDark: isDark,
              onTap: () => _showAyahPicker(context, surahMeanings, mainColor, goldColor, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required String label,
    required VoidCallback onTap,
    required Color mainColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : mainColor,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
      ),
    );
  }

  void _showSurahPicker(BuildContext context, Color mainColor, Color goldColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                "اختر السورة",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getMainColor(context),
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: AppBloc.quranCubit.surahs.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (c, i) {
                  final s = AppBloc.quranCubit.surahs[i];
                  bool isSelected = s.index == _selectedSurahIndex;
                  return InkWell(
                    onTap: () {
                      final firstAyahInNewSurah = _allMeanings.firstWhere(
                        (m) => m['sura'] == s.index && m['text'].toString().trim().isNotEmpty,
                        orElse: () => {'aya': 1},
                      );

                      setState(() {
                        _selectedSurahIndex = s.index;
                        _selectedAyahIndex = firstAyahInNewSurah['aya'];
                        _itemKeys.clear();
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(15.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.getMainColor(context).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.getMainColor(context)
                              : AppColors.getSurface(context).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35.w,
                            height: 35.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.getMainColor(context)
                                  : AppColors.getSurface(context),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.index.toString().toArabic(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.getTextColor(context),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Text(
                            s.nameAr,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 20.sp,
                              color: isSelected
                                  ? AppColors.getMainColor(context)
                                  : AppColors.getTextColor(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.getMainColor(context),
                              size: 20.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showAyahPicker(
    BuildContext context,
    List<dynamic> meanings,
    Color mainColor,
    Color goldColor,
    bool isDark,
  ) {
    int currentIdx = meanings.indexWhere((m) => m['aya'] == _selectedAyahIndex);
    if (currentIdx == -1) currentIdx = 0;

    double itemHeight = 85.h;
    double initialOffset = (currentIdx > 3) ? (currentIdx - 3) * itemHeight : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final pickerScrollController = ScrollController(initialScrollOffset: initialOffset);
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppColors.getBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  "اختر الآية",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getMainColor(context),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: pickerScrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: meanings.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (c, i) {
                    final item = meanings[i];
                    final ayahNum = item['aya'] as int;
                    final ayah = AppBloc.quranCubit.ayahs.firstWhere(
                      (a) => a.surahNumber == _selectedSurahIndex && a.ayahNumber == ayahNum,
                      orElse: () => AppBloc.quranCubit.ayahs.first,
                    );

                    List<String> words = ayah.ayah.trim().split(' ');
                    String shortText = words.take(15).join(' ');
                    if (words.length > 15) shortText += '...';

                    bool isSelected = ayahNum == _selectedAyahIndex;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAyahIndex = ayahNum;
                        });
                        Navigator.pop(ctx);
                        _scrollToAyah(ayahNum, meanings);
                      },
                      borderRadius: BorderRadius.circular(15.r),
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.getMainColor(context).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.getMainColor(context)
                                : AppColors.getSurface(context).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 35.w,
                              height: 35.w,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.getMainColor(context)
                                    : AppColors.getSurface(context),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                ayahNum.toString().toArabic(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.getTextColor(context),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              child: Text(
                                shortText,
                                style: TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 16.sp,
                                  color: isSelected
                                      ? AppColors.getMainColor(context)
                                      : AppColors.getTextColor(context),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.getMainColor(context),
                                size: 20.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}
