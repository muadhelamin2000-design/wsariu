import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/extensions/string_extensions.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:wasariu/features/quran/data/services/khatma_service.dart';
import 'package:wasariu/core/flutter_quran/src/app_bloc.dart';

class KhatmaIndexSheet extends StatefulWidget {
  const KhatmaIndexSheet({super.key});

  @override
  State<KhatmaIndexSheet> createState() => _KhatmaIndexSheetState();
}

class _KhatmaIndexSheetState extends State<KhatmaIndexSheet> {
  List<KhatmaModel> _khatmas = [];

  @override
  void initState() {
    super.initState();
    _loadKhatmas();
  }

  void _loadKhatmas() {
    setState(() {
      _khatmas = KhatmaService.getAllKhatmas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);
    final bgColor = AppColors.getBackground(context);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "ختمات القراءة",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: mainColor,
              fontFamily: 'ReemKufi',
            ),
          ),
          SizedBox(height: 20.h),
          if (_khatmas.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30.h),
              child: Text("لا توجد ختمات نشطة حالياً", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _khatmas.length,
                itemBuilder: (context, index) {
                  final k = _khatmas[index];
                  double progress = k.currentPage / k.targetPages;
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    elevation: 0,
                    color: mainColor.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    child: ListTile(
                      title: Text(k.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: mainColor.withOpacity(0.1),
                            color: mainColor,
                            minHeight: 6.h,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "ص ${k.currentPage.toString().toArabic()} من ${k.targetPages.toString().toArabic()}",
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.check_circle_outline, color: mainColor),
                        onPressed: () {
                          final lastPage = AppBloc.quranCubit.lastPage;
                          KhatmaService.updateProgress(k.id, lastPage).then((_) => _loadKhatmas());
                        },
                      ),
                      onTap: () {
                        if (k.currentPage > 0) {
                          AppBloc.quranCubit.animateToPage(k.currentPage - 1);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 10.h),
          ElevatedButton.icon(
            onPressed: _showAddKhatmaDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("بدء ختمة جديدة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _showAddKhatmaDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ختمة جديدة"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "اسم الختمة (مثلاً: ختمة رمضان)"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                KhatmaService.addKhatma(nameController.text, 604).then((_) {
                  Navigator.pop(context);
                  _loadKhatmas();
                });
              }
            },
            child: const Text("بدء"),
          ),
        ],
      ),
    );
  }
}
