import 'package:flutter/material.dart';
import 'dart:typed_data';

enum AppCategory { social, study, worship, productivity, entertainment, education, health, games, other }

class AppUsageInfo {
  final String packageName;
  final String appName;
  final Duration usageDuration;
  final int launchCount;
  final AppCategory category;
  final Uint8List? icon;

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.usageDuration,
    this.launchCount = 0,
    this.category = AppCategory.other,
    this.icon,
  });

  double get usageInHours => usageDuration.inMinutes / 60.0;

  Map<String, dynamic> toMap() => {
    'packageName': packageName,
    'appName': appName,
    'usageMs': usageDuration.inMilliseconds,
    'launchCount': launchCount,
    'category': category.index,
  };

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> map) => AppUsageInfo(
    packageName: map['packageName'],
    appName: map['appName'],
    usageDuration: Duration(milliseconds: map['usageMs']),
    launchCount: map['launchCount'] ?? 0,
    category: AppCategory.values[map['category'] ?? AppCategory.other.index],
  );
}

class DailyUsageSummary {
  final DateTime date;
  final Duration totalScreenTime;
  final int unlockCount;
  final List<AppUsageInfo> appUsages;
  final Map<AppCategory, Duration> categoryBreakdown;

  DailyUsageSummary({
    required this.date,
    required this.totalScreenTime,
    this.unlockCount = 0,
    required this.appUsages,
    required this.categoryBreakdown,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'totalMs': totalScreenTime.inMilliseconds,
    'unlockCount': unlockCount,
    'appUsages': appUsages.map((e) => e.toMap()).toList(),
    'categoryBreakdown': categoryBreakdown.map((k, v) => MapEntry(k.index.toString(), v.inMilliseconds)),
  };

  factory DailyUsageSummary.fromMap(Map<dynamic, dynamic> map) {
    final breakdown = (map['categoryBreakdown'] as Map?)?.map((k, v) => 
      MapEntry(AppCategory.values[int.parse(k)], Duration(milliseconds: v))
    ) ?? {};
    
    return DailyUsageSummary(
      date: DateTime.parse(map['date']),
      totalScreenTime: Duration(milliseconds: map['totalMs']),
      unlockCount: map['unlockCount'] ?? 0,
      appUsages: (map['appUsages'] as List?)?.map((e) => AppUsageInfo.fromMap(e)).toList() ?? [],
      categoryBreakdown: Map<AppCategory, Duration>.from(breakdown),
    );
  }
}

class AppLimit {
  final String packageName;
  final String appName;
  final Duration dailyLimit;
  final bool isEnabled;

  AppLimit({
    required this.packageName,
    required this.appName,
    required this.dailyLimit,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() => {
    'packageName': packageName,
    'appName': appName,
    'limitMs': dailyLimit.inMilliseconds,
    'isEnabled': isEnabled,
  };

  factory AppLimit.fromMap(Map<dynamic, dynamic> map) => AppLimit(
    packageName: map['packageName'],
    appName: map['appName'],
    dailyLimit: Duration(milliseconds: map['limitMs']),
    isEnabled: map['isEnabled'] ?? true,
  );
}
