import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/health_models.dart';
import 'services/health_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin, HelpFeatureMixin {
  late TabController _tabController;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkFirstTimeHelp(context, 'workout');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('التمارين والنشاط 🏋️'),
        actions: [
          buildHelpButton(
            context,
            title: 'شرح التمارين',
            description: 'هذا القسم لتنظيم نشاطك البدني:\n'
            '- أضف تمارين الكارديو أو تمارين البيت أو الجيم.\n'
            '- سجل الأوزان والعدات لكل تمرين.\n'
            '- تابع حرق السعرات اليومي من خلال نشاطك.',
            pageId: 'workout',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseDialog(WorkoutType.values[_tabController.index]),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'كارديو'),
            Tab(text: 'تمارين بيت'),
            Tab(text: 'تمارين جيم'),
          ],
        ),
      ),
      body: Column(
        children: [
          const QuickLinkNavigator(currentPageId: 'workout'),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExerciseList(WorkoutType.cardio),
                _buildExerciseList(WorkoutType.home),
                _buildExerciseList(WorkoutType.gym),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExerciseDialog(WorkoutType.values[_tabController.index]),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.fitness_center, color: AppTheme.accentGold),
        label: const Text('إضافة تمرين', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildExerciseList(WorkoutType type) {
    final exercises = HealthService.getExercises(type);
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('لا توجد تمارين ${_getTypeLabel(type)} مضافة', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        final dateKey = "${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}";
        final bool isDone = ex.completionLog[dateKey] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Checkbox(
              value: isDone,
              onChanged: (val) async {
                await HealthService.toggleCompletion(ex.id, _today);
                setState(() {});
              },
            ),
            title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_getExerciseSubtitle(ex)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showAddExerciseDialog(type, exercise: ex)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _confirmDeleteExercise(ex)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getExerciseSubtitle(WorkoutExercise ex) {
    if (ex.type == WorkoutType.cardio) {
      return '${ex.durationMinutes} دقيقة • ${ex.caloriesBurned?.toInt() ?? 0} سعرة';
    } else if (ex.type == WorkoutType.home) {
      return '${ex.sets} مجموعات • ${ex.reps} عدات';
    } else {
      return '${ex.sets} مجموعات • ${ex.reps} عدات • ${ex.weight} كجم';
    }
  }

  void _showAddExerciseDialog(WorkoutType type, {WorkoutExercise? exercise}) {
    final isEdit = exercise != null;
    final nameController = TextEditingController(text: exercise?.name);
    final setsController = TextEditingController(text: exercise?.sets?.toString());
    final repsController = TextEditingController(text: exercise?.reps?.toString());
    final weightController = TextEditingController(text: exercise?.weight?.toString());
    final durController = TextEditingController(text: exercise?.durationMinutes?.toString());
    final calController = TextEditingController(text: exercise?.caloriesBurned?.toString());

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل تمرين' : 'إضافة تمرين جديد',
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم التمرين')),
              if (type != WorkoutType.cardio) ...[
                Row(
                  children: [
                    Expanded(child: TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المجموعات'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العدات'))),
                  ],
                ),
                if (type == WorkoutType.gym)
                  TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كجم)')),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: TextField(controller: durController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة (دقيقة)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعرات المحروقة'))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              final newExercise = WorkoutExercise(
                id: exercise?.id ?? const Uuid().v4(),
                userId: UserService.currentUser!.id,
                name: nameController.text,
                type: type,
                sets: int.tryParse(setsController.text),
                reps: int.tryParse(repsController.text),
                weight: double.tryParse(weightController.text),
                durationMinutes: int.tryParse(durController.text),
                caloriesBurned: double.tryParse(calController.text),
                date: _today,
                completionLog: exercise?.completionLog ?? {},
              );
              await HealthService.saveExercise(newExercise);
              Navigator.pop(context);
              setState(() {});
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _confirmDeleteExercise(WorkoutExercise ex) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف التمرين', message: 'هل تريد حذف ${ex.name} نهائياً؟', isDestructive: true);
    if (res == true) {
      await HealthService.deleteExercise(ex.id);
      setState(() {});
    }
  }

  String _getTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.cardio: return 'كارديو';
      case WorkoutType.home: return 'تمارين بيت';
      case WorkoutType.gym: return 'تمارين جيم';
    }
  }
}
