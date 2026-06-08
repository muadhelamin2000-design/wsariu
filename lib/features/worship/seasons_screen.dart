import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/season_model.dart';
import 'services/season_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_dialog.dart';

class SeasonsScreen extends StatefulWidget {
  const SeasonsScreen({super.key});

  @override
  State<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen> {
  List<WorshipSeason> _seasons = [];

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  void _loadSeasons() {
    setState(() {
      _seasons = SeasonService.getSeasons();
    });
  }

  Future<void> _addSeason() async {
    final nameController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('موسم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الموسم'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(ctx, {'name': nameController.text});
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      await SeasonService.saveSeason(WorshipSeason(
        name: result['name'],
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      ));
      _loadSeasons();
    }
  }

  Future<void> _deleteSeason(WorshipSeason season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الموسم'),
        content: Text('هل أنت متأكد من حذف "${season.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SeasonService.deleteSeason(season.id);
      _loadSeasons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواسم الإيمانية'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addSeason),
        ],
      ),
      body: _seasons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('لا توجد مواسم بعد', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('أضف موسماً جديداً لبدء رحلة إيمانية', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _seasons.length,
              itemBuilder: (context, index) {
                final season = _seasons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                    ),
                    title: Text(season.name),
                    subtitle: Text(
                      '${season.startDate.toString().split(' ')[0]} - ${season.endDate.toString().split(' ')[0]}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteSeason(season),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
