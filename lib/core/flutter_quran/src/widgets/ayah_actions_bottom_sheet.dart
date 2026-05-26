import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/flutter_quran/src/models/highlight.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/ayah_long_click_dialog.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/ayah_note_dialog.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/ayah_word_highlight_bottom_sheet.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_tafseer_bottom_sheet.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/similar_ayahs_dialog.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/utils/app_strings.dart';
import 'package:wasariu/features/quran/presentation/widgets/ayah_share_template.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../configurations/di.dart';
import '../../../extensions/distance_extension.dart';

class AyahActionsBottomSheet extends StatelessWidget {
  final Ayah ayah;
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  const AyahActionsBottomSheet({required this.ayah, super.key});

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);
    final sheetBgColor = AppColors.getBackground(context);
    final previewBgColor = mainColor.withValues(alpha: 0.05);

    final quranCubit = context.read<QuranCubit>();

    final fullAyah = AppBloc.quranCubit.ayahs.firstWhere(
      (a) =>
          a.surahNumber == ayah.surahNumber && a.ayahNumber == ayah.ayahNumber,
      orElse: () => ayah,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.r, 20.w, 30.h),
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          15.isHeight,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "سورة ${fullAyah.surahNameAr}",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "آية ${fullAyah.ayahNumber}".toArabic(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          20.isHeight,
          Flexible(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20.r),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: previewBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: mainColor.withValues(alpha: 0.1)),
                ),
                child: Text(
                  fullAyah.ayah.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 22.sp,
                    color: mainColor,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
          25.isHeight,
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 20.h,
            crossAxisSpacing: 10.w,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ActionItem(
                icon: Icons.menu_book_rounded,
                label: 'المعاني',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => MultiBlocProvider(
                      providers: AppBloc.providers,
                      child: AyahLongClickDialog(ayah: fullAyah),
                    ),
                  );
                },
              ),
              _ActionItem(
                icon: Icons.auto_stories_rounded,
                label: 'التفسير',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => MultiBlocProvider(
                      providers: AppBloc.providers,
                      child: QuranTafseerScreen(initialAyah: fullAyah),
                    ),
                  );
                },
              ),
              _ActionItem(
                icon: Icons.image_outlined,
                label: 'مشاركة كصورة',
                onTap: () => _shareAyahAsImage(context, fullAyah),
              ),
              _ActionItem(
                icon: Icons.note_alt_outlined,
                label: 'تدبر',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AyahNoteDialog(
                      ayahId: fullAyah.id,
                      surahNumber: fullAyah.surahNumber,
                      ayahNumber: fullAyah.ayahNumber,
                      ayahText: fullAyah.ayah.trim(),
                    ),
                  );
                },
              ),
              if (fullAyah.similarAyahs != null &&
                  fullAyah.similarAyahs!.isNotEmpty)
                _ActionItem(
                  icon: Icons.compare_arrows_rounded,
                  label: 'متشابهات',
                  onTap: () {
                    Navigator.pop(context);
                    _showSimilarAyahsDialog(
                      context,
                      fullAyah,
                      fullAyah.similarAyahs!,
                    );
                  },
                ),
              _ActionItem(
                icon: quranCubit.isAyahHidden(fullAyah.id)
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: quranCubit.isAyahHidden(fullAyah.id) ? 'إظهار' : 'حفظ',
                onTap: () {
                  quranCubit.toggleAyahVisibility(fullAyah.id);
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: quranCubit.isAyahHidden(fullAyah.id)
                        ? "تم تظليل الآية للمراجعة"
                        : "تم إظهار الآية",
                  );
                },
              ),
              _ActionItem(
                icon: Icons.format_color_fill_rounded,
                label: 'تلوين',
                onTap: () {
                  _showColorPicker(context, quranCubit, fullAyah);
                },
              ),
              _ActionItem(
                icon: Icons.copy_rounded,
                label: 'نسخ',
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: fullAyah.ayah.trim()),
                  ).then((_) {
                    Fluttertoast.showToast(msg: "تم نسخ الآية");
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSimilarAyahsDialog(
    BuildContext context,
    Ayah target,
    List<Ayah> similar,
  ) {
    showDialog(
      context: context,
      builder: (ctx) =>
          SimilarAyahsDialog(targetAyah: target, similarAyahs: similar),
    );
  }

  void _showColorPicker(
    BuildContext context,
    QuranCubit quranCubit,
    Ayah ayah,
  ) {
    final colors = [
      {'color': const Color(0xFFFFF176), 'label': 'تظليل أصفر'},
      {'color': const Color(0xFFAED581), 'label': 'حفظ متقن'},
      {'color': const Color(0xFFFF8A65), 'label': 'خطأ'},
      {'color': const Color(0xFF4FC3F7), 'label': 'تنبيه'},
      {'color': const Color(0xFFBA68C8), 'label': 'مراجعة'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            20.isHeight,
            const Text(
              "اختر لون التظليل",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            20.isHeight,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...colors.map(
                  (c) => GestureDetector(
                    onTap: () {
                      quranCubit.addHighlight(
                        Highlight(
                          ayahId: ayah.id,
                          colorCode: (c['color'] as Color).toARGB32(),
                          label: c['label'] as String,
                        ),
                      );
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 45.w,
                      height: 45.w,
                      decoration: BoxDecoration(
                        color: (c['color'] as Color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    quranCubit.removeHighlight(ayah.id);
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.format_color_reset_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            20.isHeight,
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => MultiBlocProvider(
                    providers: AppBloc.providers,
                    child: AyahWordHighlightBottomSheet(ayah: ayah),
                  ),
                );
              },
              icon: const Icon(Icons.abc_rounded),
              label: const Text(
                "تحديد كلمات معينة",
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 45.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            10.isHeight,
          ],
        ),
      ),
    );
  }

  Future<void> _shareAyahAsImage(BuildContext context, Ayah ayah) async {
    Fluttertoast.showToast(msg: "جاري تجهيز الصورة...");

    final image = await _screenshotController.captureFromWidget(
      Material(
        child: AyahShareTemplate(
          ayahText: ayah.ayah.trim(),
          surahName: ayah.surahNameAr,
          ayahNumber: ayah.ayahNumber,
        ),
      ),
      delay: const Duration(milliseconds: 100),
    );

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/ayah_share.png').create();
    await imagePath.writeAsBytes(image);

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'مشاركة من ${AppStrings.appName}',
      );
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : color = null;

  @override
  Widget build(BuildContext context) {
    final mainColor = color ?? AppColors.getMainColor(context);
    final iconBgColor = mainColor.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mainColor, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              color: AppColors.getTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
