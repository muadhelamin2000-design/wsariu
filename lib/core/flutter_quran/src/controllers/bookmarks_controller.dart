import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/bookmark.dart';
import '../repository/quran_repository.dart';

class BookmarksCubit extends Cubit<List<Bookmark>> {
  BookmarksCubit({QuranRepository? quranRepository})
    : _quranRepository = quranRepository ?? QuranRepository(),
      super([]);

  final QuranRepository _quranRepository;

  List<Bookmark> bookmarks = [];

  void initBookmarks({List<Bookmark>? userBookmarks, bool overwrite = false}) {
    if (overwrite) {
      bookmarks = [...(userBookmarks ?? [])];
    } else {
      bookmarks = _quranRepository.getBookmarks();
    }

    if (bookmarks.isEmpty || !bookmarks.any((b) => b.id == 1)) {
      final mainBookmark = Bookmark(id: 1, colorCode: 0xAAF36077, name: 'العلامة الرئيسية');
      bookmarks.insert(0, mainBookmark);
      _quranRepository.saveBookmarks(bookmarks);
    }

    emit(List.from(bookmarks));
  }

  void addNamedBookmark(String name) {
    final int newId = bookmarks.isEmpty
        ? 1
        : bookmarks.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final newBookmark = Bookmark(id: newId, colorCode: 0xAAF36077, name: name);

    bookmarks.add(newBookmark);
    _quranRepository.saveBookmarks(bookmarks);
    emit(List.from(bookmarks));
  }

  void moveToPage(int bookmarkId, int page) {
    final index = bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      bookmarks[index].page = page;
      bookmarks[index].ayahId = -1;
      _quranRepository.saveBookmarks(bookmarks);
      emit(List.from(bookmarks));
    }
  }

  void moveToAyah(int bookmarkId, int ayahId, int page) {
    final index = bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      bookmarks[index].ayahId = ayahId;
      bookmarks[index].page = page;
      _quranRepository.saveBookmarks(bookmarks);
      emit(List.from(bookmarks));
    }
  }

  void updateBookmarkName(int id, String newName) {
    final index = bookmarks.indexWhere((b) => b.id == id);
    if (index != -1) {
      bookmarks[index].name = newName;
      _quranRepository.saveBookmarks(bookmarks);
      emit(List.from(bookmarks));
    }
  }

  void removeBookmark(int bookmarkId) {
    if (bookmarkId == 1) {
      final index = bookmarks.indexWhere((b) => b.id == 1);
      if (index != -1) {
        bookmarks[index].page = -1;
        bookmarks[index].ayahId = -1;
        _quranRepository.saveBookmarks(bookmarks);
        emit(List.from(bookmarks));
      }
      return;
    }

    bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    _quranRepository.saveBookmarks(bookmarks);
    emit(List.from(bookmarks));
  }
}
