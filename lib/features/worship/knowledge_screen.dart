import 'package:flutter/material.dart';
import 'models/knowledge_model.dart';
import 'services/knowledge_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';

import '../../core/mixins/help_feature_mixin.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> with SingleTickerProviderStateMixin, HelpFeatureMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkFirstTimeHelp(context, 'knowledge');
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('knowledge');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: Text('حُجَّة لي')),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح حُجَّة لي', 
            description: 'هذا القسم لبناء وعيك وثقافتك:\n'
            '- تابع القنوات والمواقع المفيدة في مكان واحد.\n'
            '- اربط المعارف ببعضها لتعميق فهمك.\n'
            '- العلم حجة لك أو عليك، فاجعله حجة لك بطلبه والعمل به.',
            pageId: 'knowledge',
          ),
          TextButton(
            onPressed: () => _showAddEntryDialog(KnowledgeType.values[_tabController.index]),
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ابحث في النصوص والفوائد...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accentGold,
                labelColor: AppTheme.primaryGreen,
                tabs: const [
                  Tab(text: 'قرآن'),
                  Tab(text: 'سنة'),
                  Tab(text: 'كتب شرعية'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'knowledge'),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(KnowledgeType.quran),
                _buildList(KnowledgeType.hadith),
                _buildList(KnowledgeType.book),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(KnowledgeType.values[_tabController.index]),
        backgroundColor: AppTheme.primaryGreen,
        label: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildList(KnowledgeType type) {
    final entries = _searchQuery.isEmpty 
        ? KnowledgeService.getEntries(type)
        : KnowledgeService.searchEntries(_searchQuery).where((e) => e.type == type).toList();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا يوجد فوائد مسجلة بعد', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildEntryCard(entries[index]),
    );
  }

  Widget _buildEntryCard(KnowledgeEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconForType(entry.type), size: 16, color: AppTheme.accentGold),
                const SizedBox(width: 8),
                Text(
                  _getSourceLabel(entry),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                ),
                const Spacer(),
                Text(
                  _formatDate(entry.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _confirmDelete(entry),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.contentText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
            ),
            const Divider(height: 24),
            const Text('الفوائد المستنبطة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            ...entry.benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  Expanded(child: Text(benefit, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: entry.tags.map((tag) => Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.blue))).toList(),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _showAddBenefitOnlyDialog(entry),
                child: const Text('أضف فائدة جديدة', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.quran: return Icons.menu_book;
      case KnowledgeType.hadith: return Icons.auto_stories;
      case KnowledgeType.book: return Icons.book;
    }
  }

  String _getSourceLabel(KnowledgeEntry entry) {
    if (entry.type == KnowledgeType.quran) {
      return "${entry.sourceName ?? 'سورة'} - آية ${entry.detail ?? ''}";
    }
    return entry.sourceName ?? '';
  }

  String _formatDate(DateTime date) => "${date.year}/${date.month}/${date.day}";

  void _showAddEntryDialog(KnowledgeType type) {
    final contentController = TextEditingController();
    final sourceController = TextEditingController();
    final detailController = TextEditingController();
    final benefitController = TextEditingController();
    final tagsController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<String> benefitsList = [];

    ModernDialog.show(
      context: context,
      title: _getDialogTitle(type),
      accentColor: AppTheme.accentGold,
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: _getContentLabel(type), 
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sourceController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: _getSourceFieldLabel(type), 
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                      ),
                    ),
                  ),
                  if (type == KnowledgeType.quran) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: detailController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'رقم الآية', 
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              Text('أضف الفوائد', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              ...benefitsList.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(b, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                  trailing: IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: () => setModalState(() => benefitsList.remove(b))),
                  visualDensity: VisualDensity.compact,
                ),
              )),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: benefitController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'اكتب فائدة...', 
                        isDense: true,
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                    onPressed: () {
                      if (benefitController.text.isNotEmpty) {
                        setModalState(() {
                          benefitsList.add(benefitController.text);
                          benefitController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'الوسوم (Tag1, Tag2...)', 
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
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
            if (contentController.text.isNotEmpty && benefitsList.isNotEmpty) {
              final entry = KnowledgeEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: UserService.currentUser!.id,
                type: type,
                contentText: contentController.text,
                sourceName: sourceController.text,
                detail: detailController.text,
                benefits: benefitsList,
                tags: tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                createdAt: DateTime.now(),
              );
              await KnowledgeService.saveEntry(entry);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            }
          },
          child: const Text('حفظ في مكتبي'),
        ),
      ],
    );
  }

  void _showAddBenefitOnlyDialog(KnowledgeEntry entry) async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إضافة فائدة جديدة',
      hint: 'اكتب الفائدة هنا...',
    );
    if (result != null && result.isNotEmpty) {
      final updated = entry.copyWith(benefits: [...entry.benefits, result]);
      await KnowledgeService.saveEntry(updated);
      if (mounted) setState(() {});
    }
  }

  void _confirmDelete(KnowledgeEntry entry) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف الفائدة؟',
      message: 'هل أنت متأكد من حذف هذا السجل من مكتبتك؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await KnowledgeService.deleteEntry(entry.id);
      if (mounted) setState(() {});
    }
  }

  String _getDialogTitle(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.quran: return 'تسجيل فائدة قرآنية';
      case KnowledgeType.hadith: return 'تسجيل فائدة نبوية';
      case KnowledgeType.book: return 'تسجيل فائدة من كتاب';
    }
  }

  String _getContentLabel(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.quran: return 'نص الآية الكريمة';
      case KnowledgeType.hadith: return 'نص الحديث الشريف';
      case KnowledgeType.book: return 'نص الفكرة أو الاقتباس';
    }
  }

  String _getSourceFieldLabel(KnowledgeType type) {
    switch (type) {
      case KnowledgeType.quran: return 'اسم السورة';
      case KnowledgeType.hadith: return 'المصدر / الراوي';
      case KnowledgeType.book: return 'اسم الكتاب';
    }
  }
}
