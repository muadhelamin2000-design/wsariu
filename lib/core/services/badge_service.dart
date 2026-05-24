import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final bool isUnlocked;
  final int days;

  BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.days = 0,
  });
}

class BadgeService {
  static const String boxName = 'badges_box';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static List<BadgeItem> getBadgesForCategory(String category) {
    final box = Hive.box(boxName);
    
    List<BadgeItem> categoryBadges = [];
    
    // الأيام المستهدفة بناءً على دراسات تكوين العادات
    final Map<int, Map<String, dynamic>> levels = {
      3: {'name': 'درع البداية', 'color': Colors.brown.shade400},
      7: {'name': 'درع الثبات', 'color': Colors.blueGrey.shade400},
      21: {'name': 'درع العادة', 'color': Colors.blue.shade400},
      40: {'name': 'درع الانضباط', 'color': Colors.teal.shade400},
      66: {'name': 'درع التلقائية', 'color': Colors.amber.shade600},
      90: {'name': 'درع أسلوب الحياة', 'color': Colors.deepOrange.shade600},
    };

    if (category == 'worship' || category == 'habits' || category == 'routine') {
      levels.forEach((days, info) {
        final id = '${category}_shield_$days';
        categoryBadges.add(
          BadgeItem(
            id: id,
            title: info['name'],
            description: 'الالتزام لمدة $days يوماً متتالياً',
            icon: '🛡️',
            color: info['color'],
            isUnlocked: box.get(id, defaultValue: false),
            days: days,
          ),
        );
      });
    }

    return categoryBadges;
  }

  static Future<bool> checkAndUnlockShield(String category, int currentStreak) async {
    final box = Hive.box(boxName);
    final levels = [3, 7, 21, 40, 66, 90];
    bool unlockedNew = false;

    for (var days in levels) {
      final id = '${category}_shield_$days';
      if (currentStreak >= days && !box.get(id, defaultValue: false)) {
        await box.put(id, true);
        unlockedNew = true;
      }
    }
    return unlockedNew;
  }

  static Widget buildBadgeSection(String category) {
    final badges = getBadgesForCategory(category);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('نظام الدروع (تكوين العادات) 🛡️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final b = badges[index];
              return Opacity(
                opacity: b.isUnlocked ? 1.0 : 0.2,
                child: Container(
                  width: 75,
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: b.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: b.isUnlocked ? Border.all(color: b.color, width: 2) : Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(b.icon, style: const TextStyle(fontSize: 22)),
                          if (b.isUnlocked)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: Icon(Icons.check_circle, color: Colors.green, size: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${b.days} يوم',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: b.isUnlocked ? b.color : Colors.grey),
                      ),
                      Text(
                        b.title, 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 8, color: b.isUnlocked ? Colors.black87 : Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
