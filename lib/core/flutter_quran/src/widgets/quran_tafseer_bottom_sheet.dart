// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/gen/assets.gen.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/custom_loading_indicator.dart';
import '../app_bloc.dart';
import '../controllers/bookmarks_controller.dart';
import '../models/ayah.dart';
import '../models/bookmark.dart';
import '../models/surah.dart';

class QuranTafseerScreen extends StatefulWidget {
  final Ayah? initialAyah;

  const QuranTafseerScreen({this.initialAyah, super.key});

  @override
  State<QuranTafseerScreen> createState() => _QuranTafseerScreenState();
}

class _QuranTafseerScreenState extends State<QuranTafseerScreen> {
  List<dynamic> _allTafseer = [];
  bool _isLoading = true;
  late int _selectedSurahIndex;
  late int _selectedAyahIndex;

  final List<Map<String, String>> _tafseers = [
    {'name': 'الميسر', 'file': 'ar_muyassar.json'},
    {'name': 'السعدي', 'file': 'sa3dy.json'},
    {'name': 'ابن كثير', 'file': 'katheer.json'},
    {'name': 'البغوي', 'file': 'baghawy.json'},
    {'name': 'القرطبي', 'file': 'qortoby.json'},
    {'name': 'الطبري', 'file': 'tabary.json'},
    {'name': 'الوسيط', 'file': 'waseet.json'},
    {'name': 'إعراب القرآن', 'file': 'e3rab.json'},
  ];
  int _selectedTafseerIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _selectedSurahIndex = widget.initialAyah?.surahNumber ?? 1;
    _selectedAyahIndex = widget.initialAyah?.ayahNumber ?? 1;
    _loadTafseer();
  }

  Future<void> _loadTafseer() async {
    setState(() => _isLoading = true);
    try {
      final String fileName = _tafseers[_selectedTafseerIndex]['file']!;
      final String content = await rootBundle.loadString(
        'assets/jsons/tafseer/$fileName',
      );
      final List<dynamic> jsonList = json.decode(content);
      setState(() {
        _allTafseer = jsonList;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToAyah(_selectedAyahIndex),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToAyah(int ayahNumber) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;

      final key = _itemKeys[ayahNumber];

      if (key?.currentContext == null) {
        double estimateOffset = (ayahNumber - 1) * 400.h;
        _scrollController.jumpTo(
          estimateOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );

        await Future.delayed(const Duration(milliseconds: 100));
      }

      final targetKey = _itemKeys[ayahNumber];
      if (targetKey?.currentContext != null && mounted) {
        await Scrollable.ensureVisible(
          targetKey!.currentContext!,
          alignment: 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = isDark
        ? Colors.white
        : Theme.of(context).primaryColor;
    final Color goldColor = isDark
        ? const Color(0xFFFFD54F)
        : const Color(0xFFD4AF37);
    final Color ayahTextColor = isDark
        ? const Color(0xFFD2B48C)
        : const Color(0xFF8B4513);
    final Color bgColor = isDark
        ? Colors.black.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);
    final Color textColor = isDark ? Colors.white70 : Colors.black87;

    final surahs = AppBloc.quranCubit.surahs;
    final currentSurah = surahs.firstWhere(
      (s) => s.index == _selectedSurahIndex,
      orElse: () => surahs.first,
    );
    final surahTafseer = _allTafseer
        .where((t) => t['sura'] == _selectedSurahIndex)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider.value(
        value: AppBloc.bookmarksCubit,
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFFBF9F4),
          body: Stack(
            children: [
              Positioned.fill(
                child: Assets.images.backgroundImage.image(fit: BoxFit.cover),
              ),
              Positioned.fill(child: Container(color: bgColor)),
              Column(
                children: [
                  _buildAppBar(context, mainColor),
                  _buildSelectionBar(
                    currentSurah,
                    surahTafseer.length,
                    mainColor,
                    goldColor,
                    isDark,
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CustomLoadingIndicator())
                        : ListView(
                            controller: _scrollController,
                            cacheExtent: 3000,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            children: surahTafseer.map((item) {
                              final ayahNum = item['aya'] as int;
                              final isSelected = ayahNum == _selectedAyahIndex;
                              final ayah = AppBloc.quranCubit.ayahs.firstWhere(
                                (a) =>
                                    a.surahNumber == _selectedSurahIndex &&
                                    a.ayahNumber == ayahNum,
                                orElse: () => AppBloc.quranCubit.ayahs.first,
                              );

                              return InkWell(
                                onTap: () => setState(
                                  () => _selectedAyahIndex = ayahNum,
                                ),
                                child: Container(
                                  key: _itemKeys[ayahNum] ??= GlobalKey(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? goldColor.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    border: Border(
                                      right: BorderSide(
                                        color: isSelected
                                            ? goldColor
                                            : Colors.transparent,
                                        width: 4.w,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "${ayah.ayah.replaceAll('\n', ' ').trim()} ﴿${ayahNum.toString().toArabic()}﴾",
                                              style: TextStyle(
                                                fontFamily: 'AmiriQuran',
                                                fontSize: 19.sp,
                                                color: isSelected
                                                    ? mainColor
                                                    : ayahTextColor,
                                                height: 1.8,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                              ),
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                          _buildAyahActions(
                                            context,
                                            ayah,
                                            item['text'],
                                            mainColor,
                                            isDark,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        _cleanHtml(item['text']),
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: textColor,
                                          height: 1.7,
                                          fontFamily: 'Cairo',
                                        ),
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.justify,
                                      ),
                                      if (!isSelected)
                                        Divider(
                                          height: 32,
                                          color: isDark ? Colors.white10 : null,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color mainColor) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "تفسير القرآن الكريم",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: mainColor,
                fontFamily: 'ReemKufi',
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

  void _showTafseerPicker(
    BuildContext context,
    Color mainColor,
    Color goldColor,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                "اختر كتاب التفسير",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getMainColor(context),
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                itemCount: _tafseers.length,
                separatorBuilder: (context, index) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  bool isSelected = index == _selectedTafseerIndex;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedTafseerIndex = index);
                      _loadTafseer();
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(15.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        vertical: 15.h,
                        horizontal: 20.w,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.getMainColor(
                                context,
                              ).withValues(alpha: 0.1)
                            : AppColors.getSurface(
                                context,
                              ).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.getMainColor(context)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.getMainColor(context),
                              size: 20.sp,
                            ),
                          if (isSelected) SizedBox(width: 10.w),
                          Text(
                            _tafseers[index]['name']!,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.getMainColor(context)
                                  : AppColors.getTextColor(context),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 16.sp,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    Surah currentSurah,
    int ayahCount,
    Color mainColor,
    Color goldColor,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          _buildSelectorButton(
            label: "تفسير ${_tafseers[_selectedTafseerIndex]['name']}",
            mainColor: mainColor,
            isDark: isDark,
            onTap: () =>
                _showTafseerPicker(context, mainColor, goldColor, isDark),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildSelectorButton(
                  label: "سورة ${currentSurah.nameAr}",
                  mainColor: mainColor,
                  isDark: isDark,
                  onTap: () =>
                      _showSurahPicker(context, mainColor, goldColor, isDark),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSelectorButton(
                  label: "الآية ${_selectedAyahIndex.toString().toArabic()}",
                  mainColor: mainColor,
                  isDark: isDark,
                  onTap: () => _showAyahPicker(
                    context,
                    ayahCount,
                    mainColor,
                    goldColor,
                    isDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required String label,
    required VoidCallback onTap,
    required Color mainColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : mainColor,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showSurahPicker(
    BuildContext context,
    Color mainColor,
    Color goldColor,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                "اختر السورة",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getMainColor(context),
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: AppBloc.quranCubit.surahs.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (c, i) {
                  final s = AppBloc.quranCubit.surahs[i];
                  bool isSelected = s.index == _selectedSurahIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSurahIndex = s.index;
                        _selectedAyahIndex = 1;
                        _itemKeys.clear();
                      });
                      _scrollController.jumpTo(0);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(15.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.getMainColor(
                                context,
                              ).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.getMainColor(context)
                              : AppColors.getSurface(
                                  context,
                                ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35.w,
                            height: 35.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.getMainColor(context)
                                  : AppColors.getSurface(context),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.index.toString().toArabic(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.getTextColor(context),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Text(
                            s.nameAr,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 20.sp,
                              color: isSelected
                                  ? AppColors.getMainColor(context)
                                  : AppColors.getTextColor(context),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.getMainColor(context),
                              size: 20.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showAyahPicker(
    BuildContext context,
    int count,
    Color mainColor,
    Color goldColor,
    bool isDark,
  ) {
    double itemHeight = 85.h;
    double initialOffset = (_selectedAyahIndex > 3)
        ? (_selectedAyahIndex - 3) * itemHeight
        : 0.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final pickerScrollController = ScrollController(
          initialScrollOffset: initialOffset,
        );
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppColors.getBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  "اختر الآية",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getMainColor(context),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: pickerScrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: count,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (c, i) {
                    final ayahNum = i + 1;
                    final ayah = AppBloc.quranCubit.ayahs.firstWhere(
                      (a) =>
                          a.surahNumber == _selectedSurahIndex &&
                          a.ayahNumber == ayahNum,
                      orElse: () => AppBloc.quranCubit.ayahs.first,
                    );
                    List<String> words = ayah.ayah.trim().split(' ');
                    String shortText = words.take(15).join(' ');
                    if (words.length > 15) shortText += '...';
                    bool isSelected = ayahNum == _selectedAyahIndex;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedAyahIndex = ayahNum);
                        Navigator.pop(ctx);
                        _scrollToAyah(ayahNum);
                      },
                      borderRadius: BorderRadius.circular(15.r),
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.getMainColor(
                                  context,
                                ).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.getMainColor(context)
                                : AppColors.getSurface(
                                    context,
                                  ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 35.w,
                              height: 35.w,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.getMainColor(context)
                                    : AppColors.getSurface(context),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                ayahNum.toString().toArabic(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.getTextColor(context),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              child: Text(
                                shortText,
                                style: TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 16.sp,
                                  color: isSelected
                                      ? AppColors.getMainColor(context)
                                      : AppColors.getTextColor(context),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.getMainColor(context),
                                size: 20.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAyahActions(
    BuildContext context,
    Ayah ayah,
    String tafseerText,
    Color mainColor,
    bool isDark,
  ) {
    return BlocBuilder<BookmarksCubit, List<Bookmark>>(
      builder: (context, bookmarks) {
        final bool isBookmarked = bookmarks.any((b) => b.ayahId == ayah.id);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked
                    ? Colors.amber
                    : mainColor.withValues(alpha: 0.5),
                size: 20.sp,
              ),
              onPressed: () {
                final bookmarksCubit = context.read<BookmarksCubit>();
                if (isBookmarked) {
                  final bookmark = bookmarks.firstWhere(
                    (b) => b.ayahId == ayah.id,
                  );
                  bookmarksCubit.removeBookmark(bookmark.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تمت الإزالة من العلامات المرجعية"),
                    ),
                  );
                } else {
                  final mainBookmark = bookmarks.firstWhere(
                    (b) => b.id == 1,
                    orElse: () => bookmarks.first,
                  );
                  mainBookmark.ayahId = ayah.id;
                  mainBookmark.page = ayah.page;
                  bookmarksCubit.emit(List.from(bookmarksCubit.bookmarks));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تم الحفظ في العلامات المرجعية"),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.copy,
                color: mainColor.withValues(alpha: 0.5),
                size: 18.sp,
              ),
              onPressed: () {
                final textToCopy =
                    "الآية: ${ayah.ayah}\nالتفسير: ${_cleanHtml(tafseerText)}";
                Clipboard.setData(ClipboardData(text: textToCopy));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم نسخ الآية والتفسير")),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.share,
                color: mainColor.withValues(alpha: 0.5),
                size: 18.sp,
              ),
              onPressed: () {
                final textToShare =
                    "﴿${ayah.ayah}﴾\n\nتفسير ${_tafseers[_selectedTafseerIndex]['name']}:\n${_cleanHtml(tafseerText)}";
                Share.share(textToShare);
              },
            ),
          ],
        );
      },
    );
  }
}
