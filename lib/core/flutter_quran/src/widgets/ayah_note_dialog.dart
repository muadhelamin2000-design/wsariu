import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/utils/font_style.dart';
import 'package:wasariu/features/quran/data/models/ayah_note_model.dart';
import 'package:wasariu/features/quran/data/repos/ayah_notes_repo.dart';

import '../../../extensions/distance_extension.dart';
import '../../../widgets/custom_loading_indicator.dart';

class AyahNoteDialog extends StatefulWidget {
  final int ayahId;
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;

  const AyahNoteDialog({
    super.key,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  State<AyahNoteDialog> createState() => _AyahNoteDialogState();
}

class _AyahNoteDialogState extends State<AyahNoteDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  List<AyahNoteModel> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await AyahNotesRepo.getNotesByAyahId(widget.ayahId);
    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNote() async {
    if (_controller.text.trim().isEmpty) return;

    final note = AyahNoteModel(
      ayahId: widget.ayahId,
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      note: _controller.text.trim(),
      createdAt: DateFormat('yyyy/MM/dd | hh:mm a').format(DateTime.now()),
    );

    await AyahNotesRepo.addNote(note);
    if (!mounted) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    await AyahNotesRepo.deleteNote(id);
    if (!mounted) return;
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: AppColors.getBackground(context),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: mainColor, size: 28.sp),
                8.isWidth,
                Text(
                  'تدبرات الآية',
                  style: AppFontStyle.fontCairo18w700black(context).copyWith(color: mainColor),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.getSubtitleColor(context).withValues(alpha: 0.5),
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            12.isHeight,
            Container(
              constraints: BoxConstraints(maxHeight: 80.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: mainColor.withValues(alpha: 0.1)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.ayahText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 15.sp,
                    color: mainColor.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            16.isHeight,
            if (_isLoading)
              const Center(child: CustomLoadingIndicator())
            else ...[
              Flexible(
                child: _notes.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.only(bottom: 16.h),
                        itemCount: _notes.length,
                        separatorBuilder: (context, index) => 12.isHeight,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return _buildNoteCard(note, mainColor);
                        },
                      ),
              ),
              Divider(height: 24.h, color: mainColor.withValues(alpha: 0.1)),
              _buildInputSection(mainColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notes_rounded,
              color: AppColors.getSubtitleColor(context).withValues(alpha: 0.2),
              size: 40.sp,
            ),
            8.isHeight,
            Text(
              'ابدأ بكتابة أول تدبر لك لهذه الآية',
              style: TextStyle(color: AppColors.getSubtitleColor(context), fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(AyahNoteModel note, Color mainColor) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: mainColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.getSubtitleColor(context).withValues(alpha: 0.5),
                size: 12.sp,
              ),
              6.isWidth,
              Text(
                note.createdAt,
                style: TextStyle(
                  color: AppColors.getSubtitleColor(context).withValues(alpha: 0.5),
                  fontSize: 10.sp,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _deleteNote(note.id!),
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade300,
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          8.isHeight,
          Text(
            note.note,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 13.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(Color mainColor) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          maxLines: 2,
          style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'ماذا استوقفك في هذه الآية؟',
            hintStyle: TextStyle(
              color: AppColors.getSubtitleColor(context).withValues(alpha: 0.5),
              fontSize: 13.sp,
            ),
            filled: true,
            fillColor: AppColors.getSurface(context),
            contentPadding: EdgeInsets.all(12.r),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.getMainColor(context).withValues(alpha: 0.3)),
            ),
          ),
        ),
        12.isHeight,
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getMainColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20.sp),
                8.isWidth,
                Text(
                  'إضافة التدبر',
                  style: AppFontStyle.fontAlmarai14w700Black(context).copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
