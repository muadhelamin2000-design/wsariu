import 'package:equatable/equatable.dart';

enum AudioRepeatMode { none, ayah, range, infinity }

class AudioState extends Equatable {
  final bool isPlaying;
  final bool isAudioPreparing;
  final int ayahReaderIndex;
  final int surahReaderIndex;
  final int? playingAyahId;
  final int? selectedAyahId;
  final bool isSelectionActive;
  final double playbackSpeed;
  final int selectedSurahIndex;
  final AudioRepeatMode repeatMode;
  final int repeatCount;
  final int remainingRepeats;
  final int? startAyahId;
  final int? endAyahId;
  final double playerTop;
  final double playerLeft;
  final bool isDraggingMode;
  final String? errorMessage;
  final Map<int, double> downloadProgress;
  final Map<int, String> downloadStatus;

  const AudioState({
    this.isPlaying = false,
    this.isAudioPreparing = false,
    this.ayahReaderIndex = 0,
    this.surahReaderIndex = 0,
    this.playingAyahId,
    this.selectedAyahId,
    this.isSelectionActive = false,
    this.playbackSpeed = 1.0,
    this.selectedSurahIndex = 0,
    this.repeatMode = AudioRepeatMode.none,
    this.repeatCount = 1,
    this.remainingRepeats = 0,
    this.startAyahId,
    this.endAyahId,
    this.playerTop = 20.0,
    this.playerLeft = 0.0,
    this.isDraggingMode = false,
    this.errorMessage,
    this.downloadProgress = const {},
    this.downloadStatus = const {},
  });

  AudioState copyWith({
    bool? isPlaying,
    bool? isAudioPreparing,
    int? ayahReaderIndex,
    int? surahReaderIndex,
    int? playingAyahId,
    int? selectedAyahId,
    bool? isSelectionActive,
    double? playbackSpeed,
    int? selectedSurahIndex,
    AudioRepeatMode? repeatMode,
    int? repeatCount,
    int? remainingRepeats,
    int? startAyahId,
    int? endAyahId,
    double? playerTop,
    double? playerLeft,
    bool? isDraggingMode,
    String? errorMessage,
    Map<int, double>? downloadProgress,
    Map<int, String>? downloadStatus,
    bool clearPlayingAyah = false,
    bool clearSelectedAyah = false,
    bool clearRange = false,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isAudioPreparing: isAudioPreparing ?? this.isAudioPreparing,
      ayahReaderIndex: ayahReaderIndex ?? this.ayahReaderIndex,
      surahReaderIndex: surahReaderIndex ?? this.surahReaderIndex,
      playingAyahId: clearPlayingAyah ? null : (playingAyahId ?? this.playingAyahId),
      selectedAyahId: clearSelectedAyah ? null : (selectedAyahId ?? this.selectedAyahId),
      isSelectionActive: isSelectionActive ?? this.isSelectionActive,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      selectedSurahIndex: selectedSurahIndex ?? this.selectedSurahIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatCount: repeatCount ?? this.repeatCount,
      remainingRepeats: remainingRepeats ?? this.remainingRepeats,
      startAyahId: clearRange ? null : (startAyahId ?? this.startAyahId),
      endAyahId: clearRange ? null : (endAyahId ?? this.endAyahId),
      playerTop: playerTop ?? this.playerTop,
      playerLeft: playerLeft ?? this.playerLeft,
      isDraggingMode: isDraggingMode ?? this.isDraggingMode,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadStatus: downloadStatus ?? this.downloadStatus,
    );
  }

  @override
  List<Object?> get props => [
    isPlaying,
    isAudioPreparing,
    ayahReaderIndex,
    surahReaderIndex,
    playingAyahId,
    selectedAyahId,
    isSelectionActive,
    playbackSpeed,
    selectedSurahIndex,
    repeatMode,
    repeatCount,
    remainingRepeats,
    startAyahId,
    endAyahId,
    playerTop,
    playerLeft,
    isDraggingMode,
    errorMessage,
    downloadProgress,
    downloadStatus,
  ];
}
