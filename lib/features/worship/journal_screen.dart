import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models/journal_model.dart';
import 'services/journal_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';

import '../../core/mixins/help_feature_mixin.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with HelpFeatureMixin {
  List<JournalEntry> _notes = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadNotes();
    checkFirstTimeHelp(context, 'journal');
  }

  void _loadNotes() {
    setState(() {
      _notes = JournalService.getAllEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final filtered = _notes.where((n) => 
      n.headline.contains(_searchQuery) || n.content.contains(_searchQuery)
    ).toList().reversed.toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('المذكرات 📝'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح المذكرات', 
            description: 'هذا القسم لتسجيل ذكرياتك وأفكارك الخاصة بطريقة منظمة (تشبه ملاحظات الهاتف):\n'
            '- أضف عنواناً (Headline) لكل مذكرة لتمييزها.\n'
            '- تحكم في حجم ولون الخط والتظليل.\n'
            '- ميز مذكراتك المفضلة لتصل إليها بسرعة.'
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'journal'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث في المذكرات...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد مذكرات مضافة بعد', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildNoteCard(filtered[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditNoteSheet(),
        backgroundColor: const Color(0xFFC8A24A),
        child: const Icon(Icons.edit_note, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildNoteCard(JournalEntry note) {
    final isDark = ThemeService.isDarkMode;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        onTap: () => _showEditNoteSheet(note: note),
        onLongPress: () => _confirmDelete(note),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.headline.isEmpty ? 'بدون عنوان' : note.headline,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),
              Expanded(
                child: Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 13, 
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                    backgroundColor: note.highlightColorValue != null ? Color(note.highlightColorValue!).withOpacity(0.3) : null,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy/MM/dd').format(note.date),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  const Icon(Icons.edit_note, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteSheet({JournalEntry? note}) {
    final isEdit = note != null;
    final headlineController = TextEditingController(text: note?.headline);
    final contentController = TextEditingController(text: note?.content);
    bool isFavorite = note?.isFavorite ?? false;
    double fontSize = note?.fontSize ?? 16.0;
    int selectedColor = note?.colorValue ?? 0xFF000000;
    int? highlightColor = note?.highlightColorValue;
    
    final List<Color> colors = [
      Colors.black, Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange, Colors.brown,
      const Color(0xFF0F3D2E), const Color(0xFFC8A24A),
    ];

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
                  Text(isEdit ? 'تعديل المذكرة' : 'مذكرة جديدة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
                        onPressed: () => setModalState(() => isFavorite = !isFavorite),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (contentController.text.isEmpty && headlineController.text.isEmpty) return;
                          final newNote = JournalEntry(
                            id: note?.id ?? const Uuid().v4(),
                            userId: UserService.currentUser!.id,
                            date: note?.date ?? DateTime.now(),
                            headline: headlineController.text,
                            content: contentController.text,
                            isFavorite: isFavorite,
                            fontSize: fontSize,
                            colorValue: selectedColor,
                            highlightColorValue: highlightColor,
                          );
                          await JournalService.saveEntry(newNote);
                          Navigator.pop(context);
                          _loadNotes();
                        },
                        child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              TextField(
                controller: headlineController,
                decoration: const InputDecoration(hintText: 'العنوان (مثلاً: العائلة)', border: InputBorder.none, hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 12),
              // Toolbar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.format_size), onPressed: () => setModalState(() => fontSize = (fontSize + 2).clamp(12, 32))),
                    IconButton(icon: const Icon(Icons.text_decrease), onPressed: () => setModalState(() => fontSize = (fontSize - 2).clamp(12, 32))),
                    const VerticalDivider(),
                    ...colors.map((c) => GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c.value),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: selectedColor == c.value ? Border.all(color: Colors.grey, width: 2) : null),
                      ),
                    )),
                    const VerticalDivider(),
                    IconButton(
                      icon: const Icon(Icons.format_color_fill),
                      onPressed: () => setModalState(() => highlightColor = highlightColor == null ? Colors.yellow.value : null),
                      color: highlightColor != null ? Color(highlightColor!) : Colors.grey,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(hintText: 'اكتب ذكرياتك هنا...', border: InputBorder.none),
                  style: TextStyle(
                    fontSize: fontSize, 
                    color: Color(selectedColor),
                    backgroundColor: highlightColor != null ? Color(highlightColor!).withOpacity(0.3) : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(JournalEntry note) async {
    final res = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف المذكرة؟',
      message: 'هل أنت متأكد من حذف هذه المذكرة نهائياً؟',
      isDestructive: true,
    );
    if (res == true) {
      await JournalService.deleteEntry(note.id);
      _loadNotes();
    }
  }
}
