import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'models/health_models.dart';
import 'services/health_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
    _tabController.addListener(() {
      if (mounted) setState(() {}); 
    });
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
          TextButton(
            onPressed: () => _showAddExerciseDialog(WorkoutType.values[_tabController.index]),
            child: const Text('إضافة تمرين', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
          if (_tabController.index == 0) _buildBurnSummary(),
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
    );
  }

  Widget _buildBurnSummary() {
    final burn = HealthService.calculateDailyBurn(_today);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange),
          const SizedBox(width: 8),
          Text('حرق الكارديو التقريبي: ${burn.toInt()} سعرة', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExerciseList(WorkoutType type) {
    final allExercises = HealthService.getExercises(type);
    
    if (allExercises.isEmpty) {
      return const Center(child: Text('لا توجد تمارين مضافة', style: TextStyle(color: Colors.grey)));
    }

    if (type == WorkoutType.cardio) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allExercises.length,
        itemBuilder: (context, index) => _buildExerciseCard(allExercises[index], type),
      );
    }

    // Grouping by Muscle Group
    final groups = <String, List<WorkoutExercise>>{};
    for (var ex in allExercises) {
      final g = ex.muscleGroup ?? 'أخرى';
      groups.putIfAbsent(g, () => []).add(ex);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groups.entries.map((entry) => _buildMuscleGroupSection(entry.key, entry.value, type)).toList(),
    );
  }

  Widget _buildMuscleGroupSection(String group, List<WorkoutExercise> exercises, WorkoutType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(group, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        ),
        ...exercises.map((ex) => _buildExerciseCard(ex, type)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutExercise ex, WorkoutType type) {
    final dateKey = "${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}";
    final bool isDone = ex.completionLog[dateKey] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Checkbox(
          value: isDone,
          onChanged: (val) async {
            await HealthService.toggleCompletion(ex.id, _today);
            setState(() {});
          },
        ),
        title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_getExerciseSubtitle(ex)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ex.notes.isNotEmpty) Text('ملاحظات: ${ex.notes}', style: const TextStyle(fontSize: 12)),
                if (ex.imagePath != null) Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: InkWell(
                    onTap: () => _showImageDialog(ex.imagePath!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.file(File(ex.imagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(30)),
                            child: const Icon(Icons.fullscreen, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (ex.videoPath != null) Padding(
                   padding: const EdgeInsets.only(top: 8),
                   child: InkWell(
                     onTap: () => context.push('/video-library/video-player', extra: {'path': ex.videoPath, 'name': ex.name}),
                     child: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.blue.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.blue.withOpacity(0.3)),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.play_circle_fill, size: 30, color: Colors.blue),
                           const SizedBox(width: 12),
                           Expanded(child: Text('تشغيل الفيديو التوضيحي', style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                           const Icon(Icons.chevron_right, color: Colors.blue),
                         ],
                       ),
                     ),
                   ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showAddExerciseDialog(type, exercise: ex)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDeleteExercise(ex)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
            InteractiveViewer(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(path)))),
          ],
        ),
      ),
    );
  }

  String _getExerciseSubtitle(WorkoutExercise ex) {
    if (ex.type == WorkoutType.cardio) {
      return '${ex.durationMinutes} دقيقة • ${ex.caloriesBurned?.toInt() ?? 0} سعرة';
    } else {
      String s = '${ex.sets} مجموعات • ${ex.reps} عدات';
      if (ex.weight != null) s += ' • ${ex.weight} كجم';
      return s;
    }
  }

  void _showAddExerciseDialog(WorkoutType type, {WorkoutExercise? exercise}) async {
    final isEdit = exercise != null;
    final nameController = TextEditingController(text: exercise?.name);
    final setsController = TextEditingController(text: exercise?.sets?.toString());
    final repsController = TextEditingController(text: exercise?.reps?.toString());
    final weightController = TextEditingController(text: exercise?.weight?.toString());
    final durController = TextEditingController(text: exercise?.durationMinutes?.toString());
    final notesController = TextEditingController(text: exercise?.notes);
    
    String selectedMuscleGroup = exercise?.muscleGroup ?? 'صدر';
    String? imagePath = exercise?.imagePath;
    String? videoPath = exercise?.videoPath;

    await ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل تمرين' : 'إضافة تمرين',
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم التمرين')),
              if (type != WorkoutType.cardio) ...[
                DropdownButtonFormField<String>(
                  value: selectedMuscleGroup,
                  items: ['صدر', 'ظهر', 'أكتاف', 'ذراع', 'أرجل', 'بطن', 'أخرى'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setModalState(() => selectedMuscleGroup = v!),
                  decoration: const InputDecoration(labelText: 'العضلة الرئيسية'),
                ),
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
                TextField(controller: durController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة بالدقائق')),
              ],
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات')),
              const Divider(),
              ListTile(
                title: const Text('صورة توضيحية', style: TextStyle(fontSize: 13)),
                trailing: Icon(imagePath != null ? Icons.check_circle : Icons.image, color: imagePath != null ? Colors.green : Colors.grey),
                onTap: () async {
                   final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                   if (picked != null) setModalState(() => imagePath = picked.path);
                },
              ),
              ListTile(
                title: const Text('فيديو توضيحي', style: TextStyle(fontSize: 13)),
                trailing: Icon(videoPath != null ? Icons.check_circle : Icons.video_library, color: videoPath != null ? Colors.green : Colors.grey),
                onTap: () async {
                   final result = await FilePicker.pickFiles(type: FileType.video);
                   if (result != null) setModalState(() => videoPath = result.files.single.path);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty) {
              int mins = int.tryParse(durController.text) ?? 0;
              final newExercise = WorkoutExercise(
                id: exercise?.id ?? const Uuid().v4(),
                userId: UserService.currentUser!.id,
                name: nameController.text,
                type: type,
                muscleGroup: type == WorkoutType.cardio ? 'كارديو' : selectedMuscleGroup,
                sets: int.tryParse(setsController.text),
                reps: int.tryParse(repsController.text),
                weight: double.tryParse(weightController.text),
                durationMinutes: mins,
                caloriesBurned: type == WorkoutType.cardio ? (mins * 7.0) : (int.tryParse(setsController.text) ?? 0) * 5.0,
                notes: notesController.text,
                imagePath: imagePath,
                videoPath: videoPath,
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
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف', message: 'حذف التمرين؟', isDestructive: true);
    if (res == true) { await HealthService.deleteExercise(ex.id); setState(() {}); }
  }
}
