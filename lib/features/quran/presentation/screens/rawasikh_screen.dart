import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wasariu/core/configurations/di.dart';
import '../manager/quran_task_cubit.dart';
import '../../data/services/hifz_service.dart';
import '../manager/hifz_model.dart';
import '../manager/hifz_cubit.dart';

class RawasikhScreen extends StatefulWidget {
  const RawasikhScreen({super.key});

  @override
  State<RawasikhScreen> createState() => _RawasikhScreenState();
}

class _RawasikhScreenState extends State<RawasikhScreen> {

  @override
  void initState() {
    super.initState();
    getIt<QuranTaskCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<QuranTaskCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رواسخ', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        ),
        body: const HifzSection(),
      ),
    );
  }
}

class HifzSection extends StatelessWidget {
  const HifzSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranTaskCubit, QuranTaskState>(
      builder: (context, state) {
        if (state is! QuranTaskLoaded) return const Center(child: CircularProgressIndicator());
        final items = state.hifzItems;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHifzGroup(context, "الجديد", items.where((t) => t.category == HifzCategory.newly).toList()),
            _buildHifzGroup(context, "التثبيت", items.where((t) => t.category == HifzCategory.fixing).toList()),
            _buildHifzGroup(context, "المراجعة الأسبوعية", items.where((t) => t.category == HifzCategory.review).toList()),
            
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => context.push('/worship/hifz-management'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                ),
                child: const Text("إدارة الحفظ"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHifzGroup(BuildContext context, String title, List<HifzItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 12),
        ...items.map((t) => _buildHifzItem(context, t)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHifzItem(BuildContext context, HifzItem t) {
    double progress = 0;
    if (t.category == HifzCategory.fixing && t.targetDays > 0) {
      progress = (t.checkDates.length / t.targetDays).clamp(0, 1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () {
           if (t.pages.isNotEmpty) {
             context.push('/worship/quran', extra: {'initialPage': t.pages.first});
           } else if (t.juzNumber != null) {
              final startPage = _getStartPageForJuz(t.juzNumber!);
              context.push('/worship/quran', extra: {'initialPage': startPage});
           }
        },
        leading: t.category == HifzCategory.fixing 
          ? SizedBox(
              width: 24, 
              height: 24, 
              child: CircularProgressIndicator(value: progress, strokeWidth: 3),
            )
          : null,
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: t.category == HifzCategory.fixing 
          ? Text('تم إنجاز ${t.checkDates.length} من أصل ${t.targetDays} أيام متصلة')
          : Text(t.firstWords),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
          onPressed: () => HifzService.deleteItem(t.id).then((_) {
            getIt<QuranTaskCubit>().loadAll();
          }),
        ),
      ),
    );
  }

  int _getStartPageForJuz(int juz) {
    final juzPages = [1, 22, 42, 62, 82, 102, 122, 142, 162, 182, 202, 222, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
    return juzPages[(juz - 1).clamp(0, 29)];
  }
}
