import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/services/page_management_service.dart';
import '../core/widgets/modern_dialog.dart';
import 'dashboard/services/navigation_service.dart';

import '../core/services/security_service.dart';

class SectionScreen extends StatefulWidget {
  final String title;
  final String sectionKey;

  const SectionScreen({
    super.key,
    required this.title,
    required this.sectionKey,
  });

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  late List<PageItem> _items;
  String _displayTitle = "";

  @override
  void initState() {
    super.initState();
    _displayTitle = widget.title;
    _loadItems();
    _syncTitle();
  }

  void _syncTitle() {
    final sections = PageManagementService.getSections();
    final current = sections.where((s) => s.key == widget.sectionKey);
    if (current.isNotEmpty) {
      setState(() => _displayTitle = current.first.name);
    }
  }

  void _loadItems() {
    setState(() {
      _items = PageManagementService.getPagesForSection(widget.sectionKey);
    });
  }

  void _showPageSettings(PageItem item) {
    ModernDialog.show(
      context: context,
      title: 'إعدادات الصفحة: ${item.name}',
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined, color: Colors.blue),
                title: const Text('تغيير الأيقونة (إيموجي)'),
                onTap: () async {
                  final newEmoji = await ModernDialog.showInput(
                    context: context, 
                    title: 'تغيير الأيقونة', 
                    hint: 'أدخل إيموجي من لوحة المفاتيح', 
                    initialValue: item.iconData
                  );
                  if (newEmoji != null && newEmoji.isNotEmpty) {
                    setState(() => item.iconData = newEmoji);
                    await PageManagementService.savePage(item);
                    _loadItems();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('تعديل الاسم'),
                onTap: () async {
                  final newName = await ModernDialog.showInput(context: context, title: 'تعديل الاسم', hint: 'الاسم الجديد', initialValue: item.name);
                  if (newName != null && newName.isNotEmpty) {
                    setState(() => item.name = newName);
                    await PageManagementService.savePage(item);
                    _loadItems();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.move_up, color: Colors.orange),
                title: const Text('نقل إلى قسم آخر'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveDialog(item);
                },
              ),
              const Divider(),
              const Text('لون خلفية الصفحة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: PageItem.availableColors.length,
                  itemBuilder: (context, index) {
                    final color = Color(PageItem.availableColors[index]);
                    return GestureDetector(
                      onTap: () async {
                        setModalState(() => item.backgroundColorValue = color.value);
                        await PageManagementService.savePage(item);
                        _loadItems();
                      },
                      child: Container(
                        width: 30,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: item.backgroundColorValue == color.value ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () async {
                 setModalState(() => item.backgroundColorValue = null);
                 await PageManagementService.savePage(item);
                 _loadItems();
              }, child: const Text('إعادة لون النظام التلقائي', style: TextStyle(fontSize: 11))),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف من هذا القسم', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await PageManagementService.deletePage(item.id);
                  _loadItems();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveDialog(PageItem item) {
    final sections = PageManagementService.getSections();

    ModernDialog.show(
      context: context,
      title: 'نقل إلى قسم',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: sections.map((s) => ListTile(
          title: Text('${s.icon} ${s.name}'),
          onTap: () async {
            item.sectionKey = s.key;
            await PageManagementService.savePage(item);
            Navigator.pop(context);
            _loadItems();
          },
        )).toList(),
      ),
    );
  }

  void _showEditSectionDialog() async {
    final sections = PageManagementService.getSections();
    final section = sections.firstWhere((s) => s.key == widget.sectionKey, orElse: () => SectionItem(key: '', name: '', icon: ''));
    if (section.key.isEmpty) return;

    final nameController = TextEditingController(text: section.name);
    final iconController = TextEditingController(text: section.icon);

    ModernDialog.show(
      context: context,
      title: 'تعديل القسم',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم القسم')),
          const SizedBox(height: 12),
          TextField(controller: iconController, decoration: const InputDecoration(labelText: 'الأيقونة (إيموجي)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              section.name = nameController.text;
              section.icon = iconController.text;
              await PageManagementService.saveSection(section);
              
              // مزامنة التغييرات فوراً مع شريط التنقل السفلي
              await NavigationService.syncTabsWithSections();

              if (mounted) {
                Navigator.pop(context);
                setState(() => _displayTitle = section.name);
                // إجبار الواجهة الرئيسية على التحديث إذا كانت مفتوحة في الخلفية
                try {
                  Hive.box('navigation_settings_box').put('last_sync', DateTime.now().millisecondsSinceEpoch);
                } catch (e) {}
              }
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _displayTitle, 
                style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
              onPressed: _showEditSectionDialog,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.language_outlined),
          onPressed: () => context.push('/browser'),
          tooltip: 'المتصفح الآمن',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/'),
            tooltip: 'الرئيسية',
          ),
        ],
      ),
      body: _items.isEmpty 
          ? const Center(child: Text('لا توجد صفحات في هذا القسم', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(item.colorValue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(item.iconData, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
                        onPressed: () => _showPageSettings(item),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                  onTap: () async {
                    if (mounted) context.push(item.route);
                  },
                ),
              ),
            );
          },
        ),
    );
  }
}
