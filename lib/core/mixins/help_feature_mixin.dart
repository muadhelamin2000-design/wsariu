import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/modern_dialog.dart';
import '../services/page_management_service.dart';

mixin HelpFeatureMixin<T extends StatefulWidget> on State<T> {
  static const String helpBoxName = 'help_settings_box';

  void showHelp(BuildContext context, {required String title, required String description}) {
    ModernDialog.showInfo(
      context: context,
      title: title,
      message: description,
    );
  }

  /// يظهر تنبيه صغير إذا كانت هذه أول مرة يدخل فيها المستخدم للصفحة
  void checkFirstTimeHelp(BuildContext context, String pageId) async {
    final box = await Hive.openBox(helpBoxName);
    final hasSeen = box.get('seen_help_$pageId', defaultValue: false);
    
    if (!hasSeen) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('اضغط على علامة الاستفهام (؟) في الأعلى لمعرفة مميزات هذه الصفحة'),
            backgroundColor: const Color(0xFFC8A24A),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'حسناً',
              textColor: Colors.white,
              onPressed: () => box.put('seen_help_$pageId', true),
            ),
          ),
        );
      });
      await box.put('seen_help_$pageId', true);
    }
  }

  Widget buildHelpButton(BuildContext context, {required String title, required String description, String? pageId}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pageId != null)
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Color(0xFFC8A24A)),
            onPressed: () => _showPageColorPicker(context, pageId),
            tooltip: 'لون الصفحة',
          ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Color(0xFFC8A24A)),
          onPressed: () => showHelp(context, title: title, description: description),
          tooltip: 'شرح الصفحة',
        ),
      ],
    );
  }

  void _showPageColorPicker(BuildContext context, String pageId) {
    ModernDialog.show(
      context: context,
      title: 'لون خلفية الصفحة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PageItem.availableColors.map((colorValue) => GestureDetector(
              onTap: () async {
                final pages = PageManagementService.getAllPages();
                final page = pages.firstWhere((p) => p.id == pageId, orElse: () => PageItem(id: pageId, name: '', route: '', iconData: '', sectionKey: ''));
                page.backgroundColorValue = colorValue;
                await PageManagementService.savePage(page);
                Navigator.pop(context);
                if (mounted) setState(() {});
              },
              child: CircleAvatar(backgroundColor: Color(colorValue), radius: 18),
            )).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final pages = PageManagementService.getAllPages();
              final page = pages.firstWhere((p) => p.id == pageId, orElse: () => PageItem(id: pageId, name: '', route: '', iconData: '', sectionKey: ''));
              page.backgroundColorValue = null;
              await PageManagementService.savePage(page);
              Navigator.pop(context);
              if (mounted) setState(() {});
            },
            child: const Text('إعادة للوضع التلقائي'),
          ),
        ],
      ),
    );
  }

  Color? getPageBackgroundColor(String pageId) {
     try {
       final page = PageManagementService.getAllPages().firstWhere((p) => p.id == pageId);
       return page.backgroundColorValue != null ? Color(page.backgroundColorValue!) : null;
     } catch(_) { return null; }
  }
}
