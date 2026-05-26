import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/default_drawer.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_app_bar.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_auto_scroll_pill.dart';
import 'package:wasariu/core/flutter_quran/src/widgets/quran_page_view.dart';
import 'package:wasariu/gen/assets.gen.dart';

class FlutterQuranScreen extends StatefulWidget {
  final bool showBottomWidget;
  final bool useDefaultAppBar;
  final Widget? bottomWidget;
  final PreferredSizeWidget? appBar;
  final Function(int)? onPageChanged;
  final int? initialSurah;
  final int? initialPage;
  final bool isSinglePageMode;
  final List<int>? pageRange;

  const FlutterQuranScreen({
    this.showBottomWidget = true,
    this.useDefaultAppBar = true,
    this.bottomWidget,
    this.appBar,
    this.onPageChanged,
    this.initialSurah,
    this.initialPage,
    this.isSinglePageMode = false,
    this.pageRange,
    super.key,
  });

  @override
  State<FlutterQuranScreen> createState() => _FlutterQuranScreenState();
}

class _FlutterQuranScreenState extends State<FlutterQuranScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppBloc.quranCubit.state.isEmpty) {
        AppBloc.quranCubit.loadQuran();
      }
    });
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        await _handlePop(didPop);
      },
      child: MultiBlocProvider(
        providers: AppBloc.providers,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            key: scaffoldKey,
            drawer: const DefaultDrawer(),
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                Positioned.fill(child: Assets.images.backgroundImage.image(fit: BoxFit.cover)),
                Positioned.fill(
                  child: Container(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Column(
                  children: [
                    QuranAppBar(scaffoldKey: scaffoldKey),
                    Expanded(
                      child: QuranPageView(
                        initialSurah: widget.initialSurah,
                        initialPage: widget.initialPage,
                        showBottomWidget: widget.showBottomWidget,
                        bottomWidget: widget.bottomWidget,
                        isSinglePageMode: widget.isSinglePageMode,
                        pageRange: widget.pageRange,
                        onPageChanged: (page) {
                          if (widget.onPageChanged != null) {
                            widget.onPageChanged!(page);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (!widget.isSinglePageMode) const QuranAutoScrollPill(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
