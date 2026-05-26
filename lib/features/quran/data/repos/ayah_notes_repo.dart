import '../models/ayah_note_model.dart';

class AyahNotesRepo {
  static Future<List<AyahNoteModel>> getNotesByAyahId(int ayahId) async {
    return [];
  }

  static Future<void> addNote(AyahNoteModel note) async {}
  static Future<void> deleteNote(int id) async {}
}
