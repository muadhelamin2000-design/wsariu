import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/gen/assets.gen.dart';

class QuranTextContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const QuranTextContentScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    final Color bgColor = isDark
        ? Colors.black.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);
    final Color cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFFBF9F4),
        body: Stack(
          children: [
            Positioned.fill(child: Assets.images.backgroundImage.image(fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: bgColor)),
            Column(
              children: [
                _buildAppBar(context, mainColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(color: mainColor.withValues(alpha: 0.1)),
                          ),
                          child: RichText(
                            textAlign: TextAlign.justify,
                            text: _buildStyledContent(isDark),
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

  TextSpan _buildStyledContent(bool isDark) {
    final Color goldColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFD4AF37);
    final Color ayahTextColor = isDark ? const Color(0xFFD2B48C) : const Color(0xFF8B4513);
    final Color greyColor = isDark ? Colors.white38 : Colors.grey;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    final List<TextSpan> spans = [];

    final RegExp regExp = RegExp(r'(﴿[^﴾]+﴾)|(\[[^\]]+\])|(۞)|(•)');

    int start = 0;
    content.splitMapJoin(
      regExp,
      onMatch: (Match match) {
        if (match.start > start) {
          spans.add(
            TextSpan(
              text: content.substring(start, match.start),
              style: TextStyle(
                fontSize: 18.sp,
                color: textColor,
                height: 2.0,
                fontFamily: 'AmiriQuran',
              ),
            ),
          );
        }

        final String matchedText = match.group(0)!;
        if (matchedText.startsWith('﴿')) {
          spans.add(
            TextSpan(
              text: matchedText,
              style: TextStyle(
                fontSize: 19.sp,
                color: ayahTextColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'AmiriQuran',
              ),
            ),
          );
        } else if (matchedText.startsWith('[')) {
          spans.add(
            TextSpan(
              text: matchedText,
              style: TextStyle(fontSize: 14.sp, color: greyColor, fontFamily: 'Cairo'),
            ),
          );
        } else if (matchedText == '۞') {
          spans.add(
            TextSpan(
              text: ' $matchedText ',
              style: TextStyle(fontSize: 20.sp, color: goldColor),
            ),
          );
        } else if (matchedText == '•') {
          spans.add(
            TextSpan(
              text: '\n$matchedText ',
              style: TextStyle(fontSize: 22.sp, color: goldColor, fontWeight: FontWeight.bold),
            ),
          );
        }

        start = match.end;
        return '';
      },
      onNonMatch: (String text) {
        return '';
      },
    );

    if (start < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(start),
          style: TextStyle(
            fontSize: 18.sp,
            color: textColor,
            height: 2.0,
            fontFamily: 'AmiriQuran',
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  Widget _buildAppBar(BuildContext context, Color mainColor) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                  fontFamily: 'ReemKufi',
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.1),
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
      ),
    );
  }
}
