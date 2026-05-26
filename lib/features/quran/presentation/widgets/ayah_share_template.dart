import 'package:flutter/material.dart';

class AyahShareTemplate extends StatelessWidget {
  final String ayahText;
  final String surahName;
  final int ayahNumber;

  const AyahShareTemplate({
    required this.ayahText,
    required this.surahName,
    required this.ayahNumber,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ayahText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontFamily: 'Amiri'),
          ),
          const SizedBox(height: 10),
          Text(
            'سورة $surahName - آية $ayahNumber',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
