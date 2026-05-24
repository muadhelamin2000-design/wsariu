import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'models/progress_goal_model.dart';
import 'services/progress_service.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';
import '../profile/services/user_service.dart';

import '../../core/mixins/help_feature_mixin.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with HelpFeatureMixin {
  List<ProgressGoal> _goals = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    setState(() {
      _goals = ProgressService.getGoals();
    });
  }

  void _showAddGoalSheet({ProgressGoal? goal}) {
    final isEdit = goal != null;
    final titleController = TextEditingController(text: goal?.title ?? '');
    final emojiController = TextEditingController(text: goal?.emoji ?? '🎯');
    final typeController = TextEditingController(text: goal?.type ?? '');
    final totalController = TextEditingController(text: goal?.totalValue.toInt().toString() ?? '100');
    final currentController = TextEditingController(text: goal?.currentValue.toInt().toString() ?? '0');
    
    String? imagePath = goal?.imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'تعديل الهدف' : 'تدوين هدف جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: emojiController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(labelText: 'أيقونة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'اسم الهدف', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'نوع الهدف (نوم، كتاب، كورس...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: currentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القيمة الحالية'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: totalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الإجمالي (الهدف)'))),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setSheetState(() => imagePath = image.path);
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(imagePath!), fit: BoxFit.cover)),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => imagePath = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.delete, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey), Text('إضافة صورة غلاف', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty || UserService.currentUser == null) return;
                      final newGoal = ProgressGoal(
                        id: goal?.id ?? const Uuid().v4(),
                        userId: UserService.currentUser!.id,
                        title: titleController.text,
                        type: typeController.text.isEmpty ? 'عام' : typeController.text,
                        emoji: emojiController.text,
                        imagePath: imagePath,
                        totalValue: double.tryParse(totalController.text) ?? 100,
                        currentValue: double.tryParse(currentController.text) ?? 0,
                        createdAt: goal?.createdAt ?? DateTime.now(),
                        lastUpdate: DateTime.now(),
                      );
                      await ProgressService.saveGoal(newGoal);
                      Navigator.pop(context);
                      _loadGoals();
                    },
                    child: const Text('حفظ'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('progress');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const Text('متابعة التقدم'),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح متابعة التقدم', 
            description: 'راقب نمو شخصيتك وإنجازاتك:\n'
            '- الرسوم البيانية توضح مدى التزامك بالعادات والعبادات.\n'
            '- ميزان النفس يظهر التوازن بين الأعمال الإيجابية والسلبية.\n'
            '- قارن أداءك بين الأسابيع المختلفة لتتحسن باستمرار.',
            pageId: 'progress',
          ),
          TextButton(
            onPressed: () => _showAddGoalSheet(),
            child: const Text('إضافة هدف', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(),
        label: const Text('إضافة'),
      ),
      body: Column(
        children: [
          QuickLinkNavigator(currentPageId: 'progress'),
          Expanded(
            child: _goals.isEmpty
                ? const Center(child: Text('ابدأ بتدوين أول أهدافك اليوم!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return _buildGoalCard(goal);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ProgressGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          if (goal.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.file(File(goal.imagePath!), height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(goal.type, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _showAddGoalSheet(goal: goal)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(goal.id)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('التقدم: ${(goal.progressPercentage * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: goal.statusColor)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${goal.currentValue.toInt()} / ${goal.totalValue.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(goal.remainingMessage, style: TextStyle(color: goal.statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: goal.progressPercentage,
                    minHeight: 10,
                    backgroundColor: goal.statusColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(goal.statusColor),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: goal.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: goal.statusColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(goal.insightMessage, style: TextStyle(fontSize: 12, color: goal.statusColor, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: goal.statusColor, side: BorderSide(color: goal.statusColor)),
                      onPressed: () => _showAddQuantityDialog(goal),
                      child: const Text('كمية مخصصة'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: goal.statusColor, foregroundColor: Colors.white),
                      onPressed: () => _updateGoalProgress(goal, goal.currentValue + 1),
                      child: const Text('1'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showSubtractQuantityDialog(goal),
                      child: const Text('خصم كمية'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _updateGoalProgress(goal, goal.currentValue - 1),
                      child: const Text('خصم 1'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateGoalProgress(ProgressGoal goal, double newCurrentValue) async {
    final updatedGoal = goal.copyWith(currentValue: newCurrentValue < 0 ? 0 : newCurrentValue, lastUpdate: DateTime.now());
    await ProgressService.saveGoal(updatedGoal);
    _loadGoals();
  }

  void _showAddQuantityDialog(ProgressGoal goal) async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إضافة كمية',
      hint: 'أدخل الكمية المنجزة',
    );
    if (result != null) {
      final quantity = double.tryParse(result);
      if (quantity != null && quantity > 0) {
        _updateGoalProgress(goal, goal.currentValue + quantity);
      }
    }
  }

  void _showSubtractQuantityDialog(ProgressGoal goal) async {
    final result = await ModernDialog.showInput(
      context: context,
      title: 'إنقاص كمية',
      hint: 'أدخل الكمية المراد خصمها',
    );
    if (result != null) {
      final quantity = double.tryParse(result);
      if (quantity != null && quantity > 0) {
        _updateGoalProgress(goal, goal.currentValue - quantity);
      }
    }
  }

  void _confirmDelete(String id) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: 'حذف الهدف',
      message: 'هل أنت متأكد من حذف هذا الهدف وسجل تقدمه نهائياً؟',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (result == true) {
      await ProgressService.deleteGoal(id);
      _loadGoals();
    }
  }
}
