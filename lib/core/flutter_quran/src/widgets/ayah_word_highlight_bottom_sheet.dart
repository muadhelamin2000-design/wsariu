import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/distance_extension.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/flutter_quran/src/models/highlight.dart';
import 'package:wasariu/core/utils/app_colors.dart';

class AyahWordHighlightBottomSheet extends StatefulWidget {
  final Ayah ayah;

  const AyahWordHighlightBottomSheet({required this.ayah, super.key});

  @override
  State<AyahWordHighlightBottomSheet> createState() => _AyahWordHighlightBottomSheetState();
}

class _AyahWordHighlightBottomSheetState extends State<AyahWordHighlightBottomSheet> {
  final List<int> selectedIndices = [];
  Color selectedColor = const Color(0xFFFFF176);

  @override
  Widget build(BuildContext context) {
    final words = widget.ayah.ayah.trim().split(' ');
    final mainColor = AppColors.getMainColor(context);

    return Container(
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
            "اختر الكلمات المراد تظليلها",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          20.isHeight,
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(words.length, (index) {
                  final isSelected = selectedIndices.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIndices.remove(index);
                        } else {
                          selectedIndices.add(index);
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected ? selectedColor : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        words[index],
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 18.sp,
                          color: mainColor,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          25.isHeight,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _colorDot(const Color(0xFFFFF176)),
              _colorDot(const Color(0xFFAED581)),
              _colorDot(const Color(0xFFFF8A65)),
              _colorDot(const Color(0xFF4FC3F7)),
              _colorDot(const Color(0xFFBA68C8)),
            ],
          ),
          25.isHeight,
          ElevatedButton(
            onPressed: selectedIndices.isEmpty
                ? null
                : () {
                    _saveHighlights(context, words);
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getMainColor(context),
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.getMainColor(context).withValues(alpha: 0.3),
              disabledForegroundColor: AppColors.white.withValues(alpha: 0.5),
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectanglePlatform.borderRadius(12.r),
            ),
            child: const Text("تأكيد التظليل", style: TextStyle(fontFamily: 'Cairo')),
          ),
          20.isHeight,
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    final isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        width: 35.w,
        height: 35.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.white,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  void _saveHighlights(BuildContext context, List<String> words) {
    final quranCubit = context.read<QuranCubit>();

    selectedIndices.sort();

    for (int index in selectedIndices) {
      int start = 0;
      for (int i = 0; i < index; i++) {
        start += words[i].length + 1;
      }
      int end = start + words[index].length;

      quranCubit.addHighlight(
        Highlight(
          ayahId: widget.ayah.id,
          colorCode: selectedColor.toARGB32(),
          start: start + widget.ayah.ayahOffset,
          end: end + widget.ayah.ayahOffset,
        ),
      );
    }
  }
}

class RoundedRectanglePlatform {
  static RoundedRectangleBorder borderRadius(double radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}
