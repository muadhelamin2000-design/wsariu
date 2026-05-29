import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'models/memo_model.dart';
import 'services/memo_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';
import '../../core/mixins/help_feature_mixin.dart';

class DialoguesScreen extends StatefulWidget {
  const DialoguesScreen({super.key});

  @override
  State<DialoguesScreen> createState() => _DialoguesScreenState();
}

class _DialoguesScreenState extends State<DialoguesScreen> with SingleTickerProviderStateMixin, HelpFeatureMixin {
  List<Memo> _memos = [];
  List<MemoCategory> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = "";
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    checkFirstTimeHelp(context, 'dialogues');
  }

  void _loadData() {
    setState(() {
      _memos = MemoService.getAllMemos();
      _categories = MemoService.getCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final filteredMemos = _memos.where((m) {
      final matchesSearch = m.title.contains(_searchQuery) || m.content.contains(_searchQuery);
      final matchesCategory = _selectedCategoryId == null || m.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(child: const QuickLinkNavigator(currentPageId: 'dialogues')),
          SliverToBoxAdapter(child: _buildCategoryBar(isDark)),
          if (filteredMemos.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('لا توجد مذكرات حالياً', style: TextStyle(color: Colors.grey))))
          else
            _isGridView 
              ? _buildGridView(filteredMemos, isDark)
              : _buildListView(filteredMemos, isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.edit_note, color: Color(0xFFC8A24A)),
        label: const Text('تدوين ذكرى', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('حوارات ومذكرات', style: TextStyle(color: isDark ? Colors.white : AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: Colors.grey),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.grey),
          onPressed: _showSearchDialog,
        ),
        buildHelpButton(
          context, 
          title: 'شرح حوارات ومذكرات', 
          description: 'مساحتك الشخصية للنمو:\n- قسم ذكرياتك حسب التصنيفات.\n- استخدم التثبيت للمهم.\n- استمتع بمحرر نصوص متطور.',
          pageId: 'dialogues',
        ),
      ],
    );
  }

  Widget _buildCategoryBar(bool isDark) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _categoryChip(null, 'الكل', '📑', isDark);
          }
          final cat = _categories[index - 1];
          return _categoryChip(cat.id, cat.name, cat.icon, isDark);
        },
      ),
    );
  }

  Widget _categoryChip(String? id, String name, String icon, bool isDark) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Memo> memos, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _memoCard(memos[index], isDark),
          childCount: memos.length,
        ),
      ),
    );
  }

  Widget _buildListView(List<Memo> memos, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _memoCard(memos[index], isDark, isList: true),
          ),
          childCount: memos.length,
        ),
      ),
    );
  }

  Widget _memoCard(Memo memo, bool isDark, {bool isList = false}) {
    return GestureDetector(
      onTap: () => _openEditor(memo: memo),
      onLongPress: () => _showMemoOptions(memo),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: memo.isPinned ? Border.all(color: AppTheme.accentGold.withOpacity(0.5), width: 2) : null,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                    isDark ? Colors.white.withOpacity(0.01) : Colors.white.withOpacity(0.4),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (memo.isPinned) const Icon(Icons.push_pin, size: 14, color: AppTheme.accentGold),
                      if (memo.isFavorite) const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                      const Spacer(),
                      Text(DateFormat('MM/dd').format(memo.dateModified), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memo.title.isEmpty ? 'بدون عنوان' : memo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      memo.content,
                      maxLines: isList ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54, height: 1.4),
                    ),
                  ),
                  if (memo.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: memo.tags.take(2).map((t) => Text('#$t', style: const TextStyle(fontSize: 9, color: Colors.blue))).toList(),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditor({Memo? memo}) {
    // Navigate to a specialized editor screen (to be created)
    // For now, I will use a placeholder or a dialog
    _showEditorSheet(memo: memo);
  }

  void _showEditorSheet({Memo? memo}) {
    final isEdit = memo != null;
    final titleController = TextEditingController(text: memo?.title);
    final contentController = TextEditingController(text: memo?.content);
    String? categoryId = memo?.categoryId ?? 'cat_general';
    bool isFavorite = memo?.isFavorite ?? false;
    bool isPinned = memo?.isPinned ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: ThemeService.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'تعديل' : 'تدوين ذكرى', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: isPinned ? AppTheme.accentGold : Colors.grey),
                        onPressed: () => setModalState(() => isPinned = !isPinned),
                      ),
                      IconButton(
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : Colors.grey),
                        onPressed: () => setModalState(() => isFavorite = !isFavorite),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (contentController.text.isNotEmpty && UserService.currentUser != null) {
                            final newMemo = Memo(
                              id: memo?.id ?? const Uuid().v4(),
                              userId: UserService.currentUser!.id,
                              title: titleController.text,
                              content: contentController.text,
                              dateCreated: memo?.dateCreated ?? DateTime.now(),
                              dateModified: DateTime.now(),
                              categoryId: categoryId,
                              isFavorite: isFavorite,
                              isPinned: isPinned,
                            );
                            await MemoService.saveMemo(newMemo);
                            _loadData();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              DropdownButton<String>(
                value: categoryId,
                isExpanded: true,
                underline: const SizedBox(),
                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
                onChanged: (val) => setModalState(() => categoryId = val),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'العنوان', border: InputBorder.none, hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(hintText: 'اكتب ذكرياتك وأفكارك هنا...', border: InputBorder.none),
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
              // Toolbar placeholder
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.format_bold), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_italic), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_list_bulleted), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.image_outlined), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.lock_outline), onPressed: () {}),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showMemoOptions(Memo memo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('حذف الذكرى', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final res = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'هل تريد حذف هذه الذكرى نهائياً؟', isDestructive: true);
              if (res == true) {
                await MemoService.deleteMemo(memo.id);
                _loadData();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: Icon(memo.isHidden ? Icons.visibility : Icons.visibility_off),
            title: Text(memo.isHidden ? 'إظهار' : 'إخفاء (تشفير)'),
            onTap: () async {
              await MemoService.saveMemo(memo.copyWith(isHidden: !memo.isHidden));
              _loadData();
              if (mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    ModernDialog.show(
      context: context,
      title: 'بحث وفلترة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(hintText: 'ابحث عن كلمة...', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 20),
          const Text('ترتيب حسب:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(label: const Text('الأحدث'), onPressed: () {}),
              ActionChip(label: const Text('الأبجدية'), onPressed: () {}),
              ActionChip(label: const Text('المفضلة'), onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }
}
