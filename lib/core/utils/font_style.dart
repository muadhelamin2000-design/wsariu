import 'package:flutter/material.dart';

class AppFontStyle {
  static const TextStyle bold16 = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const TextStyle regular14 = TextStyle(fontSize: 14);

  static TextStyle fontCairo18w700black(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Cairo',
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle fontAlmarai14w700Black(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Almarai',
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle fontReemKafi20w600titleColor(BuildContext context) {
    return const TextStyle(
      fontFamily: 'ReemKufi',
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle fontAlmarai12w400mainColor(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Almarai',
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle fontReemKafi18w700titleColor(BuildContext context) {
    return const TextStyle(
      fontFamily: 'ReemKufi',
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
  }
}
