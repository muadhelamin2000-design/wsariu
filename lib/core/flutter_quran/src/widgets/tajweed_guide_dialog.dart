import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/utils/flutter_quran_utils.dart';
import 'package:wasariu/core/utils/app_colors.dart';

class TajweedGuideDialog extends StatelessWidget {
  const TajweedGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = AppColors.getMainColor(context);
    final bgColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextColor(context);
    final subTextColor = AppColors.getSubtitleColor(context);

    final tajweedColors = FlutterQuran().getTajweedColors(isDark);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 30.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadowColor(context),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: mainColor, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'دليل ألوان أحكام التجويد',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: mainColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: subTextColor.withValues(alpha: 0.5), size: 20.sp),
                ),
              ],
            ),
            Divider(height: 25.h, thickness: 1, color: mainColor.withValues(alpha: 0.1)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('أحكام النون الساكنة والتنوين', subTextColor),
                    _buildGuideItem(
                      color: tajweedColors['ghunnah']!,
                      title: 'غنة',
                      desc: 'صوت يخرج من الخيشوم',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['ikhfa']!,
                      title: 'إخفاء',
                      desc: 'نطق الحرف بحالة بين الإظهار والإدغام',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['idghaam_ghunnah']!,
                      title: 'إدغام بغنة',
                      desc: 'دمج النون في الحرف التالي مع غنة',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['iqlab']!,
                      title: 'إقلاب',
                      desc: 'قلب النون ميماً عند الباء',
                      textColor: textColor,
                    ),
                    _buildSectionTitle('أحكام الميم الساكنة', subTextColor),
                    _buildGuideItem(
                      color: tajweedColors['ikhfa_shafawi']!,
                      title: 'إخفاء شفوي',
                      desc: 'إخفاء الميم عند حرف الباء',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['idghaam_shafawi']!,
                      title: 'إدغام شفوي',
                      desc: 'إدغام الميم في ميم مثلها',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['idghaam_mutajanisayn']!,
                      title: 'إدغام متجانسين',
                      desc: 'إدغام الحروف المتحدة في المخرج',
                      textColor: textColor,
                    ),
                    _buildSectionTitle('أحكام القلقلة واللفظ', subTextColor),
                    _buildGuideItem(
                      color: tajweedColors['qalqalah']!,
                      title: 'قلقلة',
                      desc: 'اضطراب الصوت عند نطق الحرف ساكناً',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: Colors.redAccent,
                      title: 'لفظ الجلالة',
                      desc: 'اسم الله تعالى (تعظيماً)',
                      isBold: true,
                      textColor: textColor,
                    ),
                    _buildSectionTitle('أحكام المدود', subTextColor),
                    _buildGuideItem(
                      color: tajweedColors['madd_munfasil']!,
                      title: 'مد منفصل / عارض',
                      desc: 'مد بمقدار 2 أو 4 أو 5 حركات',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['madd_muttasil']!,
                      title: 'مد متصل',
                      desc: 'مد بمقدار 4 أو 5 حركات',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['madd_6']!,
                      title: 'مد لازم',
                      desc: 'مد بمقدار 6 حركات مشبعة',
                      textColor: textColor,
                    ),
                    _buildSectionTitle('الوصل والحروف الصامتة', subTextColor),
                    _buildGuideItem(
                      color: tajweedColors['idghaam_no_ghunnah']!,
                      title: 'إدغام بدون غنة',
                      desc: 'دمج الحرف بدون صوت غنة',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['hamzat_wasl']!,
                      title: 'همزة وصل',
                      desc: 'تثبت ابتداءً وتسقط وصلاً',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['lam_shamsiyyah']!,
                      title: 'لام شمسية',
                      desc: 'لام تكتب ولا تنطق',
                      textColor: textColor,
                    ),
                    _buildGuideItem(
                      color: tajweedColors['silent']!,
                      title: 'حروف صامتة',
                      desc: 'حروف مكتوبة لا تلفظ',
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  elevation: 0,
                ),
                child: Text(
                  'فهمت',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          color: color,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required Color color,
    required String title,
    required String desc,
    required Color textColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, right: 5.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: textColor),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
