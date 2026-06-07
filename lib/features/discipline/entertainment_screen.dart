import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/entertainment_model.dart';
import 'services/entertainment_service.dart';
import '../dashboard/services/proactive_assistant_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/services/theme_service.dart';

import '../../core/mixins/help_feature_mixin.dart';

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> with HelpFeatureMixin {
  List<EntertainmentActivity> _activities = [];
  String? _timeFilter;
  EntertainmentType? _typeFilter;
  String? _aiSuggestion;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    checkFirstTimeHelp(context, 'entertainment');
  }

  void _loadActivities() {
    setState(() {
      _activities = EntertainmentService.getActivities();
    });
  }

  void _showAddEditActivityDialog({EntertainmentActivity? activity}) {
    final isEdit = activity != null;
    final titleController = TextEditingController(text: activity?.title);
    final descController = TextEditingController(text: activity?.description);
    final durationController = TextEditingController(text: activity?.durationMinutes.toString() ?? '15');
    EntertainmentType selectedType = activity?.type ?? EntertainmentType.social;
    String selectedIcon = (activity?.icon as String?) ?? '🎮'; // Explicit cast to handle potential Object inference

    ModernDialog.show(
      context: context,
      title: isEdit ? 'تعديل نشاط' : 'إضافة نشاط ترفيهي',
      content: StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'اسم النشاط')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'وصف بسيط')),
              TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة (بالدقائق)')),
              const SizedBox(height: 16),
              DropdownButtonFormField<EntertainmentType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: EntertainmentType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getTypeName(t)))).toList(),
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),
              const SizedBox(height: 16),
              const Text('اختر إيموجي:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['🏃', '📚', '🧘', '📞', '🎬', '🥗', '📿', '🎮', '🎨', '🎵', '🎭', '🚲', '⛵', '🗺️', '📸', '📽️', '🍳', '🏋️'].map((emoji) => GestureDetector(
                    onTap: () => setModalState(() => selectedIcon = emoji),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == emoji ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        if (isEdit)
          TextButton(
            onPressed: () async {
              final res = await ModernDialog.showConfirm(context: context, title: 'حذف النشاط', message: 'هل تريد حذف "${activity.title}"؟', isDestructive: true);
              if (res == true) {
                await EntertainmentService.deleteActivity(activity.id);
                if (mounted) Navigator.pop(context);
                _loadActivities();
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: () async {
            if (titleController.text.isNotEmpty) {
              final newActivity = EntertainmentActivity(
                id: activity?.id ?? const Uuid().v4(),
                title: titleController.text,
                description: descController.text,
                icon: selectedIcon,
                type: selectedType,
                durationMinutes: int.tryParse(durationController.text) ?? 15,
                isFavorite: activity?.isFavorite ?? false,
                executionCount: activity?.executionCount ?? 0,
              );
              await EntertainmentService.saveActivity(newActivity);
              if (mounted) Navigator.pop(context);
              _loadActivities();
            }
          },
          child: Text(isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }

  List<EntertainmentActivity> get _filteredActivities {
    return _activities.where((a) {
      if (_timeFilter != null) {
        int max = int.parse(_timeFilter!);
        if (a.durationMinutes > max) return false;
      }
      if (_typeFilter != null && a.type != _typeFilter) return false;
      return true;
    }).toList();
  }

  void _getAiSuggestion() async {
    setState(() {
      _isThinking = true;
      _aiSuggestion = null;
    });

    // Simulate smart thinking logic
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Simple logic based on activities
    final activities = EntertainmentService.getActivities();
    activities.shuffle();
    final suggestion = activities.first;

    if (mounted) {
      setState(() {
        _isThinking = false;
        _aiSuggestion = "بناءً على نشاطك اليوم، أنصحك بـ \"${suggestion.title}\". هو نشاط ${_getDurationName(suggestion.durationMinutes)} وسيفرق جداً في حالتك النفسية.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFDFCFB),
      appBar: AppBar(
        title: const Text('الترفيه الذكي', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح الترفيه الذكي', 
            description: 'روّح عن نفسك بوعي وبدون إفراط:\n'
            '- سجل نشاطاتك الترفيهية (ألعاب، خروج، مشاهدة).\n'
            '- حدد مدة النشاط ومدى فائدته أو ضرره.\n'
            '- راقب استهلاكك للترفيه لضمان عدم طغيانه على يومك.'
          ),
          TextButton(
            onPressed: () => _showAddEditActivityDialog(),
            child: const Text('إضافة', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAiHeader(),
          _buildFilters(),
          Expanded(
            child: _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiHeader() {
    final isDark = ThemeService.isDarkMode;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.psychology_alt, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'المساعد الذكي للترفيه',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: _isThinking ? null : _getAiSuggestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('اقترح لي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: LinearProgressIndicator(minHeight: 2, borderRadius: BorderRadius.all(Radius.circular(2))),
            ),
          if (_aiSuggestion != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accentGold.withOpacity(0.1))),
                child: Text(
                  _aiSuggestion!,
                  style: const TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip(label: 'الكل', isSelected: _timeFilter == null && _typeFilter == null, onTap: () => setState(() { _timeFilter = null; _typeFilter = null; })),
          const SizedBox(width: 8),
          _filterChip(label: 'سريع', isSelected: _timeFilter == '10', onTap: () => setState(() => _timeFilter = '10')),
          const SizedBox(width: 8),
          _filterChip(label: 'متوسط', isSelected: _timeFilter == '30', onTap: () => setState(() => _timeFilter = '30')),
          const SizedBox(width: 8),
          _filterChip(label: 'طويل', isSelected: _timeFilter == '60', onTap: () => setState(() => _timeFilter = '60')),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: VerticalDivider(width: 1)),
          ...EntertainmentType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _filterChip(
              label: _getTypeName(type),
              isSelected: _typeFilter == type,
              onTap: () => setState(() => _typeFilter = type),
            ),
          )),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    final isDark = ThemeService.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final activities = _filteredActivities;
    if (activities.isEmpty) {
      return const Center(child: Text('لا يوجد أنشطة تناسب الفلتر الحالي'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) => _buildActivityCard(activities[index]),
    );
  }

  Widget _buildActivityCard(EntertainmentActivity activity) {
    final isDark = ThemeService.isDarkMode;
    return InkWell(
      onLongPress: () => _showAddEditActivityDialog(activity: activity),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(activity.icon, style: const TextStyle(fontSize: 24)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(activity.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.pink, size: 18),
                  onPressed: () async {
                    await EntertainmentService.toggleFavorite(activity.id);
                    _loadActivities();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                activity.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDurationName(activity.durationMinutes),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                ),
                InkWell(
                  onTap: () => _startActivity(activity),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('ابدأ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startActivity(EntertainmentActivity activity) async {
    final result = await ModernDialog.showConfirm(
      context: context,
      title: activity.title,
      message: 'هل أنت مستعد للبدء الآن؟ سيتم تسجيل هذا النشاط في سجل إنجازاتك.',
      confirmLabel: 'نعم، ابدأ',
    );

    if (result == true) {
      await EntertainmentService.incrementExecution(activity.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(activity.motivationalMessage),
          backgroundColor: AppTheme.primaryGreen,
        ));
        _loadActivities();
      }
    }
  }

  String _getTypeName(EntertainmentType type) {
    switch (type) {
      case EntertainmentType.sports: return 'رياضي';
      case EntertainmentType.social: return 'اجتماعي';
      case EntertainmentType.psychology: return 'نفسي';
      case EntertainmentType.educational: return 'تعليمي';
      case EntertainmentType.lightReligious: return 'ديني خفيف';
    }
  }

  String _getDurationName(int mins) {
    if (mins <= 10) return 'سريع';
    if (mins <= 30) return 'متوسط';
    return 'طويل';
  }
}
