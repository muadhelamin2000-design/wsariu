import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class ModernAudioPlayer extends StatefulWidget {
  final List<String> audioPaths;
  final List<String> titles;
  final int initialIndex;

  const ModernAudioPlayer({
    super.key,
    required this.audioPaths,
    required this.titles,
    this.initialIndex = 0,
  });

  @override
  State<ModernAudioPlayer> createState() => _ModernAudioPlayerState();
}

class _ModernAudioPlayerState extends State<ModernAudioPlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final List<AudioSource> sources = [];
      for (int i = 0; i < widget.audioPaths.length; i++) {
        final path = widget.audioPaths[i];
        final title = widget.titles[i];
        
        final mediaItem = MediaItem(
          id: path,
          album: "المكتبة الصوتية",
          title: title,
          artist: "وَسَارِعُواُ",
        );

        if (path.startsWith('http')) {
          sources.add(AudioSource.uri(Uri.parse(path), tag: mediaItem));
        } else {
          final file = File(path);
          if (await file.exists()) {
            sources.add(AudioSource.uri(Uri.file(path), tag: mediaItem));
          } else {
            debugPrint("Audio file not found at: $path");
          }
        }
      }

      if (sources.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر العثور على الملفات الصوتية ⚠️')),
          );
        }
        return;
      }

      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist, initialIndex: widget.initialIndex < sources.length ? widget.initialIndex : 0);
      _player.play(); // تشغيل تلقائي عند الفتح
      
      _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      
      _player.playerStateStream.listen((state) {
        if (mounted) setState(() => _isPlaying = state.playing);
        // Automatic next is handled by ConcatenatingAudioSource
      });

      _player.currentIndexStream.listen((idx) {
        if (mounted && idx != null) {
          setState(() => _currentIndex = idx);
        }
      });
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Icon(Icons.music_note, size: 48, color: Color(0xFFC8A24A)),
          const SizedBox(height: 16),
          Text(
            widget.titles[_currentIndex],
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "ملف ${_currentIndex + 1} من ${widget.titles.length}",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
            max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
            activeColor: const Color(0xFFC8A24A),
            onChanged: (val) {
              _player.seek(Duration(milliseconds: val.toInt()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _player.hasPrevious ? () => _player.seekToPrevious() : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () => _player.seek(_position - const Duration(seconds: 10)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (_isPlaying) {
                    _player.pause();
                  } else {
                    _player.play();
                  }
                },
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF0F3D2E),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () => _player.seek(_position + const Duration(seconds: 10)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _player.hasNext ? () => _player.seekToNext() : null,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
