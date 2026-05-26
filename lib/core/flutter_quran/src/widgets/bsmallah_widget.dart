import 'package:flutter/material.dart';
import 'package:wasariu/core/flutter_quran/src/utils/flutter_quran_utils.dart';

class BasmallahWidget extends StatelessWidget {
  final int surahNumber;

  const BasmallahWidget({required this.surahNumber, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        style: FlutterQuran().getHafsStyle(context).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
