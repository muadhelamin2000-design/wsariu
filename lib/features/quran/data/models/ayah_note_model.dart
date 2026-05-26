class AyahNoteModel {
  final int? id;
  final int ayahId;
  final int surahNumber;
  final int ayahNumber;
  final String note;
  final String createdAt;

  AyahNoteModel({
    this.id,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.note,
    required this.createdAt,
  });
}
