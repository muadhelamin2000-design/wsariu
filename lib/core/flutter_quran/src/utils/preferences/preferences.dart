class Preferences {
  final String bookmarks = 'bookmarks';
  final String lastPage = 'last_page';
  final String pageColor = 'page_color';
  final String highlights = 'highlights';

  static final Preferences _instance = Preferences._internal();

  factory Preferences() {
    return _instance;
  }

  Preferences._internal();
}
