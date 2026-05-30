import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models/personal_matters_models.dart';
import 'services/personal_matters_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';

class KhaznatiScreen extends StatefulWidget {
  const KhaznatiScreen({super.key});

  @override
  State<KhaznatiScreen> createState() => _KhaznatiScreenState();
}

class _KhaznatiScreenState extends State<KhaznatiScreen> {
  FinanceSummary _finSummary = FinanceSummary();
  List<FinanceTransaction> _transactions = [];
  List<Subscription> _subscriptions = [];
  String _currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
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
    return Scaffold(
      appBar: AppBar(title: const Text('خزنتي 💰'), centerTitle: true),
      body: Column(
        children: [
          const QuickLinkNavigator(currentPageId: 'khaznati'),
          _buildBalanceHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionCard('الاشتراكات الشهرية 🗓️', Colors.blue, _subscriptions, 'subs'),
                _buildSectionCard('المصروفات 💸', Colors.orange, _transactions.where((t) => t.type == FinanceType.expense).toList(), 'expense'),
                _buildSectionCard('الدخل 💰', Colors.green, _transactions.where((t) => t.type == FinanceType.income).toList(), 'income'),
                _buildSectionCard('الديون 🚩', Colors.red, _transactions.where((t) => t.type == FinanceType.debt).toList(), 'debt'),
                _buildSectionCard('الحقوق ✅', Colors.teal, _transactions.where((t) => t.type == FinanceType.owed).toList(), 'owed'),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade900, Colors.green.shade700]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('الرصيد الفعلي الحالي', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${_finSummary.currentBalance.toInt()} ج.م', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ]),
          const Icon(Icons.account_balance_wallet, color: Colors.white24, size: 40),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, Color color, List items, String type) {
    double total = 0;
    if (type == 'subs') {
      total = (items as List<Subscription>).fold(0, (a, b) => a + b.amount);
    } else {
      total = (items as List<FinanceTransaction>).fold(0, (a, b) => a + b.amount);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('الإجمالي: ${total.toInt()} ج', style: TextStyle(color: color, fontSize: 12)),
        trailing: TextButton(
          onPressed: () => type == 'subs' ? _showAddSubscriptionDialog() : _showAddTransactionDialog(forcedType: _getFinanceType(type)),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC8A24A))),
        ),
        children: items.map((item) => _buildItemRow(item, type)).toList(),
      ),
    );
  }

  Widget _buildItemRow(dynamic item, String type) {
    bool isChecked = false;
    String title = "";
    double amount = 0;
    List<String> details = [];

    if (type == 'subs') {
      final sub = item as Subscription;
      isChecked = sub.paidMonths.contains(_currentMonthKey);
      title = sub.name;
      amount = sub.amount;
    } else {
      final trans = item as FinanceTransaction;
      isChecked = trans.isSettled;
      title = trans.description;
      amount = trans.amount;
      details = trans.details;
    }

    return ListTile(
      leading: Checkbox(
        value: isChecked,
        onChanged: (_) async {
          if (type == 'subs') await PersonalMattersService.toggleSubscriptionMonth(item.id, _currentMonthKey);
          else await PersonalMattersService.toggleSettled(item.id);
          _loadData();
        },
      ),
      title: Text(title),
      subtitle: details.isNotEmpty ? Text(details.join(', '), style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${amount.toInt()} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (type != 'subs')
            TextButton(
              onPressed: () => _showAddDetailDialog(item as FinanceTransaction),
              child: const Text('إضافة', style: TextStyle(fontSize: 10, color: Colors.green)),
            ),
        ],
      ),
      onLongPress: () => _showItemOptions(item, type),
    );
  }

  void _showItemOptions(dynamic item, String type) {
    final screenContext = context;
    showModalBottomSheet(
      context: screenContext,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(modalContext);
                if (type == 'subs') {
                  _showAddSubscriptionDialog(sub: item as Subscription);
                } else {
                  _showAddTransactionDialog(trans: item as FinanceTransaction);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(modalContext);
                final confirm = await ModernDialog.showConfirm(
                  context: screenContext, 
                  title: 'حذف السجل', 
                  message: 'هل أنت متأكد من حذف هذا السجل؟',
                  confirmLabel: 'حذف',
                  isDestructive: true,
                );
                if (confirm == true) {
                  if (type == 'subs') await PersonalMattersService.deleteSubscription(item.id);
                  else await PersonalMattersService.deleteTransaction(item.id);
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
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

  void _showAddDetailDialog(FinanceTransaction trans) {
    final amountController = TextEditingController();
    final detailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة إلى: ${trans.description}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ الإضافي')),
            TextField(controller: detailController, decoration: const InputDecoration(labelText: 'التفصيل (مثلاً: أرز)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                double add = double.tryParse(amountController.text) ?? 0;
                String d = detailController.text.isNotEmpty ? "${detailController.text}: $add" : "إضافة: $add";
                await PersonalMattersService.addDetailsToTransaction(trans.id, add, d);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog({FinanceType? forcedType, FinanceTransaction? trans}) {
    final amountController = TextEditingController(text: trans?.amount.toInt().toString());
    final descController = TextEditingController(text: trans?.description);
    FinanceType type = trans?.type ?? forcedType ?? FinanceType.expense;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(trans == null ? 'إضافة معاملة' : 'تعديل معاملة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (forcedType == null)
                DropdownButton<FinanceType>(
                  value: type,
                  items: FinanceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (v) => setModalState(() => type = v!),
                ),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'الوصف')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty && descController.text.isNotEmpty) {
                  final t = FinanceTransaction(
                    id: trans?.id ?? const Uuid().v4(),
                    amount: double.tryParse(amountController.text) ?? 0,
                    type: type,
                    category: trans?.category ?? 'عام',
                    description: descController.text,
                    date: trans?.date ?? DateTime.now(),
                    isSettled: trans?.isSettled ?? false,
                    details: trans?.details ?? [],
                  );
                  if (trans == null) {
                    await PersonalMattersService.addTransaction(t);
                  } else {
                    await PersonalMattersService.updateTransaction(trans, t);
                  }
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubscriptionDialog({Subscription? sub}) {
    final nameController = TextEditingController(text: sub?.name);
    final amountController = TextEditingController(text: sub?.amount.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sub == null ? 'إضافة اشتراك' : 'تعديل اشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الخدمة')),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ الشهري')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final newSub = Subscription(
                  id: sub?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  startDate: sub?.startDate ?? DateTime.now(),
                  paidMonths: sub?.paidMonths ?? [],
                );
                await PersonalMattersService.saveSubscription(newSub);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
