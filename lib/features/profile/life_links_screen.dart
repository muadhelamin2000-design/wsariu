import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/life_link_model.dart';
import 'services/life_link_service.dart';
import '../../features/discipline/services/habit_service.dart';
import '../../features/worship/services/worship_service.dart';
import '../../features/discipline/services/task_service.dart';
import '../../features/discipline/services/routine_service.dart';
import '../../features/discipline/models/habit_model.dart';
import 'services/user_service.dart';
import '../../core/widgets/modern_dialog.dart';

class LifeLinksScreen extends StatefulWidget {
  const LifeLinksScreen({super.key});

  @override
  State<LifeLinksScreen> createState() => _LifeLinksScreenState();
}

class _LifeLinksScreenState extends State<LifeLinksScreen> {
  List<LifeLink> _links = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _links = LifeLinkService.getLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاعل الصفحات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLinkDialog,
        icon: const Icon(Icons.swap_calls),
        label: const Text('إضافة تفاعل'),
      ),
      body: _links.isEmpty
          ? const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('ابدأ بربط عناصر حياتك ببعضها (مثلاً: النوم المتأخر يؤثر على صلاة الفجر)', textAlign: TextAlign.center),
          ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _links.length,
              itemBuilder: (context, index) => _buildLinkCard(_links[index]),
            ),
    );
  }

  Widget _buildLinkCard(LifeLink link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _typeIcon(link.sourceType),
                const SizedBox(width: 8),
                Expanded(child: Text(link.sourceName, style: const TextStyle(fontWeight: FontWeight.bold))),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                _typeIcon(link.targetType),
                const SizedBox(width: 8),
                Expanded(child: Text(link.targetName, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: link.isNegativeImpact ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(link.relationDescription, 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: link.isNegativeImpact ? Colors.red : Colors.green)),
                ),
                IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await ModernDialog.showConfirm(
                      context: context,
                      title: 'حذف التفاعل',
                      message: 'هل أنت متأكد من حذف هذا التفاعل نهائياً؟',
                      confirmLabel: 'حذف',
                      isDestructive: true,
                    );
                    if (confirm == true) {
                      await LifeLinkService.deleteLink(link.id);
                      _refreshData();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(String type) {
    IconData icon;
    switch(type) {
      case 'habit': icon = Icons.check_circle_outline; break;
      case 'worship': icon = Icons.mosque_outlined; break;
      case 'goal': icon = Icons.account_tree_outlined; break;
      case 'task': icon = Icons.bolt; break;
      case 'routine': icon = Icons.repeat; break;
      default: icon = Icons.help_outline;
    }
    return Icon(icon, size: 18, color: const Color(0xFFC8A24A));
  }

  void _showAddLinkDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModernLinkDialog(),
    ).then((_) => _refreshData());
  }
}

class ModernLinkDialog extends StatefulWidget {
  const ModernLinkDialog({super.key});

  @override
  State<ModernLinkDialog> createState() => _ModernLinkDialogState();
}

class _ModernLinkDialogState extends State<ModernLinkDialog> {
  String? sourcePage;
  String? sourceSubCategory; // Section for worship, GoalType for goal, etc.
  Map<String, dynamic>? selectedSource;

  bool isNegative = true;
  final descController = TextEditingController();

  String? targetPage;
  String? targetSubCategory;
  Map<String, dynamic>? selectedTarget;

  final List<String> pages = ['الانضباط', 'العبادة', 'المهام', 'الروتين'];

  List<String> _getSubCategories(String page) {
    if (page == 'العبادة') {
      return WorshipService.getSections().map((s) => s.name).toList();
    } else if (page == 'الانضباط') {
      return ['عادات جيدة', 'عادات سيئة'];
    }
    return [];
  }

  List<Map<String, dynamic>> _getItems(String page, String? subCat) {
    if (page == 'العبادة') {
      return WorshipService.getItems()
          .where((i) => subCat == null || WorshipService.getSections().any((s) => s.id == i.sectionId && s.name == subCat))
          .map((e) => {'id': e.id, 'name': e.name, 'type': 'worship'}).toList();
    } else if (page == 'الانضباط') {
      final goal = subCat == 'عادات جيدة' ? HabitGoal.good : HabitGoal.bad;
      return HabitService.getHabits()
          .where((h) => subCat == null || h.goal == goal)
          .map((e) => {'id': e.id, 'name': e.name, 'type': 'habit'}).toList();
    } else if (page == 'المهام') {
      return TaskService.getTasks().map((e) => {'id': e.id, 'name': e.title, 'type': 'task'}).toList();
    } else if (page == 'الروتين') {
      return RoutineService.getRoutines().map((e) => {'id': e.id, 'name': e.title, 'type': 'routine'}).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Text('إنشاء تفاعل ذكي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('العنصر الأول (المؤثر)', isDark),
                  _buildDropdown('الصفحة', sourcePage, pages, (v) => setState(() { sourcePage = v; sourceSubCategory = null; selectedSource = null; }), isDark),
                  if (_getSubCategories(sourcePage ?? '').isNotEmpty)
                    _buildDropdown('القسم/النوع', sourceSubCategory, _getSubCategories(sourcePage!), (v) => setState(() { sourceSubCategory = v; selectedSource = null; }), isDark),
                  _buildItemDropdown('العنصر', selectedSource, _getItems(sourcePage ?? '', sourceSubCategory), (v) => setState(() => selectedSource = v), isDark),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Icon(Icons.link, color: Color(0xFFC8A24A), size: 30)),
                  ),

                  _buildSectionTitle('نوع العلاقة', isDark),
                  DropdownButtonFormField<bool>(
                    value: isNegative,
                    dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: _inputDecoration('طبيعة التفاعل', isDark),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('يؤثر سلباً على (يضيع/يعيق)')),
                      DropdownMenuItem(value: false, child: Text('يؤثر إيجاباً على (يدعم/يقوي)')),
                    ],
                    onChanged: (v) => setState(() => isNegative = v!),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle('العنصر الثاني (المتأثر)', isDark),
                  _buildDropdown('الصفحة', targetPage, pages, (v) => setState(() { targetPage = v; targetSubCategory = null; selectedTarget = null; }), isDark),
                  if (_getSubCategories(targetPage ?? '').isNotEmpty)
                    _buildDropdown('القسم/النوع', targetSubCategory, _getSubCategories(targetPage!), (v) => setState(() { targetSubCategory = v; selectedTarget = null; }), isDark),
                  _buildItemDropdown('العنصر', selectedTarget, _getItems(targetPage ?? '', targetSubCategory), (v) => setState(() => selectedTarget = v), isDark),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('شرح التفاعل', isDark),
                  TextField(
                    controller: descController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: _inputDecoration('مثلاً: السهر يسبب تضييع صلاة الفجر', isDark),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (selectedSource == null || selectedTarget == null || UserService.currentUser == null) return;
                        final newLink = LifeLink(
                          id: const Uuid().v4(),
                          userId: UserService.currentUser!.id,
                          sourceId: selectedSource!['id'],
                          sourceType: selectedSource!['type'],
                          sourceName: selectedSource!['name'],
                          targetId: selectedTarget!['id'],
                          targetType: selectedTarget!['type'],
                          targetName: selectedTarget!['name'],
                          relationDescription: descController.text.isNotEmpty ? descController.text : (isNegative ? 'تأثير سلبي' : 'تأثير إيجابي'),
                          isNegativeImpact: isNegative,
                        );
                        await LifeLinkService.saveLink(newLink);
                        Navigator.pop(context);
                      },
                      child: const Text('حفظ التفاعل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.grey)),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: _inputDecoration(label, isDark),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildItemDropdown(String label, Map<String, dynamic>? selectedValue, List<Map<String, dynamic>> items, Function(Map<String, dynamic>?) onChanged, bool isDark) {
    // نستخدم المعرف (ID) كقيمة للمنسدلة لتجنب أخطاء المقارنة بين الكائنات (Objects)
    // نستخدم String كنوع للقيمة في DropdownButtonFormField
    String? selectedId = selectedValue?['id'];
    
    // التأكد من أن المعرف موجود فعلاً في قائمة العناصر وأن القائمة لا تحتوي على مكررات
    final uniqueItems = <String, Map<String, dynamic>>{};
    for (var item in items) {
      if (item['id'] != null) {
        uniqueItems[item['id']] = item;
      }
    }
    final finalItems = uniqueItems.values.toList();

    if (selectedId != null && !uniqueItems.containsKey(selectedId)) {
      selectedId = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedId,
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: _inputDecoration(label, isDark),
        items: finalItems.map((e) => DropdownMenuItem<String>(
          value: e['id'], 
          child: Text(e['name'] ?? 'بدون اسم', overflow: TextOverflow.ellipsis)
        )).toList(),
        onChanged: (id) {
          if (id == null) {
            onChanged(null);
          } else {
            final item = uniqueItems[id];
            onChanged(item);
          }
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
    );
  }
}
