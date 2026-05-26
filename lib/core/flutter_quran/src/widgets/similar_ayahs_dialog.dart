import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/utils/font_style.dart';

class SimilarAyahsDialog extends StatelessWidget {
  final Ayah targetAyah;
  final List<Ayah> similarAyahs;

  const SimilarAyahsDialog({super.key, required this.targetAyah, required this.similarAyahs});

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);
    final bgColor = AppColors.getBackground(context);
    final subtitleColor = AppColors.getSubtitleColor(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: bgColor,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, color: mainColor, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'المتشابهات اللفظية (${similarAyahs.length})',
                      style: AppFontStyle.fontCairo18w700black(
                        context,
                      ).copyWith(color: mainColor, fontSize: 16.sp),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: subtitleColor.withValues(alpha: 0.5),
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                shrinkWrap: true,
                itemCount: similarAyahs.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final ayah = similarAyahs[index];
                  return _buildAyahCard(context, ayah, mainColor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahCard(BuildContext context, Ayah ayah, Color mainColor) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        AppBloc.quranCubit.animateToPage(ayah.page - 1);
        AppBloc.quranCubit.highlightAyah(ayah.id);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: mainColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ayah.ayah.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 18.sp,
                color: mainColor,
                height: 1.6,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      color: AppColors.getMainColor(context),
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'انتقال للآية',
                      style: AppFontStyle.fontAlmarai14w700Black(
                        context,
                      ).copyWith(color: AppColors.getMainColor(context), fontSize: 11.sp),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'سورة ${ayah.surahNameAr} - ${ayah.ayahNumber}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
