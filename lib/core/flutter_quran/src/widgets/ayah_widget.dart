import 'package:flutter/material.dart';

import '../models/ayah.dart';
import '../utils/flutter_quran_utils.dart';

class AyahWidget extends StatelessWidget {
  const AyahWidget(this.ayah, {super.key});

  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: ayah.ayah.split(' ').map((word) => TextSpan(text: word)).toList(),
        style: FlutterQuran().getHafsStyle(context),
      ),
    );
  }
}
