import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasariu/core/configurations/di.dart';
import 'package:wasariu/features/quran/presentation/manager/hifz_cubit.dart';

import 'audio/audio.dart';
import 'controllers/bookmarks_controller.dart';
import 'controllers/quran_controller.dart';

class AppBloc {
  static final quranCubit = QuranCubit();
  static final bookmarksCubit = BookmarksCubit();
  static final audioCubit = AudioCubit();
  static final hifzCubit = getIt<HifzCubit>();

  static final List<BlocProvider> providers = [
    BlocProvider<QuranCubit>.value(value: quranCubit),
    BlocProvider<BookmarksCubit>.value(value: bookmarksCubit),
    BlocProvider<AudioCubit>.value(value: audioCubit),
    BlocProvider<HifzCubit>.value(value: hifzCubit),
  ];

  static void init() {
    audioCubit.init();
  }

  static void dispose() {
    quranCubit.close();
    bookmarksCubit.close();
    audioCubit.close();
  }

  static final AppBloc _instance = AppBloc._internal();

  factory AppBloc() {
    return _instance;
  }

  AppBloc._internal();
}
