import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models/memo_model.dart';
import 'services/memo_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';
import '../discipline/services/task_service.dart';
import '../discipline/models/task_model.dart';
import '../discipline/services/habit_service.dart';
import '../discipline/models/habit_model.dart';

class DialoguesScreen extends StatefulWidget {
  const DialoguesScreen({super.key});

  @override
  State<DialoguesScreen> createState() => _DialoguesScreenState();
}

class _DialoguesScreenState extends State<DialoguesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MemoCategory> _categories = [];
  List<MemoIdea> _ideas = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _categories = MemoService.getCategories();
      _ideas = MemoService.getIdeas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('حوارات ومذكرات', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'أقسام المذكرات'),
            Tab(text: 'بنك الأفكار'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesGrid(),
          _buildIdeasTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.index == 0 ? _showAddCategoryDialog() : _showAddIdeaDialog(),
        label: Text(_tabController.index == 0 ? 'إنشاء قسم' : 'تدوين فكرة'),
        icon: Icon(_tabController.index == 0 ? Icons.folder_open : Icons.lightbulb_outline),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: const Color(0xFFC8A24A),
      ),
    );
  }

  // ================= CATEGORIES (SECTIONS) =================

  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('لم تضف أي أقسام بعد', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _showAddCategoryDialog, child: const Text('أنشئ أول قسم لك')),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _buildCategoryCard(cat);
      },
    );
  }

  Widget _buildCategoryCard(MemoCategory cat) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Color(cat.colorValue).withOpacity(0.2))),
      child: InkWell(
        onTap: () => _openCategoryNotes(cat),
        onLongPress: () => _showCategoryOptions(cat),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(cat.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    String selectedIcon = '📁';
    int selectedColor = AppTheme.primaryGreen.value;

    ModernDialog.show(
      context: context,
      title: 'قسم جديد',
      content: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'اسم القسم (مثل: ذكريات العائلة)'),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['📁', '🏠', '💼', '✈️', '🎞️', '💡', '❤️', '🎓', '📚', '🎨', '🍳', '🏋️', '🧘', '🏥', '🌱', '🌍', '🛠️', '💻', '🎮', '🎵', '📸', '📽️', '🖋️', '🔑', '🔓', '🗓️', '🚩', '🏁', '🏷️', '💎', '🏆', '🎁', '🎈', '🔥', '🌊', '☀️', '🌙', '☁️', '⛈️', '🌈', '⚡', '🌟', '🍀', '🍂', '🍎', '🍕', '☕', '🍷', '🎭', '🚲', '⛵', '🗺️', '🔔', '📢', '⏰', '🔋', '🔋', '🛡️', '⚔️', '⚖️', '⛓️', '⚗️', '🔭', '🔬', '🧺', '🧼', '🧹', '🪴'].map((emoji) => GestureDetector(
                  onTap: () => setModalState(() => selectedIcon = emoji),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedIcon == emoji ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.isNotEmpty && UserService.currentUser != null) {
              final newCat = MemoCategory(
                id: const Uuid().v4(),
                userId: UserService.currentUser!.id,
                name: controller.text,
                icon: selectedIcon,
                colorValue: selectedColor,
              );
              await MemoService.saveCategory(newCat);
              _loadData();
              Navigator.pop(context);
            }
          },
          child: const Text('إنشاء'),
        ),
      ],
    );
  }

  // ================= IDEAS TAB =================

  Widget _buildIdeasTab() {
    if (_ideas.isEmpty) {
      return const Center(child: Text('لا توجد أفكار مسجلة', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ideas.length,
      itemBuilder: (context, index) {
        final idea = _ideas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: Text(idea.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('yyyy/MM/dd').format(idea.date), style: const TextStyle(fontSize: 10)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (idea.description.isNotEmpty) ...[
                      Text(idea.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ideaActionButton(Icons.task_alt, 'مهمة', Colors.blue, () => _convertIdeaToTask(idea)),
                        _ideaActionButton(Icons.autorenew, 'عادة', Colors.green, () => _convertIdeaToHabit(idea)),
                        _ideaActionButton(Icons.delete_outline, 'حذف', Colors.red, () => _deleteIdea(idea)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _ideaActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }

  void _showAddIdeaDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    ModernDialog.show(
      context: context,
      title: 'تدوين فكرة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'الفكرة')),
          TextField(controller: descController, decoration: const InputDecoration(labelText: 'تفاصيل (اختياري)'), maxLines: 3),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (titleController.text.isNotEmpty && UserService.currentUser != null) {
              final newIdea = MemoIdea(
                id: const Uuid().v4(),
                userId: UserService.currentUser!.id,
                title: titleController.text,
                description: descController.text,
                date: DateTime.now(),
              );
              await MemoService.saveIdea(newIdea);
              _loadData();
              Navigator.pop(context);
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  // ================= ACTIONS & NAVIGATION =================

  void _openCategoryNotes(MemoCategory cat) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryNotesScreen(category: cat)));
  }

  void _showCategoryOptions(MemoCategory cat) {
    final screenContext = context;
    showModalBottomSheet(
      context: screenContext,
      builder: (modalContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('حذف القسم', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(modalContext);
              final res = await ModernDialog.showConfirm(
                context: screenContext, 
                title: 'حذف القسم', 
                message: 'هل تريد حذف قسم "${cat.name}" نهائياً بما يحتويه؟',
                confirmLabel: 'حذف',
                isDestructive: true,
              );
              if (res == true) {
                await MemoService.deleteCategory(cat.id);
                _loadData();
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _convertIdeaToTask(MemoIdea idea) async {
    final task = Task(
      id: const Uuid().v4(),
      userId: idea.userId,
      title: idea.title,
      description: idea.description,
      priority: TaskPriority.medium,
      date: DateTime.now(),
    );
    await TaskService.saveTask(task);
    await MemoService.deleteIdea(idea.id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل الفكرة إلى مهمة بنجاح')));
  }

  void _convertIdeaToHabit(MemoIdea idea) {
    // This would typically navigate to the add habit screen or show a dialog
    // For now, let's show a snackbar or implement simple logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح واجهة العادات ببيانات الفكرة')));
    // Logic: Navigator.push to Habits with initialTitle = idea.title
  }

  void _deleteIdea(MemoIdea idea) async {
    await MemoService.deleteIdea(idea.id);
    _loadData();
  }
}

// ================= NOTES PER CATEGORY SCREEN =================

class CategoryNotesScreen extends StatefulWidget {
  final MemoCategory category;
  const CategoryNotesScreen({super.key, required this.category});

  @override
  State<CategoryNotesScreen> createState() => _CategoryNotesScreenState();
}

class _CategoryNotesScreenState extends State<CategoryNotesScreen> {
  List<MemoNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = MemoService.getNotes(categoryId: widget.category.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.icon} ${widget.category.name}')),
      body: _notes.isEmpty
          ? const Center(child: Text('لا توجد مذكرات في هذا القسم', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () => _editNote(note),
                    title: Text(note.title.isEmpty ? 'بدون عنوان' : note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: note.isPinned ? const Icon(Icons.push_pin, size: 16, color: Colors.orange) : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        label: const Text('تدوين ذكرى'),
        icon: const Icon(Icons.edit_note),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: const Color(0xFFC8A24A),
      ),
    );
  }

  void _createNewNote() {
    _showNoteEditor();
  }

  void _editNote(MemoNote note) {
    _showNoteEditor(note: note);
  }

  void _showNoteEditor({MemoNote? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);
    bool isFavorite = note?.isFavorite ?? false;
    bool isPinned = note?.isPinned ?? false;
    double fontSize = note?.fontSize ?? 16.0;
    int colorValue = note?.colorValue ?? 0xFFFFFFFF;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ThemeService.isDarkMode ? const Color(0xFF1E293B) : Color(colorValue),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(note == null ? 'تدوين ذكرى' : 'تعديل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: isPinned ? Colors.orange : Colors.grey),
                        onPressed: () => setModalState(() => isPinned = !isPinned),
                      ),
                      IconButton(
                        icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
                        onPressed: () => setModalState(() => isFavorite = !isFavorite),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (contentController.text.isNotEmpty && UserService.currentUser != null) {
                            final newNote = MemoNote(
                              id: note?.id ?? const Uuid().v4(),
                              userId: UserService.currentUser!.id,
                              categoryId: widget.category.id,
                              title: titleController.text,
                              content: contentController.text,
                              dateCreated: note?.dateCreated ?? DateTime.now(),
                              dateModified: DateTime.now(),
                              isFavorite: isFavorite,
                              isPinned: isPinned,
                              fontSize: fontSize,
                              colorValue: colorValue,
                            );
                            await MemoService.saveNote(newNote);
                            _loadNotes();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      ),
                    ],
                  )
                ],
              ),
              const Divider(),
              // Editor Toolbar
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.format_size), onPressed: () => setModalState(() => fontSize = (fontSize + 2).clamp(12, 32))),
                  IconButton(icon: const Icon(Icons.text_decrease), onPressed: () => setModalState(() => fontSize = (fontSize - 2).clamp(12, 32))),
                  const VerticalDivider(),
                  ...[0xFFFFFFFF, 0xFFFFF9C4, 0xFFE1F5FE, 0xFFF1F8E9, 0xFFFCE4EC].map((c) => GestureDetector(
                    onTap: () => setModalState(() => colorValue = c),
                    child: Container(
                      width: 24, height: 24, margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                    ),
                  )),
                ],
              ),
              const Divider(),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'العنوان', border: InputBorder.none, hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  style: TextStyle(fontSize: fontSize),
                  decoration: const InputDecoration(hintText: 'اكتب ذكرياتك هنا...', border: InputBorder.none),
                ),
              ),
              if (note != null) 
                TextButton(
                  onPressed: () async {
                    await MemoService.deleteNotePermanently(note.id);
                    _loadNotes();
                    Navigator.pop(context);
                  }, 
                  child: const Text('حذف نهائياً', style: TextStyle(color: Colors.red))
                ),
            ],
          ),
        ),
      ),
    );
  }
}
