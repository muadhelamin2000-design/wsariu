import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'models/library_models.dart';
import 'services/library_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import 'package:intl/intl.dart';
import 'video_player_screen.dart';
import '../../core/widgets/modern_audio_player.dart';
import '../../core/widgets/quick_link_navigator.dart';

class LibraryScreen extends StatefulWidget {
  final LibraryType libraryType;
  const LibraryScreen({super.key, this.libraryType = LibraryType.pdf});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _currentCategoryId;
  List<LibraryCategory> _categories = [];
  List<LibraryFile> _files = [];
  List<LibraryCategory> _breadcrumb = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _categories = LibraryService.getCategories(parentId: _currentCategoryId, type: widget.libraryType);
      _files = LibraryService.getFiles(categoryId: _currentCategoryId ?? 'root', type: widget.libraryType);
    });
  }

  void _navigateToCategory(LibraryCategory? category) {
    setState(() {
      if (category == null) {
        _currentCategoryId = null;
        _breadcrumb = [];
      } else {
        _currentCategoryId = category.id;
        if (!_breadcrumb.any((c) => c.id == category.id)) {
          _breadcrumb.add(category);
        } else {
          int index = _breadcrumb.indexWhere((c) => c.id == category.id);
          _breadcrumb = _breadcrumb.sublist(0, index + 1);
        }
      }
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = 'المكتبة';
    if (widget.libraryType == LibraryType.pdf) title = 'المكتبة الرقمية';
    else if (widget.libraryType == LibraryType.video) title = 'مكتبة المرئيات';
    else if (widget.libraryType == LibraryType.audio) title = 'الصوتيات';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => GoRouter.of(context).go('/'),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: widget.libraryType == LibraryType.pdf ? 'library' : 'video-library'),
          _buildSearchBar(),
          _buildBreadcrumb(),
          Expanded(
            child: _files.isEmpty && _categories.isEmpty && _searchQuery.isEmpty
                ? _buildEmptyState()
                : _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        backgroundColor: AppTheme.primaryGreen,
        label: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            if (val.isNotEmpty) {
              _files = LibraryService.searchFiles(val, type: widget.libraryType);
              _categories = [];
            } else {
              _loadData();
            }
          });
        },
        decoration: InputDecoration(
          hintText: widget.libraryType == LibraryType.pdf ? 'ابحث في الكتب والملفات...' : (widget.libraryType == LibraryType.video ? 'ابحث في الفيديوهات...' : 'ابحث في الصوتيات...'),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    String rootName = 'المكتبة';
    if (widget.libraryType == LibraryType.video) rootName = 'المرئيات';
    else if (widget.libraryType == LibraryType.audio) rootName = 'الصوتيات';

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ActionChip(
            onPressed: () => _navigateToCategory(null),
            label: Text(rootName),
            avatar: const Icon(Icons.home_outlined, size: 16),
          ),
          ..._breadcrumb.map((cat) => Row(
            children: [
              const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
              ActionChip(
                onPressed: () => _navigateToCategory(cat),
                label: Text(cat.name),
                avatar: Text(cat.emoji, style: const TextStyle(fontSize: 12)),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon = Icons.library_books_outlined;
    if (widget.libraryType == LibraryType.video) icon = Icons.video_library_outlined;
    else if (widget.libraryType == LibraryType.audio) icon = Icons.audiotrack_outlined;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('لا توجد ملفات في هذا القسم'),
          TextButton(onPressed: _showAddMenu, child: const Text('إضافة عنصر جديد')),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ReorderableListView(
      padding: const EdgeInsets.all(16),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        
        // We have categories first, then files.
        if (oldIndex < _categories.length && newIndex < _categories.length) {
          final item = _categories.removeAt(oldIndex);
          _categories.insert(newIndex, item);
          await LibraryService.saveCategoriesOrder(_categories);
        } else if (oldIndex >= _categories.length && newIndex >= _categories.length) {
          int fileOldIdx = oldIndex - _categories.length;
          int fileNewIdx = newIndex - _categories.length;
          final item = _files.removeAt(fileOldIdx);
          _files.insert(fileNewIdx, item);
          await LibraryService.saveFilesOrder(_files);
        }
        _loadData();
      },
      children: [
        ..._categories.asMap().entries.map((e) => _buildCategoryTile(e.value, e.key)).toList(),
        ..._files.asMap().entries.map((e) => _buildFileTile(e.value, _categories.length + e.key)).toList(),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length + _files.length,
      itemBuilder: (context, index) {
        if (index < _categories.length) {
          return _buildCategoryGridItem(_categories[index]);
        } else {
          return _buildFileGridItem(_files[index - _categories.length]);
        }
      },
    );
  }

  Widget _buildCategoryTile(LibraryCategory cat, int index) {
    double progress = LibraryService.getCategoryProgress(cat.id, widget.libraryType);
    return ReorderableDelayedDragStartListener(
      key: ValueKey(cat.id),
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('قسم - ${(progress * 100).toInt()}% مكتمل', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
                onPressed: () => _showCategoryOptions(cat),
              ),
              onTap: () => _navigateToCategory(cat),
            ),
            if (progress > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(LibraryFile file, int index) {
    bool isVideo = file.type == LibraryType.video;
    bool isAudio = file.type == LibraryType.audio;
    double progress = file.progressPercentage;

    IconData fileIcon = Icons.picture_as_pdf;
    Color iconColor = Colors.red;
    if (isVideo) {
      fileIcon = Icons.play_circle_outline;
      iconColor = Colors.blue;
    } else if (isAudio) {
      fileIcon = Icons.audiotrack_outlined;
      iconColor = Colors.orange;
    }

    return ReorderableDelayedDragStartListener(
      key: ValueKey(file.id),
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: file.isCompleted,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) async {
                      await LibraryService.toggleCompletion(file.id);
                      _loadData();
                      if (val == true && mounted) {
                        String action = "قراءة الكتاب";
                        if (isVideo) action = "مشاهدة الفيديو";
                        if (isAudio) action = "الاستماع للملف";
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('أحسنت! أتممت $action: ${file.name}')),
                        );
                      }
                    },
                  ),
                  Icon(fileIcon, color: iconColor, size: 30),
                ],
              ),
              title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                file.lastOpenedAt != null 
                    ? 'آخر فتح: ${DateFormat('yyyy/MM/dd').format(file.lastOpenedAt!)}' 
                    : 'تاريخ الإضافة: ${DateFormat('yyyy/MM/dd').format(file.addedAt)}',
                style: const TextStyle(fontSize: 10),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(file.isFavorite ? Icons.favorite : Icons.favorite_border, color: file.isFavorite ? Colors.red : null, size: 20),
                    onPressed: () => _toggleFavorite(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
                    onPressed: () => _showFileOptions(file),
                  ),
                ],
              ),
              onTap: () => _openFile(file),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isVideo 
                          ? '${file.currentUnit} / ${file.totalUnits} دقيقة' 
                          : 'صفحة ${file.currentUnit} من ${file.totalUnits}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(isVideo ? Colors.blue : Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            if (file.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.1)),
                  ),
                  child: Text(
                    file.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridItem(LibraryCategory cat) {
    return InkWell(
      onTap: () => _navigateToCategory(cat),
      onLongPress: () => _showCategoryOptions(cat),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(cat.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileGridItem(LibraryFile file) {
    bool isVideo = file.type == LibraryType.video;
    return InkWell(
      onTap: () => _openFile(file),
      onLongPress: () => _showFileOptions(file),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf, color: isVideo ? Colors.blue : Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(file.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined, color: AppTheme.primaryGreen),
            title: const Text('قسم فرعي جديد'),
            onTap: () {
              Navigator.pop(context);
              _showAddCategoryDialog();
            },
          ),
          ListTile(
            leading: Icon(
              widget.libraryType == LibraryType.pdf ? Icons.upload_file_outlined : (widget.libraryType == LibraryType.video ? Icons.video_call_outlined : Icons.audio_file_outlined), 
              color: Colors.blue
            ),
            title: Text(
              widget.libraryType == LibraryType.pdf ? 'إضافة ملف PDF من الجهاز' : (widget.libraryType == LibraryType.video ? 'إضافة فيديو من الجهاز' : 'إضافة ملف صوتي من الجهاز')
            ),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog({LibraryCategory? categoryToEdit}) {
    final isEdit = categoryToEdit != null;
    final nameController = TextEditingController(text: categoryToEdit?.name);
    final emojiController = TextEditingController(text: categoryToEdit?.emoji ?? '📁');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل القسم' : 'قسم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emojiController, decoration: const InputDecoration(labelText: 'أيقونة/إيموجي')),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم القسم'), autofocus: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && UserService.currentUser != null) {
                final cat = LibraryCategory(
                  id: categoryToEdit?.id ?? const Uuid().v4(),
                  userId: UserService.currentUser!.id,
                  name: nameController.text,
                  emoji: emojiController.text,
                  parentId: categoryToEdit?.parentId ?? _currentCategoryId,
                  orderIndex: categoryToEdit?.orderIndex ?? 0,
                  type: widget.libraryType,
                );
                await LibraryService.saveCategory(cat);
                _loadData();
                Navigator.pop(context);
              }
            },
            child: Text(isEdit ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    List<String> extensions = ['pdf'];
    if (widget.libraryType == LibraryType.video) {
      extensions = ['mp4', 'mkv', 'mov', 'avi', 'wmv'];
    } else if (widget.libraryType == LibraryType.audio) {
      extensions = ['mp3', 'wav', 'm4a', 'ogg', 'aac'];
    }

    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result != null && result.files.single.path != null && UserService.currentUser != null) {
      final originalFile = File(result.files.single.path!);
      final fileName = result.files.single.name;
      
      // حفظ نسخة دائمة في مجلد التطبيق لتجنب فقدان الوصول للملف لاحقاً
      final appDir = await getApplicationDocumentsDirectory();
      final libraryDir = Directory('${appDir.path}/library');
      if (!await libraryDir.exists()) await libraryDir.create();
      
      final persistentPath = '${libraryDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await originalFile.copy(persistentPath);
      
      if (!mounted) return;

      // Ask for total units
      final totalController = TextEditingController(text: widget.libraryType == LibraryType.video ? '60' : '100');
      bool isVideo = widget.libraryType == LibraryType.video;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isVideo ? 'كم عدد دقائق الفيديو؟' : 'كم عدد صفحات الكتاب؟'),
          content: TextField(
            controller: totalController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(labelText: isVideo ? 'إجمالي الدقائق' : 'إجمالي الصفحات'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                int total = int.tryParse(totalController.text) ?? 100;
                final file = LibraryFile(
                  id: const Uuid().v4(),
                  userId: UserService.currentUser!.id,
                  name: fileName,
                  path: persistentPath,
                  categoryId: _currentCategoryId ?? 'root',
                  addedAt: DateTime.now(),
                  type: widget.libraryType,
                  totalUnits: total,
                );
                await LibraryService.saveFile(file);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      );
    }
  }

  void _openFile(LibraryFile file) async {
    final int index = _files.indexOf(file);
    if (file.type == LibraryType.pdf) {
      context.push('/library/viewer', extra: {
        'path': file.path,
        'name': file.name,
        'id': file.id,
        'currentUnit': file.currentUnit,
      });
    } else if (file.type == LibraryType.video) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            filePaths: _files.map((f) => f.path).toList(),
            titles: _files.map((f) => f.name).toList(),
            initialIndex: index,
          ),
        ),
      );
    } else if (file.type == LibraryType.audio) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ModernAudioPlayer(
          audioPaths: _files.map((f) => f.path).toList(),
          titles: _files.map((f) => f.name).toList(),
          initialIndex: index,
        ),
      );
    }
    
    // Update last opened
    await LibraryService.saveFile(file.copyWith(lastOpenedAt: DateTime.now()));
    _loadData();
  }

  void _toggleFavorite(LibraryFile file) async {
    final updated = file.copyWith(isFavorite: !file.isFavorite);
    await LibraryService.saveFile(updated);
    _loadData();
  }

  void _showFileOptions(LibraryFile file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.blue),
              title: const Text('تحديث التقدم'),
              onTap: () {
                Navigator.pop(context);
                _showUpdateProgressDialog(file);
              },
            ),
            ListTile(leading: const Icon(Icons.note_alt_outlined), title: const Text('الملاحظات'), onTap: () {
              Navigator.pop(context);
              _editFileNotes(file);
            }),
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('إعادة تسمية'), onTap: () {
              Navigator.pop(context);
              _renameFile(file);
            }),
            ListTile(leading: const Icon(Icons.move_to_inbox_outlined), title: const Text('نقل إلى قسم آخر'), onTap: () {
              Navigator.pop(context);
              _moveFile(file);
            }),
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('حذف'), onTap: () {
              Navigator.pop(context);
              _confirmDeleteFile(file);
            }),
          ],
        ),
      ),
    );
  }

  void _showUpdateProgressDialog(LibraryFile file) {
    final totalController = TextEditingController(text: file.totalUnits.toString());
    final currentController = TextEditingController(text: file.currentUnit.toString());
    bool isVideo = file.type == LibraryType.video;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isVideo ? 'تحديث دقائق الفيديو' : 'تحديث صفحات الكتاب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isVideo ? 'إجمالي الدقائق' : 'إجمالي الصفحات'),
            ),
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isVideo ? 'الدقائق التي شاهدتها' : 'الصفحة التي وصلت إليها'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              int total = int.tryParse(totalController.text) ?? 1;
              int current = int.tryParse(currentController.text) ?? 0;
              final updated = file.copyWith(totalUnits: total, currentUnit: current);
              await LibraryService.saveFile(updated);
              _loadData();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editFileNotes(LibraryFile file) {
    final controller = TextEditingController(text: file.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملاحظات'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظاتك هنا...', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await LibraryService.saveFile(file.copyWith(notes: controller.text));
              _loadData();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _renameFile(LibraryFile file) {
    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تسمية'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await LibraryService.saveFile(file.copyWith(name: controller.text));
                _loadData();
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _moveFile(LibraryFile file) {
    final allCats = LibraryService.getCategories(type: widget.libraryType); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نقل إلى'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allCats.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return ListTile(title: const Text('الرئيسية (الجذر)'), onTap: () async {
                  await LibraryService.saveFile(file.copyWith(categoryId: 'root'));
                  _loadData();
                  Navigator.pop(context);
                });
              }
              final cat = allCats[i - 1];
              return ListTile(title: Text('${cat.emoji} ${cat.name}'), onTap: () async {
                await LibraryService.saveFile(file.copyWith(categoryId: cat.id));
                _loadData();
                Navigator.pop(context);
              });
            },
          ),
        ),
      ),
    );
  }

  void _confirmDeleteFile(LibraryFile file) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف الملف',
      message: 'هل أنت متأكد من حذف هذا الملف نهائياً؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await LibraryService.deleteFile(file.id);
      _loadData();
    }
  }

  void _showCategoryOptions(LibraryCategory cat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('تعديل القسم'), onTap: () {
            Navigator.pop(context);
            _showAddCategoryDialog(categoryToEdit: cat);
          }),
          ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('حذف القسم'), onTap: () {
            Navigator.pop(context);
            _confirmDeleteCategory(cat);
          }),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(LibraryCategory cat) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف القسم',
      message: 'سيتم حذف القسم وجميع المحتويات بداخله. هل أنت متأكد؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await LibraryService.deleteCategory(cat.id);
      _loadData();
    }
  }
}
