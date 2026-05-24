import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'services/browser_service.dart';
import '../../core/widgets/modern_dialog.dart';
import '../../core/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class ConsciousBrowserScreen extends StatefulWidget {
  final String? initialUrl;
  const ConsciousBrowserScreen({super.key, this.initialUrl});

  @override
  State<ConsciousBrowserScreen> createState() => _ConsciousBrowserScreenState();
}

class _ConsciousBrowserScreenState extends State<ConsciousBrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = "";
  bool _isBlocked = false;
  double _progress = 0;
  
  // Stats tracking
  DateTime? _pageStartTime;
  
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl ?? "https://www.google.com";
    _urlController.text = _currentUrl;
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _isBlocked = BrowserService.isBlocked(url);
              });
            }
            if (_isBlocked) {
              _controller.loadHtmlString(_buildBlockedHtml());
            } else {
              _pageStartTime = DateTime.now();
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
                _urlController.text = url;
              });
            }
            _injectConsciousScripts(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Browser Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('wasariu://')) {
              if (request.url.contains('emergency')) {
                 context.push('/worship/awadho-allah');
              }
              return NavigationDecision.prevent;
            }
            if (BrowserService.isBlocked(request.url)) {
              if (mounted) setState(() => _isBlocked = true);
              _controller.loadHtmlString(_buildBlockedHtml());
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadUrl(_currentUrl);
  }

  void _loadUrl(String url) {
    String finalUrl = url.trim();
    Uri uri;
    if (finalUrl.startsWith('http')) {
      uri = Uri.parse(finalUrl);
    } else {
      uri = Uri.https('www.google.com', '/search', {'q': finalUrl});
    }
    
    final urlString = uri.toString();
    
    if (BrowserService.isBlocked(urlString)) {
      setState(() => _isBlocked = true);
      _controller.loadHtmlString(_buildBlockedHtml());
    } else {
      setState(() => _isBlocked = false);
      _controller.loadRequest(uri);
    }
  }

  void _injectConsciousScripts(String url) {
    if (url.contains('youtube.com')) {
      _controller.runJavaScript("""
        var style = document.createElement('style');
        style.innerHTML = `
          ytd-guide-entry-renderer:has(a[href*="/shorts"]),
          ytd-rich-grid-slim-media,
          ytd-reel-shelf-renderer,
          #comments,
          #related { display: none !important; }
        `;
        document.head.appendChild(style);
      """);
    }

    // General Search Result Filter
    final userKeywords = BrowserService.getUserBlockedKeywords();
    final allKeywords = [...[
      'porn', 'sex', 'xvideos', 'xnxx', 'neswanji', 'نسوانجي', 'سكس', 'نيك', '🔞', 'f95'
    ], ...userKeywords];
    
    final jsKeywords = allKeywords.map((k) => "'$k'").join(',');

    _controller.runJavaScript("""
      (function() {
        var keywords = [$jsKeywords];
        var links = document.querySelectorAll('a');
        links.forEach(function(link) {
          var href = link.href.toLowerCase();
          var text = link.innerText.toLowerCase();
          var shouldBlock = keywords.some(k => href.includes(k.toLowerCase()) || text.includes(k.toLowerCase()));
          
          if (shouldBlock) {
            var container = link.closest('div') || link.parentElement;
            if (container) container.style.display = 'none';
          }
        });
      })();
    """);
  }

  String _buildBlockedHtml() {
    return """
      <!DOCTYPE html>
      <html dir="rtl">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: sans-serif; background-color: #f8fafc; color: #1e293b; text-align: center; padding: 40px 20px; }
          .card { background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); }
          h1 { color: #b91c1c; font-size: 24px; }
          p { line-height: 1.6; margin: 20px 0; }
          .quote { font-style: italic; color: #0f3d2e; font-weight: bold; background: #f1f5f9; padding: 15px; border-radius: 10px; border-right: 4px solid #c8a24a; }
          .btn { display: inline-block; background: #0f3d2e; color: white; padding: 12px 25px; border-radius: 10px; text-decoration: none; margin: 10px 5px; font-weight: bold; }
          .btn-alt { background: #c8a24a; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>⚠️ مـسـاحـة واعية</h1>
          <p>تم حجب هذا الموقع لأنه قد يعيق تقدمك أو يحتوي على محتوى غير لائق.</p>
          <div class="quote">
            "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ"
          </div>
          <p>المجاهدة في ترك ما يضر هي أقصر طريق للراحة النفسية والبركة في الوقت.</p>
          <a href="javascript:history.back()" class="btn">الرجوع للخلف</a>
          <a href="wasariu://emergency" class="btn btn-alt">أنقذني الآن (عوضه الله)</a>
        </div>
      </body>
      </html>
    """;
  }

  void _loadFromController() {
    _loadUrl(_urlController.text);
  }

  final AudioPlayer _backgroundPlayer = AudioPlayer();

  Future<void> _playInBackground() async {
     final url = _currentUrl;
     // Basic check or just try streaming
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محاولة تشغيل الصوت في الخلفية...')));
     
     try {
       await _backgroundPlayer.setAudioSource(
         AudioSource.uri(
           Uri.parse(url),
           tag: MediaItem(
             id: url,
             title: "تصفح واعي",
             artist: "Wasariu",
           ),
         ),
       );
       _backgroundPlayer.play();
     } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، هذا الموقع لا يدعم البث المباشر للصوت.')));
     }
  }

  @override
  void dispose() {
    _backgroundPlayer.dispose();
    if (_pageStartTime != null) {
      final duration = DateTime.now().difference(_pageStartTime!).inSeconds;
      BrowserService.logUsage(_currentUrl, duration);
    }
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'ابحث أو أدخل رابطاً...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: (_) => _loadFromController(),
            ),
          ),
          actions: [
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ))
            else
              IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload()),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: _showStats,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading) LinearProgressIndicator(value: _progress, minHeight: 2, backgroundColor: Colors.transparent, color: AppTheme.primaryGreen),
            Expanded(child: WebViewWidget(controller: _controller)),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () async {
            if (await _controller.canGoBack()) _controller.goBack();
          }),
          IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20), onPressed: () async {
            if (await _controller.canGoForward()) _controller.goForward();
          }),
          IconButton(icon: const Icon(Icons.headphones_rounded, color: Colors.orange), onPressed: _playInBackground, tooltip: 'تشغيل في الخلفية'),
          IconButton(icon: const Icon(Icons.security_outlined, color: Colors.green), onPressed: _showSecuritySettings),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    ModernDialog.show(
      context: context,
      title: 'إعدادات الأمان والتصفح',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            leading: Icon(Icons.dns_outlined, color: Colors.blue),
            title: Text('نظام الحماية نشط'),
            subtitle: Text('CleanBrowsing + Cloudflare Family'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('إدارة الحظر (روابط/كلمات)'),
            onTap: () {
              Navigator.pop(context);
              _showBlockedManagement();
            },
          ),
          const ListTile(
            leading: Icon(Icons.remove_red_eye_outlined, color: Colors.purple),
            title: Text('وضع اليوتيوب الواعي'),
            subtitle: Text('إخفاء المقاطع القصيرة والتعليقات'),
          ),
        ],
      ),
    );
  }

  void _showBlockedManagement() {
    final domains = BrowserService.getBlockedDomains();
    final keywords = BrowserService.getUserBlockedKeywords();
    
    ModernDialog.show(
      context: context,
      title: 'إدارة الحظر الدائم',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'أضف رابطاً أو كلمة محظورة...',
                  helperText: 'سيتم الحظر فوراً وبشكل دائم',
                ),
                onSubmitted: (val) async {
                  if (val.isNotEmpty) {
                    if (val.contains('.')) {
                      await BrowserService.addBlockedDomain(val);
                    } else {
                      await BrowserService.addBlockedKeyword(val);
                    }
                    setDialogState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('قائمة الحظر الحالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (domains.isNotEmpty) ...[
                      const ListTile(title: Text('الروابط المحظورة', style: TextStyle(fontSize: 11, color: Colors.grey))),
                      ...domains.map((d) => ListTile(
                        leading: const Icon(Icons.link, size: 14, color: Colors.red),
                        title: Text(d, style: const TextStyle(fontSize: 13)),
                      )),
                    ],
                    if (keywords.isNotEmpty) ...[
                      const ListTile(title: Text('الكلمات المحظورة', style: TextStyle(fontSize: 11, color: Colors.grey))),
                      ...keywords.map((k) => ListTile(
                        leading: const Icon(Icons.text_format, size: 14, color: Colors.red),
                        title: Text(k, style: const TextStyle(fontSize: 13)),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStats() {
    final stats = BrowserService.getDailyStats(DateTime.now());
    final minutes = (stats['total_seconds'] ?? 0) ~/ 60;
    
    ModernDialog.show(
      context: context,
      title: 'إحصائيات التصفح اليوم',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$minutes', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          const Text('دقيقة من التصفح'),
          const SizedBox(height: 24),
          const Text('أكثر المواقع زيارة:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...((stats['history'] as List?) ?? []).take(5).map((h) => Text(Uri.parse(h['url']).host, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
