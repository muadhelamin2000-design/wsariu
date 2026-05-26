import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_search_bottom_sheet.dart';
import 'package:wasariu/features/quran/presentation/manager/hifz_cubit.dart';
import 'package:wasariu/gen/assets.gen.dart';

class QuranAppBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const QuranAppBar({required this.scaffoldKey, super.key});

  @override
  Widget build(BuildContext context) {
    final isThemeDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<QuranCubit, List<QuranPage>>(
      bloc: AppBloc.quranCubit,
      builder: (context, state) {
        final pageColor =
            AppBloc.quranCubit.pageColor ?? (isThemeDark ? Colors.black : const Color(0xFFFFF9E7));

        final isDarkColor = ThemeData.estimateBrightnessForColor(pageColor) == Brightness.dark;
        final mainColor = isDarkColor ? Colors.white : const Color(0xFF0C3708);

        return BlocListener<HifzCubit, HifzState>(
          bloc: AppBloc.hifzCubit,
          listener: (context, hifzState) {
            if (hifzState is HifzError) {
              final isWarning = hifzState.message.contains('بالفعل');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        isWarning ? Icons.info_outline : Icons.error_outline,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          hifzState.message,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: isWarning ? Colors.orange.shade800 : Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  margin: EdgeInsets.all(16.r),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            color: pageColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu_rounded, color: mainColor, size: 28.sp),
                          onPressed: () => scaffoldKey.currentState?.openDrawer(),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'القرآن الكريم',
                          style: TextStyle(
                            fontFamily: 'ReemKufi',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w600,
                            color: mainColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search_rounded, color: mainColor, size: 26.sp),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const QuranSearchBottomSheet(),
                            );
                          },
                          tooltip: 'بحث',
                        ),
                        IconButton(
                          icon: Icon(Icons.bookmark_add_outlined, color: mainColor, size: 26.sp),
                          onPressed: () {
                            final currentPage = AppBloc.quranCubit.lastPage;
                            AppBloc.hifzCubit.addPage(currentPage).then((_) {
                              if (!context.mounted) return;
                              if (AppBloc.hifzCubit.state is! HifzError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Colors.white),
                                        SizedBox(width: 10.w),
                                        Text(
                                          'تمت إضافة الصفحة لجدول الحفظ بنجاح',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF0C3708),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    margin: EdgeInsets.all(16.r),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            });
                          },
                          tooltip: 'إضافة للحفظ',
                        ),
                        IconButton(
                          icon: Icon(
                            AppBloc.quranCubit.isVertical
                                ? Icons.panorama_horizontal_select_rounded
                                : Icons.panorama_vertical_select_rounded,
                            color: mainColor,
                            size: 26.sp,
                          ),
                          onPressed: () => AppBloc.quranCubit.toggleVerticalMode(),
                          tooltip: AppBloc.quranCubit.isVertical ? 'عرض أفقي' : 'عرض رأسي',
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: isDarkColor
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
