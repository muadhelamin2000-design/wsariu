import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_theme.dart';

class SectionNavigator extends StatelessWidget {
  final String currentRoute;
  final List<SectionPage> pages;
  final Color activeColor;

  const SectionNavigator({
    super.key,
    required this.currentRoute,
    required this.pages,
    this.activeColor = AppTheme.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final page = pages[index];
          final bool isSelected = currentRoute == page.route;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ActionChip(
              onPressed: () => context.go(page.route),
              avatar: Icon(
                page.icon,
                size: 16,
                color: isSelected ? Colors.white : activeColor,
              ),
              label: Text(
                page.title,
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              backgroundColor: isSelected ? activeColor : Colors.white,
              side: BorderSide(color: activeColor, width: isSelected ? 0 : 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }
}

class SectionPage {
  final String title;
  final String route;
  final IconData icon;

  SectionPage({required this.title, required this.route, required this.icon});
}
