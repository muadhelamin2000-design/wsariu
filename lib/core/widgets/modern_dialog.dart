import 'dart:ui';
import 'package:flutter/material.dart';

class ModernDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showDivider;
  final Color? accentColor;

  const ModernDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.showDivider = true,
    this.accentColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? accentColor,
    bool showDivider = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
                child: ModernDialog(
                  title: title,
                  content: content,
                  actions: actions,
                  accentColor: accentColor,
                  showDivider: showDivider,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper: Info Dialog ---
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return show(
      context: context,
      title: title,
      accentColor: const Color(0xFFC8A24A), // Gold for info
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(); },
          child: const Text('فهمت'),
        ),
      ],
    );
  }

  // --- Helper: Confirm Dialog ---
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'نعم',
    String cancelLabel = 'إلغاء',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      accentColor: isDestructive ? Colors.red : const Color(0xFF2E7D32),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(false); },
          child: Text(cancelLabel, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(true); },
          style: _primaryButtonStyle(isDestructive ? Colors.red : const Color(0xFF2E7D32)),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  // --- Helper: Input Dialog ---
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    required String hint,
    String? initialValue,
    String confirmLabel = 'حفظ',
  }) {
    final controller = TextEditingController(text: initialValue);
    return show<String>(
      context: context,
      title: title,
      accentColor: const Color(0xFFC8A24A),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFC8A24A), width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(); },
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(controller.text); },
          style: _primaryButtonStyle(const Color(0xFF2E7D32)),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  static ButtonStyle _primaryButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeAccent = accentColor ?? const Color(0xFFC8A24A);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A38) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: themeAccent.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeAccent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Accent Bar - Stylized
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: themeAccent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: themeAccent.withOpacity(0.5), blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? themeAccent : const Color(0xFF0F3D2E),
                ),
              ),
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Divider(height: 1, color: themeAccent.withOpacity(0.1)),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                child: content,
              ),
            ),
            if (actions != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
