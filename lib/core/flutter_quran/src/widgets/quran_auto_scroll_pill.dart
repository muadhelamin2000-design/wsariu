import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';

class QuranAutoScrollPill extends StatelessWidget {
  const QuranAutoScrollPill({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<QuranCubit, List<QuranPage>>(
      builder: (context, state) {
        if (!AppBloc.quranCubit.isVertical) return const SizedBox.shrink();
        return Positioned(
          bottom: 25.h,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => AppBloc.quranCubit.toggleAutoScroll(),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppBloc.quranCubit.isAutoScrolling
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26.sp,
                          ),
                        ),
                      ),
                      Container(
                        height: 20.h,
                        width: 1.w,
                        margin: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      _SpeedBtn(
                        icon: Icons.remove_rounded,
                        onPressed: () {
                          double current = AppBloc.quranCubit.autoScrollSpeed;
                          if (current > 0.5) {
                            AppBloc.quranCubit.setAutoScrollSpeed(current - 0.5);
                          }
                        },
                      ),
                      Container(
                        width: 45.w,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'السرعة',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8.sp,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              AppBloc.quranCubit.autoScrollSpeed.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SpeedBtn(
                        icon: Icons.add_rounded,
                        onPressed: () {
                          double current = AppBloc.quranCubit.autoScrollSpeed;
                          if (current < 5.0) {
                            AppBloc.quranCubit.setAutoScrollSpeed(current + 0.5);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeedBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SpeedBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }
}
