import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'models/worship_model.dart';
import 'services/worship_service.dart';
import '../profile/services/user_service.dart';
import '../dashboard/services/prayer_service.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/app_theme.dart';
import 'worship_item_detail_screen.dart';
import '../../core/services/page_management_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/badge_service.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/widgets/page_info.dart';
import '../discipline/models/habit_model.dart';
import '../discipline/services/notification_service.dart';

class WorshipScreen extends StatefulWidget {
  const WorshipScreen({super.key});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> with HelpFeatureMixin {
  List<WorshipSection> _sections = [];
  List<WorshipItem> _items = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  final Map<String, bool> _isSectionExpanded = {};
  bool _showOnlyDueToday = false;

  static const List<String> fullArabicDays = [
    'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
    checkFirstTimeHelp(context, 'worship');
  }

  void _refreshData() {
    setState(() {
      _sections = WorshipService.getSections();
      _items = WorshipService.getItems();
    });
  }

  double _getNetScoreForDate(DateTime date) {
    double good = 0;
    double bad = 0;
    for (var item in _items) {
      double p = item.calculatePoints(date);
      final section = _sections.where((s) => s.id == item.sectionId).firstOrNull;
      if (section != null) {
        if (section.category == WorshipCategory.soulAtPeace) good += p;
        else if (section.category == WorshipCategory.soulCommandingEvil) bad += p;
      }
    }
    return good - bad;
  }

  List<DateTime> _getCurrentWeekDates() {
    DateTime now = DateTime.now();
    int currentFlutterWeekday = now.weekday;
    int daysToSubtract;
    if (currentFlutterWeekday == 6) daysToSubtract = 0;
    else if (currentFlutterWeekday == 7) daysToSubtract = 1;
    else daysToSubtract = currentFlutterWeekday + 1;
    DateTime saturday = now.subtract(Duration(days: daysToSubtract));
    return List.generate(7, (i) => saturday.add(Duration(days: i)));
  }

  Widget _buildWeeklyAnalysis() {
    List<DateTime> weekDates = _getCurrentWeekDates();
    List<double> scores = weekDates.map((d) => _getNetScoreForDate(d)).toList();
    final isDark = ThemeService.isDarkMode;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تتبع الأداء الروحي الأسبوعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                double score = scores[i];
                double heightFactor = (score.abs() / 200).clamp(0.1, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 25,
                        height: 80 * heightFactor,
                        decoration: BoxDecoration(
                          color: score >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(fullArabicDays[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double todayGood = 0;
    double todayBad = 0;
    DateTime today = PrayerService.getIslamicDayDate();
    final currentUserId = UserService.currentUser?.id ?? '';

    for (var item in _items) {
      double points = item.calculatePoints(today);
      final section = _sections.firstWhere(
        (s) => s.id == item.sectionId, 
        orElse: () => WorshipSection(id: '', userId: currentUserId, name: '', category: WorshipCategory.soulAtPeace)
      );
      if (section.category == WorshipCategory.soulAtPeace) {
        todayGood += points;
      } else if (section.category == WorshipCategory.soulCommandingEvil) {
        todayBad += points;
      }
    }

    final pages = PageManagementService.getAllPages();
    final page = pages.firstWhere((p) => p.id == 'prayers', orElse: () => PageItem(id: 'prayers', name: 'العبادة والروح', route: '', iconData: '🕌', sectionKey: 'worship'));

    final customBg = getPageBackgroundColor('worship');
    return Scaffold(
      backgroundColor: customBg,
      appBar: (_isSelectionMode || _selectedIds.isNotEmpty)
        ? AppBar(
            backgroundColor: const Color(0xFFC8A24A),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white), 
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              })
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown, 
              child: Text(
                _selectedIds.isEmpty ? 'تحديد العناصر' : '${_selectedIds.length} محدد', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              )
            ),
            actions: [
              if (_selectedIds.isNotEmpty) ...[
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white), onPressed: _showBulkEditPoints, tooltip: 'تعديل النقاط'),
                IconButton(icon: const Icon(Icons.swap_horiz, color: Colors.white), onPressed: _showBulkChangeSection, tooltip: 'تغيير القسم'),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _bulkDelete, tooltip: 'حذف المحدد'),
              ],
            ],
          )
        : AppBar(
            title: InkWell(
              onTap: _showEditPageNameDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(page.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                ],
              ),
            ),
            centerTitle: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              buildHelpButton(
                context, 
                title: 'شرح قسم العبادات', 
                description: 'تنظيم عبادتك هو طريق الفلاح:\n'
                '- أضف أقساماً للعبادات (مثل: الفرائض، السنن، الأذكار).\n'
                '- داخل كل قسم أضف العبادات التي تود متابعتها.\n'
                '- يمكنك تحديد تكرار العبادة وتنبيهاتها.\n'
                '- نقاطك تزداد عند إتمامك للعبادات بانتظام.',
                pageId: 'worship',
              ),
              IconButton(
                icon: Icon(_showOnlyDueToday ? Icons.filter_alt : Icons.filter_alt_off, color: _showOnlyDueToday ? const Color(0xFFC8A24A) : Colors.grey, size: 20),
                onPressed: () => setState(() => _showOnlyDueToday = !_showOnlyDueToday),
                tooltip: _showOnlyDueToday ? 'عرض كل الأعمال' : 'عرض أعمال اليوم فقط',
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'select') setState(() => _isSelectionMode = true);
                  if (val == 'bulk') _showBulkAddDialog();
                  if (val == 'add_section') _showAddEditSectionDialog();
                  if (val == 'reset_all') _confirmResetAllWorship();
                  if (val == 'home') GoRouter.of(context).go('/');
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'add_section', child: Text('إضافة قسم', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'select', child: Text('وضع التحديد', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'bulk', child: Text('إضافة متعددة', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'reset_all', child: Text('تصفير الكل (بداية جديدة)', style: TextStyle(fontSize: 13, color: Colors.red))),
                  const PopupMenuItem(value: 'home', child: Text('الرئيسية', style: TextStyle(fontSize: 13))),
                ],
              ),
            ],
          ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  QuickLinkNavigator(currentPageId: 'prayers'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PageInfo(
                      title: 'ميزان العبادات والروح',
                      description: 'سجل عباداتك اليومية وراقب ميزان نفسك بين المطمئنة والأمارة. جاهد نفسك لترتقي بروحك وتجمع الحسنات.',
                      icon: Icons.nightlight_round,
                    ),
                  ),
                  _buildWeeklyAnalysis(),
                  _buildInspirationWidget(),
                  _buildMizan(todayGood, todayBad),
                ],
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverReorderableList(
              itemCount: _sections.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final section = _sections.removeAt(oldIndex);
                  _sections.insert(newIndex, section);
                });
                await WorshipService.saveSectionsOrder(_sections);
                _refreshData();
              },
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  final sectionItems = _items.where((i) {
                    if (!_showOnlyDueToday) return i.sectionId == section.id;
                    return i.sectionId == section.id && i.isRequiredOn(PrayerService.getIslamicDayDate());
                  }).toList();
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(section.id),
                    index: index,
                    child: _buildSectionWidget(section, sectionItems),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildInspirationWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8A24A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Text('🌙', style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '"فَاسْتَبِقُوا الْخَيْرَاتِ"',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMizan(double good, double bad) {
    double net = good - bad;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.isDarkMode ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _mizanItem('المطمئنة', good.toInt().toString(), Colors.green),
          Column(
            children: [
              Text(net.toInt().toString(), 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: net >= 0 ? const Color(0xFF0F3D2E) : Colors.red)),
              const Text('صافي اليوم', style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          _mizanItem('الأمّارة', bad.toInt().toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _mizanItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionWidget(WorshipSection section, List<WorshipItem> items, {Key? key}) {
    double sectionScore = 0;
    if (section.category == WorshipCategory.independent) {
      DateTime today = DateTime.now();
      for (var item in items) {
        sectionScore += item.calculatePoints(today);
      }
    }

    // تنسيق خاص لقسم الصلوات ليكون في مستوى واحد
    bool isPrayersSection = section.name.contains('صلاة') || section.name.contains('صلوات') || section.name.contains('الفرائض');

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Expanded(
              flex: 5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isSectionExpanded[section.id] = !(_isSectionExpanded[section.id] ?? false)),
                  onLongPress: () => _showAddEditSectionDialog(section: section),
                  child: Row(
                    children: [
                      Text(section.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          section.name, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(section.colorValue))
                        ),
                      ),
                      if (section.category == WorshipCategory.independent) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Color(section.colorValue).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text('${sectionScore.toInt()}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(_isSectionExpanded[section.id] ?? false ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _isSectionExpanded[section.id] = !(_isSectionExpanded[section.id] ?? false)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey), 
                      onPressed: () => _showAddEditSectionDialog(section: section)
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4), 
                        minimumSize: const Size(45, 30), 
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft
                      ),
                      onPressed: () => _showAddEditItemSheet(section: section),
                      child: Text('إضافة', style: TextStyle(color: Color(section.colorValue), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isSectionExpanded[section.id] ?? false)
          isPrayersSection 
          ? _buildPrayersGrid(section, items)
          : ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
                
                // Update orderIndex for all items in this section
                for (int i = 0; i < items.length; i++) {
                  final globalIdx = _items.indexWhere((it) => it.id == items[i].id);
                  if (globalIdx != -1) {
                    _items[globalIdx] = items[i].copyWith(orderIndex: i);
                  }
                }
                // Sort _items globally to reflect new orderIndices
                _items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
              });
              await WorshipService.saveItemsOrder(_items);
              _refreshData();
            },
            children: items.where((i) => !_showOnlyDueToday || i.isRequiredOn(PrayerService.getIslamicDayDate())).map((item) => _buildItemCard(item, section, items, key: ValueKey(item.id))).toList(),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPrayersGrid(WorshipSection section, List<WorshipItem> items) {
    final filteredItems = items.where((i) => !_showOnlyDueToday || i.isRequiredOn(PrayerService.getIslamicDayDate())).toList();
    
    // ترتيب الصلوات زمنياً
    final prayerOrder = {
      'الفجر': 1,
      'الشروق': 2,
      'الضحى': 3,
      'الظهر': 4,
      'العصر': 5,
      'المغرب': 6,
      'العشاء': 7,
      'قيام الليل': 8,
      'الوتر': 9,
    };

    filteredItems.sort((a, b) {
      int orderA = 99;
      int orderB = 99;
      
      prayerOrder.forEach((key, value) {
        if (a.name.contains(key)) orderA = value;
        if (b.name.contains(key)) orderB = value;
      });

      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.orderIndex.compareTo(b.orderIndex);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return _buildItemCard(filteredItems[index], section, filteredItems, key: ValueKey(filteredItems[index].id));
      },
    );
  }

  Widget _buildItemCard(WorshipItem item, WorshipSection section, List<WorshipItem> allSectionItems, {Key? key}) {
    DateTime today = PrayerService.getIslamicDayDate();
    String dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    double currentValue = item.completionLog[dateKey] ?? 0;
    bool isGood = section.category == WorshipCategory.soulAtPeace;

    final isSelected = _selectedIds.contains(item.id);

    return ReorderableDelayedDragStartListener(
      key: key,
      index: allSectionItems.indexOf(item),
      child: InkWell(
        onLongPress: null, // Reserved for dragging
        onTap: (_isSelectionMode || _selectedIds.isNotEmpty)
          ? () => setState(() => isSelected ? _selectedIds.remove(item.id) : _selectedIds.add(item.id))
          : () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => WorshipItemDetailScreen(item: item, isGood: isGood))).then((_) => _refreshData());
          },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? const Color(0xFFC8A24A).withOpacity(0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected ? const BorderSide(color: Color(0xFFC8A24A), width: 2) : BorderSide.none,
          ),
          child: ListTile(
            leading: (_isSelectionMode || _selectedIds.isNotEmpty)
              ? Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: const Color(0xFFC8A24A), size: 24)
              : (item.type == WorshipItemType.fixed
                ? Checkbox(
                    value: currentValue > 0,
                    activeColor: Color(item.colorValue),
                    onChanged: (val) async {
                      await WorshipService.updateItemValue(item.id, DateTime.now(), val == true ? 1.0 : 0.0, increment: false);
                      _refreshData();
                    },
                  )
                : Container(
                    width: 35, height: 35,
                    decoration: BoxDecoration(color: Color(item.colorValue).withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 16))),
                  )),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.reminderTime != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item.reminderTime!.format(context), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    Text('النقاط: ${item.calculatePoints(PrayerService.getIslamicDayDate()).toInt()}', style: TextStyle(fontSize: 10, color: Color(item.colorValue))),
                    Text('التزام: ${item.commitmentRate.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.type == WorshipItemType.variable) ...[
                  SizedBox(
                    width: 50,
                    height: 35,
                    child: TextField(
                      enabled: !_isSelectionMode && _selectedIds.isEmpty,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        hintText: currentValue > 0 ? '${currentValue.toInt()}' : '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(item.colorValue).withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(item.colorValue), width: 2),
                        ),
                      ),
                      onSubmitted: (val) async {
                        double? newValue = double.tryParse(val);
                        if (newValue != null) {
                          await WorshipService.updateItemValue(item.id, DateTime.now(), newValue, increment: false);
                          _refreshData();
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                if (!_isSelectionMode && _selectedIds.isEmpty) ...[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.redAccent),
                    onPressed: () => _confirmResetWorship(item),
                    tooltip: 'بداية جديدة',
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                    onPressed: () => _showAddEditItemSheet(section: section, item: item),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPageNameDialog() async {
    final pages = PageManagementService.getAllPages();
    final page = pages.firstWhere((p) => p.id == 'prayers', orElse: () => PageItem(id: 'prayers', name: 'العبادات', route: '', iconData: '🕌', sectionKey: 'worship'));

    final nameController = TextEditingController(text: page.name);
    final iconController = TextEditingController(text: page.iconData);

    ModernDialog.show(
      context: context,
      title: 'تعديل اسم الصفحة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصفحة')),
          const SizedBox(height: 12),
          TextField(controller: iconController, decoration: const InputDecoration(labelText: 'الأيقونة (إيموجي)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              page.name = nameController.text;
              page.iconData = iconController.text;
              await PageManagementService.savePage(page);
              if (mounted) Navigator.pop(context);
              setState(() {});
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _showAddEditSectionDialog({WorshipSection? section}) {
    final isEdit = section != null;
    final controller = TextEditingController(text: section?.name ?? '');
    final emojiController = TextEditingController(text: section?.emoji ?? '🌙');
    WorshipCategory category = section?.category ?? WorshipCategory.soulAtPeace;
    Color selectedColor = Color(section?.colorValue ?? 0xFF0F3D2E);

    ModernDialog.show(
      context: context, 
      title: isEdit ? 'تعديل قسم' : 'تدوين قسم روحي',
      content: StatefulBuilder(builder: (context, setDialogState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emojiController, decoration: const InputDecoration(labelText: 'أيقونة القسم (إيموجي)')),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم القسم')),
            const SizedBox(height: 16),
            const Text('نوع النفس:', style: TextStyle(fontSize: 12)),
            DropdownButton<WorshipCategory>(
              value: category,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: WorshipCategory.soulAtPeace, child: Text('المطمئنة (إيجابي)')),
                DropdownMenuItem(value: WorshipCategory.soulCommandingEvil, child: Text('الأمّارة (سلبي)')),
                DropdownMenuItem(value: WorshipCategory.independent, child: Text('مستقل (خارج الميزان)')),
              ],
              onChanged: (v) => setDialogState(() => category = v!),
            ),
            const SizedBox(height: 16),
            const Text('اللون المميز:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: AppTheme.expandedColors.length,
                itemBuilder: (context, idx) {
                  final c = AppTheme.expandedColors[idx];
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: CircleAvatar(radius: 15, backgroundColor: c, child: selectedColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
                  );
                },
              ),
            ),
          ],
        ),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        if (isEdit) 
          TextButton(onPressed: () async {
            final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف القسم', message: 'هل تريد حذف هذا القسم بكل ما فيه؟', isDestructive: true);
            if (confirm == true) {
              await WorshipService.deleteSection(section.id);
              if (mounted) { Navigator.pop(context); _refreshData(); }
            }
          }, child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          onPressed: () async {
            if (controller.text.isEmpty || UserService.currentUser == null) return;
            final newSection = WorshipSection(
              id: section?.id ?? const Uuid().v4(),
              userId: UserService.currentUser!.id,
              name: controller.text,
              category: category,
              emoji: emojiController.text,
              colorValue: selectedColor.value,
              orderIndex: section?.orderIndex ?? 0,
            );
            await WorshipService.saveSection(newSection);
            if (mounted) { Navigator.pop(context); _refreshData(); }
          }, child: const Text('حفظ القسم')),
      ],
    );
  }

  void _showBulkAddDialog() {
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إضافة قسم أولاً')));
      return;
    }
    
    final textController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    WorshipSection selectedSection = _sections.first;

    ModernDialog.show(
      context: context,
      title: 'إضافة متعددة للعبادات',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل العبادات (واحدة في كل سطر). يمكنك استخدام الصيغة: "اسم العمل - نقاط"',
                  style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'صلاة الضحى - 20\nالاستغفار 100 مرة\nقراءة سورة الملك - 50',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: ThemeService.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'نقاط افتراضية', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<WorshipSection>(
                      value: selectedSection,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'القسم المستهدف', border: OutlineInputBorder()),
                      items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setDialogState(() => selectedSection = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8A24A), foregroundColor: Colors.white),
          onPressed: () async {
            final lines = textController.text.split('\n');
            int defaultPoints = int.tryParse(pointsController.text) ?? 10;
            int count = 0;
            final userId = UserService.currentUser?.id;
            if (userId == null) return;

            for (var line in lines) {
              final clean = line.trim();
              if (clean.isEmpty) continue;

              String name = clean;
              int points = defaultPoints;

              if (clean.contains('-')) {
                final parts = clean.split('-');
                name = parts[0].trim();
                points = int.tryParse(parts[parts.length - 1].trim()) ?? defaultPoints;
              }

              final item = WorshipItem(
                id: const Uuid().v4(),
                userId: userId,
                sectionId: selectedSection.id,
                name: name,
                type: WorshipItemType.fixed,
                basePoints: points.toDouble(),
                recurrence: WorshipRecurrence.daily,
                createdAt: DateTime.now(),
                orderIndex: _items.where((i) => i.sectionId == selectedSection.id).length + count,
                emoji: selectedSection.emoji,
                colorValue: selectedSection.colorValue,
              );
              await WorshipService.saveItem(item);
              count++;
            }

            if (mounted) {
              Navigator.pop(context);
              _refreshData();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة $count عمل بنجاح')));
            }
          },
          child: const Text('إضافة الكل'),
        ),
      ],
    );
  }

  void _showAddEditItemSheet({required WorshipSection section, WorshipItem? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final pointsController = TextEditingController(text: item?.basePoints.toInt().toString() ?? '10');
    final emojiController = TextEditingController(text: item?.emoji ?? '📍');
    final unitController = TextEditingController(text: item?.unitName ?? '');
    final intervalController = TextEditingController(text: item?.intervalValue.toString() ?? '1');
    WorshipItemType type = item?.type ?? WorshipItemType.fixed;
    WorshipRecurrence recurrence = item?.recurrence ?? WorshipRecurrence.daily;
    List<int> selectedDays = List<int>.from(item?.specificDays ?? []);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color selectedColor = Color(item?.colorValue ?? section.colorValue);
    TimeOfDay? selectedTime = item?.reminderTime;
    ReminderType reminderType = item?.reminderType ?? ReminderType.fixed;
    String? selectedPrayer = item?.linkedPrayer;
    
    // لإمكانية تغيير القسم
    String selectedSectionId = item?.sectionId ?? section.id;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل عمل' : 'تدوين عمل',
      accentColor: const Color(0xFFC8A24A),
      content: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اختيار القسم
              DropdownButtonFormField<String>(
                value: selectedSectionId,
                decoration: const InputDecoration(labelText: 'القسم'),
                items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setSheetState(() => selectedSectionId = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 60, 
                    child: TextField(
                      controller: emojiController, 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'أيقونة',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: nameController, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'اسم العمل',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<WorshipItemType>(
                      value: type, 
                      dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(labelText: 'نوع العمل', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                      items: const [
                        DropdownMenuItem(value: WorshipItemType.fixed, child: Text('ثابتة')), 
                        DropdownMenuItem(value: WorshipItemType.variable, child: Text('متغيرة')),
                      ],
                      onChanged: (v) => setSheetState(() => type = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<WorshipRecurrence>(
                      value: recurrence, 
                      dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(labelText: 'التكرار', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                      items: const [
                        DropdownMenuItem(value: WorshipRecurrence.daily, child: Text('يومياً')),
                        DropdownMenuItem(value: WorshipRecurrence.everyOtherDay, child: Text('يوم ويوم')),
                        DropdownMenuItem(value: WorshipRecurrence.specificDays, child: Text('أيام محددة')),
                        DropdownMenuItem(value: WorshipRecurrence.interval, child: Text('كل فترة')),
                      ],
                      onChanged: (v) => setSheetState(() => recurrence = v!),
                    ),
                  ),
                ],
              ),
              if (recurrence == WorshipRecurrence.specificDays) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    bool isSelected = selectedDays.contains(index);
                    return FilterChip(
                      label: Text(fullArabicDays[index], style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) selectedDays.add(index);
                          else selectedDays.remove(index);
                        });
                      },
                    );
                  }),
                ),
              ],
              if (recurrence == WorshipRecurrence.interval)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: intervalController, 
                    keyboardType: TextInputType.number, 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'كل كم يوم؟',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const Divider(height: 32),
              Text('نظام التذكير', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC8A24A) : const Color(0xFF0F3D2E))),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderType>(
                value: reminderType,
                dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'نوع التذكير', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                items: const [
                  DropdownMenuItem(value: ReminderType.fixed, child: Text('تذكير بموعد ثابت')),
                  DropdownMenuItem(value: ReminderType.prayer, child: Text('تذكير مع الصلاة 🕋')),
                ],
                onChanged: (v) => setSheetState(() => reminderType = v!),
              ),
              if (reminderType == ReminderType.fixed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFFC8A24A)),
                  title: Text(selectedTime == null ? 'ضبط منبه للتذكير' : 'وقت التذكير: ${selectedTime!.format(context)}', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  trailing: selectedTime != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setSheetState(() => selectedTime = null)) : const Icon(Icons.keyboard_arrow_left, size: 14),
                  onTap: () async {
                    final p = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
                    if (p != null) setSheetState(() => selectedTime = p);
                  },
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedPrayer,
                  dropdownColor: isDark ? const Color(0xFF1E2A38) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: 'اختر الصلاة', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                  items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSheetState(() => selectedPrayer = v),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController, 
                keyboardType: TextInputType.number, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'النقاط (لكل مرة/يوم)', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
              ),
              if (type == WorshipItemType.variable) 
                TextField(
                  controller: unitController, 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: 'اسم الوحدة (مثلاً: جزء، صفحة)', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                ),
              const SizedBox(height: 16),
              Text('لون العمل:', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: AppTheme.expandedColors.length,
                  itemBuilder: (context, idx) {
                    final c = AppTheme.expandedColors[idx];
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = c),
                      child: CircleAvatar(radius: 15, backgroundColor: c, child: selectedColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
                    );
                  },
                ),
              ),
              if (isEdit) ...[
                const Divider(height: 32),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('حذف هذا العمل', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف العمل', message: 'هل تريد حذف هذا العمل نهائياً؟', isDestructive: true);
                    if (confirm == true) {
                      await WorshipService.deleteItem(item.id);
                      if (mounted) {
                        Navigator.pop(context); // close sheet
                        _refreshData();
                      }
                    }
                  },
                )
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          onPressed: () async {
            if (nameController.text.isEmpty || UserService.currentUser == null) return;
            final newItem = WorshipItem(
              id: item?.id ?? const Uuid().v4(), 
              userId: UserService.currentUser!.id,
              sectionId: selectedSectionId, // استخدام المعرف المختار
              name: nameController.text, 
              type: type, 
              basePoints: double.tryParse(pointsController.text) ?? 10, 
              unitName: unitController.text, 
              recurrence: recurrence, 
              specificDays: selectedDays,
              intervalValue: int.tryParse(intervalController.text) ?? 1,
              createdAt: item?.createdAt ?? DateTime.now(), 
              emoji: emojiController.text, 
              colorValue: selectedColor.value, 
              completionLog: item?.completionLog ?? {},
              orderIndex: item?.orderIndex ?? 0,
              reminderHour: selectedTime?.hour,
              reminderMinute: selectedTime?.minute,
              reminderType: reminderType,
              linkedPrayer: selectedPrayer,
            );
            await WorshipService.saveItem(newItem);
            
            // جدولة التنبيهات
            await NotificationService.scheduleWorshipReminders(newItem, section.category == WorshipCategory.soulAtPeace);

            if (mounted) {
              Navigator.pop(context);
              _refreshData();
            }
          },
          child: const Text('حفظ العمل'),
        ),
      ],
    );
  }

  void _showBulkEditPoints() async {
    final res = await ModernDialog.showInput(context: context, title: 'تعديل النقاط', hint: 'أدخل النقاط الجديدة لـ ${_selectedIds.length} عمل');
    if (res != null) {
      final points = double.tryParse(res);
      if (points != null) {
        for (var id in _selectedIds) {
          final item = _items.firstWhere((i) => i.id == id);
          await WorshipService.saveItem(item.copyWith(basePoints: points));
        }
        setState(() => _selectedIds.clear());
        _refreshData();
      }
    }
  }

  void _showBulkChangeSection() async {
    String? selectedSectionId;
    ModernDialog.show(
      context: context,
      title: 'تغيير القسم',
      content: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر القسم الجديد للعناصر المحددة:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (val) => selectedSectionId = val,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (selectedSectionId != null) {
              for (var id in _selectedIds) {
                final item = _items.firstWhere((i) => i.id == id);
                await WorshipService.saveItem(item.copyWith(sectionId: selectedSectionId));
              }
              Navigator.pop(context);
              setState(() => _selectedIds.clear());
              _refreshData();
            }
          },
          child: const Text('نقل'),
        ),
      ],
    );
  }

  void _bulkDelete() async {
    final res = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف محدد',
      message: 'هل تريد حذف ${_selectedIds.length} عمل بشكل نهائي؟',
      isDestructive: true,
    );
    if (res == true) {
      for (var id in _selectedIds) {
        await WorshipService.deleteItem(id);
      }
      setState(() => _selectedIds.clear());
      _refreshData();
    }
  }

  void _confirmResetAllWorship() async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير كل العبادات',
      message: 'هل أنت متأكد من مسح جميع سجلات الإنجاز واعتبار اليوم هو أول يوم؟ (سيعيد حساب الالتزام ليكون 100%)',
      confirmLabel: 'تصفير الكل',
      isDestructive: true,
    );
    if (result == true) {
      await WorshipService.resetAllWorshipCompletion();
      _refreshData();
    }
  }

  void _confirmResetWorship(WorshipItem item) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'تصفير السجل',
      message: 'هل تريد تصفير سجل "${item.name}" والبدء من اليوم كبداية جديدة؟',
      confirmLabel: 'تصفير الآن',
    );
    if (result == true) {
      await WorshipService.resetWorshipCompletion(item.id);
      _refreshData();
    }
  }
}
