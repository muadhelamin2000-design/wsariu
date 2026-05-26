import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/audio/audio.dart';
import 'package:wasariu/core/flutter_quran/src/controllers/quran_controller.dart';
import 'package:wasariu/core/flutter_quran/src/models/bookmark.dart';
import 'package:wasariu/core/flutter_quran/src/models/highlight.dart';
import 'package:wasariu/core/flutter_quran/src/models/quran_page.dart';
import 'package:wasariu/core/flutter_quran/src/utils/flutter_quran_utils.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/ayah_actions_bottom_sheet.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/ayah_bottom_sheet.dart';

class QuranLine extends StatelessWidget {
  final Line line;
  final List<int> bookmarksAyahs;
  final List<Bookmark> bookmarks;
  final BoxFit boxFit;
  final Function? onLongPress;

  const QuranLine(
    this.line,
    this.bookmarksAyahs,
    this.bookmarks, {
    super.key,
    this.boxFit = BoxFit.fill,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final style = FlutterQuran().getHafsStyle(context);
    final quranCubit = context.read<QuranCubit>();

    return FittedBox(
      fit: boxFit,
      child: RichText(
        text: TextSpan(
          children: line.ayahs.reversed.map((ayah) {
            return WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  if (quranCubit.isAyahHidden(ayah.id)) {
                    quranCubit.toggleAyahVisibility(ayah.id);
                    return;
                  }

                  final audioCubit = context.read<AudioCubit>();
                  audioCubit.setSelectedAyah(ayah.id);

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => MultiBlocProvider(
                      providers: AppBloc.providers,
                      child: AyahAudioBottomSheet(ayah: ayah),
                    ),
                  ).then((_) {
                    audioCubit.clearSelection();
                  });
                },
                onLongPress: () {
                  if (onLongPress != null) {
                    onLongPress!(ayah);
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => MultiBlocProvider(
                        providers: AppBloc.providers,
                        child: AyahActionsBottomSheet(ayah: ayah),
                      ),
                    );
                  }
                },
                child: BlocBuilder<AudioCubit, AudioState>(
                  buildWhen: (previous, current) =>
                      previous.selectedAyahId == ayah.id ||
                      current.selectedAyahId == ayah.id ||
                      previous.isSelectionActive != current.isSelectionActive,
                  builder: (context, state) {
                    final bool isSelected =
                        state.isSelectionActive && state.selectedAyahId == ayah.id;

                    return BlocBuilder<QuranCubit, List<QuranPage>>(
                      builder: (context, pages) {
                        final bool isHidden = quranCubit.isAyahHidden(ayah.id);
                        final bool isHighlighted = quranCubit.highlightedAyahId == ayah.id;
                        final bool isTajweedEnabled = AppBloc.quranCubit.isTajweedEnabled;
                        final ayahHighlights = quranCubit.getAyahHighlights(ayah.id);

                        final wholeAyahHighlight = ayahHighlights.cast<Highlight?>().firstWhere(
                          (h) => h != null && h.start == null && h.wordIndices == null,
                          orElse: () => null,
                        );

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: isHighlighted
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                                : isHidden
                                ? Colors.grey.withValues(alpha: 0.2)
                                : isSelected
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                                : wholeAyahHighlight != null
                                ? Color(wholeAyahHighlight.colorCode).withValues(alpha: 0.5)
                                : bookmarksAyahs.contains(ayah.id)
                                ? Color(
                                    bookmarks[bookmarksAyahs.indexOf(ayah.id)].colorCode,
                                  ).withValues(alpha: 0.7)
                                : null,
                          ),
                          child: Opacity(
                            opacity: isHidden ? 0.0 : 1.0,
                            child: RichText(
                              text: FlutterQuran().getTajweedColoredText(
                                ayah,
                                style,
                                showTajweed: isTajweedEnabled,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
