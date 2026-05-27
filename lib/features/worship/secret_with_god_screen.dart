import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/secret_model.dart';
import 'services/secret_service.dart';
import '../profile/services/user_service.dart';
import '../personal_matters/services/personal_matters_service.dart';
import '../personal_matters/models/personal_matters_models.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';

import '../../core/mixins/help_feature_mixin.dart';

class SecretWithGodScreen extends StatefulWidget {
  const SecretWithGodScreen({super.key});

  @override
  State<SecretWithGodScreen> createState() => _SecretWithGodScreenState();
}

class _SecretWithGodScreenState extends State<SecretWithGodScreen> with SingleTickerProviderStateMixin, HelpFeatureMixin {
  late TabController _tabController;
  bool _globalBlur = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _globalBlur = SecretService.getBlurSetting();
    checkFirstTimeHelp(context, 'secret_with_god');
  }

  void _toggleBlur() async {
    setState(() => _globalBlur = !_globalBlur);
    await SecretService.saveBlurSetting(_globalBlur);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سر مع الله (أعمال الخفاء)'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح سر مع الله', 
            description: 'أعمال الخفاء هي زاد القلوب وسبيل الإخلاص:\n'
            '- دون هنا أعمالك الصالحة التي لا يعلم بها أحد غير الله.\n'
            '- سجل أحلامك وطموحاتك التي تسعى إليها لله.\n'
            '- التطبيق يوفر وضع "التمويه" (Blur) لحماية خصوصيتك عند فتح الصفحة.'
          ),
          IconButton(
            icon: Icon(_globalBlur ? Icons.visibility_off : Icons.visibility),
            onPressed: _toggleBlur,
            tooltip: 'إخفاء النصوص',
          ),
          TextButton(
            onPressed: () {
              if (_tabController.index == 0) {
                 _showAddEntryDialog(SecretType.dua, 'قسم الدعاء');
              } else {
                 _showAddCharityDialog();
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'خبايا الروح'),
            Tab(text: 'الصدقة الشهرية'),
          ],
        ),
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'secret'),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSecretEntriesTab(),
                _buildCharityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Secret Entries Tab ---
  Widget _buildSecretEntriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('قسم الدعاء', 'اجعلها خالصة لله', SecretType.dua),
        _buildSectionHeader('الأعمال الخفية', 'أخفِها تُرفع', SecretType.hiddenDeed),
        _buildSectionHeader('مواقف وخواطر', 'ما كان لله دام', SecretType.thought),
        _buildSectionHeader('التعاهد مع الله', 'صدق النية أصل القبول', SecretType.covenant),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String message, SecretType type) {
    final entries = SecretService.getEntries(type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                Text(message, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
              ],
            ),
            TextButton(
              onPressed: () => _showAddEntryDialog(type, title),
              child: const Text('إضافة', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text('لا يوجد مدخلات بعد...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ...entries.map((e) => _buildEntryCard(e)),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildEntryCard(SecretEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: _globalBlur ? 5 : 0, sigmaY: _globalBlur ? 5 : 0),
          child: Text(entry.content),
        ),
        subtitle: Text(DateFormat('yyyy/MM/dd').format(entry.date), style: const TextStyle(fontSize: 10)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: () async {
            await SecretService.deleteEntry(entry.id);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showAddEntryDialog(SecretType type, String title) async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إضافة إلى $title',
      hint: 'اكتب هنا ما يرضي الله...',
    );
    if (result != null && result.isNotEmpty) {
      final entry = SecretEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: UserService.currentUser!.id,
        type: type,
        content: result,
        date: DateTime.now(),
      );
      await SecretService.saveEntry(entry);
      if (mounted) setState(() {});
    }
  }

  // --- Charity Tab ---
  Widget _buildCharityTab() {
    final months = SecretService.getCharityMonths();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _showAddCharityDialog,
            child: const Text('إضافة شهر جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              return _buildCharityCard(month);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharityCard(CharityMonth month) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(month.monthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: month.isExecuted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    month.isExecuted ? 'تم الإخراج ✅' : 'نويت فقط ⏳',
                    style: TextStyle(color: month.isExecuted ? Colors.green : Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: _globalBlur ? 5 : 0, sigmaY: _globalBlur ? 5 : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCharityStat('الدخل', '${month.income.toInt()}'),
                  _buildCharityStat('النسبة', '${month.percentage.toInt()}%'),
                  _buildCharityStat('الصدقة', '${month.amount.toInt()}', color: AppTheme.primaryGreen),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!month.isExecuted)
              ElevatedButton(
            onPressed: () async {
                  final updated = CharityMonth(
                    id: month.id,
                    userId: month.userId,
                    monthLabel: month.monthLabel,
                    income: month.income,
                    percentage: month.percentage,
                    createdAt: month.createdAt,
                    isExecuted: true,
                  );
                  await SecretService.saveCharityMonth(updated);
                  
                  // إضافة معاملة لصفحة خزنتي
                  final charityAmount = (month.income * month.percentage / 100);
                  await PersonalMattersService.addTransaction(FinanceTransaction(
                    id: 'charity_${month.id}',
                    amount: charityAmount,
                    type: FinanceType.expense,
                    category: 'صدقة',
                    description: 'صدقة شهر ${month.monthLabel} (من سر مع الله)',
                    date: DateTime.now(),
                    isSettled: true,
                  ));

                  setState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                child: const Text('تم إخراج الصدقة'),
              ),
            TextButton(
              onPressed: () async {
                final confirm = await ModernDialog.showConfirm(
                  context: context,
                  title: 'حذف السجل',
                  message: 'هل أنت متأكد من حذف سجل الصدقة هذا؟',
                  confirmLabel: 'حذف',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await SecretService.deleteCharityMonth(month.id);
                  // حذف المعاملة المرتبطة من خزنتي إذا وجدت
                  await PersonalMattersService.deleteTransaction('charity_${month.id}');
                  setState(() {});
                }
              },
              child: const Text('حذف السجل', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharityStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  void _showAddCharityDialog() {
    final currentBalance = PersonalMattersService.getFinanceSummary().currentBalance;
    String monthLabel = DateFormat('MMMM yyyy', 'ar_SA').format(DateTime.now());
    double income = currentBalance > 0 ? currentBalance : 0;
    double selectedPercentage = 2.5; 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final monthController = TextEditingController(text: monthLabel);
    final incomeController = TextEditingController(text: income > 0 ? income.toInt().toString() : '');

    ModernDialog.show(
      context: context,
      title: 'إعداد صدقة الشهر',
      accentColor: AppTheme.primaryGreen,
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الرصيد المتاح في خزنتي: ${currentBalance.toInt()} ج',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'الشهر', 
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
                controller: monthController,
                onChanged: (val) => monthLabel = val,
              ),
              const SizedBox(height: 16),
              TextField(
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'المبلغ المحتسب (الدخل)', 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.money),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  hintText: 'سيتم احتساب النسبة من هذا المبلغ',
                ),
                controller: incomeController,
                keyboardType: TextInputType.number,
                onChanged: (val) => setModalState(() => income = double.tryParse(val) ?? 0),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('اختر النسبة', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  Text('${selectedPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: selectedPercentage,
                min: 0.5,
                max: 100.0,
                divisions: 199, // يسمح بالتحرك بزيادة 0.5
                label: '${selectedPercentage.toStringAsFixed(1)}%',
                activeColor: AppTheme.primaryGreen,
                inactiveColor: AppTheme.primaryGreen.withOpacity(0.2),
                onChanged: (val) => setModalState(() => selectedPercentage = val),
              ),
              Wrap(
                spacing: 8,
                children: [2.5, 5.0, 10.0].map((p) => ActionChip(
                  label: Text('%$p', style: const TextStyle(fontSize: 10)),
                  onPressed: () => setModalState(() => selectedPercentage = p),
                  backgroundColor: selectedPercentage == p ? AppTheme.primaryGreen.withOpacity(0.2) : null,
                )).toList(),
              ),
              const SizedBox(height: 20),
              if (income > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('المبلغ المستقطع لله:', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                      Text('${(income * selectedPercentage / 100).toInt()}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppTheme.primaryGreen)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () async {
            if (income <= 0) return;
            final month = CharityMonth(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: UserService.currentUser!.id,
              monthLabel: monthLabel,
              income: income,
              percentage: selectedPercentage,
              createdAt: DateTime.now(),
            );
            await SecretService.saveCharityMonth(month);
            if (mounted) {
              Navigator.pop(context);
              setState(() {});
            }
          },
          child: const Text('تأكيد وحفظ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
