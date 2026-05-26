import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import 'models/health_models.dart';
import 'services/health_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  List<ChronicCondition> _conditions = [];
  List<GradualLabTest> _labTests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _conditions = HealthService.getConditions();
      _labTests = HealthService.getLabTests(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('رعاية 🛡️', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('الأمراض المزمنة والمتابعة', 'إضافة حالة', () => _showAddConditionDialog()),
          const SizedBox(height: 16),
          if (_conditions.isEmpty) 
            const Center(child: Text('لا توجد حالات مضافة', style: TextStyle(color: Colors.grey)))
          else
            ..._conditions.map((c) => _buildConditionCard(c, isDark)),
          
          const SizedBox(height: 32),
          _buildSectionHeader('التحاليل المتدرجة 🧪', 'جدولة جديد', () => _showAddLabTestDialog()),
          const SizedBox(height: 16),
          if (_labTests.isEmpty)
             const Center(child: Text('لا توجد تحاليل مجدولة', style: TextStyle(color: Colors.grey)))
          else
            ..._labTests.map((t) => _buildLabTestCard(t, isDark)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(color: Colors.blue, fontSize: 13))),
      ],
    );
  }

  Widget _buildConditionCard(ChronicCondition condition, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: ExpansionTile(
        title: Text(condition.conditionName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        subtitle: Text('المريض: ${condition.personName} • الوزن: ${condition.weight ?? "-"} • الطول: ${condition.height ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showAddConditionDialog(condition: condition)),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الأدوية الحالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton(onPressed: () => _showAddMedicineDialog(condition), child: const Text('إضافة دواء', style: TextStyle(fontSize: 11))),
                  ],
                ),
                ...condition.medicines.map((m) => _buildMedicineMiniRow(condition, m)),
                const Divider(height: 24),
                const Text('أعراض جانبية للمراقبة ⚠️:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                Wrap(
                  spacing: 8,
                  children: condition.sideEffects.map((se) => Chip(
                    label: Text(se, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.orange.withOpacity(0.1),
                  )).toList(),
                ),
                if (condition.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('ملاحظات: ${condition.notes}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => _confirmDeleteCondition(condition),
                    child: const Text('حذف الحالة نهائياً', style: TextStyle(color: Colors.red, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineMiniRow(ChronicCondition condition, Medicine m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.medication, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${m.dose} • ${m.instruction} • ${m.time.format(context)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddMedicineDialog(condition, medicine: m)),
          IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), onPressed: () => _deleteMedicine(condition, m)),
          Checkbox(
            value: m.status == MedicineStatus.taken, 
            onChanged: (v) {
              setState(() {
                m.status = v! ? MedicineStatus.taken : MedicineStatus.pending;
                HealthService.saveCondition(condition);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabTestCard(GradualLabTest test, bool isDark) {
    final nextDate = test.nextTestDate;
    final daysLeft = nextDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade700]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(test.testName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.add_chart, color: Colors.white, size: 20), onPressed: () => _showAddLabResultDialog(test)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20), onPressed: () => _deleteLabTest(test)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text('المرحلة ${test.currentIntervalIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
              const Spacer(),
              Text(
                daysLeft <= 0 ? 'موعد التحليل اليوم!' : 'باقي $daysLeft يوم',
                style: TextStyle(color: daysLeft <= 0 ? Colors.redAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (test.results.isNotEmpty) ...[
            const Text('تطور النتائج:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: test.results.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                      isCurved: true,
                      color: Colors.cyanAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('آخر نتيجة: ${test.results.last.value} (${intl.DateFormat('MM/dd').format(test.results.last.date)})', style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
          const SizedBox(height: 12),
          Text('السبب: ${test.reason}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 20),
          _buildProgressStepper(test.currentIntervalIndex, test.intervalsInDays.length),
          if (daysLeft <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    test.currentIntervalIndex++;
                    HealthService.saveLabTest(test);
                  });
                },
                child: const Text('تم إجراء التحليل - انتقل للمرحلة التالية'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper(int current, int total) {
    return Row(
      children: List.generate(total, (index) => Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index <= current ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }

  // --- Dialogs ---

  void _showAddConditionDialog({ChronicCondition? condition}) async {
    final nameController = TextEditingController(text: condition?.conditionName);
    final personController = TextEditingController(text: condition?.personName);
    final weightController = TextEditingController(text: condition?.weight?.toString());
    final heightController = TextEditingController(text: condition?.height?.toString());
    final notesController = TextEditingController(text: condition?.notes);

    ModernDialog.show(
      context: context,
      title: condition == null ? 'إضافة حالة مرضية' : 'تعديل الحالة',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: personController, decoration: const InputDecoration(labelText: 'اسم المريض')),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الحالة المرضية (مثل: صدفية)')),
            Row(
              children: [
                Expanded(child: TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كجم)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطول (سم)'))),
              ],
            ),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات إضافية')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty && personController.text.isNotEmpty) {
              final newCondition = ChronicCondition(
                id: condition?.id ?? const Uuid().v4(),
                personName: personController.text,
                conditionName: nameController.text,
                weight: double.tryParse(weightController.text),
                height: double.tryParse(heightController.text),
                notes: notesController.text,
                medicines: condition?.medicines ?? [],
                sideEffects: condition?.sideEffects ?? [],
              );
              await HealthService.saveCondition(newCondition);
              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _showAddMedicineDialog(ChronicCondition condition, {Medicine? medicine}) async {
    final nameController = TextEditingController(text: medicine?.name);
    final doseController = TextEditingController(text: medicine?.dose);
    final instrController = TextEditingController(text: medicine?.instruction);
    TimeOfDay time = medicine?.time ?? TimeOfDay.now();

    ModernDialog.show(
      context: context,
      title: medicine == null ? 'إضافة دواء' : 'تعديل دواء',
      content: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الدواء')),
            TextField(controller: doseController, decoration: const InputDecoration(labelText: 'الجرعة (مثل: حبة واحدة)')),
            TextField(controller: instrController, decoration: const InputDecoration(labelText: 'طريقة الاستخدام (مثل: بعد الغداء)')),
            ListTile(
              title: Text('موعد الدواء: ${time.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked != null) setModalState(() => time = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              final newMed = Medicine(
                id: medicine?.id ?? const Uuid().v4(),
                name: nameController.text,
                dose: doseController.text,
                instruction: instrController.text,
                hour: time.hour,
                minute: time.minute,
                status: medicine?.status ?? MedicineStatus.pending,
              );

              final updatedMedicines = List<Medicine>.from(condition.medicines);
              if (medicine != null) {
                final idx = updatedMedicines.indexWhere((m) => m.id == medicine.id);
                updatedMedicines[idx] = newMed;
              } else {
                updatedMedicines.add(newMed);
              }

              await HealthService.saveCondition(ChronicCondition(
                id: condition.id,
                personName: condition.personName,
                conditionName: condition.conditionName,
                weight: condition.weight,
                height: condition.height,
                medicines: updatedMedicines,
                sideEffects: condition.sideEffects,
                notes: condition.notes,
              ));

              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _showAddLabTestDialog() async {
    final nameController = TextEditingController();
    final reasonController = TextEditingController();
    final intervalsController = TextEditingController(text: '3, 7, 14, 30, 90, 180');

    ModernDialog.show(
      context: context,
      title: 'جدولة تحليل متدرج',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم التحليل (مثل: وظائف كبد)')),
          TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'سبب المتابعة')),
          TextField(controller: intervalsController, decoration: const InputDecoration(labelText: 'تدرج الأيام (مفصولة بفاصلة)', hintText: '3, 7, 14...')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              final intervals = intervalsController.text.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toList();
              final test = GradualLabTest(
                id: const Uuid().v4(),
                conditionId: '',
                testName: nameController.text,
                reason: reasonController.text,
                startDate: DateTime.now(),
                intervalsInDays: intervals.isEmpty ? [3, 7, 14, 30, 90, 180] : intervals,
              );
              await HealthService.saveLabTest(test);
              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('جدولة'),
        ),
      ],
    );
  }

  void _showAddLabResultDialog(GradualLabTest test) async {
    final valController = TextEditingController();

    ModernDialog.show(
      context: context,
      title: 'تسجيل نتيجة تحليل',
      content: TextField(controller: valController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرقم الناتج من التحليل')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (valController.text.isNotEmpty) {
              final val = double.tryParse(valController.text) ?? 0;
              final results = List<LabResult>.from(test.results);
              results.add(LabResult(date: DateTime.now(), value: val));
              
              await HealthService.saveLabTest(GradualLabTest(
                id: test.id,
                conditionId: test.conditionId,
                testName: test.testName,
                startDate: test.startDate,
                intervalsInDays: test.intervalsInDays,
                currentIntervalIndex: test.currentIntervalIndex,
                reason: test.reason,
                results: results,
              ));

              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _deleteMedicine(ChronicCondition condition, Medicine m) async {
    final updated = condition.medicines.where((med) => med.id != m.id).toList();
    await HealthService.saveCondition(ChronicCondition(
      id: condition.id,
      personName: condition.personName,
      conditionName: condition.conditionName,
      weight: condition.weight,
      height: condition.height,
      medicines: updated,
      sideEffects: condition.sideEffects,
      notes: condition.notes,
    ));
    _loadData();
  }

  void _confirmDeleteCondition(ChronicCondition c) async {
    final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف الحالة', message: 'هل أنت متأكد من حذف ${c.conditionName}؟ سيتم حذف كافة الأدوية المرتبطة بها.');
    if (confirm == true) {
      await HealthService.deleteCondition(c.id);
      _loadData();
    }
  }

  void _deleteLabTest(GradualLabTest test) async {
     await HealthService.deleteLabTest(test.id);
     _loadData();
  }
}
