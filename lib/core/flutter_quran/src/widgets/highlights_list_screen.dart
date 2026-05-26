import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/utils/font_style.dart';

class HighlightsListScreen extends StatelessWidget {
  const HighlightsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranCubit, List<QuranPage>>(
      builder: (context, pages) {
        final quranCubit = context.read<QuranCubit>();
        final highlights = quranCubit.highlights;

        return Container(
          height: 0.8.sh,
          decoration: BoxDecoration(
            color: AppColors.getBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  'التظليلات المحفوظة',
                  style: AppFontStyle.fontReemKafi18w700titleColor(context),
                ),
              ),
              if (highlights.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.format_color_reset_rounded,
                          size: 64.sp,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا توجد تظليلات محفوظة بعد',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: highlights.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 20, color: Colors.grey.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final h = highlights[index];
                      final ayah = quranCubit.ayahs.firstWhere((a) => a.id == h.ayahId);

                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          AppBloc.quranCubit.animateToPage(ayah.page - 1);
                          AppBloc.quranCubit.highlightAyah(ayah.id);
                        },
                        leading: Container(
                          width: 12.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Color(h.colorCode),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        title: Text(
                          ayah.surahNameAr,
                          style: AppFontStyle.fontAlmarai14w700Black(context),
                        ),
                        subtitle: Text(
                          'آية رقم ${ayah.ayahNumber.toString().toArabic()} - ${h.label ?? (h.start != null ? "تظليل جزئي" : "تظليل كلي")}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: AppColors.getSubtitleColor(context),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () {
                            quranCubit.removeHighlight(h.ayahId, start: h.start, end: h.end);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
