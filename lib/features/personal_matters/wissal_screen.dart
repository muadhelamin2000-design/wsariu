import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/personal_matters_models.dart';
import 'services/personal_matters_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/services/page_management_service.dart';
import '../discipline/services/notification_service.dart';
import '../discipline/models/habit_model.dart';

class WissalScreen extends StatefulWidget {
  const WissalScreen({super.key});

  @override
  State<WissalScreen> createState() => _WissalScreenState();
}

class _WissalScreenState extends State<WissalScreen> with HelpFeatureMixin {
  List<RelationshipList> _relLists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    checkFirstTimeHelp(context, 'wissal');
  }

  void _loadData() {
    setState(() {
      _relLists = PersonalMattersService.getRelationshipLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('wissal');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('وِصال 👥'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح قسم وصال', 
            description: 'هذا القسم لإدارة علاقاتك الاجتماعية والتواصل:\n'
            '- أضف قوائم للأشخاص (عائلة، أصدقاء، عمل).\n'
            '- تابع تواصلك الدوري معهم وحافظ على الود.\n'
            '- احصل على تذكيرات تلقائية بمواعيد الاتصال.',
            pageId: 'wissal',
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'wissal'),
          Expanded(
            child: _buildRelationshipsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('قوائم التواصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showAddRelListDialog(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                child: const Text('قائمة جديدة'),
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
          _buildGroupedMembers(list),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(onPressed: () => _showAddPersonDialog(list), child: const Text('إضافة شخص')),
                TextButton(onPressed: () => _callRemaining(list), child: const Text('من التالي؟')),
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showAddRelListDialog(list: list)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteRelList(list)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMembers(RelationshipList list) {
    // تجميع الأعضاء حسب القسم الفرعي
    final Map<String, List<RelationshipPerson>> grouped = {};
    final List<RelationshipPerson> noGroup = [];

    for (var member in list.members) {
      if (member.subCategory.isEmpty) {
        noGroup.add(member);
      } else {
        grouped.putIfAbsent(member.subCategory, () => []).add(member);
      }
    }

    return Column(
      children: [
        // الأشخاص بدون مجموعة
        ...noGroup.map((person) => _buildPersonTile(list, person)),
        
        // المجموعات الفرعية
        ...grouped.entries.map((entry) => ExpansionTile(
          title: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey)),
          leading: const Icon(Icons.subdirectory_arrow_left, size: 18, color: Colors.grey),
          children: entry.value.map((person) => _buildPersonTile(list, person)).toList(),
        )),
      ],
    );
  }

  Widget _buildPersonTile(RelationshipList list, RelationshipPerson person) {
    return ListTile(
      dense: true,
      leading: Checkbox(
        value: person.contactedToday,
        activeColor: Colors.green,
        onChanged: (val) => _toggleContacted(list, person, val ?? false),
      ),
      title: Text(
        person.name, 
        style: TextStyle(
          fontSize: 14,
          decoration: person.contactedToday ? TextDecoration.lineThrough : null,
          color: person.contactedToday ? Colors.grey : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.call, color: Colors.green, size: 20), onPressed: () => _callPerson(list, person)),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 20),
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
        }, child: const Text('حفظ')),
      ],
    );
  }

  void _showAddPersonDialog(RelationshipList list, {RelationshipPerson? person}) async {
    final isEdit = person != null;
    final nameController = TextEditingController(text: person?.name);
    final phoneController = TextEditingController(text: person?.phone);
    final subCatController = TextEditingController(text: person?.subCategory);
    
    // الحصول على الفروع الموجودة فعلياً في هذه القائمة
    final List<String> existingSubCats = list.members
        .map((m) => m.subCategory)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

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
            
            const SizedBox(height: 16),
            const Text('الفرع / القسم الفرعي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            if (existingSubCats.isNotEmpty)
              DropdownButtonFormField<String>(
                value: existingSubCats.contains(subCatController.text) ? subCatController.text : null,
                items: [
                  const DropdownMenuItem(value: '', child: Text('بدون فرع (عام)')),
                  ...existingSubCats.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (v) => setModalState(() => subCatController.text = v ?? ''),
                decoration: const InputDecoration(hintText: 'اختر فرعاً موجوداً'),
              ),
            TextField(
              controller: subCatController, 
              decoration: const InputDecoration(
                labelText: 'أو اكتب فرعاً جديداً',
                hintText: 'مثال: فرع القاهرة، العائلة الكبيرة...'
              ),
              onChanged: (v) => setModalState(() {}), // لتحديث حالة الـ Dropdown إذا تطابق النص
            ),

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
}
