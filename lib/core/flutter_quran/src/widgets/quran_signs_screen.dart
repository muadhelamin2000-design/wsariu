import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_constants.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/gen/assets.gen.dart';

class QuranSignsScreen extends StatelessWidget {
  const QuranSignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = AppColors.getMainColor(context);
    final Color bgColor = AppColors.getBackground(context).withValues(alpha: 0.9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: Assets.images.backgroundImage.image(fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: bgColor)),
            Column(
              children: [
                _buildAppBar(context, isDark, mainColor),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: isDark ? Colors.white : mainColor,
                          unselectedLabelColor: AppColors.getSubtitleColor(context),
                          indicatorColor: isDark ? Colors.white : mainColor,
                          labelStyle: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                          tabs: const [
                            Tab(text: 'علامات الوقف'),
                            Tab(text: 'اصطلاحات الضبط'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildSignsList(context, QuranConstants.waqfSigns, isDark, mainColor),
                              _buildSignsList(
                                context,
                                QuranConstants.dabetSigns,
                                isDark,
                                mainColor,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSignsList(
    BuildContext context,
    List<Map<String, String>> signs,
    bool isDark,
    Color mainColor,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: signs.length,
      itemBuilder: (context, index) {
        final item = signs[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: mainColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.getShadowColor(context),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45.w,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: mainColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item['sign']!,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                        fontFamily: 'AmiriQuran',
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Text(
                    item['name']!,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                item['description']!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.getTextColor(context),
                  height: 1.5,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black26
                      : AppColors.getBackground(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: mainColor.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مثال:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getSubtitleColor(context),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item['example']!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isDark ? const Color(0xFFD2B48C) : const Color(0xFF8B4513),
                        fontFamily: 'AmiriQuran',
                        height: 1.6,
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

  Widget _buildAppBar(BuildContext context, bool isDark, Color mainColor) {
    final Color appBarColor = isDark ? Colors.white : mainColor;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'علامات الوقف والضبط',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: appBarColor,
                fontFamily: 'ReemKufi',
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: appBarColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Assets.images.icons.backIcon.svg(
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(appBarColor, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
