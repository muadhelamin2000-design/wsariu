import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models/personal_matters_models.dart';
import 'services/personal_matters_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';
import '../../core/services/page_management_service.dart';
import '../discipline/services/notification_service.dart';
import '../discipline/models/habit_model.dart';

class KhaznatiScreen extends StatefulWidget {
  const KhaznatiScreen({super.key});

  @override
  State<KhaznatiScreen> createState() => _KhaznatiScreenState();
}

class _KhaznatiScreenState extends State<KhaznatiScreen> with HelpFeatureMixin {
  FinanceSummary _finSummary = FinanceSummary();
  List<FinanceTransaction> _transactions = [];
  List<Subscription> _subscriptions = [];
  String _currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
    checkFirstTimeHelp(context, 'khaznati');
  }

  void _loadData() {
    setState(() {
      _finSummary = PersonalMattersService.getFinanceSummary();
      _transactions = PersonalMattersService.getTransactions();
      _subscriptions = PersonalMattersService.getSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('khaznati');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('خزنتي 💰'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح خزنتي المطور', 
            description: 'إدارة مالية شاملة:\n'
            '- 🗓️ الاشتراكات: مصروفاتك الشهرية الثابتة.\n'
            '- 💸 المصروفات: ما تنفقه يومياً.\n'
            '- 💰 الدخل: مدخلاتك المالية.\n'
            '- 🚩 الديون: مبالغ عليك دفعها.\n'
            '- ✅ الحقوق: مبالغ تنتظر استلامها.\n'
            'علم على العنصر (Checkbox) ليتم تفعيله في الرصيد الحالي.',
            pageId: 'khaznati',
          ),
        ],
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'khaznati'),
          _buildBalanceHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionCard(
                  title: 'الاشتراكات الشهرية 🗓️',
                  color: Colors.blue,
                  items: _subscriptions,
                  type: 'subs',
                ),
                _buildSectionCard(
                  title: 'المصروفات 💸',
                  color: Colors.orange,
                  items: _transactions.where((t) => t.type == FinanceType.expense).toList(),
                  type: 'expense',
                ),
                _buildSectionCard(
                  title: 'الدخل 💰',
                  color: Colors.green,
                  items: _transactions.where((t) => t.type == FinanceType.income).toList(),
                  type: 'income',
                ),
                _buildSectionCard(
                  title: 'الديون (عليّ) 🚩',
                  color: Colors.red,
                  items: _transactions.where((t) => t.type == FinanceType.debt).toList(),
                  type: 'debt',
                ),
                _buildSectionCard(
                  title: 'الحقوق (لي) ✅',
                  color: Colors.teal,
                  items: _transactions.where((t) => t.type == FinanceType.owed).toList(),
                  type: 'owed',
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        label: const Text('إضافة معاملة'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade900, Colors.green.shade700]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الرصيد الفعلي الحالي', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${_finSummary.currentBalance.toInt()} ج.م', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.account_balance_wallet, color: Colors.white24, size: 40),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Color color, required List items, required String type}) {
    double total = 0;
    if (type == 'subs') {
      total = (items as List<Subscription>).fold(0, (a, b) => a + b.amount);
    } else {
      total = (items as List<FinanceTransaction>).fold(0, (a, b) => a + b.amount);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getIconForType(type), color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('الإجمالي: ${total.toInt()} ج', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        children: [
          if (items.isEmpty)
             Padding(
               padding: const EdgeInsets.all(16),
               child: Text('لا يوجد بيانات حالياً', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
             ),
          ...items.map((item) => _buildItemRow(item, type)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () => type == 'subs' ? _showAddSubscriptionDialog() : _showAddTransactionDialog(forcedType: _getFinanceType(type)),
              child: const Text('إضافة جديد', style: TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item, String type) {
    bool isChecked = false;
    String title = "";
    String sub = "";
    double amount = 0;

    if (type == 'subs') {
      final subItem = item as Subscription;
      isChecked = subItem.paidMonths.contains(_currentMonthKey);
      title = subItem.name;
      sub = 'اشتراك شهري';
      amount = subItem.amount;
    } else {
      final trans = item as FinanceTransaction;
      isChecked = trans.isSettled;
      title = trans.description;
      sub = '${trans.category} • ${DateFormat('MM/dd').format(trans.date)}';
      if (type == 'debt' || type == 'owed') {
        sub += ' • ${trans.proximity == Proximity.near ? 'قريب' : 'بعيد'}';
      }
      amount = trans.amount;
    }

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: isChecked,
        activeColor: Colors.green,
        onChanged: (val) async {
          if (type == 'subs') {
            await PersonalMattersService.toggleSubscriptionMonth(item.id, _currentMonthKey);
          } else {
            await PersonalMattersService.toggleSettled(item.id);
          }
          _loadData();
        },
      ),
      title: Text(title, style: TextStyle(
        fontWeight: FontWeight.w500,
        decoration: (type == 'expense' && isChecked) ? TextDecoration.lineThrough : null,
      )),
      subtitle: Text(sub, style: const TextStyle(fontSize: 10)),
      trailing: Text('${amount.toInt()} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
      onLongPress: () => type == 'subs' ? _confirmDeleteSubscription(item) : _confirmDeleteTransaction(item),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'subs': return Icons.event_repeat;
      case 'expense': return Icons.remove_circle_outline;
      case 'income': return Icons.payments_outlined;
      case 'debt': return Icons.flag_outlined;
      case 'owed': return Icons.check_circle_outline;
      default: return Icons.money;
    }
  }

  FinanceType? _getFinanceType(String type) {
    switch (type) {
      case 'expense': return FinanceType.expense;
      case 'income': return FinanceType.income;
      case 'debt': return FinanceType.debt;
      case 'owed': return FinanceType.owed;
      default: return null;
    }
  }

  void _showAddTransactionDialog({FinanceTransaction? transaction, FinanceType? forcedType}) async {
    final isEdit = transaction != null;
    final amountController = TextEditingController(text: transaction?.amount.toInt().toString());
    final descController = TextEditingController(text: transaction?.description);
    
    FinanceType type = forcedType ?? transaction?.type ?? FinanceType.expense;
    String category = transaction?.category ?? 'أخرى';
    bool allocateForCharity = false;
    double charityPercent = 2.5;
    bool isSettled = transaction?.isSettled ?? true;
    Proximity proximity = transaction?.proximity ?? Proximity.near;
    Priority priority = transaction?.priority ?? Priority.normal;

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل معاملة' : 'إضافة معاملة مالية',
      content: StatefulBuilder(builder: (context, setModalState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (forcedType == null)
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
            CheckboxListTile(
              title: const Text('تمت المعاملة فعلياً؟', style: TextStyle(fontSize: 12)),
              subtitle: const Text('سيتم تفعيلها في الرصيد الحالي فوراً', style: TextStyle(fontSize: 10)),
              value: isSettled,
              onChanged: (v) => setModalState(() => isSettled = v!),
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
            if (type == FinanceType.debt || type == FinanceType.owed) ...[
              const Divider(),
              DropdownButtonFormField<Proximity>(
                value: proximity,
                items: const [
                  DropdownMenuItem(value: Proximity.near, child: Text('قريب (يجب سداده قريباً)')),
                  DropdownMenuItem(value: Proximity.far, child: Text('بعيد (أجل غير مسمى)')),
                ],
                onChanged: (v) => setModalState(() => proximity = v!),
                decoration: const InputDecoration(labelText: 'مدى الاستحقاق'),
              ),
            ],
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
                isSettled: isSettled,
                proximity: proximity,
                priority: priority,
              );
              
              if (isEdit) {
                await PersonalMattersService.updateTransaction(transaction, newTrans);
              } else {
                await PersonalMattersService.addTransaction(newTrans);
                
                if (type == FinanceType.income && allocateForCharity) {
                  final charityAmount = amount * (charityPercent / 100);
                  await PersonalMattersService.addTransaction(FinanceTransaction(
                    id: const Uuid().v4(),
                    amount: charityAmount,
                    type: FinanceType.expense,
                    category: 'صدقة',
                    description: 'صدقة مستقطعة من ( ${descController.text} )',
                    date: DateTime.now(),
                    isSettled: true,
                  ));
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

  String _getTypeLabel(FinanceType type) {
    switch(type) {
      case FinanceType.income: return 'دخل';
      case FinanceType.expense: return 'مصروف';
      case FinanceType.debt: return 'ديْن عليّ (سلف)';
      case FinanceType.owed: return 'حق لي (أطلب)';
    }
  }
}
