import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/utils/flutter_quran_utils.dart';
import 'package:wasariu/features/quran/data/models/surah_item_model.dart';
import 'package:wasariu/features/quran/data/repos/surah_repos.dart';

import '../../../utils/app_colors.dart';

class SurahHeaderWidget extends StatelessWidget {
  final String surahName;
  final int surahNumber;

  const SurahHeaderWidget({required this.surahName, required this.surahNumber, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final surahs = await SurahRepo.loadSurahs();
        final surahInfo = surahs.firstWhere((element) => element.surahNumber == surahNumber);

        if (!context.mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _SurahInfoBottomSheet(surahInfo: surahInfo),
        );
      },
      child: Container(
        height: 50.h,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8.0.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'lib/core/flutter_quran/assets/images/surah_banner.png',
              fit: BoxFit.fill,
              width: double.infinity,
              height: 50.h,
            ),
            Text(
              'سورة $surahName',
              style: FlutterQuran()
                  .getHafsStyle(context)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahInfoBottomSheet extends StatefulWidget {
  final SurahItemModel surahInfo;

  const _SurahInfoBottomSheet({required this.surahInfo});

  @override
  State<_SurahInfoBottomSheet> createState() => _SurahInfoBottomSheetState();
}

class _SurahInfoBottomSheetState extends State<_SurahInfoBottomSheet> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mainColor = isDark ? Colors.white : AppColors.getMainColor(context);
    final accentColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2B790A);
    final goldColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF26D00);
    final sheetBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7EFE0);
    final cardBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: mainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mainColor.withValues(alpha: 0.1)),
                ),
                child: Text(
                  widget.surahInfo.surahName,
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: mainColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.surahInfo.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1.5, height: 20, color: mainColor.withValues(alpha: 0.1)),
                  Expanded(
                    child: Center(
                      child: Text(
                        'عدد الآيات: ${widget.surahInfo.ayahNumbers}'.toArabic(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: 'أسماء السورة',
                    index: 1,
                    isDark: isDark,
                    mainColor: mainColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    title: 'عن السورة',
                    index: 0,
                    isDark: isDark,
                    mainColor: mainColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: mainColor.withValues(alpha: 0.05)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: RichText(
                    textAlign: TextAlign.justify,
                    text: _buildStyledText(
                      selectedTabIndex == 0
                          ? (widget.surahInfo.surahInfo ?? 'لا توجد معلومات')
                          : (widget.surahInfo.surahNames ?? 'لا توجد معلومات'),
                      textColor: textColor,
                      mainColor: mainColor,
                      accentColor: accentColor,
                      goldColor: goldColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required bool isDark,
    required Color mainColor,
  }) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.getMainColor(context))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: mainColor.withValues(alpha: 0.2)),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: AppColors.getMainColor(context).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : mainColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildStyledText(
    String text, {
    required Color textColor,
    required Color mainColor,
    required Color accentColor,
    required Color goldColor,
  }) {
    List<TextSpan> spans = [];

    final regex = RegExp(
      r'(\[.*?\])|(«.*?»)|(".*?")|(قَالَ|أَخْرَجَ|رَوَى|حَكَى|سُمِّيَت|تُسَمَّى)',
    );

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(fontSize: 17, height: 1.8, color: textColor, fontFamily: 'Cairo'),
          ),
        );
      }

      final matchedText = match.group(0)!;

      if (matchedText.startsWith('[')) {
        spans.add(
          TextSpan(
            text: matchedText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: mainColor,
              fontFamily: 'Cairo',
            ),
          ),
        );
      } else if (matchedText.startsWith('«') || matchedText.startsWith('"')) {
        spans.add(
          TextSpan(
            text: matchedText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: goldColor,
              fontFamily: 'Cairo',
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: matchedText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: accentColor,
              fontFamily: 'Cairo',
            ),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            fontSize: 17,
            height: 1.8,
            color: textColor,
            fontFamily: 'Cairo',
            backgroundColor: Colors.transparent,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
