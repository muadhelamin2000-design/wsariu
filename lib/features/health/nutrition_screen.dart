import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_theme.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../profile/services/user_service.dart';
import 'models/health_models.dart';
import 'services/health_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  UserHealthProfile? _profile;
  List<FoodEntry> _entries = [];
  Map<String, double> _targets = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final profile = HealthService.getProfile();
    final entries = HealthService.getFoodEntries(DateTime.now());
    setState(() {
      _profile = profile;
      _entries = entries;
      if (profile != null) {
        _targets = HealthService.calculateTargets(profile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('التغذية والماكروز 🍎', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _showProfileSetup,
            ),
        ],
      ),
      body: _profile == null ? _buildSetupPrompt() : _buildDashboard(isDark),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calculate_outlined, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text('احسب احتياجك اليومي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('أدخل بياناتك لنقوم بحساب السعرات والماكروز المناسبة لهدفك', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _showProfileSetup,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text('بدء الإعداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    double consumedCals = 0;
    double consumedProtein = 0;
    double consumedCarbs = 0;
    double consumedFats = 0;

    for (var entry in _entries) {
      consumedCals += entry.calories;
      consumedProtein += entry.protein;
      consumedCarbs += entry.carbs;
      consumedFats += entry.fats;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTargetCard(consumedCals, consumedProtein, consumedCarbs, consumedFats, isDark),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'إضافة وجبة سريعة',
                Icons.fastfood_outlined,
                Colors.orange,
                _showAddMealDialog,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'وجبات متكررة',
                Icons.replay_outlined,
                Colors.green,
                _showTemplatesDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('وجبات اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        if (_entries.isEmpty)
          const Center(child: Text('لم يتم إضافة وجبات اليوم بعد', style: TextStyle(color: Colors.grey)))
        else
          ..._entries.map((e) => _buildFoodEntryCard(e, isDark)),
      ],
    );
  }

  Widget _buildTargetCard(double cals, double protein, double carbs, double fats, bool isDark) {
    final targetCals = _targets['calories'] ?? 2000;
    final targetProtein = _targets['protein'] ?? 150;
    final targetCarbs = _targets['carbs'] ?? 200;
    final targetFats = _targets['fats'] ?? 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroInfo('السعرات', cals, targetCals, 'سعرة'),
              _buildCircularProgress(cals, targetCals),
            ],
          ),
          const Divider(color: Colors.white24, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroSmall('بروتين', protein, targetProtein),
              _buildMacroSmall('كارب', carbs, targetCarbs),
              _buildMacroSmall('دهون', fats, targetFats),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, double current, double target, String unit) {
    final remaining = target - current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text('${current.toInt()} / ${target.toInt()} $unit', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(remaining > 0 ? 'المتبقي: ${remaining.toInt()}' : 'تجاوزت الهدف بـ ${(remaining * -1).toInt()}', 
          style: TextStyle(color: remaining > 0 ? Colors.white60 : Colors.redAccent, fontSize: 12)),
      ],
    );
  }

  Widget _buildCircularProgress(double current, double target) {
    double progress = current / target;
    if (progress > 1.0) progress = 1.0;
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Center(child: Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildMacroSmall(String label, double current, double target) {
    double progress = current / target;
    if (progress > 1.0) progress = 1.0;
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.orange : Colors.cyanAccent),
          ),
        ),
        const SizedBox(height: 4),
        Text('${current.toInt()}g / ${target.toInt()}g', style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodEntryCard(FoodEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('كـ: ${entry.calories.toInt()} | ب: ${entry.protein.toInt()} | ك: ${entry.carbs.toInt()} | د: ${entry.fats.toInt()}', 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () async {
              await HealthService.deleteFood(entry.id);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  void _showProfileSetup() {
    final weightController = TextEditingController(text: _profile?.weight.toString());
    final heightController = TextEditingController(text: _profile?.height.toString());
    final ageController = TextEditingController(text: _profile?.age.toString());
    Gender gender = _profile?.gender ?? Gender.male;
    ActivityLevel activity = _profile?.activityLevel ?? ActivityLevel.moderate;
    HealthGoal goal = _profile?.goal ?? HealthGoal.maintain;

    ModernDialog.show(
      context: context,
      title: 'إعداد الملف الصحي',
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<Gender>(
                value: gender,
                decoration: const InputDecoration(labelText: 'الجنس'),
                items: const [
                  DropdownMenuItem(value: Gender.male, child: Text('ذكر')),
                  DropdownMenuItem(value: Gender.female, child: Text('أنثى')),
                ],
                onChanged: (v) => setModalState(() => gender = v!),
              ),
              TextField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر')),
              TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كجم)')),
              TextField(controller: heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطول (سم)')),
              DropdownButtonFormField<ActivityLevel>(
                value: activity,
                decoration: const InputDecoration(labelText: 'مستوى النشاط'),
                items: const [
                  DropdownMenuItem(value: ActivityLevel.sedentary, child: Text('خامل (مكتب)')),
                  DropdownMenuItem(value: ActivityLevel.light, child: Text('نشاط خفيف (مشى)')),
                  DropdownMenuItem(value: ActivityLevel.moderate, child: Text('نشاط متوسط (تمرين 3-5 أيام)')),
                  DropdownMenuItem(value: ActivityLevel.active, child: Text('نشط جداً')),
                ],
                onChanged: (v) => setModalState(() => activity = v!),
              ),
              DropdownButtonFormField<HealthGoal>(
                value: goal,
                decoration: const InputDecoration(labelText: 'الهدف'),
                items: const [
                  DropdownMenuItem(value: HealthGoal.loseFat, child: Text('خسارة دهون')),
                  DropdownMenuItem(value: HealthGoal.cleanBulk, child: Text('تضخيم نظيف')),
                  DropdownMenuItem(value: HealthGoal.recomposition, child: Text('إعادة توزيع الجسم')),
                  DropdownMenuItem(value: HealthGoal.maintain, child: Text('محافظة')),
                ],
                onChanged: (v) => setModalState(() => goal = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            final userId = UserService.currentUser?.id;
            if (userId != null) {
              final profile = UserHealthProfile(
                userId: userId,
                gender: gender,
                age: int.tryParse(ageController.text) ?? 25,
                height: double.tryParse(heightController.text) ?? 170,
                weight: double.tryParse(weightController.text) ?? 70,
                activityLevel: activity,
                goal: goal,
              );
              await HealthService.saveProfile(profile);
              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proController = TextEditingController();
    final carbController = TextEditingController();
    final fatController = TextEditingController();

    ModernDialog.show(
      context: context,
      title: 'إضافة وجبة',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الوجبة')),
            TextField(controller: calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعرات')),
            Row(
              children: [
                Expanded(child: TextField(controller: proController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بروتين'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: carbController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كارب'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'دهون'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            final userId = UserService.currentUser?.id;
            if (userId != null && nameController.text.isNotEmpty) {
              final entry = FoodEntry(
                id: const Uuid().v4(),
                userId: userId,
                name: nameController.text,
                calories: double.tryParse(calController.text) ?? 0,
                protein: double.tryParse(proController.text) ?? 0,
                carbs: double.tryParse(carbController.text) ?? 0,
                fats: double.tryParse(fatController.text) ?? 0,
                date: DateTime.now(),
              );
              await HealthService.addFood(entry);
              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  void _showTemplatesDialog() {
    final templates = HealthService.getFoodTemplates();
    
    ModernDialog.show(
      context: context,
      title: 'وجبات متكررة',
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreateTemplateDialog();
              },
              child: const Text('إنشاء قالب وجبة جديد'),
            ),
            const Divider(),
            if (templates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('لا توجد قوالب مخزنة'),
              )
            else
              ...templates.map((t) => ListTile(
                title: Text(t.name),
                subtitle: Text('لكل 100 جرام: ${t.caloriesPer100g.toInt()} سعرة'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showAddFromTemplateDialog(t);
                },
                onLongPress: () async {
                  await HealthService.deleteFoodTemplate(t.id);
                  Navigator.pop(context);
                  _showTemplatesDialog();
                },
              )),
          ],
        ),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proController = TextEditingController();
    final carbController = TextEditingController();
    final fatController = TextEditingController();

    ModernDialog.show(
      context: context,
      title: 'إنشاء قالب وجبة (لكل 100 جرام)',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف (مثلاً: أرز مطبوخ)')),
            TextField(controller: calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعرات لكل 100جم')),
            Row(
              children: [
                Expanded(child: TextField(controller: proController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بروتين'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: carbController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كارب'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'دهون'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            final userId = UserService.currentUser?.id;
            if (userId != null && nameController.text.isNotEmpty) {
              final template = FoodTemplate(
                id: const Uuid().v4(),
                userId: userId,
                name: nameController.text,
                caloriesPer100g: double.tryParse(calController.text) ?? 0,
                proteinPer100g: double.tryParse(proController.text) ?? 0,
                carbsPer100g: double.tryParse(carbController.text) ?? 0,
                fatsPer100g: double.tryParse(fatController.text) ?? 0,
              );
              await HealthService.saveFoodTemplate(template);
              Navigator.pop(context);
              _showTemplatesDialog();
            }
          },
          child: const Text('حفظ القالب'),
        ),
      ],
    );
  }

  void _showAddFromTemplateDialog(FoodTemplate t) {
    final weightController = TextEditingController();

    ModernDialog.show(
      context: context,
      title: 'إضافة ${t.name}',
      content: TextField(
        controller: weightController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'الوزن بالجرام', suffixText: 'جم'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            final weight = double.tryParse(weightController.text) ?? 0;
            if (weight > 0) {
              final factor = weight / 100;
              final entry = FoodEntry(
                id: const Uuid().v4(),
                userId: t.userId,
                name: '${t.name} ($weight جم)',
                calories: t.caloriesPer100g * factor,
                protein: t.proteinPer100g * factor,
                carbs: t.carbsPer100g * factor,
                fats: t.fatsPer100g * factor,
                date: DateTime.now(),
              );
              await HealthService.addFood(entry);
              Navigator.pop(context);
              _loadData();
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
