import 'package:flutter/material.dart';
import 'package:wasariu/core/app_theme.dart';

class AppColors {
  static const Color primary = AppTheme.primaryGreen;
  static const Color accent = AppTheme.accentGold;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color gray = Colors.grey;

  static Color getMainColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  static Color getSubtitleColor(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getShadowColor(BuildContext context) {
    return Colors.black.withValues(alpha: 0.1);
  }
}
