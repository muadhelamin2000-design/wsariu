import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/personal_matters_models.dart';
import 'services/personal_matters_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/widgets/page_info.dart';
import '../../core/services/page_management_service.dart';
import '../discipline/services/notification_service.dart';
import '../discipline/models/habit_model.dart';

class PersonalMattersScreen extends StatefulWidget {
  const PersonalMattersScreen({super.key});

  @override
  State<PersonalMattersScreen> createState() => _PersonalMattersScreenState();
}

class _PersonalMattersScreenState extends State<PersonalMattersScreen> with SingleTickerProviderStateMixin, HelpFeatureMixin {
  late TabController _tabController;
  List<RelationshipList> _relLists = [];
  FinanceSummary _finSummary = FinanceSummary();
  List<FinanceTransaction> _transactions = [];
  List<Subscription> _subscriptions = [];
  bool _showOnlyPending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    checkFirstTimeHelp(context, 'personal');
  }

  void _loadData() {
    setState(() {
      _relLists = PersonalMattersService.getRelationshipLists();
      _finSummary = PersonalMattersService.getFinanceSummary();
      _transactions = PersonalMattersService.getTransactions();
      _subscriptions = PersonalMattersService.getSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('personal');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('شؤوني 👥'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح قسم شؤوني', 
            description: 'هذا القسم لإدارة علاقاتك والتزاماتك المالية:\n'
            '- أضف قوائم للأشخاص (عائلة، أصدقاء) وتابع تواصلك معهم.\n'
            '- سجل معاملاتك المالية (دخل، مصروف، ديون).\n'
            '- تابع اشتراكاتك الشهرية واحسب رصيدك المتبقي.',
            pageId: 'personal',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'العلاقات'),
            Tab(text: 'المالية'),
          ],
        ),
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'personal'),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRelationshipsTab(),
                _buildFinanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= RELATIONSHIPS =================

  Widget _buildRelationshipsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('قوائم التواصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddRelListDialog(),
                icon: const Icon(Icons.add),
                label: const Text('قائمة جديدة'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _relLists.isEmpty 
            ? const Center(child: Text('لا توجد قوائم مضافة بعد'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _relLists.length,
                itemBuilder: (context, index) => _buildRelListCard(_relLists[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildRelListCard(RelationshipList list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(list.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${list.members.length} أشخاص • تم التواصل مع ${list.contactedCount}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: list.progress, minHeight: 4, borderRadius: BorderRadius.circular(2), color: AppTheme.primaryGreen, backgroundColor: Colors.grey.shade200),
          ],
        ),
        children: [
          ...list.members.map((person) => ListTile(
            leading: CircleAvatar(
              backgroundColor: person.contactedToday ? Colors.green.shade100 : Colors.grey.shade100,
              child: Icon(person.contactedToday ? Icons.check : Icons.person, color: person.contactedToday ? Colors.green : Colors.grey),
            ),
            title: Text(person.name),
            subtitle: Text(person.subCategory.isNotEmpty ? person.subCategory : 'تواصل معتاد'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _callPerson(list, person)),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') _showAddPersonDialog(list, person: person);
                    if (val == 'delete') _deletePerson(list, person);
                  },
                ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(onPressed: () => _showAddPersonDialog(list), icon: const Icon(Icons.add), label: const Text('إضافة شخص')),
                TextButton.icon(onPressed: () => _callRemaining(list), icon: const Icon(Icons.auto_awesome), label: const Text('من التالي؟')),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteRelList(list)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callRemaining(RelationshipList list) async {
    final pending = list.members.where((m) => !m.contactedToday).toList();
    if (pending.isEmpty) return;
    await _callPerson(list, pending.first);
  }

  Future<void> _callPerson(RelationshipList list, RelationshipPerson person) async {
    final Uri launchUri = Uri(scheme: 'tel', path: person.phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      await _toggleContacted(list, person, true);
    }
  }

  Future<void> _toggleContacted(RelationshipList list, RelationshipPerson person, bool val) async {
    final updatedMembers = list.members.map((m) {
      if (m.id == person.id) {
        return m.copyWith(
          lastContacted: val ? DateTime.now() : null,
          clearLastContacted: !val,
        );
      }
      return m;
    }).toList();
    await PersonalMattersService.saveRelationshipList(list.copyWith(members: updatedMembers));
    _loadData();
  }

  void _showAddRelListDialog({RelationshipList? list}) async {
    final isEdit = list != null;
    final controller = TextEditingController(text: list?.title);
    ReminderType reminderType = list?.reminderType ?? ReminderType.fixed;
    TimeOfDay? reminderTime = list?.reminderHour != null ? TimeOfDay(hour: list!.reminderHour!, minute: list.reminderMinute!) : null;
    String? linkedPrayer = list?.linkedPrayer;
    bool isRepeatable = list?.isRepeatable ?? true;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل قائمة' : 'إضافة قائمة',
      content: StatefulBuilder(builder: (context, setModalState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم القائمة (عائلة، أصدقاء...)')),
          const Divider(height: 32),
          const Text('إعدادات تذكير القائمة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<ReminderType>(
            value: reminderType,
            items: const [
              DropdownMenuItem(value: ReminderType.fixed, child: Text('تذكير بموعد ثابت')),
              DropdownMenuItem(value: ReminderType.prayer, child: Text('تذكير مع الصلاة 🕋')),
              DropdownMenuItem(value: ReminderType.flexible, child: Text('تذكير مرن (موزع)')),
            ],
            onChanged: (v) => setModalState(() => reminderType = v!),
            decoration: const InputDecoration(labelText: 'نوع التذكير'),
          ),
          if (reminderType == ReminderType.fixed)
            ListTile(
              title: Text(reminderTime == null ? 'اختر الوقت' : reminderTime!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final p = await showTimePicker(context: context, initialTime: reminderTime ?? TimeOfDay.now());
                if (p != null) setModalState(() => reminderTime = p);
              },
            )
          else if (reminderType == ReminderType.prayer)
            DropdownButtonFormField<String>(
              value: linkedPrayer,
              items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setModalState(() => linkedPrayer = v),
              decoration: const InputDecoration(labelText: 'اختر الصلاة'),
            )
          else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('البداية', style: TextStyle(fontSize: 12)),
                    subtitle: Text(list?.flexibleStartHour != null ? TimeOfDay(hour: list!.flexibleStartHour!, minute: 0).format(context) : '08:00'),
                    onTap: () async {
                      final p = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                      if (p != null) setModalState(() => list = (list ?? RelationshipList(id: '', title: '', members: [])).copyWith(flexibleStartHour: p.hour));
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('النهاية', style: TextStyle(fontSize: 12)),
                    subtitle: Text(list?.flexibleEndHour != null ? TimeOfDay(hour: list!.flexibleEndHour!, minute: 0).format(context) : '22:00'),
                    onTap: () async {
                      final p = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
                      if (p != null) setModalState(() => list = (list ?? RelationshipList(id: '', title: '', members: [])).copyWith(flexibleEndHour: p.hour));
                    },
                  ),
                ),
              ],
            ),
            TextField(
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: 'عدد مرات التذكير'),
              onChanged: (v) => list = (list ?? RelationshipList(id: '', title: '', members: [])).copyWith(flexibleCount: int.tryParse(v)),
            ),
          ],
          SwitchListTile(
            title: const Text('تذكير متكرر يومياً', style: TextStyle(fontSize: 12)),
            value: isRepeatable,
            onChanged: (v) => setModalState(() => isRepeatable = v),
          ),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (controller.text.isNotEmpty) {
            final RelationshipList newList = (list ?? RelationshipList(id: const Uuid().v4(), title: controller.text, members: [])).copyWith(
              title: controller.text,
              reminderType: reminderType,
              reminderHour: reminderTime?.hour,
              reminderMinute: reminderTime?.minute,
              linkedPrayer: linkedPrayer,
              isRepeatable: isRepeatable,
            );
            
            await PersonalMattersService.saveRelationshipList(newList);

            // Schedule Notification
            await NotificationService.schedulePersonalReminder(
              id: 'list_${newList.id}',
              title: 'تذكير بالقائمة: ${newList.title}',
              body: 'حان موعد التواصل مع أعضاء قائمة ${newList.title} 📞',
              reminderType: reminderType,
              hour: reminderTime?.hour,
              minute: reminderTime?.minute,
              prayer: linkedPrayer,
              repeatable: isRepeatable,
            );

            if (mounted) Navigator.pop(context);
            _loadData();
          }
        }, child: Text(isEdit ? 'حفظ' : 'إضافة')),
      ],
    );
  }

  void _showAddPersonDialog(RelationshipList list, {RelationshipPerson? person}) async {
    final isEdit = person != null;
    final nameController = TextEditingController(text: person?.name);
    final phoneController = TextEditingController(text: person?.phone);
    final subCatController = TextEditingController(text: person?.subCategory);
    
    ReminderType reminderType = person?.reminderType ?? ReminderType.fixed;
    TimeOfDay? reminderTime = person?.reminderHour != null ? TimeOfDay(hour: person!.reminderHour!, minute: person.reminderMinute!) : null;
    String? linkedPrayer = person?.linkedPrayer;
    bool isRepeatable = person?.isRepeatable ?? true;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل بيانات ${person.name}' : 'إضافة شخص لـ ${list.title}',
      content: StatefulBuilder(builder: (context, setModalState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            TextField(controller: subCatController, decoration: const InputDecoration(labelText: 'القسم الفرعي (اختياري)')),
            const Divider(height: 32),
            const Text('إعدادات التذكير والتنبيه', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReminderType>(
              value: reminderType,
              items: const [
                DropdownMenuItem(value: ReminderType.fixed, child: Text('تذكير بموعد ثابت')),
                DropdownMenuItem(value: ReminderType.prayer, child: Text('تذكير مع الصلاة 🕋')),
                DropdownMenuItem(value: ReminderType.flexible, child: Text('تذكير مرن (موزع)')),
              ],
              onChanged: (v) => setModalState(() => reminderType = v!),
              decoration: const InputDecoration(labelText: 'نوع التذكير'),
            ),
            if (reminderType == ReminderType.fixed)
              ListTile(
                title: Text(reminderTime == null ? 'اختر الوقت' : reminderTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: reminderTime ?? TimeOfDay.now());
                  if (p != null) setModalState(() => reminderTime = p);
                },
              )
            else if (reminderType == ReminderType.prayer)
              DropdownButtonFormField<String>(
                value: linkedPrayer,
                items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setModalState(() => linkedPrayer = v),
                decoration: const InputDecoration(labelText: 'اختر الصلاة'),
              )
            else ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('البداية', style: TextStyle(fontSize: 12)),
                        subtitle: Text(person?.flexibleStartHour != null ? TimeOfDay(hour: person!.flexibleStartHour!, minute: 0).format(context) : '08:00'),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                          if (p != null) setModalState(() => person = (person ?? RelationshipPerson(id: '', name: '')).copyWith(flexibleStartHour: p.hour));
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('النهاية', style: TextStyle(fontSize: 12)),
                        subtitle: Text(person?.flexibleEndHour != null ? TimeOfDay(hour: person!.flexibleEndHour!, minute: 0).format(context) : '22:00'),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
                          if (p != null) setModalState(() => person = (person ?? RelationshipPerson(id: '', name: '')).copyWith(flexibleEndHour: p.hour));
                        },
                      ),
                    ),
                  ],
                ),
                TextField(
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: 'عدد مرات التذكير'),
                  onChanged: (v) => person = (person ?? RelationshipPerson(id: '', name: '')).copyWith(flexibleCount: int.tryParse(v)),
                ),
            ],
            SwitchListTile(
              title: const Text('تذكير متكرر يومياً', style: TextStyle(fontSize: 12)),
              value: isRepeatable,
              onChanged: (v) => setModalState(() => isRepeatable = v),
            ),
          ],
        ),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (nameController.text.isNotEmpty) {
            final updatedMembers = List<RelationshipPerson>.from(list.members);
            final RelationshipPerson newPerson = (person ?? RelationshipPerson(id: const Uuid().v4(), name: nameController.text)).copyWith(
              name: nameController.text,
              phone: phoneController.text,
              subCategory: subCatController.text,
              reminderType: reminderType,
              reminderHour: reminderTime?.hour,
              reminderMinute: reminderTime?.minute,
              linkedPrayer: linkedPrayer,
              isRepeatable: isRepeatable,
            );

            final personToEdit = person;
            if (isEdit && personToEdit != null) {
               final idx = updatedMembers.indexWhere((m) => m.id == personToEdit.id);
               if (idx != -1) updatedMembers[idx] = newPerson;
            } else {
              updatedMembers.add(newPerson);
            }
            
            await PersonalMattersService.saveRelationshipList(list.copyWith(members: updatedMembers));

            // Schedule Notification
            await NotificationService.schedulePersonalReminder(
              id: 'rel_${newPerson.id}',
              title: 'تذكير بالتواصل: ${newPerson.name}',
              body: 'حان موعد التواصل مع ${newPerson.name} 📞',
              reminderType: reminderType,
              hour: reminderTime?.hour,
              minute: reminderTime?.minute,
              prayer: linkedPrayer,
              repeatable: isRepeatable,
            );

            if (mounted) Navigator.pop(context);
            _loadData();
          }
        }, child: const Text('حفظ')),
      ],
    );
  }

  void _deletePerson(RelationshipList list, RelationshipPerson person) async {
    final updated = list.members.where((m) => m.id != person.id).toList();
    await PersonalMattersService.saveRelationshipList(list.copyWith(members: updated));
    _loadData();
  }

  void _confirmDeleteRelList(RelationshipList list) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف القائمة', message: 'سيتم حذف قائمة ${list.title} ومن فيها.', isDestructive: true);
    if (res == true) {
      await PersonalMattersService.deleteRelationshipList(list.id);
      _loadData();
    }
  }

  // ================= FINANCE =================

  Widget _buildFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('آخر المعاملات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              TextButton(onPressed: () => _showAddTransactionDialog(), child: const Text('إضافة معاملة')),
            ],
          ),
          ..._transactions.take(5).map((t) => ListTile(
            leading: CircleAvatar(backgroundColor: _getColorForType(t.type).withOpacity(0.1), child: Icon(Icons.money, color: _getColorForType(t.type))),
            title: Text(t.description),
            subtitle: Text('${DateFormat('yyyy/MM/dd').format(t.date)} • ${t.category}'),
            trailing: Text('${t.amount.toInt()} ج', style: TextStyle(fontWeight: FontWeight.bold, color: _getColorForType(t.type))),
            onLongPress: () => _confirmDeleteTransaction(t),
          )),
          const Divider(height: 48),
          Row(
            children: [
              const Text('الاشتراكات الشهرية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              TextButton(onPressed: () => _showAddSubscriptionDialog(), child: const Text('إضافة اشتراك')),
            ],
          ),
          ..._subscriptions.map((s) => Card(
            child: ListTile(
              title: Text(s.name),
              subtitle: Text('المبلغ: ${s.amount.toInt()} ج • البداية: ${DateFormat('MM/dd').format(s.startDate)}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteSubscription(s)),
              onTap: () => _showAddSubscriptionDialog(sub: s),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F3D2E), Color(0xFF1B4D3E)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('الرصيد المتاح', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${_finSummary.currentBalance.toInt()} ج.م', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceStat('المصروفات', _transactions.where((t) => t.type == FinanceType.expense).fold(0, (a, b) => a + b.amount.toInt())),
              _buildBalanceStat('الديون', _transactions.where((t) => t.type == FinanceType.debt && !t.isSettled).fold(0, (a, b) => a + b.amount.toInt())),
              _buildBalanceStat('الحقوق', _transactions.where((t) => t.type == FinanceType.owed && !t.isSettled).fold(0, (a, b) => a + b.amount.toInt())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, int amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text('$amount ج', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showAddTransactionDialog({FinanceTransaction? transaction}) async {
    final isEdit = transaction != null;
    final amountController = TextEditingController(text: transaction?.amount.toInt().toString());
    final descController = TextEditingController(text: transaction?.description);
    
    FinanceType type = transaction?.type ?? FinanceType.expense;
    String category = transaction?.category ?? 'أخرى';
    bool allocateForCharity = false;
    double charityPercent = 2.5;
    bool isWish = false;
    Proximity proximity = transaction?.proximity ?? Proximity.near;
    Priority priority = transaction?.priority ?? Priority.normal;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل معاملة' : 'إضافة معاملة مالية',
      content: StatefulBuilder(builder: (context, setModalState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<FinanceType>(
              value: type,
              items: FinanceType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getTypeLabel(t)))).toList(),
              onChanged: (v) => setModalState(() => type = v!),
              decoration: const InputDecoration(labelText: 'نوع المعاملة'),
            ),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'البيان (شراء أغراض، راتب...)')),
            DropdownButtonFormField<String>(
              value: category,
              items: _finSummary.customExpenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setModalState(() => category = v!),
              decoration: const InputDecoration(labelText: 'التصنيف'),
            ),
            if (type == FinanceType.income) ...[
              CheckboxListTile(
                title: const Text('استقطاع نسبة للصدقة تلقائياً؟', style: TextStyle(fontSize: 12)),
                value: allocateForCharity,
                onChanged: (v) => setModalState(() => allocateForCharity = v!),
              ),
              if (allocateForCharity)
                Row(
                  children: [
                    const Text('النسبة: ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Slider(value: charityPercent, min: 1, max: 100, divisions: 20, label: '${charityPercent.toInt()}%', onChanged: (v) => setModalState(() => charityPercent = v))),
                    Text('${charityPercent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
            const Divider(),
            const Text('خيارات إضافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            DropdownButtonFormField<Proximity>(
              value: proximity,
              items: const [
                DropdownMenuItem(value: Proximity.near, child: Text('مكان قريب (محل، شخص متاح)')),
                DropdownMenuItem(value: Proximity.far, child: Text('مكان بعيد (مشوار، سفر)')),
              ],
              onChanged: (v) => setModalState(() => proximity = v!),
            ),
            DropdownButtonFormField<Priority>(
              value: priority,
              items: const [
                DropdownMenuItem(value: Priority.important, child: Text('ضروري جداً')),
                DropdownMenuItem(value: Priority.normal, child: Text('عادي')),
                DropdownMenuItem(value: Priority.trivial, child: Text('ترفيهي / كماليات')),
              ],
              onChanged: (v) => setModalState(() => priority = v!),
            ),
            CheckboxListTile(
              title: const Text('أمنية (Wishlist)؟', style: TextStyle(fontSize: 12)),
              subtitle: const Text('لن تخصم من الرصيد حتى تتحقق', style: TextStyle(fontSize: 10)),
              value: isWish,
              onChanged: (v) => setModalState(() => isWish = v!),
            ),
          ],
        ),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (amountController.text.isNotEmpty && descController.text.isNotEmpty) {
              final amount = double.tryParse(amountController.text) ?? 0;
              final newTrans = FinanceTransaction(
                id: transaction?.id ?? const Uuid().v4(),
                amount: amount,
                type: type,
                category: category,
                description: descController.text,
                date: transaction?.date ?? DateTime.now(),
                isSettled: isWish ? false : (transaction?.isSettled ?? true),
                proximity: proximity,
                priority: priority,
              );
              
              if (isEdit) {
                await PersonalMattersService.updateTransaction(transaction, newTrans);
              } else {
                await PersonalMattersService.addTransaction(newTrans);
                
                // Logic for auto-charity
                if (type == FinanceType.income && allocateForCharity) {
                  final charityAmount = amount * (charityPercent / 100);
                  final charityTrans = FinanceTransaction(
                    id: const Uuid().v4(),
                    amount: charityAmount,
                    type: FinanceType.expense,
                    category: 'صدقة',
                    description: 'صدقة مستقطعة من ( ${descController.text} )',
                    date: DateTime.now(),
                    isSettled: true,
                  );
                  await PersonalMattersService.addTransaction(charityTrans);
                }
              }

              if (mounted) Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _showAddSubscriptionDialog({Subscription? sub}) {
    final isEdit = sub != null;
    final nameController = TextEditingController(text: sub?.name);
    final amountController = TextEditingController(text: sub?.amount.toInt().toString());
    DateTime startDate = sub?.startDate ?? DateTime.now();

    ReminderType reminderType = sub?.reminderType ?? ReminderType.fixed;
    TimeOfDay? reminderTime = sub?.reminderHour != null ? TimeOfDay(hour: sub!.reminderHour!, minute: sub.reminderMinute!) : null;
    String? linkedPrayer = sub?.linkedPrayer;
    bool isRepeatable = sub?.isRepeatable ?? true;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل اشتراك' : 'إضافة اشتراك جديد',
      content: StatefulBuilder(builder: (context, setModalState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الخدمة (جيم، نت...)')),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ الشهري')),
            ListTile(
              title: const Text('تاريخ بداية الاشتراك'),
              subtitle: Text(DateFormat('yyyy/MM/dd').format(startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, 
                  initialDate: startDate, 
                  firstDate: DateTime(2024), 
                  lastDate: DateTime.now().add(const Duration(days: 365))
                );
                if (picked != null) setModalState(() => startDate = picked);
              },
            ),
            const Divider(height: 32),
            const Text('إعدادات تذكير الدفع', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReminderType>(
              value: reminderType,
              items: const [
                DropdownMenuItem(value: ReminderType.fixed, child: Text('تذكير بموعد ثابت')),
                DropdownMenuItem(value: ReminderType.prayer, child: Text('تذكير مع الصلاة 🕋')),
                DropdownMenuItem(value: ReminderType.flexible, child: Text('تذكير مرن (موزع)')),
              ],
              onChanged: (v) => setModalState(() => reminderType = v!),
              decoration: const InputDecoration(labelText: 'نوع التذكير'),
            ),
            if (reminderType == ReminderType.fixed)
              ListTile(
                title: Text(reminderTime == null ? 'اختر الوقت' : reminderTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: reminderTime ?? TimeOfDay.now());
                  if (p != null) setModalState(() => reminderTime = p);
                },
              )
            else if (reminderType == ReminderType.prayer)
              DropdownButtonFormField<String>(
                value: linkedPrayer,
                items: ['الفجر', 'الشروق', 'الضحى', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setModalState(() => linkedPrayer = v),
                decoration: const InputDecoration(labelText: 'اختر الصلاة'),
              )
            else ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('البداية', style: TextStyle(fontSize: 12)),
                        subtitle: Text(sub?.flexibleStartHour != null ? TimeOfDay(hour: sub!.flexibleStartHour!, minute: 0).format(context) : '08:00'),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                          if (p != null) setModalState(() => sub = (sub ?? Subscription(id: '', name: '', amount: 0, startDate: DateTime.now())).copyWith(flexibleStartHour: p.hour));
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('النهاية', style: TextStyle(fontSize: 12)),
                        subtitle: Text(sub?.flexibleEndHour != null ? TimeOfDay(hour: sub!.flexibleEndHour!, minute: 0).format(context) : '22:00'),
                        onTap: () async {
                          final p = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
                          if (p != null) setModalState(() => sub = (sub ?? Subscription(id: '', name: '', amount: 0, startDate: DateTime.now())).copyWith(flexibleEndHour: p.hour));
                        },
                      ),
                    ),
                  ],
                ),
                TextField(
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: 'عدد مرات التذكير'),
                  onChanged: (v) => sub = (sub ?? Subscription(id: '', name: '', amount: 0, startDate: DateTime.now())).copyWith(flexibleCount: int.tryParse(v)),
                ),
            ],
            SwitchListTile(
              title: const Text('تذكير متكرر يومياً', style: TextStyle(fontSize: 12)),
              value: isRepeatable,
              onChanged: (v) => setModalState(() => isRepeatable = v),
            ),
          ],
        ),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
            final double amount = double.tryParse(amountController.text) ?? 0;
            final newSub = (sub ?? Subscription(id: const Uuid().v4(), name: nameController.text, amount: amount, startDate: startDate)).copyWith(
              name: nameController.text,
              amount: amount,
              startDate: startDate,
              reminderType: reminderType,
              reminderHour: reminderTime?.hour,
              reminderMinute: reminderTime?.minute,
              linkedPrayer: linkedPrayer,
              isRepeatable: isRepeatable,
            );
            
            await PersonalMattersService.saveSubscription(newSub);

            // Schedule Notification
            await NotificationService.schedulePersonalReminder(
              id: 'sub_${newSub.id}',
              title: 'تذكير باشتراك: ${newSub.name}',
              body: 'حان موعد دفع قسط ${newSub.name} بمبلغ ${newSub.amount.toInt()} ج 💳',
              reminderType: reminderType,
              hour: reminderTime?.hour,
              minute: reminderTime?.minute,
              prayer: linkedPrayer,
              repeatable: isRepeatable,
            );

            if (mounted) Navigator.pop(context);
            _loadData();
          }
        }, child: const Text('حفظ')),
      ],
    );
  }

  void _confirmDeleteSubscription(Subscription sub) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف اشتراك', message: 'هل تريد حذف اشتراك ${sub.name}؟ لن يتم خصمه تلقائياً.', isDestructive: true);
    if (res == true) {
      await PersonalMattersService.deleteSubscription(sub.id);
      _loadData();
    }
  }

  void _confirmDeleteTransaction(FinanceTransaction t) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف العملية', message: 'هل تريد حذف هذه العملية وتعديل الرصيد؟', isDestructive: true);
    if (res == true) {
      await PersonalMattersService.deleteTransaction(t.id);
      _loadData();
    }
  }

  Color _getColorForType(FinanceType type) {
    switch(type) {
      case FinanceType.income: return Colors.green;
      case FinanceType.expense: return Colors.orange;
      case FinanceType.debt: return Colors.red;
      case FinanceType.owed: return Colors.blue;
    }
  }

  String _getTitleForType(FinanceType type) {
    switch(type) {
      case FinanceType.income: return 'تسجيل دخل';
      case FinanceType.expense: return 'تسجيل مصروف';
      case FinanceType.debt: return 'تسجيل ديْن (عليّ)';
      case FinanceType.owed: return 'تسجيل حق (لي)';
    }
  }

  String _getTypeLabel(FinanceType type) {
    switch(type) {
      case FinanceType.income: return 'دخل (+)';
      case FinanceType.expense: return 'مصروف (-)';
      case FinanceType.debt: return 'ديْن عليّ (سلف)';
      case FinanceType.owed: return 'حق لي (أطلب)';
    }
  }
}
