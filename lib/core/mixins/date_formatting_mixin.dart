import 'package:intl/intl.dart';

/// Mixin لمعالجة التواريخ والأوقات بشكل موحد
mixin DateFormattingMixin {
  /// تنسيق التاريخ بالصيغة العربية
  String formatDateAr(DateTime date) {
    return DateFormat('EEEE, d MMMM y', 'ar_SA').format(date);
  }

  /// تنسيق الوقت (ساعة : دقيقة)
  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// حساب الفرق بين تاريخين بصيغة إنسانية
  String getTimeDifference(DateTime from, DateTime to) {
    final diff = to.difference(from);
    
    if (diff.inDays > 0) return '${diff.inDays} أيام';
    if (diff.inHours > 0) return '${diff.inHours} ساعات';
    if (diff.inMinutes > 0) return '${diff.inMinutes} دقائق';
    return 'للتو';
  }

  /// الحصول على اسم اليوم (السبت، الأحد، إلخ)
  String getDayName(DateTime date) {
    final days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[date.weekday % 7];
  }

  /// التحقق من أن التاريخين في نفس اليوم
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// بداية اليوم (00:00:00)
  DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// نهاية اليوم (23:59:59)
  DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
