import 'package:flutter/material.dart';
import '../app_theme.dart';

class SelfDialogueWidget extends StatefulWidget {
  const SelfDialogueWidget({super.key});

  @override
  State<SelfDialogueWidget> createState() => _SelfDialogueWidgetState();
}

class _SelfDialogueWidgetState extends State<SelfDialogueWidget> {
  int _currentIndex = 0;

  final List<Map<String, String>> _dialogue = [
    {
      'question': 'أنا: يا نفسُ، إنِّي سائِلُكِ عن شيءٍ، فإنْ صدقتِني نظرتُ في أمركِ.',
      'answer': 'نفسي: سَلْني عمَّا شئتَ، فلن أقولَ إلا الحقَّ.'
    },
    {
      'question': 'أنا: أخبريني، لو أنَّ مَلَكَ الموتِ أتاكِ ليقبضَ روحَكِ، أكان يَسُرُّكِ أن تُقضى لكِ هذه الشهوة؟',
      'answer': 'نفسي: اللهمَّ لا.'
    },
    {
      'question': 'أنا: صدقتِ. ولو أُدخلتِ قبرَكِ، وأُجلِستِ للمسألة، أكان يَسُرُّكِ أن تُقضى لكِ هذه الشهوة؟',
      'answer': 'نفسي: اللهمَّ لا.'
    },
    {
      'question': 'أنا: صدقتِ. ولو أُعطي الناسُ كتبَهم، ولا تدرينَ أتأخذينَ كتابَكِ بيمينِكِ أم بشمالِكِ، أكان يَسُرُّكِ أن تُقضى لكِ هذه الشهوة؟',
      'answer': 'نفسي: اللهمَّ لا.'
    },
    {
      'question': 'أنا: صدقتِ. ولو أردتِ المرورَ على الصراطِ، ولا تدرينَ أتنجينَ أم لا تنجين، أكان يَسُرُّكِ أن تُقضى لكِ هذه الشهوة؟',
      'answer': 'نفسي: اللهمَّ لا.'
    },
    {
      'question': 'أنا: صدقتِ. ولو وُضع الميزانُ، وجيءَ بكِ، ولا تدرينَ أيَخفُّ ميزانُكِ أم يثقُل، أكان يَسُرُّكِ أن تُقضى لكِ هذه الشهوة؟',
      'answer': 'نفسي: اللهمَّ لا.'
    },
    {
      'question': 'أنا: صدقتِ. ولو وقفتِ بين يديِ اللهِ للمسألة، أكان يَسُرُّكِ أن تُقضى لكِ هذه الشهوة؟',
      'answer': 'نفسي: اللهمَّ لا.'
    },
    {
      'question': 'أنا: فاتَّقي اللهَ يا نفسُ، فقد أنعمَ اللهُ عليكِ وأحسنَ إليكِ.',
      'answer': 'آمبين.. ثبّتنا الله.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8A24A).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'محاورة مع النفس 🗣️',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFC8A24A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey(_currentIndex),
              children: [
                Text(
                  _dialogue[_currentIndex]['question']!,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_currentIndex < _dialogue.length - 1) {
                        _currentIndex++;
                      } else {
                        _currentIndex = 0; // Reset or show completion
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8A24A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    _dialogue[_currentIndex]['answer']!,
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _dialogue.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index ? const Color(0xFFC8A24A) : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
