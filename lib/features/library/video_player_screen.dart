import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<String> filePaths;
  final List<String> titles;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.filePaths,
    required this.titles,
    this.initialIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  int _currentIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializePlayer();
  }

  void _videoListener() {
    if (!mounted || _videoPlayerController == null) return;
    
    final value = _videoPlayerController!.value;
    if (value.isInitialized && 
        value.position >= value.duration && 
        !value.isPlaying) {
      _playNext();
    }
  }

  Future<void> _initializePlayer() async {
    // تنظيف الموارد القديمة
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoListener);
      await _videoPlayerController!.dispose();
    }
    _chewieController?.dispose();

    setState(() {
      _videoPlayerController = null;
      _chewieController = null;
      _errorMessage = null;
    });

    final path = widget.filePaths[_currentIndex];
    final file = File(path);
    
    if (!file.existsSync()) {
      setState(() => _errorMessage = 'الفيديو غير موجود: $path');
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (context, msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.white))),
      );

      // الاستماع لانتهاء الفيديو للتشغيل التلقائي
      _videoPlayerController!.addListener(_videoListener);

      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'خطأ في التشغيل: $e');
    }
  }

  void _playNext() {
    if (_currentIndex < widget.filePaths.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializePlayer();
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titles[_currentIndex], style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (widget.filePaths.length > 1)
              Text('${_currentIndex + 1} من ${widget.filePaths.length}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          if (widget.filePaths.length > 1) ...[
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: _currentIndex > 0 ? _playPrevious : null,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: _currentIndex < widget.filePaths.length - 1 ? _playNext : null,
            ),
          ]
        ],
      ),
      body: Center(
        child: _errorMessage != null
            ? Text(_errorMessage!, style: const TextStyle(color: Colors.white))
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
      ),
    );
  }
}
