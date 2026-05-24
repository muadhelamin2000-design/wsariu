import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../profile/services/user_service.dart';
import 'models/knowledge_model.dart';
import 'services/node_service.dart';

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedCategoryId;

  List<Category> _categories = [];
  List<Node> _nodes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _categories = CategoryService.getCategories();
    _nodes = NodeService.getNodes();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخطط المعرفي الشامل'),
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
                    hintText: 'ابحث في كل ما سجلته من معلومات...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accentGold,
                tabs: const [
                  Tab(text: 'إدارة الأقسام'),
                  Tab(text: 'بطاقات المعرفة'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesList(),
          _buildNodesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 ? _showAddCategoryDialog() : _showAddNodeDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriesList() {
    final filtered = _categories.where((c) => c.name.contains(_searchQuery)).toList();
    if (filtered.isEmpty && _searchQuery.isEmpty) {
      return const Center(child: Text('ابدأ بإضافة أول تخصص أو قسم تدرسه (مثلاً: جراحة، فقه، فضاء)'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final cat = filtered[index];
        final nodeCount = _nodes.where((n) => n.categoryIds.contains(cat.id)).length;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder_copy_outlined, color: AppTheme.primaryGreen),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$nodeCount معلومة مسجلة'),
            onTap: () {
              setState(() => _selectedCategoryId = cat.id);
              _tabController.animateTo(1);
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteCategory(cat),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodesList() {
    var filtered = _nodes.where((n) {
      final matchesSearch = n.contentText.contains(_searchQuery) || (n.sourceName?.contains(_searchQuery) ?? false);
      final matchesCat = _selectedCategoryId == null || n.categoryIds.contains(_selectedCategoryId);
      return matchesSearch && matchesCat;
    }).toList();

    return Column(
      children: [
        if (_selectedCategoryId != null)
          Container(
            color: AppTheme.accentGold.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('تصفية: ${_categories.firstWhere((c) => c.id == _selectedCategoryId).name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(onPressed: () => setState(() => _selectedCategoryId = null), child: const Text('إلغاء')),
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty 
            ? const Center(child: Text('لا توجد بطاقات هنا، أضف معلومة جديدة واربطها بتخصصك'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildNodeCard(filtered[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildNodeCard(Node node) {
    final linkedNodes = node.linkedNodeIds.map((id) => _nodes.firstWhereOrNull((n) => n.id == id)).whereType<Node>().toList();
    final catNames = node.categoryIds.map((id) => _categories.firstWhereOrNull((c) => c.id == id)?.name).whereType<String>().toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(node.contentText, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(catNames.isEmpty ? 'غير مصنف' : 'التخصصات: ${catNames.join(' | ')}', 
          style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (node.sourceName != null && node.sourceName!.isNotEmpty)
                  Text('المرجع: ${node.sourceName}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const Divider(),
                const Text('الفوائد والملاحظات:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ...node.benefits.map((b) => Text('• $b')),
                const SizedBox(height: 12),
                if (node.mediaLinks.isNotEmpty) ...[
                  const Text('روابط ووسائط (فيديو/صور/مقالات):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ...node.mediaLinks.map((link) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.tryParse(link);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('لا يمكن فتح هذا الرابط')),
                            );
                          }
                        }
                      }, 
                      child: Text(link, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13)),
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                const Text('ارتباطات ذكية (Knowledge Graph):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Wrap(
                  spacing: 8,
                  children: linkedNodes.map((ln) => ActionChip(
                    label: Text(ln.contentText),
                    onPressed: () {
                      setState(() {
                        _searchController.text = ln.contentText;
                        _searchQuery = ln.contentText;
                        _selectedCategoryId = null; // Reset category filter to find the linked node
                      });
                    }, 
                    avatar: const Icon(Icons.link, size: 14),
                  )).toList(),
                ),
                if (linkedNodes.isEmpty) const Text('لا توجد ارتباطات بعد', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.add_link, color: Colors.blue), onPressed: () => _showLinkNodesDialog(node)),
                    IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _showAddNodeDialog(nodeToEdit: node)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteNode(node)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قسم دراسي جديد'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'اسم التخصص (مثلاً: أدوية، فقه، برمجة)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final cat = Category.create(name: controller.text, userId: UserService.currentUser!.id);
                await CategoryService.saveCategory(cat);
                _loadData();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showAddNodeDialog({Node? nodeToEdit}) {
    final contentController = TextEditingController(text: nodeToEdit?.contentText);
    final sourceController = TextEditingController(text: nodeToEdit?.sourceName);
    final benefitController = TextEditingController();
    final mediaController = TextEditingController();
    List<String> benefits = List.from(nodeToEdit?.benefits ?? []);
    List<String> mediaLinks = List.from(nodeToEdit?.mediaLinks ?? []);
    List<String> selectedCatIds = List.from(nodeToEdit?.categoryIds ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nodeToEdit == null ? 'إضافة كارت معرفة جديد' : 'تعديل الكارت', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: 'المفهوم / المعلومة الأساسية', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: sourceController, decoration: const InputDecoration(labelText: 'المرجع أو المصدر', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('ربط بأقسام الدراسة'),
                  children: _categories.map((c) => CheckboxListTile(
                    title: Text(c.name),
                    value: selectedCatIds.contains(c.id),
                    onChanged: (val) => setModalState(() => val! ? selectedCatIds.add(c.id) : selectedCatIds.remove(c.id)),
                  )).toList(),
                ),
                const Divider(),
                const Text('الفوائد المستنبطة', style: TextStyle(fontWeight: FontWeight.bold)),
                ...benefits.map((b) => ListTile(title: Text(b, fontSize: 13), trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setModalState(() => benefits.remove(b))))),
                Row(children: [
                  Expanded(child: TextField(controller: benefitController, decoration: const InputDecoration(hintText: 'اكتب فائدة...'))),
                  IconButton(icon: const Icon(Icons.add_circle), onPressed: () {
                    if (benefitController.text.isNotEmpty) setModalState(() { benefits.add(benefitController.text); benefitController.clear(); });
                  })
                ]),
                const Divider(),
                const Text('روابط الوسائط (يوتيوب، صور، مقالات)', style: TextStyle(fontWeight: FontWeight.bold)),
                ...mediaLinks.map((m) => ListTile(title: Text(m, fontSize: 12), trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setModalState(() => mediaLinks.remove(m))))),
                Row(children: [
                  Expanded(child: TextField(controller: mediaController, decoration: const InputDecoration(hintText: 'أضف رابط URL...'))),
                  IconButton(icon: const Icon(Icons.add_link), onPressed: () {
                    if (mediaController.text.isNotEmpty) setModalState(() { mediaLinks.add(mediaController.text); mediaController.clear(); });
                  })
                ]),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () async {
                    if (contentController.text.isNotEmpty) {
                      final node = Node(
                        id: nodeToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: UserService.currentUser!.id,
                        categoryIds: selectedCatIds,
                        contentText: contentController.text,
                        sourceName: sourceController.text,
                        benefits: benefits,
                        mediaLinks: mediaLinks,
                        createdAt: nodeToEdit?.createdAt ?? DateTime.now(),
                        linkedNodeIds: nodeToEdit?.linkedNodeIds ?? [],
                      );
                      await NodeService.saveNode(node);
                      _loadData();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('حفظ في الذاكرة المترابطة', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLinkNodesDialog(Node sourceNode) {
    List<Node> available = _nodes.where((n) => n.id != sourceNode.id && !sourceNode.linkedNodeIds.contains(n.id)).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر كارت لربطه بهذا الكارت'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(available[index].contentText),
              subtitle: Text('في: ${available[index].categoryIds.map((id) => _categories.firstWhereOrNull((c) => c.id == id)?.name).whereType<String>().join(', ')}'),
              onTap: () async {
                await NodeService.linkNodes(sourceNode.id, available[index].id);
                _loadData();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCategory(Category c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القسم؟'),
        content: Text('هل أنت متأكد من حذف قسم "${c.name}"؟ ستبقى البطاقات موجودة ولكن غير منتمية لهذا القسم.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () async {
            await CategoryService.deleteCategory(c.id);
            _loadData();
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _confirmDeleteNode(Node n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكارت؟'),
        content: const Text('هل أنت متأكد من حذف هذه المعلومة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await NodeService.deleteNode(n.id);
              _loadData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
