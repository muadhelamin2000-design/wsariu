import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'models/health_models.dart';
import 'services/health_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';
import '../../core/services/theme_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/mixins/help_feature_mixin.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with HelpFeatureMixin {
  UserHealthProfile? _profile;
  List<FoodEntry> _todayFoods = [];
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    checkFirstTimeHelp(context, 'nutrition');
  }

  void _loadData() {
    setState(() {
      _profile = HealthService.getProfile();
      _todayFoods = HealthService.getFoodEntries(_selectedDate);
    });
  }

  String _getActivityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.low: return 'قليل النشاط';
      case ActivityLevel.medium: return 'متوسط النشاط';
      case ActivityLevel.high: return 'عالي النشاط (رياضي)';
    }
  }

  String _getGoalLabel(HealthGoal goal) {
    switch (goal) {
      case HealthGoal.loseFat: return 'خسارة دهون';
      case HealthGoal.gainMuscle: return 'زيادة عضلات';
      case HealthGoal.recomposition: return 'إعادة تركيب الجسم';
      case HealthGoal.maintain: return 'تثبيت وزن';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('التغذية والماكروز 🥗'),
        actions: [
          buildHelpButton(
            context,
            title: 'شرح قسم التغذية',
            description: 'هذا القسم لمتابعة احتياج جسمك من السعرات:\n'
            '- سجل وزنك وطولك لحساب احتياجك التلقائي.\n'
            '- أضف الوجبات التي تتناولها خلال اليوم.\n'
            '- تابع الماكروز (بروتين، كارب، دهون) للوصول لهدفك.',
            pageId: 'nutrition',
          ),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: _showProfileDialog),
        ],
      ),
      body: Column(
        children: [
          const QuickLinkNavigator(currentPageId: 'nutrition'),
          Expanded(
            child: _profile == null 
              ? _buildProfileSetup()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildMacrosBreakdown(),
                      const SizedBox(height: 32),
                      _buildFoodListHeader(),
                      const SizedBox(height: 16),
                      _buildFoodList(),
                    ],
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: _profile != null ? FloatingActionButton.extended(
        onPressed: _showAddFoodDialog,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: AppTheme.accentGold),
        label: const Text('إضافة وجبة', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildProfileSetup() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calculate_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('يجب ضبط ملفك الصحي لحساب السعرات', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _showProfileDialog, child: const Text('ضبط الملف الآن')),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final double target = _calculateCalories();
    final double consumed = _todayFoods.fold(0, (sum, item) => sum + item.calories);
    final double remaining = target - consumed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F3D2E), Color(0xFF1B4D3E)]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('المستهدف', target.toInt().toString()),
              _buildStat('المتناول', consumed.toInt().toString()),
              _buildStat('المتبقي', remaining.toInt().toString(), isHighlight: true),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: (consumed / target).clamp(0, 1),
            backgroundColor: Colors.white10,
            color: AppTheme.accentGold,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(val, style: TextStyle(color: isHighlight ? AppTheme.accentGold : Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMacrosBreakdown() {
    final double cal = _todayFoods.fold(0, (sum, item) => sum + item.calories);
    final double pro = _todayFoods.fold(0, (sum, item) => sum + item.protein);
    final double carb = _todayFoods.fold(0, (sum, item) => sum + item.carbs);
    final double fat = _todayFoods.fold(0, (sum, item) => sum + item.fats);

    return Row(
      children: [
        _macroItem('بروتين', pro, Colors.redAccent),
        const SizedBox(width: 12),
        _macroItem('كارب', carb, Colors.blueAccent),
        const SizedBox(width: 12),
        _macroItem('دهون', fat, Colors.orangeAccent),
      ],
    );
  }

  Widget _macroItem(String label, double val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text('${val.toInt()}ج', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodListHeader() {
    return const Row(
      children: [
        Text('وجبات اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Spacer(),
      ],
    );
  }

  Widget _buildFoodList() {
    if (_todayFoods.isEmpty) return const Center(child: Text('لم يتم تسجيل وجبات اليوم', style: TextStyle(color: Colors.grey, fontSize: 12)));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todayFoods.length,
      itemBuilder: (context, index) {
        final food = _todayFoods[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('P: ${food.protein.toInt()} | C: ${food.carbs.toInt()} | F: ${food.fats.toInt()}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${food.calories.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const Text('سعرة', style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
            onLongPress: () => _confirmDeleteFood(food),
          ),
        );
      },
    );
  }

  double _calculateCalories() {
    if (_profile == null) return 2000;
    // Mifflin-St Jeor Equation
    double bmr = (10 * _profile!.weight) + (6.25 * _profile!.height) - (5 * _profile!.age);
    bmr += (_profile!.gender == Gender.male ? 5 : -161);
    
    double multiplier = 1.2;
    if (_profile!.activityLevel == ActivityLevel.medium) multiplier = 1.55;
    if (_profile!.activityLevel == ActivityLevel.high) multiplier = 1.725;
    
    double tdee = bmr * multiplier;
    
    if (_profile!.goal == HealthGoal.loseFat) tdee -= 500;
    if (_profile!.goal == HealthGoal.gainMuscle) tdee += 300;
    
    return tdee;
  }

  void _showAddFoodDialog() async {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final pController = TextEditingController();
    final cController = TextEditingController();
    final fController = TextEditingController();

    ModernDialog.show(
      context: context,
      title: 'إضافة وجبة',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الوجبة')),
            TextField(controller: calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعرات')),
            Row(
              children: [
                Expanded(child: TextField(controller: pController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بروتين (ج)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: cController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كارب (ج)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'دهون (ج)'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty && calController.text.isNotEmpty) {
              final entry = FoodEntry(
                id: const Uuid().v4(),
                userId: UserService.currentUser!.id,
                name: nameController.text,
                calories: double.tryParse(calController.text) ?? 0,
                protein: double.tryParse(pController.text) ?? 0,
                carbs: double.tryParse(cController.text) ?? 0,
                fats: double.tryParse(fController.text) ?? 0,
                date: _selectedDate,
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

  void _confirmDeleteFood(FoodEntry food) async {
    final res = await ModernDialog.showConfirm(context: context, title: 'حذف الوجبة', message: 'هل تريد حذف ${food.name}؟', isDestructive: true);
    if (res == true) {
      await HealthService.deleteFood(food.id);
      _loadData();
    }
  }

  void _showProfileDialog() async {
    final wController = TextEditingController(text: _profile?.weight.toString());
    final hController = TextEditingController(text: _profile?.height.toString());
    final aController = TextEditingController(text: _profile?.age.toString());
    Gender gender = _profile?.gender ?? Gender.male;
    ActivityLevel activity = _profile?.activityLevel ?? ActivityLevel.medium;
    HealthGoal goal = _profile?.goal ?? HealthGoal.loseFat;

    ModernDialog.show(
      context: context,
      title: 'بيانات الجسم',
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: wController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كجم)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: hController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطول (سم)'))),
                ],
              ),
              TextField(controller: aController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر')),
              const SizedBox(height: 16),
              const Text('الجنس:', style: TextStyle(fontSize: 12)),
              Row(
                children: [
                  ChoiceChip(label: const Text('ذكر'), selected: gender == Gender.male, onSelected: (v) => setModalState(() => gender = Gender.male)),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('أنثى'), selected: gender == Gender.female, onSelected: (v) => setModalState(() => gender = Gender.female)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButton<ActivityLevel>(
                value: activity,
                isExpanded: true,
                items: ActivityLevel.values.map((a) => DropdownMenuItem(value: a, child: Text(_getActivityLevelLabel(a)))).toList(),
                onChanged: (v) => setModalState(() => activity = v!),
              ),
              DropdownButton<HealthGoal>(
                value: goal,
                isExpanded: true,
                items: HealthGoal.values.map((g) => DropdownMenuItem(value: g, child: Text(_getGoalLabel(g)))).toList(),
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
            if (wController.text.isNotEmpty && hController.text.isNotEmpty) {
              final profile = UserHealthProfile(
                userId: UserService.currentUser!.id,
                weight: double.tryParse(wController.text) ?? 0,
                height: double.tryParse(hController.text) ?? 0,
                age: int.tryParse(aController.text) ?? 20,
                gender: gender,
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
}
