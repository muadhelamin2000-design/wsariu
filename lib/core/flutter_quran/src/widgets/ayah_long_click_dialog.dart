import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/widgets/custom_loading_indicator.dart';

class AyahLongClickDialog extends StatelessWidget {
  final Ayah ayah;

  const AyahLongClickDialog({required this.ayah, super.key});

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);
    final goldColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFD54F)
        : const Color(0xFFD4AF37);
    final bgColor = AppColors.getBackground(context);
    final itemColor = AppColors.getSurface(context);
    final textColor = AppColors.getTextColor(context);
    final subtitleColor = AppColors.getSubtitleColor(context);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: mainColor, size: 24.sp),
                  SizedBox(width: 10.w),
                  Text(
                    "معاني الكلمات",
                    style: TextStyle(
                      fontFamily: 'ReemKufi',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                  const Spacer(),
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
              Divider(color: mainColor.withValues(alpha: 0.1)),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: mainColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          ayah.ayah.trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 18.sp,
                            color: mainColor,
                            height: 1.6,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      FutureBuilder<String?>(
                        future: _loadMeaning(ayah.surahNumber, ayah.ayahNumber),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CustomLoadingIndicator(color: mainColor));
                          }

                          final meaningText = snapshot.data;
                          if (meaningText == null || meaningText.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: Text(
                                "لا توجد معاني كلمات مسجلة لهذه الآية",
                                style: TextStyle(color: subtitleColor, fontSize: 14.sp),
                              ),
                            );
                          }

                          final meanings = meaningText.split('<br>');

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: meanings.length,
                            itemBuilder: (context, index) {
                              final parts = meanings[index].split(':');
                              final word = parts.isNotEmpty ? parts[0].trim() : "";
                              final meaning = parts.length > 1 ? parts[1].trim() : "";

                              return Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: itemColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: mainColor.withValues(alpha: 0.1)),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "$word: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: goldColor,
                                          fontSize: 15.sp,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      TextSpan(
                                        text: meaning,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14.sp,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    minimumSize: Size(double.infinity, 45.h),
                  ),
                  child: Text(
                    "إغلاق",
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontFamily: 'Cairo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _loadMeaning(int surah, int ayahNo) async {
    try {
      final String content = await rootBundle.loadString('assets/jsons/tafseer/ar_ma3any.json');
      final List<dynamic> jsonList = json.decode(content);

      final result = jsonList.firstWhere(
        (element) => element['sura'] == surah && element['aya'] == ayahNo,
        orElse: () => null,
      );

      return result != null ? result['text'] : null;
    } catch (e) {
      return null;
    }
  }
}
