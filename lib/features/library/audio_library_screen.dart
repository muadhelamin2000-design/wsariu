import 'package:flutter/material.dart';
import 'models/library_models.dart';
import 'services/library_service.dart';
import '../../core/services/theme_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../profile/services/user_service.dart';
import 'dart:io';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_audio_player.dart';

class AudioLibraryScreen extends StatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  void _pickAudio() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final newFile = LibraryFile(
          id: const Uuid().v4(),
          userId: UserService.currentUser!.id,
          name: result.files.single.name,
          path: file.path,
          categoryId: 'root',
          addedAt: DateTime.now(),
          type: LibraryType.audio,
        );
        await LibraryService.saveFile(newFile);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الملف الصوتي بنجاح ✅')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في اختيار الملف: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final files = LibraryService.getFiles(type: LibraryType.audio);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الصوتيات 🎧', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'audio-library'),
          Expanded(
            child: files.isEmpty 
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: files.length,
                  itemBuilder: (context, index) => _buildAudioTile(files[index], index, isDark),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAudio,
        backgroundColor: const Color(0xFFC8A24A),
        child: const Text('أضف', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.audiotrack_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('لا يوجد ملفات صوتية بعد', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAudioTile(LibraryFile file, int index, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.play_arrow, color: Colors.white)),
        title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(file.path.split('.').last.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            await LibraryService.deleteFile(file.id);
            setState(() {});
          }
        ),
        onTap: () {
          final allAudios = LibraryService.getFiles(type: LibraryType.audio);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ModernAudioPlayer(
              audioPaths: allAudios.map((f) => f.path).toList(),
              titles: allAudios.map((f) => f.name).toList(),
              fileIds: allAudios.map((f) => f.id).toList(), // Pass file IDs
              initialIndex: index,
            ),
          );
        },
      ),
    );
  }
}
