import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import 'models/library_models.dart';

class LibraryChoiceScreen extends StatelessWidget {
  const LibraryChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة الشاملة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFFC8A24A)),
            onPressed: () => ModernDialog.showInfo(
              context: context, 
              title: 'المكتبة الشاملة', 
              message: 'هنا تجد كل المواد التعليمية والترفيهية:\n'
              '- المكتبة الصوتية: تحتوي على المحاضرات والتلاوات.\n'
              '- المكتبة المقروءة: تحتوي على الكتب وملفات PDF.\n'
              '- المكتبة المرئية: تحتوي على الدروس المسجلة.'
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildChoiceCard(
              context,
              title: 'المكتبة الصوتية',
              subtitle: 'محاضرات، أذكار، وتلاوات صوتية',
              icon: Icons.audiotrack_rounded,
              color: Colors.blue,
              onTap: () => context.push('/audio-library'),
            ),
            const SizedBox(height: 16),
            _buildChoiceCard(
              context,
              title: 'المكتبة المقروءة',
              subtitle: 'كتب، ملفات PDF، ومقالات',
              icon: Icons.menu_book_rounded,
              color: Colors.green,
              onTap: () => context.push('/library'),
            ),
            const SizedBox(height: 16),
            _buildChoiceCard(
              context,
              title: 'المكتبة المرئية',
              subtitle: 'دروس ومقاطع فيديو تعليمية',
              icon: Icons.video_library_rounded,
              color: Colors.orange,
              onTap: () => context.push('/video-library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
