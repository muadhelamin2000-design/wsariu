import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/quick_link_service.dart';
import '../services/page_management_service.dart';
import '../services/theme_service.dart';

class QuickLinkNavigator extends StatefulWidget {
  final String currentPageId;

  const QuickLinkNavigator({
    super.key,
    required this.currentPageId,
  });

  @override
  State<QuickLinkNavigator> createState() => _QuickLinkNavigatorState();
}

class _QuickLinkNavigatorState extends State<QuickLinkNavigator> {
  late List<String> _linkedPageIds;
  late List<PageItem> _allPages;

  @override
  void initState() {
    super.initState();
    _refreshLinks();
    _allPages = PageManagementService.getAllPages();
  }

  void _refreshLinks() {
    setState(() {
      _linkedPageIds = QuickLinkService.getLinksForPage(widget.currentPageId);
    });
  }

  void _showAddLinkDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('إضافة رابط سريع متبادل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('اختر الصفحة التي تريد ربطها بهذه الصفحة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allPages.length,
                    itemBuilder: (context, index) {
                      final page = _allPages[index];
                      if (page.id == widget.currentPageId) return const SizedBox.shrink();
                      
                      final isLinked = _linkedPageIds.contains(page.id);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(page.colorValue).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(page.iconData, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(page.name)),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showEditPageDialog(page),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          isLinked ? Icons.link_off : Icons.link,
                          color: isLinked ? Colors.red : Colors.green,
                        ),
                        onTap: () async {
                          if (isLinked) {
                            await QuickLinkService.unlinkPages(widget.currentPageId, page.id);
                          } else {
                            await QuickLinkService.linkPages(widget.currentPageId, page.id);
                          }
                          _refreshLinks();
                          setModalState(() {});
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPageDialog(PageItem page) {
    final nameController = TextEditingController(text: page.name);
    final iconController = TextEditingController(text: page.iconData);
    int selectedColor = page.colorValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الصفحة'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصفحة'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'أيقونة (إيموجي)',
                    hintText: 'ضع إيموجي من لوحة المفاتيح',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('اختر اللون:', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: PageItem.availableColors.map((color) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(color),
                      child: selectedColor == color ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              page.name = nameController.text;
              page.iconData = iconController.text;
              page.colorValue = selectedColor;
              await PageManagementService.savePage(page);
              Navigator.pop(context);
              setState(() {
                _allPages = PageManagementService.getAllPages();
              });
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_linkedPageIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextButton.icon(
          onPressed: _showAddLinkDialog,
          icon: const Icon(Icons.link, size: 16),
          label: const Text('إضافة روابط سريعة', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _linkedPageIds.length,
              itemBuilder: (context, index) {
                final pageId = _linkedPageIds[index];
                final page = _allPages.firstWhere((p) => p.id == pageId, orElse: () => PageItem(id: '', name: 'مفقود', route: '', iconData: '❓', sectionKey: ''));
                if (page.id.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ActionChip(
                    onPressed: () => context.go(page.route),
                    avatar: Text(page.iconData, style: const TextStyle(fontSize: 16)),
                    label: Text(page.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Color(page.colorValue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
            onPressed: _showAddLinkDialog,
          ),
        ],
      ),
    );
  }
}
