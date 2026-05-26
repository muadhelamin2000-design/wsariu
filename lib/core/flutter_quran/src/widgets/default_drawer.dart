import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/bookmarks_controller.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/bookmark.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_constants.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/highlights_list_screen.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_index_bottom_sheet.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_meanings_bottom_sheet.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_signs_screen.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_tafseer_bottom_sheet.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_text_content_screen.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/tajweed_guide_dialog.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/core/utils/font_style.dart';

class DefaultDrawer extends StatelessWidget {
  const DefaultDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: AppColors.getBackground(context),
      width: 0.75.sw,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.r),
          bottomLeft: Radius.circular(25.r),
        ),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionTitle(context, 'أدوات المصحف'),
                _buildDrawerItem(
                  context,
                  icon: Icons.format_list_bulleted_rounded,
                  title: 'فهرس القرآن',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const QuranIndexBottomSheet(),
                    );
                  },
                ),
                BlocBuilder<QuranCubit, List<QuranPage>>(
                  builder: (context, state) {
                    final isTajweed = AppBloc.quranCubit.isTajweedEnabled;
                    return _buildTajweedToggle(context, isTajweed);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.spellcheck_rounded,
                  title: 'علامات الوقف والضبط',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuranSignsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'تغيير لون الصفحة',
                  onTap: () {
                    _showColorPickerDialog(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.auto_awesome_motion_rounded,
                  title: 'التظليلات الملونة',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MultiBlocProvider(
                        providers: AppBloc.providers,
                        child: const HighlightsListScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 30, color: isDark ? Colors.white10 : null),
                _buildSectionTitle(context, 'العلامات المرجعية'),
                BlocBuilder<BookmarksCubit, List<Bookmark>>(
                  builder: (context, bookmarks) {
                    final currentPage = AppBloc.quranCubit.lastPage;
                    return Column(
                      children: [
                        _buildDrawerItem(
                          context,
                          icon: Icons.bookmark_add_outlined,
                          title: 'وضع علامة هنا',
                          onTap: () {
                            if (bookmarks.length == 1) {
                              AppBloc.bookmarksCubit.moveToPage(bookmarks.first.id, currentPage);
                              Fluttertoast.showToast(
                                msg: "تم حفظ العلامة في ص ${currentPage.toString().toArabic()}",
                              );
                              Navigator.pop(context);
                            } else {
                              _showPlaceBookmarkDialog(context, bookmarks, currentPage);
                            }
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.near_me_outlined,
                          title: 'الانتقال للعلامات',
                          onTap: () {
                            final validBookmarks = bookmarks.where((b) => b.page != -1).toList();
                            if (validBookmarks.isEmpty) {
                              Fluttertoast.showToast(msg: "لا توجد علامات محفوظة");
                            } else if (validBookmarks.length == 1) {
                              Navigator.pop(context);
                              AppBloc.quranCubit.animateToPage(validBookmarks.first.page - 1);
                            } else {
                              _showGoToBookmarkDialog(context, validBookmarks);
                            }
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.settings_suggest_outlined,
                          title: 'إدارة العلامات',
                          onTap: () => _showManageBookmarksDialog(context),
                        ),
                      ],
                    );
                  },
                ),
                Divider(height: 30, color: isDark ? Colors.white10 : null),
                _buildSectionTitle(context, 'المحتوى العلمي'),
                _buildDrawerItem(
                  context,
                  icon: Icons.translate_rounded,
                  title: 'معاني الكلمات',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const QuranMeaningsScreen(),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.auto_stories_rounded,
                  title: 'تفسير القرآن الكريم',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const QuranTafseerScreen(),
                    );
                  },
                ),
                Divider(height: 30, color: isDark ? Colors.white10 : null),
                _buildSectionTitle(context, 'إضافات'),
                _buildDrawerItem(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: 'أدعية ختم القرآن',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuranTextContentScreen(
                          title: 'أدعية ختم القرآن',
                          content: QuranConstants.doaaKhatmQuran,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.star_rounded,
                  title: 'فضل قراءة القرآن',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuranTextContentScreen(
                          title: 'فضل قراءة القرآن',
                          content: QuranConstants.fadlQuran,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 60.h, bottom: 20.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : AppColors.getMainColor(context),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.r)),
        image: const DecorationImage(
          image: AssetImage('assets/images/background_image.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'الفهرس والخيارات',
            style: AppFontStyle.fontReemKafi20w600titleColor(context).copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Text(
        title,
        style: AppFontStyle.fontAlmarai12w400mainColor(context).copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.getMainColor(context).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.getMainColor(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.getMainColor(context), size: 22.sp),
        ),
        title: Text(
          title,
          style: AppFontStyle.fontAlmarai14w700Black(context).copyWith(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextColor(context),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildTajweedToggle(BuildContext context, bool isTajweed) {
    final mainColor = AppColors.getMainColor(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: mainColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.info_outline_rounded, color: mainColor, size: 22.sp),
        ),
        title: Text(
          'أحكام التجويد',
          style: AppFontStyle.fontAlmarai14w700Black(context).copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextColor(context),
          ),
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isTajweed,
                onChanged: (val) => AppBloc.quranCubit.toggleTajweed(),
                activeThumbColor: mainColor,
              ),
            ),
            if (isTajweed)
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: mainColor.withValues(alpha: 0.5),
                  size: 20.sp,
                ),
                onPressed: () =>
                    showDialog(context: context, builder: (context) => const TajweedGuideDialog()),
              ),
          ],
        ),
        onTap: () => showDialog(context: context, builder: (context) => const TajweedGuideDialog()),
      ),
    );
  }

  void _showPlaceBookmarkDialog(BuildContext context, List<Bookmark> bookmarks, int page) {
    showDialog(
      context: context,
      builder: (ctx) => MultiBlocProvider(
        providers: AppBloc.providers,
        child: AlertDialog(
          backgroundColor: AppColors.getBackground(context),
          title: Text(
            'أين تريد وضع العلامة؟',
            textAlign: TextAlign.center,
            style: AppFontStyle.fontReemKafi18w700titleColor(
              context,
            ).copyWith(color: AppColors.getTextColor(context)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final b = bookmarks[index];
                return ListTile(
                  leading: Icon(Icons.bookmark_rounded, color: Color(b.colorCode)),
                  title: Text(
                    b.name,
                    style: AppFontStyle.fontAlmarai14w700Black(
                      context,
                    ).copyWith(color: AppColors.getTextColor(context)),
                  ),
                  subtitle: Text(
                    b.page != -1 ? 'حالياً في ص ${b.page.toString().toArabic()}' : 'غير موضوعة بعد',
                    style: TextStyle(color: AppColors.getSubtitleColor(context)),
                  ),
                  onTap: () {
                    AppBloc.bookmarksCubit.moveToPage(b.id, page);
                    Navigator.pop(ctx);
                    Fluttertoast.showToast(msg: "تم نقل \"${b.name}\" إلى هذه الصفحة");
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showGoToBookmarkDialog(BuildContext context, List<Bookmark> validBookmarks) {
    showDialog(
      context: context,
      builder: (ctx) => MultiBlocProvider(
        providers: AppBloc.providers,
        child: AlertDialog(
          backgroundColor: AppColors.getBackground(context),
          title: Text(
            'انتقال إلى',
            textAlign: TextAlign.center,
            style: AppFontStyle.fontReemKafi18w700titleColor(
              context,
            ).copyWith(color: AppColors.getTextColor(context)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: validBookmarks.length,
              itemBuilder: (context, index) {
                final b = validBookmarks[index];
                return ListTile(
                  leading: Icon(Icons.bookmark_rounded, color: Color(b.colorCode)),
                  title: Text(
                    b.name,
                    style: AppFontStyle.fontAlmarai14w700Black(
                      context,
                    ).copyWith(color: AppColors.getTextColor(context)),
                  ),
                  subtitle: Text(
                    'صفحة ${b.page.toString().toArabic()}',
                    style: TextStyle(color: AppColors.getSubtitleColor(context)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    AppBloc.quranCubit.animateToPage(b.page - 1);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showManageBookmarksDialog(BuildContext context) {
    final TextEditingController newNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => MultiBlocProvider(
        providers: AppBloc.providers,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 0.85.sw,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.getBackground(context),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<BookmarksCubit, List<Bookmark>>(
                  builder: (context, bookmarks) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final b = bookmarks[index];
                        return _BookmarkEditTile(bookmark: b);
                      },
                    );
                  },
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: AppColors.getTextColor(context), size: 24.sp),
                      onPressed: () {
                        if (newNameController.text.isNotEmpty) {
                          AppBloc.bookmarksCubit.addNamedBookmark(newNameController.text);
                          newNameController.clear();
                        }
                      },
                    ),
                    Expanded(
                      child: Container(
                        height: 42.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.getSubtitleColor(context).withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: TextField(
                          controller: newNameController,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: AppColors.getTextColor(context)),
                          decoration: InputDecoration(
                            hintText: 'إضافة علامة ...',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.getSubtitleColor(context),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [
      const Color(0xFFFFF9E7),
      const Color(0xFFF1E4D0),
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFF5F5F5),
      const Color(0xFFFFFFFF),
      const Color(0xFF263238),
      const Color(0xFF1A1A1A),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getBackground(context),
        title: Text(
          'اختر لون الصفحة',
          textAlign: TextAlign.center,
          style: AppFontStyle.fontReemKafi18w700titleColor(
            context,
          ).copyWith(color: AppColors.getTextColor(context)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: BlocBuilder<QuranCubit, List<QuranPage>>(
            bloc: AppBloc.quranCubit,
            builder: (context, state) {
              final selectedColor =
                  AppBloc.quranCubit.pageColor ?? (isDark ? Colors.black : const Color(0xFFFFF9E7));

              return GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected = selectedColor.value == color.value;

                  return InkWell(
                    onTap: () {
                      AppBloc.quranCubit.setPageColor(color);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.getMainColor(context)
                              : (isDark ? Colors.white24 : Colors.black12),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                                  ? Colors.white
                                  : AppColors.getMainColor(context),
                              size: 20.sp,
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BookmarkEditTile extends StatefulWidget {
  final Bookmark bookmark;

  const _BookmarkEditTile({required this.bookmark});

  @override
  State<_BookmarkEditTile> createState() => _BookmarkEditTileState();
}

class _BookmarkEditTileState extends State<_BookmarkEditTile> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.bookmark.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.getSubtitleColor(context).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: IconButton(
          icon: Icon(
            _isEditing ? Icons.check : Icons.edit_outlined,
            size: 20.sp,
            color: _isEditing ? Colors.green : AppColors.getSubtitleColor(context),
          ),
          onPressed: () {
            if (_isEditing) {
              if (_controller.text.isNotEmpty) {
                AppBloc.bookmarksCubit.updateBookmarkName(widget.bookmark.id, _controller.text);
              }
              setState(() => _isEditing = false);
            } else {
              setState(() => _isEditing = true);
            }
          },
        ),
        title: Center(
          child: _isEditing
              ? TextField(
                  controller: _controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.getTextColor(context)),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                )
              : Text(
                  widget.bookmark.name,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        trailing: widget.bookmark.id == 1
            ? Icon(Icons.bookmark_rounded, color: AppColors.getTextColor(context), size: 24.sp)
            : IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 22.sp,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                onPressed: () => AppBloc.bookmarksCubit.removeBookmark(widget.bookmark.id),
              ),
      ),
    );
  }
}
