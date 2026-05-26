import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_constants.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';

class QuranPageBottomInfoWidget extends StatelessWidget {
  final String surahName;
  final int page;
  final int? hizb;

  const QuranPageBottomInfoWidget({
    required this.surahName,
    required this.page,
    required this.hizb,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isThemeDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<QuranCubit, List<QuranPage>>(
      bloc: AppBloc.quranCubit,
      builder: (context, state) {
        final pageColor =
            AppBloc.quranCubit.pageColor ?? (isThemeDark ? Colors.black : const Color(0xFFFFF9E7));
        final isDarkColor = ThemeData.estimateBrightnessForColor(pageColor) == Brightness.dark;

        final mainColor = isDarkColor ? Colors.white : Theme.of(context).primaryColor;
        final goldColor = isDarkColor ? const Color(0xFFFFD54F) : const Color(0xFFD4AF37);

        String hizbText = '';
        if (hizb != null) {
          hizbText =
              '${_mapNumberToHizbPart(hizb!)} الحزب ${QuranConstants.quranHizbs[((hizb! - 1) / 4).floor()]}';
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (AppBloc.quranCubit.isTajweedEnabled)
              Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: mainColor.withValues(alpha: 0.05), width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TajweedItem(
                        color: Theme.of(context).primaryColor,
                        text: 'غنة',
                        isDark: isDarkColor,
                      ),
                      _TajweedItem(
                        color: const Color(0xFF4CAF50),
                        text: 'إخفاء',
                        isDark: isDarkColor,
                      ),
                      _TajweedItem(
                        color: const Color(0xFFF57C00),
                        text: 'إقلاب',
                        isDark: isDarkColor,
                      ),
                      _TajweedItem(
                        color: const Color(0xFFC2185B),
                        text: 'قلقلة',
                        isDark: isDarkColor,
                      ),
                      _TajweedItem(
                        color: const Color(0xFF1976D2),
                        text: 'مدود',
                        isDark: isDarkColor,
                      ),
                      _TajweedItem(
                        color: const Color(0xFF616161),
                        text: 'إدغام/أخرى',
                        isDark: isDarkColor,
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: hizb != null
                        ? Text(
                            hizbText,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 11.sp,
                              color: mainColor.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          )
                        : const SizedBox(),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.brightness_low_rounded,
                          color: goldColor.withValues(alpha: 0.25),
                          size: 44.sp,
                        ),
                        Text(
                          page.toString().toArabic(),
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ReemKufi',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'سورة $surahName',
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 12.sp,
                        color: mainColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _mapNumberToHizbPart(int number) {
    final reminder = (number / 4) % 1;
    if (number / 4 == 0) {
      return '';
    } else if (reminder == 0.25) {
      return 'ربع';
    } else if (reminder == 0.5) {
      return 'نصف';
    } else if (reminder == 0.75) {
      return 'ثلاثة أرباع';
    } else {
      return 'بداية';
    }
  }
}

class _TajweedItem extends StatelessWidget {
  final Color color;
  final String text;
  final bool isDark;

  const _TajweedItem({required this.color, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              fontFamily: 'Cairo',
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
