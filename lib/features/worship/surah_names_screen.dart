import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SurahNamesScreen extends StatefulWidget {
  const SurahNamesScreen({super.key});

  @override
  State<SurahNamesScreen> createState() => _SurahNamesScreenState();
}

class _SurahNamesScreenState extends State<SurahNamesScreen> {
  List<dynamic> _surahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahNames();
  }

  Future<void> _loadSurahNames() async {
    try {
      final String response = await rootBundle.loadString('assets/json/surahs_name.json');
      final data = await json.decode(response);
      setState(() {
        _surahs = data['data']['surahs'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تحميل أسماء السور')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسماء السور'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _surahs.length,
              itemBuilder: (context, index) {
                final surah = _surahs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        '${surah['number']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      surah['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      '${surah['englishName']} - ${surah['revelationType']} - ${surah['ayahsNumber']} آية',
                    ),
                    onTap: () {
                       // Navigate to specific surah in Quran screen
                       context.push('/worship/quran', extra: {'surahNumber': surah['number']});
                    },
                  ),
                );
              },
            ),
    );
  }
}
