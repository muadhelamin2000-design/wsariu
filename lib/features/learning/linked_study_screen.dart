import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/knowledge_section_model.dart';
import 'services/knowledge_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/widgets/page_info.dart';

class LinkedStudyScreen extends StatefulWidget {
  const LinkedStudyScreen({super.key});

  @override
  State<LinkedStudyScreen> createState() => _LinkedStudyScreenState();
}

class _LinkedStudyScreenState extends State<LinkedStudyScreen> with HelpFeatureMixin {
  List<KnowledgeSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSections();
    checkFirstTimeHelp(context, 'linked_study');
  }

  void _loadSections() {
    setState(() {
      _sections = KnowledgeService.getSections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المذاكرة المترابطة'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح المذاكرة المترابطة', 
            description: 'هذا القسم يساعدك على ربط المعلومات:\n'
            '- أضف مدخلات معرفية (صور، نصوص، ملاحظات).\n'
            '- اربط المدخلات ببعضها لترى العلاقات بين المواضيع.\n'
            '- استعرض المعرفة كشبكة مترابطة (قريباً).'
          ),
          TextButton(
            onPressed: _showAddSectionDialog,
            child: const Text('إضافة قسم', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'linked'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PageInfo(
              title: 'التطوير والدراسة المترابطة',
              description: 'قم بتنظيم رحلتك التعليمية من خلال تقسيم المواد إلى أقسام، تتبع إنجازك في كل وحدة، وربط أهدافك بالمواد الدراسية.',
              icon: Icons.school,
            ),
          ),
          Expanded(
            child: _sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('لا توجد أقسام مذاكرة بعد'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showAddSectionDialog,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                          child: const Text('إضافة أول قسم', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const Icon(Icons.folder_open, color: Colors.blueGrey),
                          title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SectionEntriesScreen(section: section),
                              ),
                            );
                          },
                          onLongPress: () => _confirmDeleteSection(section),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSectionDialog,
        backgroundColor: Colors.blueGrey,
        label: const Text('إضافة قسم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showAddSectionDialog() async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إضافة قسم جديد',
      hint: 'اسم القسم (مثلاً: علوم القرآن)',
    );
    
    if (result != null && result.isNotEmpty && UserService.currentUser != null) {
      final section = KnowledgeSection(
        id: const Uuid().v4(),
        userId: UserService.currentUser!.id,
        name: result,
      );
      await KnowledgeService.saveSection(section);
      _loadSections();
    }
  }

  void _confirmDeleteSection(KnowledgeSection section) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف القسم؟',
      message: 'هل أنت متأكد من حذف قسم "${section.name}" وجميع عناصره؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await KnowledgeService.deleteSection(section.id);
      _loadSections();
    }
  }
}

class SectionEntriesScreen extends StatefulWidget {
  final KnowledgeSection section;
  const SectionEntriesScreen({super.key, required this.section});

  @override
  State<SectionEntriesScreen> createState() => _SectionEntriesScreenState();
}

class _SectionEntriesScreenState extends State<SectionEntriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final ImagePicker _picker = ImagePicker();

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final entries = _searchQuery.isEmpty 
        ? KnowledgeService.getEntriesBySection(widget.section.id)
        : KnowledgeService.searchEntries(_searchQuery).where((e) => e.sectionId == widget.section.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.name),
        actions: [
          TextButton(
            onPressed: () => _showAddEntryDialog(context),
            child: const Text('إضافة عنصر', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ابحث في هذا القسم...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: entries.isEmpty
          ? const Center(child: Text('لا توجد عناصر في هذا القسم بعد.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entry.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _showEntryDetails(context, entry),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: Colors.blueGrey,
        label: const Text('إضافة عنصر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(path)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, {KnowledgeEntry? entryToEdit}) {
    final isEdit = entryToEdit != null;
    final titleController = TextEditingController(text: entryToEdit?.title);
    final contentController = TextEditingController(text: entryToEdit?.content);
    final tagsController = TextEditingController(text: entryToEdit?.tags.join(', '));
    final linkController = TextEditingController(text: entryToEdit?.mediaLink);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String? imagePath = entryToEdit?.imagePath;
    String? videoPath = entryToEdit?.videoPath;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل العنصر' : 'إضافة عنصر جديد',
      accentColor: Colors.blueGrey,
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'العنوان', 
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController, 
                maxLines: 3, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'المحتوى', 
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'الوسوم (مفصولة بفاصلة)', 
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'رابط (صورة، فيديو، مقال...)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 12),
                  suffixIcon: IconButton(icon: const Icon(Icons.clear, color: Colors.red, size: 18), onPressed: () => linkController.clear()),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMediaAction(Icons.image, imagePath != null, () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setModalState(() => imagePath = image.path);
                  }, () => setModalState(() => imagePath = null), 'صورة'),
                  _buildMediaAction(Icons.videocam, videoPath != null, () async {
                    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                    if (video != null) setModalState(() => videoPath = video.path);
                  }, () => setModalState(() => videoPath = null), 'فيديو'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          onPressed: () async {
            if (titleController.text.isNotEmpty && UserService.currentUser != null) {
              final entry = KnowledgeEntry(
                id: entryToEdit?.id ?? const Uuid().v4(),
                userId: UserService.currentUser!.id,
                sectionId: widget.section.id,
                title: titleController.text,
                content: contentController.text,
                tags: tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                imagePath: imagePath,
                videoPath: videoPath,
                mediaLink: linkController.text,
                createdAt: entryToEdit?.createdAt ?? DateTime.now(),
                linkedEntryIds: entryToEdit?.linkedEntryIds ?? [],
              );
              await KnowledgeService.saveEntry(entry);
              if (mounted) {
                Navigator.pop(context);
                _refresh();
              }
            }
          },
          child: const Text('حفظ العنصر'),
        ),
      ],
    );
  }

  Widget _buildMediaAction(IconData icon, bool hasValue, VoidCallback onPick, VoidCallback onClear, String label) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: onPick,
          icon: Icon(icon, color: hasValue ? Colors.green : Colors.grey, size: 20),
          label: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        if (hasValue)
          GestureDetector(
            onTap: onClear,
            child: const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 10)),
          ),
      ],
    );
  }

  void _showEntryDetails(BuildContext context, KnowledgeEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) {
            final current = KnowledgeService.getEntryById(entry.id) ?? entry;
            final linked = current.linkedEntryIds.map((id) => KnowledgeService.getEntryById(id)).whereType<KnowledgeEntry>().toList();

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(current.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showAddEntryDialog(context, entryToEdit: current)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                             await KnowledgeService.deleteEntry(current.id);
                             Navigator.pop(context);
                             _refresh();
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('المحتوى:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(current.content.isEmpty ? 'لا يوجد وصف.' : current.content),
                  if (current.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: current.tags.map((t) => Chip(label: Text('#$t', style: const TextStyle(fontSize: 12)))).toList()),
                  ],
                  if (current.imagePath != null || current.videoPath != null || current.mediaLink != null) ...[
                    const SizedBox(height: 16),
                    const Text('الوسائط المرفقة:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (current.imagePath != null)
                          GestureDetector(
                            onTap: () => _showImagePreview(context, current.imagePath!),
                            child: Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: FileImage(File(current.imagePath!)), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        if (current.videoPath != null)
                          IconButton(
                            icon: const Icon(Icons.video_library, color: Colors.blue),
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فيديو محلي مرفق'))),
                          ),
                        if (current.mediaLink != null && current.mediaLink!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.link, color: Colors.orange),
                            onPressed: () async {
                              final url = Uri.parse(current.mediaLink!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('العناصر المرتبطة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.link), onPressed: () => _showLinkDialog(context, current, () => setModalState(() {}))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (linked.isEmpty)
                    const Text('لا توجد روابط.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: linked.map((ln) => InputChip(
                        label: Text(ln.title),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEntryDetails(context, ln);
                        },
                        onDeleted: () async {
                          await KnowledgeService.unlinkEntries(current.id, ln.id);
                          setModalState(() {});
                        },
                      )).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLinkDialog(BuildContext context, KnowledgeEntry current, VoidCallback onUpdate) {
    final all = KnowledgeService.getAllEntries().where((e) => e.id != current.id && !current.linkedEntryIds.contains(e.id)).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ربط عنصر'),
        content: SizedBox(
          width: double.maxFinite,
          child: all.isEmpty ? const Text('لا توجد عناصر متاحة للربط.') : ListView.builder(
            shrinkWrap: true,
            itemCount: all.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(all[i].title),
              subtitle: Text(all[i].content, maxLines: 1),
              onTap: () async {
                await KnowledgeService.linkEntries(current.id, all[i].id);
                Navigator.pop(context);
                onUpdate();
                _refresh();
              },
            ),
          ),
        ),
      ),
    );
  }
}
