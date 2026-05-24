import 'package:hive_flutter/hive_flutter.dart';

class BrowserService {
  static const String boxName = 'browser_settings_box';
  
  static const List<String> _blockedKeywords = [
    'porn', 'sex', 'xvideos', 'xnxx', 'gamble', 'casino', 'betting', 'poker',
    'إباحي', 'جنس', 'قمار', 'كازينو', 'مراهنات', 'neswanji', 'نسوانجي', 'سكس',
    'نيك', 'شيميل', 'محارم', 'افلام للكبار', 'فيديوهات ساخنة', 'adult', 'nude',
    'xxx', 'erotic', 'hot video', 'redtube', 'pornhub', 'youporn', 'brazzers',
    'hentai', 'فتيات', 'بنات عاريات', 'صور ساخنة', 'افلام بورن', 'مواقع اباحية',
    'f95', 'f95zone', 'sex game', 'العاب كبار', 'العاب جنس'
  ];

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static bool isBlocked(String url) {
    final lowerUrl = url.toLowerCase();
    
    // 1. Check hardcoded keywords
    for (var keyword in _blockedKeywords) {
      if (lowerUrl.contains(keyword)) return true;
    }
    
    // 2. Check user-added keywords
    final userKeywords = getUserBlockedKeywords();
    for (var keyword in userKeywords) {
      if (lowerUrl.contains(keyword.toLowerCase())) return true;
    }
    
    // 3. Check user-added domain patterns
    final uri = Uri.tryParse(lowerUrl);
    final host = uri?.host ?? "";
    for (var domain in getBlockedDomains()) {
      if (lowerUrl.contains(domain.toLowerCase()) || host.contains(domain.toLowerCase())) return true;
    }
    
    return false;
  }

  static List<String> getBlockedDomains() {
    if (!Hive.isBoxOpen(boxName)) return [];
    final box = Hive.box(boxName);
    return List<String>.from(box.get('blocked_domains', defaultValue: <String>[]));
  }

  static List<String> getUserBlockedKeywords() {
    if (!Hive.isBoxOpen(boxName)) return [];
    final box = Hive.box(boxName);
    return List<String>.from(box.get('blocked_keywords', defaultValue: <String>[]));
  }

  static Future<void> addBlockedDomain(String domain) async {
    final box = Hive.box(boxName);
    final domains = getBlockedDomains();
    if (!domains.contains(domain) && domain.isNotEmpty) {
      domains.add(domain);
      await box.put('blocked_domains', domains);
    }
  }

  static Future<void> addBlockedKeyword(String keyword) async {
    final box = Hive.box(boxName);
    final keywords = getUserBlockedKeywords();
    if (!keywords.contains(keyword) && keyword.isNotEmpty) {
      keywords.add(keyword);
      await box.put('blocked_keywords', keywords);
    }
  }

  static void logUsage(String url, int durationSeconds) {
    final box = Hive.box(boxName);
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month}-${now.day}";
    
    Map<String, dynamic> stats = Map<String, dynamic>.from(box.get('stats_$dateKey') ?? {});
    stats['total_seconds'] = (stats['total_seconds'] ?? 0) + durationSeconds;
    
    List<Map<String, dynamic>> history = (stats['history'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    history.add({
      'url': url,
      'time': now.toIso8601String(),
      'duration': durationSeconds,
    });
    stats['history'] = history;
    
    box.put('stats_$dateKey', stats);
  }

  static Map<String, dynamic> getDailyStats(DateTime date) {
    final box = Hive.box(boxName);
    final dateKey = "${date.year}-${date.month}-${date.day}";
    return Map<String, dynamic>.from(box.get('stats_$dateKey', defaultValue: {}));
  }
}
