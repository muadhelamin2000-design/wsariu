import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import '../manager/quran_task_cubit.dart';
import '../../data/services/khatma_service.dart';
import '../../data/services/hifz_service.dart';
import '../manager/hifz_model.dart';

class QuranTasksScreen extends StatefulWidget {
  const QuranTasksScreen({super.key});

  @override
  State<QuranTasksScreen> createState() => _QuranTasksScreenState();
}

class _QuranTasksScreenState extends State<QuranTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuranTaskCubit()..loadAll(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مهام القرآن 📖', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'الختمات'),
              Tab(text: 'الحفظ'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const KhatmaSection(),
            const HifzSection(),
          ],
        ),
      ),
    );
  }
}

class KhatmaSection extends StatelessWidget {
  const KhatmaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranTaskCubit, QuranTaskState>(
      builder: (context, state) {
        if (state is QuranTaskLoading) return const Center(child: CircularProgressIndicator());
        if (state is! QuranTaskLoaded) return const Center(child: Text('حدث خطأ'));
        
        final khatmas = state.khatmas;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (khatmas.isEmpty)
              _buildEmptyState(context, "لا توجد ختمات نشطة", "ابدأ ختمة جديدة وحافظ على وردك اليومي")
            else
              ...khatmas.map((k) => _buildKhatmaCard(context, k)),
            
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddKhatmaDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("إضافة ختمة جديدة"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKhatmaCard(BuildContext context, KhatmaModel k) {
    final inactiveDays = DateTime.now().difference(k.lastActivityDate).inDays;
    final bool isInactive = inactiveDays > 2;
    final progressVal = k.progress;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(k.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${k.durationDays} يوم', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isInactive)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text("تنبيه: لم تفتح هذه الختمة منذ $inactiveDays أيام!", style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            LinearProgressIndicator(
              value: progressVal,
              backgroundColor: Colors.grey.withOpacity(0.1),
              color: Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('أنجزت ${k.finishedPages.length} صفحة', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('المتبقي: ${k.remainingPages}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final nextPage = k.finishedPages.isEmpty ? 1 : (k.finishedPages.reduce((a, b) => a > b ? a : b) + 1).clamp(1, 604);
                      context.push('/worship/quran', extra: {'initialPage': nextPage});
                    },
                    child: const Text('متابعة التلاوة'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteKhatma(context, k.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddKhatmaDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء ختمة جديدة'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'اسم الختمة')),
              const SizedBox(height: 20),
              const Text('مدة الختمة (بالأيام):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [7, 15, 30, 40].map((d) => ChoiceChip(
                  label: Text('$d يوم'),
                  selected: selectedDays == d,
                  onSelected: (val) => setModalState(() => selectedDays = d),
                )).toList(),
              ),
              const SizedBox(height: 12),
              Text('المعدل المطلوب: ${(604 / selectedDays).ceil()} صفحة يومياً', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                KhatmaService.addKhatma(nameController.text, selectedDays).then((_) {
                  context.read<QuranTaskCubit>().loadAll();
                  Navigator.pop(ctx);
                });
              }
            },
            child: const Text('بدء'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKhatma(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الختمة'),
        content: const Text('هل أنت متأكد من حذف هذه الختمة؟ ستفقد كل سجلات التقدم الخاصة بها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              KhatmaService.deleteKhatma(id).then((_) {
                context.read<QuranTaskCubit>().loadAll();
                Navigator.pop(ctx);
              });
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String sub) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.auto_stories_outlined, size: 60, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class HifzSection extends StatelessWidget {
  const HifzSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranTaskCubit, QuranTaskState>(
      builder: (context, state) {
        if (state is! QuranTaskLoaded) return const SizedBox.shrink();
        final tasks = state.hifzTasks;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHifzGroup(context, "الجديد 🆕", tasks.where((t) => t.category == HifzCategory.newly).toList()),
            _buildHifzGroup(context, "التثبيت 🛡️", tasks.where((t) => t.category == HifzCategory.fixing).toList()),
            _buildHifzGroup(context, "المراجعة الأسبوعية 🔁", tasks.where((t) => t.category == HifzCategory.weeklyReview).toList()),
            
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(context),
              icon: const Icon(Icons.add_task),
              label: const Text("إضافة ورد حفظ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHifzGroup(BuildContext context, String title, List<HifzTask> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 12),
        ...tasks.map((t) => _buildHifzItem(context, t)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHifzItem(BuildContext context, HifzTask t) {
    final progress = t.completedPages.length / t.pages.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () => context.push('/worship/quran', extra: {'initialPage': t.pages.first}),
        leading: CircularProgressIndicator(
          value: progress,
          strokeWidth: 3,
          backgroundColor: Colors.grey.withOpacity(0.1),
          color: Colors.blue,
        ),
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(t.firstWords, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: () => HifzService.deleteTask(t.id).then((_) => context.read<QuranTaskCubit>().loadAll()),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    // Simplified add dialog
    final titleController = TextEditingController();
    final pagesController = TextEditingController();
    HifzCategory selectedCat = HifzCategory.newly;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة ورد حفظ'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'الاسم (سورة/جزء/صفحة)')),
              TextField(controller: pagesController, decoration: const InputDecoration(labelText: 'أرقام الصفحات (مثال: 2-5)')),
              const SizedBox(height: 12),
              DropdownButton<HifzCategory>(
                value: selectedCat,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: HifzCategory.newly, child: Text('جديد')),
                  DropdownMenuItem(value: HifzCategory.fixing, child: Text('تثبيت')),
                  DropdownMenuItem(value: HifzCategory.weeklyReview, child: Text('مراجعة')),
                ],
                onChanged: (v) => setModalState(() => selectedCat = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && pagesController.text.isNotEmpty) {
                final List<int> pages = [];
                if (pagesController.text.contains('-')) {
                  final parts = pagesController.text.split('-');
                  final start = int.parse(parts[0]);
                  final end = int.parse(parts[1]);
                  for (int i = start; i <= end; i++) pages.add(i);
                } else {
                  pages.add(int.parse(pagesController.text));
                }

                final task = HifzTask(
                  id: const Uuid().v4(),
                  title: titleController.text,
                  pages: pages,
                  category: selectedCat,
                  createdAt: DateTime.now(),
                  firstWords: "بداية من ص ${pages.first}",
                );
                HifzService.saveTask(task).then((_) {
                  context.read<QuranTaskCubit>().loadAll();
                  Navigator.pop(ctx);
                });
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
