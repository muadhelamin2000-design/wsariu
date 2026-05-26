import 'package:arabic_search/arabic_search.dart' as as_lib;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/flutter_quran/src/models/surah.dart';
import 'package:wasariu/core/widgets/custom_search_field.dart';

import '../../../configurations/di.dart';
import '../../../extensions/distance_extension.dart';
import '../../../utils/app_colors.dart';
import '../app_bloc.dart';
import '../utils/flutter_quran_utils.dart';

class QuranSearchBottomSheet extends StatefulWidget {
  const QuranSearchBottomSheet({super.key});

  @override
  State<QuranSearchBottomSheet> createState() => _QuranSearchBottomSheetState();
}

class _QuranSearchBottomSheetState extends State<QuranSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Ayah> _ayahResults = [];
  List<Surah> _surahResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);
    final bgColor = AppColors.getBackground(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Text(
                  "البحث في القرآن",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                    fontFamily: 'ReemKufi',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: CustomSearchField(
                  controller: _searchController,
                  hintText: "ابحث عن سورة أو آية...",
                  debounceDuration: const Duration(milliseconds: 500),
                  onChanged: (val) {
                    setState(() {
                      _ayahResults = AppBloc.quranCubit.search(val);
                      if (val.isEmpty) {
                        _surahResults = [];
                      } else {
                        final normalizedSearch = as_lib.ArabicText.normalize(val);
                        _surahResults = AppBloc.quranCubit.surahs
                            .where((s) => s.normalizedNameAr.contains(normalizedSearch))
                            .toList();
                      }
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _ayahResults = [];
                      _surahResults = [];
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  children: [
                    if (_searchController.text.isEmpty) _buildInitialState(context, mainColor),
                    if (_surahResults.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          "السور",
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      ..._surahResults.map((s) => _buildSurahCard(s, mainColor)),
                      SizedBox(height: 15.h),
                    ],
                    if (_ayahResults.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          "الآيات",
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      ..._ayahResults.map((ayah) => _buildAyahCard(ayah, mainColor)),
                    ],
                    if (_searchController.text.isNotEmpty &&
                        _ayahResults.isEmpty &&
                        _surahResults.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.h),
                          child: Text(
                            "لا توجد نتائج مطابقة",
                            style: TextStyle(color: AppColors.getSubtitleColor(context)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialState(BuildContext context, Color mainColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 60.h),
        Icon(Icons.manage_search_rounded, size: 100.sp, color: mainColor.withValues(alpha: 0.1)),
        20.isHeight,
        Text(
          "البحث في كتاب الله",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: mainColor,
            fontFamily: 'Cairo',
          ),
        ),
        8.isHeight,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Text(
            "اكتب كلمة من آية أو اسم سورة للوصول السريع إليها",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.getSubtitleColor(context),
              fontFamily: 'Cairo',
            ),
          ),
        ),
        30.isHeight,
        Wrap(
          spacing: 15.w,
          runSpacing: 10.h,
          alignment: WrapAlignment.center,
          children: [
            _buildSearchTip(context, Icons.menu_book_rounded, "أسماء السور"),
            _buildSearchTip(context, Icons.format_quote_rounded, "كلمات الآيات"),
            _buildSearchTip(context, Icons.numbers_rounded, "أرقام الصفحات"),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchTip(BuildContext context, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.getMainColor(context).withValues(alpha: 0.6)),
          8.isWidth,
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'Cairo',
              color: AppColors.getSubtitleColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(Surah s, Color mainColor) {
    return Card(
      color: mainColor.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: mainColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: () {
          FlutterQuran().navigateToSurah(s.index);
          Navigator.pop(context);
        },
        leading: Icon(Icons.menu_book_rounded, color: mainColor),
        title: Text(
          s.nameAr,
          style: TextStyle(
            fontFamily: 'AmiriQuran',
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
            color: mainColor,
          ),
        ),
        trailing: Text(
          "ص ${s.startPage}".toArabic(),
          style: TextStyle(fontSize: 12.sp, color: mainColor.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  Widget _buildAyahCard(Ayah ayah, Color mainColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 0 : 2,
      color: AppColors.getSurface(context),
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
        side: isDark ? const BorderSide(color: Colors.white10) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          FlutterQuran().navigateToAyah(ayah);
          Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: mainColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      ayah.surahNameAr,
                      style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Text(
                    "آية ${ayah.ayahNumber.toString().toArabic()}",
                    style: TextStyle(color: AppColors.getSubtitleColor(context), fontSize: 11.sp),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                ayah.ayah.replaceAll('\n', ' '),
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 17.sp,
                  height: 1.6,
                  color: AppColors.getTextColor(context),
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
