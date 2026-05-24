import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/journal_model.dart';
import 'services/journal_service.dart';
import '../profile/services/user_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/quick_link_navigator.dart';

import '../../core/mixins/help_feature_mixin.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with HelpFeatureMixin {
  DateTime _selectedDate = DateTime.now();
  
  List<JournalItem> _blessings = [];
  List<MistakeWithEffect> _sinsWithEffects = [];
  List<JournalItem> _shortcomings = [];

  final List<Color> _availableTextColors = [
    Colors.black, Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange, Colors.brown,
    const Color(0xFF0F3D2E), const Color(0xFFC8A24A),
  ];

  @override
  void initState() {
    super.initState();
    _loadEntry();
    checkFirstTimeHelp(context, 'journal');
  }

  void _loadEntry() {
    final entry = JournalService.getEntryForDate(_selectedDate);
    setState(() {
      _blessings = entry != null ? List.from(entry.blessings) : [];
      _sinsWithEffects = entry != null ? List.from(entry.mistakesWithEffects) : [];
      _shortcomings = entry != null ? List.from(entry.shortcomings) : [];
    });
  }

  Future<void> _saveEntry() async {
    final String? userId = UserService.currentUser?.id;
    if (userId == null) return;

    final entry = JournalEntry(
      id: "${userId}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
      userId: userId,
      date: _selectedDate,
      blessings: _blessings,
      mistakesWithEffects: _sinsWithEffects,
      shortcomings: _shortcomings,
    );

    await JournalService.saveEntry(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الصحيفة بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customBg = getPageBackgroundColor('journal');
    return Scaffold(
      backgroundColor: customBg,
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: Text('صحيفتي')),
        actions: [
          buildHelpButton(
            context, 
            title: 'شرح صحيفتي', 
            description: 'هذا القسم لتسجيل مشاعرك وأعمالك:\n'
            '- سجل النعم التي تشكر الله عليها.\n'
            '- اعترف بذنوبك واستغفر عنها.\n'
            '- دون إنجازاتك ومشاعرك اليومية.\n'
            '- يمكنك اختيار لون الخط لكل تدوينة.',
            pageId: 'journal',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadEntry();
              }
            },
          ),
          TextButton(onPressed: _saveEntry, child: const Text('حفظ', style: TextStyle(color: Color(0xFFC8A24A), fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            QuickLinkNavigator(currentPageId: 'journal'),
            _buildSummaryRow(),
            const SizedBox(height: 16),
            _buildSmartMessage(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'النعم (الحمد لله)',
              items: _blessings,
              color: Colors.green,
              icon: Icons.favorite,
              hint: 'نعمة جديدة اليوم...',
              onAdd: (val, color) => setState(() => _blessings.add(JournalItem(text: val, colorValue: color.value))),
              onDelete: (idx) => setState(() => _blessings.removeAt(idx)),
            ),
            const SizedBox(height: 16),
            _buildSinsSection(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'التقصير (سأتحسن بإذن الله)',
              items: _shortcomings,
              color: Colors.orange,
              icon: Icons.trending_down,
              hint: 'أمر قصرت فيه اليوم...',
              onAdd: (val, color) => setState(() => _shortcomings.add(JournalItem(text: val, colorValue: color.value))),
              onDelete: (idx) => setState(() => _shortcomings.removeAt(idx)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('حفظ اليوم'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _summaryItem('النعم', _blessings.length.toString(), Colors.green),
        const SizedBox(width: 8),
        _summaryItem('الذنوب', _sinsWithEffects.length.toString(), Colors.red),
        const SizedBox(width: 8),
        _summaryItem('التقصير', _shortcomings.length.toString(), Colors.orange),
      ],
    );
  }

  Widget _summaryItem(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartMessage() {
    String msg = "ابدأ يومك بذكر نعم الله عليك.";
    if (_blessings.length > _sinsWithEffects.length) msg = "ما شاء الله، النعم كثيرة اليوم. استمر في شكر الله.";
    if (_sinsWithEffects.length > 0) msg = "باب التوبة مفتوح دائماً، أستغفر الله وتب إليه.";
    if (_blessings.isEmpty && _sinsWithEffects.isEmpty && _shortcomings.isEmpty) msg = "كيف كان يومك؟ ابدأ بكتابة صحيفتك الآن.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
    );
  }

  Widget _buildSinsSection() {
    final sinController = TextEditingController();
    final effectController = TextEditingController();
    Color sectionColor = Colors.red;
    Color selectedTextColor = Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: sectionColor, size: 20),
                const SizedBox(width: 8),
                Text('الذنوب وأثرها (أستغفر الله)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sectionColor)),
              ],
            ),
            const Text('إضافة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ..._sinsWithEffects.asMap().entries.map((e) => Card(
          elevation: 0,
          color: sectionColor.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e.value.mistake, style: TextStyle(fontWeight: FontWeight.bold, color: Color(e.value.colorValue))),
            subtitle: e.value.effect.isNotEmpty ? Text("الأثر: ${e.value.effect}", style: const TextStyle(color: Colors.redAccent, fontSize: 12)) : null,
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _sinsWithEffects.removeAt(e.key))),
          ),
        )),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              StatefulBuilder(builder: (context, setInputState) => Column(
                children: [
                  TextField(
                    controller: sinController,
                    style: TextStyle(color: selectedTextColor),
                    decoration: const InputDecoration(hintText: 'ما هو الذنب؟', border: InputBorder.none, isDense: true),
                  ),
                  const Divider(),
                  TextField(
                    controller: effectController,
                    decoration: const InputDecoration(hintText: 'أثر الذنب (إن وجد)...', border: InputBorder.none, isDense: true),
                  ),
                  const SizedBox(height: 8),
                  const Text('لون الخط:', style: TextStyle(fontSize: 10)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableTextColors.map((c) => GestureDetector(
                        onTap: () => setInputState(() => selectedTextColor = c),
                        child: Container(
                          width: 24, height: 24, margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: selectedTextColor == c ? Border.all(color: Colors.white, width: 2) : null),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              )),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    if (sinController.text.isNotEmpty) {
                      setState(() {
                        _sinsWithEffects.add(MistakeWithEffect(
                          mistake: sinController.text, 
                          effect: effectController.text,
                          colorValue: selectedTextColor.value,
                        ));
                      });
                      sinController.clear();
                      effectController.clear();
                    }
                  },
                  child: Text('إضافة الذنب', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<JournalItem> items,
    required Color color,
    required IconData icon,
    required String hint,
    required Function(String, Color) onAdd,
    required Function(int) onDelete,
  }) {
    final controller = TextEditingController();
    Color selectedTextColor = Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Text('إضافة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) => Card(
          elevation: 0,
          color: color.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            title: Text(e.value.text, style: TextStyle(color: Color(e.value.colorValue))),
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => onDelete(e.key)),
            dense: true,
          ),
        )),
        StatefulBuilder(builder: (context, setInputState) => Column(
          children: [
            TextField(
              controller: controller,
              style: TextStyle(color: selectedTextColor),
              decoration: InputDecoration(
                hintText: hint,
                suffixIcon: TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      onAdd(controller.text, selectedTextColor);
                      controller.clear();
                    }
                  },
                  child: Text('إضافة', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableTextColors.map((c) => GestureDetector(
                  onTap: () => setInputState(() => selectedTextColor = c),
                  child: Container(
                    width: 20, height: 24, margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: selectedTextColor == c ? Border.all(color: Colors.white, width: 2) : null),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        )),
      ],
    );
  }
}
