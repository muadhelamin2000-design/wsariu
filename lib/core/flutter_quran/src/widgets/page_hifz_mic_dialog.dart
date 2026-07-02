import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wasariu/core/flutter_quran/src/models/ayah.dart';
import 'package:wasariu/core/utils/app_colors.dart';
import 'package:arabic_search/arabic_search.dart';

class PageHifzMicDialog extends StatefulWidget {
  final List<Ayah> ayahs;
  final int pageNumber;
  const PageHifzMicDialog({required this.ayahs, required this.pageNumber, super.key});

  @override
  State<PageHifzMicDialog> createState() => _PageHifzMicDialogState();
}

class _PageHifzMicDialogState extends State<PageHifzMicDialog> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _currentWords = "";
  List<String> _allWords = [];
  List<bool> _revealed = [];
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    for (var ayah in widget.ayahs) {
      _allWords.addAll(ayah.ayah.trim().split(RegExp(r'\s+')));
    }
    _revealed = List.filled(_allWords.length, false);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        if (mounted) {
          setState(() {
            _isListening = true;
            _currentWords = "";
          });
        }
        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _currentWords = val.recognizedWords;
                _compareResult(_currentWords);
              });
            }
          },
          localeId: 'ar-SA',
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
        );
      } else {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خدمة التعرف على الصوت غير متوفرة')),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isListening = false);
      }
      _speech.stop();
    }
  }

  void _compareResult(String recognized) {
    List<String> recognizedWords = recognized.split(RegExp(r'\s+'));
    for (var recWord in recognizedWords) {
      String normRec = ArabicText.normalize(recWord);
      for (int i = 0; i < _allWords.length; i++) {
        if (!_revealed[i]) {
          String normAyah = ArabicText.normalize(_allWords[i]);
          if (normRec == normAyah || _isSimilar(normRec, normAyah)) {
            _revealed[i] = true;
          }
        }
      }
    }
  }

  bool _isSimilar(String s1, String s2) {
    if (s1.length < 2 || s2.length < 2) return s1 == s2;
    return s1.contains(s2) || s2.contains(s1);
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.getMainColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog.fullscreen(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (_isListening) _speech.stop();
                    Navigator.pop(context);
                  },
                ),
                Text(
                  'تسميع الصفحة ${widget.pageNumber}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: mainColor,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            SizedBox(height: 25.h),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: mainColor.withOpacity(0.1)),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 10,
                    children: List.generate(_allWords.length, (index) {
                      bool isRevealed = _revealed[index] || _showAll;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isRevealed ? Colors.transparent : mainColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          isRevealed ? _allWords[index] : "......",
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 19.sp,
                            height: 1.5,
                            color: isRevealed 
                                ? (isDark ? Colors.white : mainColor) 
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            if (_currentWords.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  "ما تم التقاطه: $_currentWords",
                  style: TextStyle(
                    fontSize: 13.sp, 
                    fontStyle: FontStyle.italic, 
                    color: Colors.blue,
                    fontFamily: 'Cairo'
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(
                  icon: _showAll ? Icons.visibility : Icons.visibility_off,
                  onTap: () => setState(() => _showAll = !_showAll),
                  color: Colors.grey,
                  tooltip: "إظهار/إخفاء الكل",
                ),
                GestureDetector(
                  onTap: _listen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 70.r,
                    height: 70.r,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : mainColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : mainColor).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 35.r,
                    ),
                  ),
                ),
                _buildActionBtn(
                  icon: Icons.refresh,
                  onTap: () => setState(() {
                    _revealed = List.filled(_allWords.length, false);
                    _currentWords = "";
                  }),
                  color: Colors.orange,
                  tooltip: "إعادة البدء",
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required VoidCallback onTap, required Color color, required String tooltip}) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24.sp),
      ),
      tooltip: tooltip,
    );
  }
}
