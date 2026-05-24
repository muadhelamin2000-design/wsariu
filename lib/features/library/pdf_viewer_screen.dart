import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'services/library_service.dart';
import 'models/library_models.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final String fileId;
  final int initialPage;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
    required this.fileId,
    this.initialPage = 0,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _checkFile();
  }

  void _checkFile() {
    if (!File(widget.filePath).existsSync()) {
      setState(() {
        _errorMessage = 'الملف غير موجود في المسار: ${widget.filePath}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: _showNotesDialog,
            tooltip: 'الملاحظات',
          ),
          if (_isReady)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${_currentPage + 1} / $_totalPages'),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            defaultPage: _currentPage,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
                _isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                _errorMessage = '$page: ${error.toString()}';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              if (page != null) {
                setState(() {
                  _currentPage = page;
                });
                LibraryService.updateCurrentUnit(widget.fileId, page);
              }
            },
          ),
          if (!_isReady)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage.isNotEmpty)
            Center(child: Text(_errorMessage)),
        ],
      ),
      floatingActionButton: _isReady 
          ? FloatingActionButton(
              mini: true,
              onPressed: () {
                _showJumpToPageDialog();
              },
              child: const Icon(Icons.find_in_page),
            )
          : null,
    );
  }

  void _showNotesDialog() {
    final file = LibraryService.getFileById(widget.fileId);
    if (file == null) return;

    final controller = TextEditingController(text: file.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملاحظات وفوائد'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'دون فوائدك من الكتاب هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await LibraryService.saveFile(file.copyWith(notes: controller.text));
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الملاحظات')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showJumpToPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتقل إلى صفحة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'رقم الصفحة'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page > 0 && page <= _totalPages) {
                _pdfViewController?.setPage(page - 1);
              }
              Navigator.pop(context);
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
  }
}
