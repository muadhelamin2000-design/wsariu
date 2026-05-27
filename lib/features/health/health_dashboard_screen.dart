import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import 'models/health_models.dart';
import 'services/health_service.dart';
import '../discipline/services/notification_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  List<PatientProfile> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAndResetMedicines();
  }

  void _loadData() {
    setState(() {
      _patients = HealthService.getPatients();
    });
  }

  void _checkAndResetMedicines() async {
    final allConditions = HealthService.getConditions(null);
    final now = DateTime.now();
    bool changed = false;

    for (var condition in allConditions) {
      final updatedMedicines = <Medicine>[];
      bool conditionChanged = false;

      for (var m in condition.medicines) {
        bool shouldReset = false;
        if (m.status == MedicineStatus.taken && m.lastTakenAt != null) {
          if (m.remindType == MedicineRemindType.fixed) {
            final lastReset = DateTime(m.lastTakenAt!.year, m.lastTakenAt!.month, m.lastTakenAt!.day, 4);
            final nextReset = lastReset.add(const Duration(days: 1));
            if (now.isAfter(nextReset)) shouldReset = true;
          } else {
            final intervalHours = 24 / m.frequencyPerDay;
            final nextDose = m.lastTakenAt!.add(Duration(minutes: (intervalHours * 60).toInt()));
            if (now.isAfter(nextDose)) shouldReset = true;
          }
        }

        if (shouldReset) {
          updatedMedicines.add(m.copyWith(status: MedicineStatus.pending));
          conditionChanged = true;
        } else {
          updatedMedicines.add(m);
        }
      }

      if (conditionChanged) {
        await HealthService.saveCondition(ChronicCondition(
          id: condition.id,
          patientId: condition.patientId,
          personName: condition.personName,
          conditionName: condition.conditionName,
          weight: condition.weight,
          height: condition.height,
          medicines: updatedMedicines,
          sideEffects: condition.sideEffects,
          notes: condition.notes,
        ));
        changed = true;
      }
    }
    if (changed) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('رعاية وشفاء 🛡️', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('سجلات المرضى', 'إضافة مريض', () => _showAddPatientDialog()),
          const SizedBox(height: 16),
          if (_patients.isEmpty) 
            const Center(child: Text('لا توجد سجلات مضافة', style: TextStyle(color: Colors.grey)))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
              itemCount: _patients.length,
              itemBuilder: (context, index) => _buildPatientCard(_patients[index], isDark),
            ),
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

  Widget _buildPatientCard(PatientProfile patient, bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDetailsScreen(patient: patient))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue.withOpacity(0.1),
              backgroundImage: patient.imagePath != null ? FileImage(File(patient.imagePath!)) : null,
              child: patient.imagePath == null ? const Icon(Icons.person, size: 35, color: Colors.blue) : null,
            ),
            const SizedBox(height: 12),
            Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${patient.age ?? "?"} سنة', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text('عرض السجل', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPatientDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String? imagePath;

    ModernDialog.show(
      context: context,
      title: 'إضافة ملف مريض',
      content: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) setModalState(() => imagePath = picked.path);
              },
              child: CircleAvatar(
                radius: 30,
                backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
                child: imagePath == null ? const Icon(Icons.camera_alt) : null,
              ),
            ),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المريض')),
            TextField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              final patient = PatientProfile(
                id: const Uuid().v4(),
                userId: HealthService.getProfile()?.userId ?? 'default',
                name: nameController.text,
                age: int.tryParse(ageController.text),
                imagePath: imagePath,
              );
              await HealthService.savePatient(patient);
              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class PatientDetailsScreen extends StatefulWidget {
  final PatientProfile patient;
  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  List<ChronicCondition> _conditions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _conditions = HealthService.getConditions(widget.patient.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoBar(isDark),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الأمراض والحالات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton(onPressed: _showAddConditionDialog, child: const Text('إضافة حالة')),
            ],
          ),
          if (_conditions.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('لا توجد حالات مسجلة', style: TextStyle(color: Colors.grey))))
          else
            ..._conditions.map((c) => _buildConditionCard(c, isDark)),
        ],
      ),
    );
  }

  Widget _buildInfoBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: widget.patient.imagePath != null ? FileImage(File(widget.patient.imagePath!)) : null),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('العمر: ${widget.patient.age ?? "?"} | الوزن: ${widget.patient.weight ?? "?"} كجم', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(ChronicCondition condition, bool isDark) {
    final tests = HealthService.getLabTests(condition.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: Text(condition.conditionName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الأدوية والمواعيد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...condition.medicines.map((m) => _buildMedicineRow(condition, m)),
                TextButton(onPressed: () => _showAddMedicineDialog(condition), child: const Text('+ إضافة دواء', style: TextStyle(fontSize: 11))),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('التحاليل والتطور:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton(onPressed: () => _showAddLabTestDialog(condition.id), child: const Text('+ جدولة تحليل', style: TextStyle(fontSize: 11))),
                  ],
                ),
                ...tests.map((t) => _buildTestMiniCard(t)),
                const SizedBox(height: 16),
                Center(child: TextButton(onPressed: () => _deleteCondition(condition), child: const Text('حذف الحالة', style: TextStyle(color: Colors.red, fontSize: 11)))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMedicineRow(ChronicCondition condition, Medicine m) {
    String timeText = m.remindType == MedicineRemindType.fixed ? m.time.format(context) : 'كل ${24 ~/ m.frequencyPerDay} ساعات';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.medication, size: 20, color: Colors.blue),
      title: Text(m.name, style: const TextStyle(fontSize: 13)),
      subtitle: Text('${m.dose} • $timeText', style: const TextStyle(fontSize: 10)),
      trailing: Checkbox(
        value: m.status == MedicineStatus.taken,
        onChanged: (v) async {
          final updatedMed = m.copyWith(status: v! ? MedicineStatus.taken : MedicineStatus.pending, lastTakenAt: v ? DateTime.now() : null);
          final meds = List<Medicine>.from(condition.medicines);
          meds[meds.indexWhere((item) => item.id == m.id)] = updatedMed;
          await HealthService.saveCondition(ChronicCondition(
            id: condition.id, patientId: condition.patientId, personName: condition.personName,
            conditionName: condition.conditionName, medicines: meds, notes: condition.notes,
          ));
          if (v && updatedMed.remindType == MedicineRemindType.interval) {
             final nextTime = DateTime.now().add(Duration(minutes: (24 / updatedMed.frequencyPerDay * 60).toInt()));
             await NotificationService.scheduleNotification(id: updatedMed.id.hashCode.abs(), title: '⏰ موعد دواء: ${updatedMed.name}', body: 'حان موعد جرعة ${updatedMed.dose}', time: nextTime);
          }
          _loadData();
        },
      ),
    );
  }

  Widget _buildTestMiniCard(GradualLabTest test) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(test.testName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_chart, size: 16), onPressed: () => _showAddLabResultDialog(test)),
            ],
          ),
          if (test.results.isNotEmpty)
            SizedBox(
              height: 60,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
                lineBarsData: [LineChartBarData(spots: test.results.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(), isCurved: true, color: Colors.blue, barWidth: 2)],
              )),
            ),
        ],
      ),
    );
  }

  void _showAddConditionDialog() {
    final nameController = TextEditingController();
    ModernDialog.show(
      context: context,
      title: 'إضافة حالة للمريض',
      content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الحالة')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (nameController.text.isNotEmpty) {
            final c = ChronicCondition(id: const Uuid().v4(), patientId: widget.patient.id, personName: widget.patient.name, conditionName: nameController.text);
            await HealthService.saveCondition(c);
            Navigator.pop(context);
            _loadData();
          }
        }, child: const Text('حفظ')),
      ],
    );
  }

  void _showAddMedicineDialog(ChronicCondition condition) {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final freqController = TextEditingController(text: '1');
    TimeOfDay time = TimeOfDay.now();
    MedicineRemindType remindType = MedicineRemindType.fixed;

    ModernDialog.show(
      context: context,
      title: 'إضافة دواء',
      content: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الدواء')),
            TextField(controller: doseController, decoration: const InputDecoration(labelText: 'الجرعة')),
            DropdownButtonFormField<MedicineRemindType>(
              value: remindType,
              items: const [DropdownMenuItem(value: MedicineRemindType.fixed, child: Text('وقت ثابت')), DropdownMenuItem(value: MedicineRemindType.interval, child: Text('تكرار يومي'))],
              onChanged: (v) => setModalState(() => remindType = v!),
              decoration: const InputDecoration(labelText: 'النوع'),
            ),
            if (remindType == MedicineRemindType.fixed)
              ListTile(title: Text('الموعد: ${time.format(context)}'), trailing: const Icon(Icons.access_time), onTap: () async {
                final p = await showTimePicker(context: context, initialTime: time);
                if (p != null) setModalState(() => time = p);
              })
            else
              TextField(controller: freqController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مرات في اليوم')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (nameController.text.isNotEmpty) {
            final m = Medicine(id: const Uuid().v4(), name: nameController.text, dose: doseController.text, hour: time.hour, minute: time.minute, frequencyPerDay: int.tryParse(freqController.text) ?? 1, remindType: remindType);
            final meds = List<Medicine>.from(condition.medicines)..add(m);
            await HealthService.saveCondition(ChronicCondition(id: condition.id, patientId: condition.patientId, personName: condition.personName, conditionName: condition.conditionName, medicines: meds));
            if (remindType == MedicineRemindType.fixed) {
               await NotificationService.scheduleNotification(id: m.id.hashCode.abs(), title: '⏰ دواء: ${m.name}', body: 'جرعة ${m.dose}', time: TimeOfDay(hour: m.hour, minute: m.minute));
            }
            Navigator.pop(context);
            _loadData();
          }
        }, child: const Text('حفظ')),
      ],
    );
  }

  void _showAddLabTestDialog(String conditionId) {
    final nameController = TextEditingController();
    ModernDialog.show(
      context: context,
      title: 'جدولة تحليل',
      content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم التحليل')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (nameController.text.isNotEmpty) {
            await HealthService.saveLabTest(GradualLabTest(id: const Uuid().v4(), conditionId: conditionId, testName: nameController.text, startDate: DateTime.now()));
            Navigator.pop(context);
            _loadData();
          }
        }, child: const Text('جدولة')),
      ],
    );
  }

  void _showAddLabResultDialog(GradualLabTest test) {
    final valController = TextEditingController();
    ModernDialog.show(
      context: context,
      title: 'تسجيل نتيجة',
      content: TextField(controller: valController, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (valController.text.isNotEmpty) {
            final results = List<LabResult>.from(test.results)..add(LabResult(date: DateTime.now(), value: double.parse(valController.text)));
            await HealthService.saveLabTest(GradualLabTest(id: test.id, conditionId: test.conditionId, testName: test.testName, startDate: test.startDate, results: results));
            Navigator.pop(context);
            _loadData();
          }
        }, child: const Text('حفظ')),
      ],
    );
  }

  void _deleteCondition(ChronicCondition c) async {
    final confirm = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'حذف الحالة؟');
    if (confirm == true) { await HealthService.deleteCondition(c.id); _loadData(); }
  }
}
