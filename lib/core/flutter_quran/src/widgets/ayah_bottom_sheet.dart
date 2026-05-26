import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/utils/app_colors.dart';

import '../app_bloc.dart';
import '../audio/constants/readers_constants.dart';
import '../audio/controller/audio_cubit.dart';
import '../audio/controller/audio_state.dart';

class AyahAudioBottomSheet extends StatefulWidget {
  final Ayah ayah;

  const AyahAudioBottomSheet({super.key, required this.ayah});

  @override
  State<AyahAudioBottomSheet> createState() => _AyahAudioBottomSheetState();
}

class _AyahAudioBottomSheetState extends State<AyahAudioBottomSheet> {
  double _currentExtent = 0.15;
  late AudioCubit _audioCubit;
  late int _startAyah;
  late int _endAyah;
  late int _maxAyah;

  @override
  void initState() {
    super.initState();
    _startAyah = widget.ayah.ayahNumber;
    _endAyah = widget.ayah.ayahNumber;

    final currentSurah = AppBloc.quranCubit.surahs.firstWhere(
      (s) => s.index == widget.ayah.surahNumber,
    );
    _maxAyah = currentSurah.ayahs.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioCubit = context.read<AudioCubit>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    final goldColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFD4AF37);
    final sheetBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (mounted) {
          setState(() {
            _currentExtent = notification.extent;
          });
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.15,
        minChildSize: 0.15,
        maxChildSize: 0.9,
        snap: true,
        expand: false,
        builder: (context, scrollController) {
          final isExpanded = _currentExtent > 0.25;

          return Container(
            decoration: BoxDecoration(
              color: sheetBgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BlocConsumer<AudioCubit, AudioState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  Fluttertoast.showToast(
                    msg: state.errorMessage!,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 14.sp,
                  );
                  context.read<AudioCubit>().clearError();
                }
              },
              builder: (context, state) {
                final audioCubit = context.read<AudioCubit>();
                final readers = ReadersConstants.activeAyahReaders;

                final currentAyahId = state.selectedAyahId ?? state.playingAyahId ?? widget.ayah.id;
                final currentAyah = AppBloc.quranCubit.ayahs.firstWhere(
                  (a) => a.id == currentAyahId,
                  orElse: () => widget.ayah,
                );

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: isExpanded ? 15.h : 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isExpanded) ...[
                              _buildPlayerAction(
                                state.repeatMode == AudioRepeatMode.infinity
                                    ? Icons.all_inclusive
                                    : state.repeatMode == AudioRepeatMode.ayah
                                    ? Icons.repeat_one_rounded
                                    : state.repeatMode == AudioRepeatMode.range
                                    ? Icons.compare_arrows_rounded
                                    : Icons.repeat_rounded,
                                () => audioCubit.toggleRepeat(),
                                state.repeatMode == AudioRepeatMode.none
                                    ? mainColor.withValues(alpha: 0.4)
                                    : goldColor,
                              ),
                              SizedBox(width: 15.w),
                            ],
                            _buildPlayerAction(
                              Icons.skip_previous_rounded,
                              () => audioCubit.skipPrevious(),
                              mainColor,
                              size: 35.sp,
                            ),
                            SizedBox(width: 20.w),
                            _buildMainPlayButton(
                              state,
                              currentAyah,
                              audioCubit,
                              mainColor,
                              isDark: isDark,
                              isSmall: !isExpanded,
                            ),
                            SizedBox(width: 20.w),
                            _buildPlayerAction(
                              Icons.skip_next_rounded,
                              () => audioCubit.skipNext(),
                              mainColor,
                              size: 35.sp,
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        Divider(height: 1.h, color: mainColor.withValues(alpha: 0.05)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAyahHeader(currentAyah, mainColor),
                              SizedBox(height: 30.h),

                              _buildRangeSelector(mainColor, isDark),

                              SizedBox(height: 25.h),
                              _buildRepeatControl(state, audioCubit, mainColor, isDark),

                              SizedBox(height: 25.h),
                              Text(
                                "سرعة التلاوة",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                              SizedBox(height: 15.h),
                              _buildPlaybackSpeedSelector(state, audioCubit, mainColor, isDark),

                              SizedBox(height: 35.h),
                              Text(
                                "اختر القارئ",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                              SizedBox(height: 15.h),
                              _buildReadersList(
                                readers,
                                state,
                                audioCubit,
                                currentAyah,
                                mainColor,
                                isDark,
                              ),
                              SizedBox(height: 40.h),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRangeSelector(Color mainColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "تحديد نطاق التلاوة (سورة ${widget.ayah.surahNameAr})",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: mainColor),
        ),
        SizedBox(height: 15.h),
        Row(
          children: [
            Expanded(
              child: _buildAyahPicker(
                label: "من آية",
                value: _startAyah,
                max: _endAyah,
                onChanged: (val) {
                  setState(() => _startAyah = val);
                  _updateAudioRange();
                },
                mainColor: mainColor,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: _buildAyahPicker(
                label: "إلى آية",
                value: _endAyah,
                min: _startAyah,
                max: _maxAyah,
                onChanged: (val) {
                  setState(() => _endAyah = val);
                  _updateAudioRange();
                },
                mainColor: mainColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAyahPicker({
    required String label,
    required int value,
    int min = 1,
    required int max,
    required ValueChanged<int> onChanged,
    required Color mainColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: mainColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: mainColor.withValues(alpha: 0.6)),
          ),
          Row(
            children: [
              _pickerBtn(Icons.remove, () {
                if (value > min) onChanged(value - 1);
              }, mainColor),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  value.toString().toArabic(),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: mainColor),
                ),
              ),
              _pickerBtn(Icons.add, () {
                if (value < max) onChanged(value + 1);
              }, mainColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickerBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 16.sp, color: color),
      ),
    );
  }

  void _updateAudioRange() {
    final surahAyahs = AppBloc.quranCubit.surahs
        .firstWhere((s) => s.index == widget.ayah.surahNumber)
        .ayahs;

    final startId = surahAyahs[_startAyah - 1].id;
    final endId = surahAyahs[_endAyah - 1].id;

    _audioCubit.setRange(startId, endId);
  }

  Widget _buildAyahHeader(Ayah currentAyah, Color mainColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "سورة ${currentAyah.surahNameAr}",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: mainColor,
                fontFamily: 'ReemKufi',
              ),
            ),
            Text(
              "آية ${currentAyah.ayahNumber}".toArabic(),
              style: TextStyle(fontSize: 16.sp, color: mainColor.withValues(alpha: 0.5)),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: mainColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Text(
            "صفحة ${currentAyah.page}".toArabic(),
            style: TextStyle(fontSize: 13.sp, color: mainColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatControl(
    AudioState state,
    AudioCubit audioCubit,
    Color mainColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "عدد مرات التكرار",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: mainColor),
            ),
            if ((state.repeatMode == AudioRepeatMode.ayah ||
                    state.repeatMode == AudioRepeatMode.range) &&
                state.remainingRepeats > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.getMainColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "المتبقي: ${state.remainingRepeats}".toArabic(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.getMainColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 3, 5, 10, 20].map((count) {
            final isSel = state.repeatCount == count;
            return GestureDetector(
              onTap: () => audioCubit.setRepeatCount(count),
              child: Container(
                width: 65.w,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.getMainColor(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSel
                        ? AppColors.getMainColor(context)
                        : mainColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    count == 1 ? "مرة" : "$count مرات",
                    style: TextStyle(
                      color: isSel ? Colors.white : mainColor,
                      fontSize: 12.sp,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlaybackSpeedSelector(
    AudioState state,
    AudioCubit audioCubit,
    Color mainColor,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
        final isSel = state.playbackSpeed == speed;
        return GestureDetector(
          onTap: () => audioCubit.setPlaybackSpeed(speed),
          child: Container(
            width: 58.w,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: isSel ? (isDark ? Colors.white24 : mainColor) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSel
                    ? (isDark ? Colors.white38 : mainColor)
                    : mainColor.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Text(
                "${speed}x",
                style: TextStyle(
                  color: isSel ? Colors.white : mainColor,
                  fontSize: 14.sp,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReadersList(
    List<ReaderInfo> readers,
    AudioState state,
    AudioCubit audioCubit,
    Ayah currentAyah,
    Color mainColor,
    bool isDark,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: readers.length,
      itemBuilder: (context, index) {
        final reader = readers[index];
        final isSelected = state.ayahReaderIndex == index;
        final progress = state.downloadProgress[reader.index];
        final statusText = state.downloadStatus[reader.index];

        return FutureBuilder<bool>(
          future: audioCubit.isSurahDownloaded(currentAyah.surahNumber, reader),
          builder: (context, snapshot) {
            final isDownloaded = snapshot.data ?? false;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? mainColor.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isSelected
                      ? mainColor.withValues(alpha: 0.3)
                      : mainColor.withValues(alpha: 0.05),
                ),
              ),
              child: ListTile(
                onTap: () {
                  if (isSelected) {
                    audioCubit.playAyah(currentAyah);
                  } else {
                    audioCubit.playAyah(currentAyah, reader: reader, autoPlay: false);
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: isSelected ? mainColor : mainColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_2_outlined,
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : mainColor,
                  ),
                ),
                title: Text(
                  reader.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: mainColor,
                  ),
                ),
                subtitle: progress != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5.h),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: mainColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(isDark ? Colors.white : mainColor),
                            minHeight: 3.h,
                          ),
                          Text(
                            (statusText ?? '').toArabic(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: mainColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        isDownloaded ? "جاهز للاستماع" : "يتطلب إنترنت",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDownloaded
                              ? Colors.green
                              : (isDark ? Colors.white38 : Colors.grey),
                        ),
                      ),
                trailing: progress != null
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.red[400]),
                        onPressed: () => audioCubit.cancelDownload(reader.index),
                      )
                    : IconButton(
                        icon: Icon(
                          isDownloaded
                              ? Icons.download_done_rounded
                              : Icons.cloud_download_outlined,
                          color: isDownloaded ? Colors.green : mainColor.withValues(alpha: 0.3),
                        ),
                        onPressed: isDownloaded
                            ? null
                            : () => audioCubit.downloadSurah(currentAyah.surahNumber, reader),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerAction(IconData icon, VoidCallback? onTap, Color color, {double? size}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: EdgeInsets.all(8.r),
        child: Icon(icon, size: size ?? 28.sp, color: color),
      ),
    );
  }

  Widget _buildMainPlayButton(
    AudioState state,
    Ayah currentAyah,
    AudioCubit audioCubit,
    Color mainColor, {
    bool isSmall = false,
    required bool isDark,
  }) {
    final isCurrentPlaying = state.isPlaying && state.playingAyahId == currentAyah.id;
    final isLoading = state.isAudioPreparing && state.playingAyahId == currentAyah.id;

    return GestureDetector(
      onTap: () {
        if (state.playingAyahId != currentAyah.id) {
          audioCubit.playAyah(currentAyah);
        } else {
          audioCubit.togglePlay();
        }
      },
      child: Container(
        width: isSmall ? 50.sp : 60.sp,
        height: isSmall ? 50.sp : 60.sp,
        decoration: BoxDecoration(
          color: mainColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: mainColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 25.sp,
                  height: 25.sp,
                  child: CircularProgressIndicator(
                    color: isDark ? Colors.black : Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Icon(
                isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: isSmall ? 35.sp : 42.sp,
                color: isDark ? Colors.black : Colors.white,
              ),
      ),
    );
  }
}
