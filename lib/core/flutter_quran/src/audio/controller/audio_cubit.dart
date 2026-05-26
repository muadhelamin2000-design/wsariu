import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasariu/core/configurations/di.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_bloc.dart';
import '../../models/ayah.dart';
import '../constants/readers_constants.dart';
import 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  final AudioPlayer _audioPlayer = getIt<AudioPlayer>();
  final Dio _dio = Dio();
  final Map<int, CancelToken> _cancelTokens = {};
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sequenceSubscription;
  bool _isProcessing = false;

  AudioCubit() : super(const AudioState());

  AudioPlayer get player => _audioPlayer;

  ReaderInfo get currentAyahReader =>
      ReadersConstants.activeAyahReaders[state.ayahReaderIndex];

  Future<void> init() async {
    await _loadSettings();
    _listenToPlayerState();
  }

  void _listenToPlayerState() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (playerState) {
        if (isClosed) return;

        final currentTag = _audioPlayer.audioSource?.sequence.firstOrNull?.tag;
        final bool isAyah =
            currentTag is MediaItem && currentTag.album == "القرآن الكريم";

        if (isAyah) {
          emit(
            state.copyWith(
              isPlaying: playerState.playing,
              isAudioPreparing:
                  playerState.processingState == ProcessingState.loading ||
                  playerState.processingState == ProcessingState.buffering,
            ),
          );

          if (playerState.processingState == ProcessingState.completed) {
            _handlePlaybackCompleted();
          }
        }
      },
      onError: (e) {
        if (kDebugMode)
          log('Player State Stream Error: $e', name: 'AudioCubit');
        if (!isClosed) {
          emit(state.copyWith(isAudioPreparing: false, isPlaying: false));
        }
      },
    );

    _sequenceSubscription?.cancel();
    _sequenceSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (isClosed || index == null) return;

      final sequence = _audioPlayer.audioSource?.sequence;
      if (sequence != null && index < sequence.length) {
        final tag = sequence[index].tag;
        if (tag is MediaItem) {
          final ayahId = int.tryParse(tag.id);
          if (ayahId != null) {
            final ayah = AppBloc.quranCubit.ayahs.firstWhere(
              (a) => a.id == ayahId,
            );
            emit(
              state.copyWith(
                playingAyahId: ayahId,
                selectedAyahId: ayahId,
                isSelectionActive: true,
              ),
            );
            AppBloc.quranCubit.animateToPage(ayah.page - 1);
          }
        }
      }
    });
  }

  Future<void> _handlePlaybackCompleted() async {
    if (state.repeatMode == AudioRepeatMode.infinity) {
      final currentId = state.selectedAyahId ?? state.playingAyahId;
      if (currentId != null) {
        final currentAyah = AppBloc.quranCubit.ayahs.firstWhere(
          (a) => a.id == currentId,
        );
        await playAyah(currentAyah);
      }
    } else if (state.repeatMode == AudioRepeatMode.ayah) {
      if (state.remainingRepeats > 1) {
        if (!isClosed)
          emit(state.copyWith(remainingRepeats: state.remainingRepeats - 1));
        final currentId = state.selectedAyahId ?? state.playingAyahId;
        if (currentId != null) {
          final currentAyah = AppBloc.quranCubit.ayahs.firstWhere(
            (a) => a.id == currentId,
          );
          await playAyah(currentAyah);
        }
      } else {
        if (!isClosed) emit(state.copyWith(remainingRepeats: 0));
        await skipNext();
      }
    } else if (state.repeatMode == AudioRepeatMode.range) {
      if (state.remainingRepeats > 1) {
        if (!isClosed)
          emit(state.copyWith(remainingRepeats: state.remainingRepeats - 1));
        try {
          await _audioPlayer.seek(Duration.zero, index: 0);
          _audioPlayer.play();
        } catch (_) {}
      } else {
        if (!isClosed)
          emit(
            state.copyWith(
              remainingRepeats: 0,
              repeatMode: AudioRepeatMode.none,
            ),
          );
        await skipNext();
      }
    } else {
      await skipNext();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speed = prefs.getDouble('playbackSpeed') ?? 1.0;
      final repeatIndex = prefs.getInt('repeatMode') ?? 0;
      final playerTop = prefs.getDouble('miniPlayerTop') ?? 20.0;
      final playerLeft = prefs.getDouble('miniPlayerLeft') ?? 0.0;

      try {
        await _audioPlayer.setSpeed(speed);
      } catch (_) {}

      if (!isClosed) {
        emit(
          state.copyWith(
            ayahReaderIndex: prefs.getInt('ayahReaderIndex') ?? 0,
            playbackSpeed: speed,
            repeatMode: AudioRepeatMode.values[repeatIndex],
            repeatCount: prefs.getInt('repeatCount') ?? 1,
            playerTop: playerTop,
            playerLeft: playerLeft,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) log('Error loading settings: $e', name: 'AudioCubit');
    }
  }

  void toggleRepeat() async {
    AudioRepeatMode nextMode;
    switch (state.repeatMode) {
      case AudioRepeatMode.none:
        nextMode = AudioRepeatMode.ayah;
        break;
      case AudioRepeatMode.ayah:
        nextMode = AudioRepeatMode.range;
        break;
      case AudioRepeatMode.range:
        nextMode = AudioRepeatMode.infinity;
        break;
      case AudioRepeatMode.infinity:
        nextMode = AudioRepeatMode.none;
        break;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          repeatMode: nextMode,
          remainingRepeats: state.repeatCount,
        ),
      );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('repeatMode', nextMode.index);
  }

  void setRepeatCount(int count) async {
    if (!isClosed)
      emit(state.copyWith(repeatCount: count, remainingRepeats: count));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('repeatCount', count);
  }

  void setRange(int startId, int endId) {
    if (!isClosed) {
      emit(
        state.copyWith(
          startAyahId: startId,
          endAyahId: endId,
          repeatMode: AudioRepeatMode.range,
          remainingRepeats: state.repeatCount,
        ),
      );
    }
  }

  void setSelectedAyah(int? ayahId) {
    if (!isClosed)
      emit(
        state.copyWith(
          selectedAyahId: ayahId,
          isSelectionActive: ayahId != null,
        ),
      );
  }

  void clearSelection() {
    if (!isClosed)
      emit(
        state.copyWith(
          isSelectionActive: false,
          clearSelectedAyah: true,
          clearRange: true,
        ),
      );
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playbackSpeed', speed);
    if (!isClosed) emit(state.copyWith(playbackSpeed: speed));
  }

  Future<String> _getAudioPath(Ayah ayah, ReaderInfo reader) async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/audio/${reader.index}/${ayah.surahNumber}/${ayah.ayahNumber}.mp3";
  }

  Future<bool> isSurahDownloaded(int surahNumber, ReaderInfo reader) async {
    final surah = AppBloc.quranCubit.surahs.firstWhere(
      (s) => s.index == surahNumber,
    );
    for (var ayah in surah.ayahs) {
      final path = await _getAudioPath(ayah, reader);
      if (!File(path).existsSync()) return false;
    }
    return true;
  }

  Future<void> downloadSurah(int surahNumber, ReaderInfo reader) async {
    bool hasInternet = await _checkInternet();
    if (!hasInternet) {
      if (!isClosed)
        emit(
          state.copyWith(errorMessage: "لا يوجد اتصال بالإنترنت لبدء التحميل"),
        );
      return;
    }

    final surah = AppBloc.quranCubit.surahs.firstWhere(
      (s) => s.index == surahNumber,
    );
    int totalAyahs = surah.ayahs.length;

    if (!isClosed) {
      Map<int, double> newProgress = Map.from(state.downloadProgress);
      Map<int, String> newStatus = Map.from(state.downloadStatus);
      newProgress[reader.index] = 0.0;
      newStatus[reader.index] = "0 / $totalAyahs";
      emit(
        state.copyWith(
          downloadProgress: newProgress,
          downloadStatus: newStatus,
        ),
      );
    }

    int downloadedCount = 0;
    final cancelToken = CancelToken();
    _cancelTokens[reader.index] = cancelToken;

    try {
      for (var ayah in surah.ayahs) {
        if (cancelToken.isCancelled) break;

        final url = _getAyahUrl(ayah, reader);
        final path = await _getAudioPath(ayah, reader);

        final file = File(path);
        if (!file.existsSync()) {
          await file.create(recursive: true);
          await _dio.download(url, path, cancelToken: cancelToken);
        }
        downloadedCount++;

        if (!isClosed) {
          Map<int, double> currentProgress = Map.from(state.downloadProgress);
          Map<int, String> currentStatus = Map.from(state.downloadStatus);
          currentProgress[reader.index] = downloadedCount / totalAyahs;
          currentStatus[reader.index] = "$downloadedCount / $totalAyahs";
          emit(
            state.copyWith(
              downloadProgress: currentProgress,
              downloadStatus: currentStatus,
            ),
          );
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        if (kDebugMode) log("Download cancelled for reader ${reader.index}");
      } else {
        if (kDebugMode) log("Download error for reader ${reader.index}: $e");
        if (!isClosed)
          emit(state.copyWith(errorMessage: "حدث خطأ أثناء التحميل"));
      }
    } finally {
      _cancelTokens.remove(reader.index);
      if (!isClosed) {
        Map<int, double> finalProgress = Map.from(state.downloadProgress);
        Map<int, String> finalStatus = Map.from(state.downloadStatus);
        finalProgress.remove(reader.index);
        finalStatus.remove(reader.index);
        emit(
          state.copyWith(
            downloadProgress: finalProgress,
            downloadStatus: finalStatus,
          ),
        );
      }
    }
  }

  void cancelDownload(int readerIndex) {
    _cancelTokens[readerIndex]?.cancel();
  }

  Future<void> setReader(ReaderInfo reader) async {
    final readerIndex = ReadersConstants.activeAyahReaders.indexOf(reader);
    if (!isClosed) emit(state.copyWith(ayahReaderIndex: readerIndex));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ayahReaderIndex', readerIndex);
  }

  Future<void> playAyah(
    Ayah ayah, {
    ReaderInfo? reader,
    bool autoPlay = true,
  }) async {
    if (_isProcessing) return;

    final targetReader = reader ?? currentAyahReader;

    if (state.repeatMode == AudioRepeatMode.range &&
        state.startAyahId != null &&
        state.endAyahId != null &&
        ayah.id == state.startAyahId) {
      await _playRange(
        state.startAyahId!,
        state.endAyahId!,
        reader: targetReader,
        autoPlay: autoPlay,
      );
      return;
    }

    _isProcessing = true;
    final localPath = await _getAudioPath(ayah, targetReader);
    final bool isDownloaded = File(localPath).existsSync();

    if (!isDownloaded) {
      bool hasInternet = await _checkInternet();
      if (!hasInternet) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isAudioPreparing: false,
              errorMessage: "لا يوجد اتصال بالإنترنت لتشغيل هذه الآية",
            ),
          );
        }
        _isProcessing = false;
        return;
      }
    }

    try {
      final url = isDownloaded ? localPath : _getAyahUrl(ayah, targetReader);
      final readerIndex = reader != null
          ? ReadersConstants.activeAyahReaders.indexOf(reader)
          : state.ayahReaderIndex;

      if (!isClosed) {
        emit(
          state.copyWith(
            isAudioPreparing: true,
            playingAyahId: ayah.id,
            selectedAyahId: ayah.id,
            isSelectionActive: true,
            ayahReaderIndex: readerIndex,
          ),
        );
      }

      AppBloc.quranCubit.animateToPage(ayah.page - 1);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ayahReaderIndex', readerIndex);

      try {
        await _audioPlayer.stop();
      } catch (_) {}

      if (isDownloaded) {
        await _audioPlayer.setAudioSource(
          AudioSource.file(
            localPath,
            tag: MediaItem(
              id: ayah.id.toString(),
              album: "القرآن الكريم",
              title: "سورة ${ayah.surahNameAr} - آية ${ayah.ayahNumber}",
              artist: targetReader.name,
            ),
          ),
        );
      } else {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: MediaItem(
              id: ayah.id.toString(),
              album: "القرآن الكريم",
              title: "سورة ${ayah.surahNameAr} - آية ${ayah.ayahNumber}",
              artist: targetReader.name,
            ),
            headers: {'User-Agent': 'Mozilla/5.0'},
          ),
        );
      }

      if (autoPlay) {
        _audioPlayer.play();
      } else {
        if (!isClosed)
          emit(state.copyWith(isAudioPreparing: false, isPlaying: false));
      }
    } catch (e) {
      if (e is PlayerInterruptedException ||
          e.toString().contains('interrupted') ||
          e.toString().contains('abort')) {
        if (kDebugMode)
          log('Audio load interrupted (expected)', name: 'AudioCubit');
        return;
      }
      if (kDebugMode) log('Error in playAyah: $e', name: 'AudioCubit');
      if (!isClosed)
        emit(state.copyWith(isAudioPreparing: false, isPlaying: false));
    } finally {
      _isProcessing = false;
    }
  }

  String _getAyahUrl(Ayah ayah, ReaderInfo reader) {
    if (reader.readerNamePath.contains('alafasy') &&
        ayah.audio != null &&
        ayah.audio!.isNotEmpty) {
      return ayah.audio!;
    }

    if (reader.url == ReadersConstants.ayahs1stSource) {
      return '${reader.url}${reader.readerNamePath}/${ayah.id}.mp3';
    } else {
      final s = ayah.surahNumber.toString().padLeft(3, '0');
      final a = ayah.ayahNumber.toString().padLeft(3, '0');
      return '${reader.url}${reader.readerNamePath}/$s$a.mp3';
    }
  }

  Future<void> _playRange(
    int startId,
    int endId, {
    ReaderInfo? reader,
    bool autoPlay = true,
  }) async {
    _isProcessing = true;
    final targetReader = reader ?? currentAyahReader;
    final ayahsInRange = AppBloc.quranCubit.ayahs
        .where((a) => a.id >= startId && a.id <= endId)
        .toList();

    if (!isClosed) {
      emit(
        state.copyWith(
          isAudioPreparing: true,
          playingAyahId: startId,
          selectedAyahId: startId,
          isSelectionActive: true,
        ),
      );
    }

    try {
      for (final ayah in ayahsInRange) {
        final path = await _getAudioPath(ayah, targetReader);
        if (!File(path).existsSync()) {
          final url = _getAyahUrl(ayah, targetReader);
          final file = File(path);
          await file.create(recursive: true);
          await _dio.download(url, path);
        }
      }

      final sources = <AudioSource>[];
      for (final ayah in ayahsInRange) {
        final localPath = await _getAudioPath(ayah, targetReader);
        sources.add(
          AudioSource.file(
            localPath,
            tag: MediaItem(
              id: ayah.id.toString(),
              album: "القرآن الكريم",
              title: "سورة ${ayah.surahNameAr} - آية ${ayah.ayahNumber}",
              artist: targetReader.name,
            ),
          ),
        );
      }

      try {
        await _audioPlayer.stop();
      } catch (_) {}

      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: sources),
      );

      if (autoPlay) await _audioPlayer.play();
      if (!isClosed) emit(state.copyWith(isAudioPreparing: false));
    } catch (e) {
      if (e is PlayerInterruptedException ||
          e.toString().contains('interrupted') ||
          e.toString().contains('abort')) {
        if (kDebugMode)
          log('Audio range load interrupted (expected)', name: 'AudioCubit');
        return;
      }
      if (kDebugMode) log('Error in _playRange: $e');
      if (!isClosed)
        emit(
          state.copyWith(
            isAudioPreparing: false,
            errorMessage: "حدث خطأ أثناء تجهيز النطاق",
          ),
        );
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> skipNext() async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
        return;
      }
    } catch (_) {}

    final currentId = state.selectedAyahId ?? state.playingAyahId;
    if (currentId == null) return;

    final currentIndex = AppBloc.quranCubit.ayahs.indexWhere(
      (a) => a.id == currentId,
    );
    if (currentIndex != -1 &&
        currentIndex < AppBloc.quranCubit.ayahs.length - 1) {
      final nextAyah = AppBloc.quranCubit.ayahs[currentIndex + 1];
      await playAyah(nextAyah);
    }
  }

  Future<void> skipPrevious() async {
    try {
      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
        return;
      }
    } catch (_) {}

    final currentId = state.selectedAyahId ?? state.playingAyahId;
    if (currentId == null) return;

    final currentIndex = AppBloc.quranCubit.ayahs.indexWhere(
      (a) => a.id == currentId,
    );
    if (currentIndex > 0) {
      final prevAyah = AppBloc.quranCubit.ayahs[currentIndex - 1];
      await playAyah(prevAyah);
    }
  }

  Future<void> togglePlay() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        if (state.playingAyahId != null) {
          await _audioPlayer.play();
        }
      }
    } catch (_) {}
  }

  void toggleDraggingMode() {
    final newMode = !state.isDraggingMode;
    if (newMode) {
      try {
        _audioPlayer.pause();
      } catch (_) {}
      HapticFeedback.heavyImpact();
    }
    if (!isClosed) emit(state.copyWith(isDraggingMode: newMode));
  }

  void updatePlayerPosition(double top, double left) {
    if (!isClosed) emit(state.copyWith(playerTop: top, playerLeft: left));
  }

  Future<void> savePlayerPosition(double top, double left) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('miniPlayerTop', top);
      await prefs.setDouble('miniPlayerLeft', left);
      if (!isClosed) emit(state.copyWith(isDraggingMode: false));
      try {
        _audioPlayer.play();
      } catch (_) {}
    } catch (e) {
      if (kDebugMode)
        log('Error saving player position: $e', name: 'AudioCubit');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    if (!isClosed) {
      emit(
        state.copyWith(
          isPlaying: false,
          clearPlayingAyah: true,
          clearSelectedAyah: true,
          isSelectionActive: false,
        ),
      );
    }
  }

  void clearError() {
    if (!isClosed) emit(state.copyWith(errorMessage: null));
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _sequenceSubscription?.cancel();
    return super.close();
  }
}
