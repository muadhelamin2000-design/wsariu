import 'package:equatable/equatable.dart';

enum HifzStatus {
  newly(0),
  fixing(1),
  review(2);

  final int value;

  const HifzStatus(this.value);

  static HifzStatus fromInt(int val) {
    return HifzStatus.values.firstWhere((e) => e.value == val, orElse: () => HifzStatus.newly);
  }
}

class HifzPage extends Equatable {
  final int? id;
  final int pageNumber;
  final String surahName;
  final String? firstWords;
  final int juzNumber;
  final String date;
  final HifzStatus status;
  final int reviewCount;
  final String lastReviewed;
  final int fixingDaysCount;
  final int targetFixingDays;
  final String? lastDailyCheck;

  const HifzPage({
    this.id,
    required this.pageNumber,
    required this.surahName,
    this.firstWords,
    required this.juzNumber,
    required this.date,
    this.status = HifzStatus.newly,
    this.reviewCount = 0,
    required this.lastReviewed,
    this.fixingDaysCount = 0,
    this.targetFixingDays = 30,
    this.lastDailyCheck,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'page_number': pageNumber,
      'surah_name': surahName,
      'first_words': firstWords,
      'juz_number': juzNumber,
      'date': date,
      'status': status.value,
      'review_count': reviewCount,
      'last_reviewed': lastReviewed,
      'fixing_days_count': fixingDaysCount,
      'target_fixing_days': targetFixingDays,
      'last_daily_check': lastDailyCheck,
    };
  }

  factory HifzPage.fromMap(Map<String, dynamic> map) {
    return HifzPage(
      id: map['id'],
      pageNumber: map['page_number'],
      surahName: map['surah_name'],
      firstWords: map['first_words'],
      juzNumber: map['juz_number'] ?? 1,
      date: map['date'],
      status: HifzStatus.fromInt(map['status']),
      reviewCount: map['review_count'] ?? 0,
      lastReviewed: map['last_reviewed'] ?? map['date'],
      fixingDaysCount: map['fixing_days_count'] ?? 0,
      targetFixingDays: map['target_fixing_days'] ?? 30,
      lastDailyCheck: map['last_daily_check'],
    );
  }

  HifzPage copyWith({
    int? id,
    int? pageNumber,
    String? surahName,
    String? firstWords,
    int? juzNumber,
    String? date,
    HifzStatus? status,
    int? reviewCount,
    String? lastReviewed,
    int? fixingDaysCount,
    int? targetFixingDays,
    String? lastDailyCheck,
  }) {
    return HifzPage(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      surahName: surahName ?? this.surahName,
      firstWords: firstWords ?? this.firstWords,
      juzNumber: juzNumber ?? this.juzNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      fixingDaysCount: fixingDaysCount ?? this.fixingDaysCount,
      targetFixingDays: targetFixingDays ?? this.targetFixingDays,
      lastDailyCheck: lastDailyCheck ?? this.lastDailyCheck,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pageNumber,
    status,
    reviewCount,
    fixingDaysCount,
    targetFixingDays,
    lastDailyCheck,
    juzNumber,
    firstWords,
  ];
}
